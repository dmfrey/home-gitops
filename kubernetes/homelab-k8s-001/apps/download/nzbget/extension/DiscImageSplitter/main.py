#!/usr/bin/env python3
"""
NZBGet Post-Processing Extension: Disc Image Splitter

Runs after a successful download. Scans NZBPP_DIRECTORY for a FLAC+CUE
disc image, splits with shnsplit, applies CUE metadata with cuetag.sh,
and places the individual tracks back into NZBPP_DIRECTORY using Lidarr's
naming conventions so Lidarr picks them up in its normal completed-download
import flow:

  Sub-folder    : {Artist Name}/{Album Title} ({Release Year})/
  Track file    : {Artist Name} - {Album Title} - {track:00} - {Track Title}.flac

Does nothing (exit POSTPROCESS_NONE) for movies, TV shows, or normal
multi-track music releases — only acts when exactly one FLAC + CUE are found.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

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


def sanitize(name):
    return ILLEGAL_CHARS.sub("_", name).strip()


def cueprint(cue_path, fmt):
    """Extract disc-level metadata from a CUE file using cueprint."""
    try:
        result = subprocess.run(
            ["cueprint", "-d", fmt, str(cue_path)],
            capture_output=True, text=True, timeout=10,
        )
        return result.stdout.strip()
    except Exception:
        return ""


def get_flac_year(flac_path):
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


def extract_year_from_path(path):
    """Find a 4-digit year in the directory or parent directory names."""
    for part in reversed(path.parts):
        m = re.search(r"\b(19|20)\d{2}\b", part)
        if m:
            return m.group(0)
    return ""


def split_disc_image(flac_path, cue_path, output_base):
    # --- Metadata ---
    performer   = cueprint(cue_path, "%P") or flac_path.parent.name
    album_title = cueprint(cue_path, "%T") or flac_path.stem
    year        = get_flac_year(flac_path) or extract_year_from_path(flac_path)

    if not performer or not album_title:
        print("  Could not determine performer/album from CUE")
        return False

    album_dir_name = (
        f"{sanitize(album_title)} ({year})" if year else sanitize(album_title)
    )
    out_dir = output_base / sanitize(performer) / album_dir_name

    if out_dir.exists() and any(out_dir.glob("*.flac")):
        print("  Output already exists — skipping")
        return True

    print(f"  Artist : {performer}")
    print(f"  Album  : {album_title}" + (f" ({year})" if year else ""))
    print(f"  Output : {out_dir}")

    # --- Split with shnsplit into a temp dir ---
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)

        result = subprocess.run(
            [
                "shnsplit",
                "-f", str(cue_path),
                "-t", "%n - %t",
                "-o", "flac",
                "-d", tmp,
                str(flac_path),
            ],
            capture_output=True, text=True, timeout=600,
        )
        if result.returncode != 0:
            print(f"  ERROR shnsplit:\n{result.stderr[-500:]}")
            return False

        split_files = sorted(tmp_path.glob("*.flac"))
        if not split_files:
            print("  ERROR: shnsplit produced no output files")
            return False

        print(f"  Split into {len(split_files)} tracks")

        # --- Tag with cuetag.sh ---
        tag_result = subprocess.run(
            ["cuetag.sh", str(cue_path)] + [str(f) for f in split_files],
            capture_output=True, text=True, timeout=120,
        )
        if tag_result.returncode != 0:
            print(f"  WARNING cuetag.sh: {tag_result.stderr[-200:]}")

        # --- Rename to Lidarr format and move to final output dir ---
        out_dir.mkdir(parents=True, exist_ok=True)
        artist_san = sanitize(performer)
        album_san  = sanitize(album_title)
        moved = 0

        for f in split_files:
            m = re.match(r"^(\d+)\s*-\s*(.*)", f.stem)
            if m:
                track_num   = m.group(1).zfill(2)
                track_title = sanitize(m.group(2).strip())
            else:
                track_num   = "00"
                track_title = sanitize(f.stem)

            # Drop shnsplit pregap track (track 00 / silence before track 1)
            if track_num == "00":
                continue

            new_name = f"{artist_san} - {album_san} - {track_num} - {track_title}.flac"
            shutil.move(str(f), str(out_dir / new_name))
            moved += 1

        print(f"  Staged {moved} tracks to {out_dir}")
        return moved > 0


def find_disc_images(directory):
    """
    Recursively find directories with exactly one FLAC + at least one CUE.
    Applies size and filename heuristics to exclude partial downloads.
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

        if len(flacs) == 1 and cues:
            flac_name = flacs[0]
            flac_path = root_path / flac_name

            if TRACK_FILENAME_RE.match(flac_name):
                continue

            try:
                if flac_path.stat().st_size < MIN_DISC_IMAGE_BYTES:
                    continue
            except OSError:
                continue

            flac_stem   = Path(flac_name).stem.lower()
            matched_cue = next(
                (c for c in cues if Path(c).stem.lower() == flac_stem),
                cues[0],
            )
            results.append((root_path, flac_path, root_path / matched_cue))

    return results


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

    for dir_path, flac_path, cue_path in disc_images:
        print(f"\nFound: {dir_path.name}")
        print(f"  FLAC: {flac_path.name}")
        print(f"  CUE : {cue_path.name}")

        # Split tracks back into the same completed-download directory so
        # Lidarr picks them up in its normal post-download import flow.
        output_base = dir_path

        try:
            success = split_disc_image(flac_path, cue_path, output_base)
            if success:
                (dir_path / PROCESSED_MARKER).touch()
                print("  Marked as processed.")
                processed += 1
            else:
                failed += 1
        except subprocess.TimeoutExpired:
            print(f"  ERROR: shnsplit timed out on {flac_path.name}")
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
