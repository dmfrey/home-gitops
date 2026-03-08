#!/usr/bin/env python3
"""
NZBGet Post-Processing Extension: Disc Image Splitter

Runs after a successful download. Scans NZBPP_DIRECTORY for a FLAC+CUE
disc image, splits with ffmpeg, applies tags with metaflac, and places
the individual tracks back into NZBPP_DIRECTORY using Lidarr's naming
conventions so Lidarr picks them up in its normal completed-download
import flow:

  Sub-folder    : {Artist Name}/{Album Title} ({Release Year})/
  Track file    : {Artist Name} - {Album Title} - {track:00} - {Track Title}.flac

Supports both single-file and multi-file (e.g. vinyl Side A/B) CUE sheets.
Does nothing (exit POSTPROCESS_NONE) for movies, TV shows, or normal
multi-track music releases.
"""

import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional

# NZBGet environment variables
NZBPP_DIRECTORY   = os.environ.get("NZBPP_DIRECTORY", "")
NZBPP_TOTALSTATUS = os.environ.get("NZBPP_TOTALSTATUS", "")

PROCESSED_MARKER     = ".disc_split_done"
ILLEGAL_CHARS        = re.compile(r'[\\/:*?"<>|]')
# Minimum FLAC size for a disc image (150 MB).
MIN_DISC_IMAGE_BYTES = 150 * 1024 * 1024
# Filenames starting with a track number are individual tracks, not disc images.
TRACK_FILENAME_RE    = re.compile(r"^\d+[\s.\-_]")

# NZBGet exit codes
POSTPROCESS_SUCCESS = 93
POSTPROCESS_ERROR   = 94
POSTPROCESS_NONE    = 95  # not applicable — does not affect download status


# ---------------------------------------------------------------------------
# CUE sheet parser
# ---------------------------------------------------------------------------

@dataclass
class CueTrack:
    number: int
    title: str = ""
    performer: str = ""
    index01: Optional[float] = None  # seconds from start of file


@dataclass
class CueFile:
    filename: str
    tracks: List[CueTrack] = field(default_factory=list)


@dataclass
class CueSheet:
    performer: str = ""
    title: str = ""
    files: List[CueFile] = field(default_factory=list)


def _cue_timestamp_to_seconds(mm: int, ss: int, ff: int) -> float:
    """Convert CUE MM:SS:FF (75 frames/sec) to fractional seconds."""
    return mm * 60.0 + ss + ff / 75.0


def parse_cue(cue_path: Path) -> CueSheet:
    """Parse a CUE sheet file and return structured disc/track metadata."""
    sheet = CueSheet()
    current_file: Optional[CueFile] = None
    current_track: Optional[CueTrack] = None

    for encoding in ("utf-8-sig", "utf-8", "latin-1"):
        try:
            lines = cue_path.read_text(encoding=encoding).splitlines()
            break
        except (UnicodeDecodeError, LookupError):
            continue
    else:
        return sheet

    for line in lines:
        line = line.strip()

        m = re.match(r'FILE\s+"(.+?)"\s+\S+', line, re.IGNORECASE)
        if m:
            if current_track is not None and current_file is not None:
                current_file.tracks.append(current_track)
                current_track = None
            current_file = CueFile(filename=m.group(1))
            sheet.files.append(current_file)
            continue

        m = re.match(r'PERFORMER\s+"(.*)"', line, re.IGNORECASE)
        if m:
            if current_track is not None:
                current_track.performer = m.group(1)
            elif current_file is None:
                sheet.performer = m.group(1)
            continue

        m = re.match(r'TITLE\s+"(.*)"', line, re.IGNORECASE)
        if m:
            if current_track is not None:
                current_track.title = m.group(1)
            elif current_file is None:
                sheet.title = m.group(1)
            continue

        m = re.match(r'TRACK\s+(\d+)\s+AUDIO', line, re.IGNORECASE)
        if m:
            if current_track is not None and current_file is not None:
                current_file.tracks.append(current_track)
            current_track = CueTrack(number=int(m.group(1)))
            continue

        # Only INDEX 01 — this is the playback start (INDEX 00 is pre-gap)
        m = re.match(r'INDEX\s+01\s+(\d+):(\d+):(\d+)', line, re.IGNORECASE)
        if m and current_track is not None:
            current_track.index01 = _cue_timestamp_to_seconds(
                int(m.group(1)), int(m.group(2)), int(m.group(3))
            )
            continue

    if current_track is not None and current_file is not None:
        current_file.tracks.append(current_track)

    for cue_file in sheet.files:
        cue_file.tracks = [t for t in cue_file.tracks if t.index01 is not None]

    return sheet


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def sanitize(name: str) -> str:
    return ILLEGAL_CHARS.sub("_", name).strip()


def get_flac_year(flac_path: Path) -> str:
    """Extract the DATE tag from a FLAC file using metaflac."""
    try:
        result = subprocess.run(
            ["metaflac", "--show-tag=DATE", str(flac_path)],
            capture_output=True, text=True, timeout=10,
        )
        m = re.search(r"\b(19|20)\d{2}\b", result.stdout)
        if m:
            return m.group(0)
    except Exception:
        pass
    return ""


def extract_year_from_path(path: Path) -> str:
    """Find a 4-digit year in the directory or parent directory names."""
    for part in reversed(path.parts):
        m = re.search(r"\b(19|20)\d{2}\b", part)
        if m:
            return m.group(0)
    return ""


# ---------------------------------------------------------------------------
# Splitting
# ---------------------------------------------------------------------------

def split_cue_file(
    cue_file: CueFile,
    dir_path: Path,
    performer: str,
    album_title: str,
    year: str,
    out_dir: Path,
) -> int:
    flac_path = dir_path / cue_file.filename
    if not flac_path.exists():
        flacs = list(dir_path.glob("*.flac"))
        stem = Path(cue_file.filename).stem.lower()
        flac_path = next((f for f in flacs if f.stem.lower() == stem), None)
        if not flac_path:
            print(f"  WARNING: FLAC not found for FILE entry: {cue_file.filename}")
            return 0

    artist_san = sanitize(performer)
    album_san  = sanitize(album_title)
    tracks     = cue_file.tracks
    moved      = 0

    for i, track in enumerate(tracks):
        track_num   = str(track.number).zfill(2)
        track_title = sanitize(track.title or f"Track {track.number}")
        out_file    = out_dir / f"{artist_san} - {album_san} - {track_num} - {track_title}.flac"

        cmd = [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", str(flac_path),
            "-ss", f"{track.index01:.6f}",
        ]
        if i + 1 < len(tracks):
            duration = tracks[i + 1].index01 - track.index01
            cmd += ["-t", f"{duration:.6f}"]
        cmd += ["-c:a", "flac", str(out_file)]

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        if result.returncode != 0:
            print(f"  ERROR ffmpeg track {track_num}: {result.stderr[-400:]}")
            continue

        tags = {
            "TITLE":       track.title or f"Track {track.number}",
            "ARTIST":      track.performer or performer,
            "ALBUM":       album_title,
            "TRACKNUMBER": str(track.number),
        }
        if year:
            tags["DATE"] = year

        tag_args = [f"--set-tag={k}={v}" for k, v in tags.items()]
        subprocess.run(
            ["metaflac", "--remove-all-tags"] + tag_args + [str(out_file)],
            capture_output=True, timeout=30,
        )

        moved += 1

    return moved


def split_disc_image(flac_paths: List[Path], cue_path: Path, output_base: Path) -> bool:
    sheet = parse_cue(cue_path)

    performer   = sheet.performer or cue_path.parent.name
    album_title = sheet.title or cue_path.stem
    year        = get_flac_year(flac_paths[0]) or extract_year_from_path(cue_path)

    if not performer or not album_title:
        print("  Could not determine performer/album from CUE")
        return False

    all_tracks = [t for f in sheet.files for t in f.tracks]
    if not all_tracks:
        print("  No tracks with INDEX 01 found in CUE file")
        return False

    album_dir_name = (
        f"{sanitize(album_title)} ({year})" if year else sanitize(album_title)
    )
    out_dir = output_base / sanitize(performer) / album_dir_name

    if out_dir.exists() and any(out_dir.glob("*.flac")):
        print("  Output already exists — skipping")
        return True

    print(f"  Artist  : {performer}")
    print(f"  Album   : {album_title}" + (f" ({year})" if year else ""))
    print(f"  Files   : {len(sheet.files)}")
    print(f"  Tracks  : {len(all_tracks)}")
    print(f"  Output  : {out_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)
    dir_path = cue_path.parent
    moved = 0

    for cue_file in sheet.files:
        moved += split_cue_file(cue_file, dir_path, performer, album_title, year, out_dir)

    print(f"  Staged {moved} tracks to {out_dir}")
    return moved > 0


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def find_disc_images(directory: str):
    """
    Recursively find directories containing a CUE sheet where all referenced
    FLACs are present and none are individually named tracks.
    """
    results = []
    scan_path = Path(directory)

    if not scan_path.exists():
        return results

    for root, dirs, files in os.walk(scan_path):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        root_path = Path(root)

        if (root_path / PROCESSED_MARKER).exists():
            continue

        flacs = [f for f in files if f.lower().endswith(".flac")]
        cues  = [f for f in files if f.lower().endswith(".cue")]

        if not cues or not flacs:
            continue

        # Skip if any FLAC looks like an individual track
        if any(TRACK_FILENAME_RE.match(f) for f in flacs):
            continue

        cue_path = root_path / cues[0]

        # Parse CUE to find referenced FLACs
        sheet = parse_cue(cue_path)
        if not sheet.files:
            continue

        referenced = [cf.filename for cf in sheet.files]
        flac_paths = []
        for ref in referenced:
            p = root_path / ref
            if not p.exists():
                stem = Path(ref).stem.lower()
                p = next((root_path / f for f in flacs if Path(f).stem.lower() == stem), None)
            if p and p.exists():
                flac_paths.append(p)

        if len(flac_paths) != len(referenced):
            continue

        # All referenced FLACs must meet minimum size
        try:
            if not all(p.stat().st_size >= MIN_DISC_IMAGE_BYTES for p in flac_paths):
                continue
        except OSError:
            continue

        results.append((root_path, flac_paths, cue_path))

    return results


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    if NZBPP_TOTALSTATUS != "SUCCESS":
        sys.exit(POSTPROCESS_NONE)

    if not NZBPP_DIRECTORY:
        sys.exit(POSTPROCESS_NONE)

    print(f"[DiscImageSplitter] Checking: {NZBPP_DIRECTORY}")

    disc_images = find_disc_images(NZBPP_DIRECTORY)
    if not disc_images:
        print("[DiscImageSplitter] No disc images found.")
        sys.exit(POSTPROCESS_NONE)

    processed = failed = 0

    for dir_path, flac_paths, cue_path in disc_images:
        print(f"\nFound: {dir_path.name}")
        for fp in flac_paths:
            print(f"  FLAC: {fp.name}")
        print(f"  CUE : {cue_path.name}")

        output_base = dir_path

        try:
            success = split_disc_image(flac_paths, cue_path, output_base)
            if success:
                (dir_path / PROCESSED_MARKER).touch()
                print("  Marked as processed.")
                processed += 1
            else:
                failed += 1
        except subprocess.TimeoutExpired:
            print(f"  ERROR: ffmpeg timed out")
            failed += 1
        except Exception as exc:
            print(f"  ERROR: {exc}")
            failed += 1

    print(f"\n[DiscImageSplitter] Processed: {processed}  Failed: {failed}")

    if processed > 0:
        print("[DiscImageSplitter] Tracks split in-place; Lidarr will import from the completed folder.")
        sys.exit(POSTPROCESS_SUCCESS)

    sys.exit(POSTPROCESS_NONE)


if __name__ == "__main__":
    main()
