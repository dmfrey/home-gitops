#!/bin/sh

directory="$1"
output_file="$2"

combined_array=""

# Iterate over files in the directory
for user_file in "$directory"/*_USER; do
  pass_file="${user_file%_USER}_PASS"

  # Check if the corresponding "_PASS" file exists
  if [ -f "$pass_file" ]; then
    # Combine the contents of the files using ":" delimiter
    combined_value="$(cat "$user_file"):$(cat "$pass_file")"
    combined_array="${combined_array}${combined_array:+
}$combined_value"
  else
    echo "No corresponding _PASS file found for $user_file"
    exit 1
  fi
done

# Append the combined values to the output file
printf "%s\n" "$combined_array" > "$output_file"
