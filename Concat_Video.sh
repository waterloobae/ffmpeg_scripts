#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_list_file> <output_file>"
  exit 1
fi

# Extract the input list file and output filename
input_list_file="$1"
output_file="$2"

# Check if the input list file exists
if [ ! -f "$input_list_file" ]; then
  echo "Error: Input list file '$input_list_file' does not exist."
  exit 1
fi

# Create a temporary directory in the current directory to store intermediate files
tmp_dir=$(mktemp -d "$(pwd)/tmp.XXXXXX")
echo "Using temporary directory: $tmp_dir"

# Create a list of input videos
input_videos=()
while IFS= read -r input_video; do
  if [ -n "$input_video" ]; then
    input_videos+=("$input_video")
  fi
done < "$input_list_file"

# Process each input video with fade-in and fade-out
input_files=()
index=0
for input_video in "${input_videos[@]}"; do
  intermediate_file="$tmp_dir/faded_$index.mp4"

  # Get the duration of the input video
  duration=$(ffprobe -i "$input_video" -show_entries format=duration -v quiet -of csv="p=0")

  # Calculate fade durations
  fade_duration=1  # Adjust fade duration as needed
  fade_out_start=$(echo "$duration - $fade_duration" | bc)

  # Apply fade-in and fade-out
  ffmpeg -hwaccel auto \
    -i "$input_video" \
    -vf "fade=t=in:st=0:d=$fade_duration,fade=t=out:st=$fade_out_start:d=$fade_duration" \
    -c:v libx264 -crf 18 -preset veryfast \
    -c:a copy \
    "$intermediate_file"

  input_files+=("$intermediate_file")
  index=$((index + 1))
done

# Create a text file listing the processed files for concatenation
concat_list="$tmp_dir/concat_list.txt"
touch "$concat_list"
for file in "${input_files[@]}"; do
  echo "file '$file'" >> "$concat_list"
done

# Concatenate the videos
ffmpeg -hwaccel auto -f concat -safe 0 -i "$concat_list" -c copy "$output_file"

# Clean up
echo "Cleaning up temporary files..."
rm -r "$tmp_dir"

echo "Output video created: $output_file"
