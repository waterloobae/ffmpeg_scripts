#!/bin/bash

# Arguments
INPUT_FILE="$1"
RANGES_FILE="$2"
OUTPUT_FILE="$3"

# Check if all arguments are provided
if [ $# -ne 3 ]; then
  echo "Usage: $0 <input_file> <ranges_file> <output_file>"
  echo "Example: $0 input.mp4 ranges.txt output.mp4"
  exit 1
fi

# Temporary directory for intermediate files
TEMP_DIR=$(mktemp -d)
FINAL_CONCAT_LIST="$TEMP_DIR/concat_list.txt"

# Function to convert mm:ss to seconds
time_to_seconds() {
    local time=$1
    local IFS=:  # Internal Field Separator
    read -r mm ss <<< "$time"
    echo $((10#${mm} * 60 + 10#${ss}))
}

# Function to process each range
process_range() {
    local start_time=$1
    local end_time=$2
    local segment_file="$TEMP_DIR/segment_${start_time}_${end_time}.mp4"
    local fade_duration=2

    # Convert start and end times to seconds
    local start_seconds=$(time_to_seconds "$start_time")
    local end_seconds=$(time_to_seconds "$end_time")

    # Extract the segment
    ffmpeg -hwaccel auto -ss "$start_seconds" -to "$end_seconds" -i "$INPUT_FILE" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "$segment_file" -y

    # Apply fade-in and fade-out effects
    local fadein_file="$TEMP_DIR/fadein_${start_time}_${end_time}.mp4"
    local fadeout_file="$TEMP_DIR/fadeout_${start_time}_${end_time}.mp4"

    ffmpeg -i "$segment_file" -vf "fade=t=in:st=0:d=$fade_duration" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "$fadein_file" -y
    ffmpeg -i "$fadein_file" -vf "fade=t=out:st=$(echo "$end_seconds - $start_seconds - $fade_duration" | bc):d=$fade_duration" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "$fadeout_file" -y

    # Add segment with fades to the list
    echo "file '$fadeout_file'" >> "$FINAL_CONCAT_LIST"
}

# Read the ranges file and store in an array, ignoring empty lines
ranges=()
while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ]; then
        ranges+=("$line")
    fi
done < "$RANGES_FILE"

# Process each range
for range in "${ranges[@]}"; do
    start_time=$(echo "$range" | cut -d ' ' -f 1)
    end_time=$(echo "$range" | cut -d ' ' -f 2)
    process_range "$start_time" "$end_time"
done

# Concatenate all segments into the final output file
ffmpeg -f concat -safe 0 -i "$FINAL_CONCAT_LIST" -c copy "$OUTPUT_FILE" -y
if [ $? -ne 0 ]; then
    echo "Error concatenating segments"
    exit 1
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete. Output file: $OUTPUT_FILE"