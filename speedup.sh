#!/bin/bash

# Input parameters
INPUT_FILE="$1"
RANGES_FILE="$2"
FRAMERATE=30

if [ -z "$INPUT_FILE" ] || [ -z "$RANGES_FILE" ]; then
    echo "Usage: $0 <input_file> <ranges_file>"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
if [ ! -d "$TEMP_DIR" ]; then
    echo "Failed to create temporary directory"
    exit 1
fi

OUTPUT_FILE="output.mp4"
FINAL_CONCAT_LIST="$TEMP_DIR/final_concat_list.txt"

# Empty the concat list file
> "$FINAL_CONCAT_LIST"

# Function to process a normal speed segment
process_normal_segment() {
    local start_time="$1"
    local end_time="$2"
    local segment_file="$TEMP_DIR/normal_${start_time//:/-}_${end_time//:/-}.mp4"
    
    # Generate normal speed segment with re-encoding
    ffmpeg -fflags +genpts -hwaccel auto -r "$FRAMERATE" -ss "$start_time" -to "$end_time" -i "$INPUT_FILE" -r "$FRAMERATE" -avoid_negative_ts make_zero -fps_mode cfr -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k "$segment_file" -y
    if [ $? -ne 0 ]; then
        echo "Error processing normal segment: $start_time to $end_time"
        exit 1
    fi
    
    # Add segment to the list
    echo "file '$segment_file'" >> "$FINAL_CONCAT_LIST"
}

# Function to process sped-up segment
process_sped_up_segment() {
    local start_time="$1"
    local end_time="$2"
    local segment_file="$TEMP_DIR/sped_${start_time//:/-}_${end_time//:/-}.mp4"
    
    # Generate sped-up segment with 20x speed increase and re-encoding
    ffmpeg -fflags +genpts -hwaccel auto -r "$FRAMERATE" -ss "$start_time" -to "$end_time" -i "$INPUT_FILE" -r "$FRAMERATE" -avoid_negative_ts make_zero -fps_mode cfr -filter_complex "[0:v]setpts=0.05*PTS[v];[0:a]atempo=2.0,atempo=2.0,atempo=2.5[a]" -map "[v]" -map "[a]" -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k "$segment_file" -y
    if [ $? -ne 0 ]; then
        echo "Error processing sped-up segment: $start_time to $end_time"
        exit 1
    fi
    
    # Add sped-up segment to the list
    echo "file '$segment_file'" >> "$FINAL_CONCAT_LIST"
}

# Get the duration of the input file
input_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
input_duration=$(echo "$input_duration" | awk '{printf "%02d:%02d:%02d\n", $1/3600, ($1%3600)/60, $1%60}')

# Read the ranges file and store in an array
ranges=()

while IFS= read -r line; do
    ranges+=("$line")
done < "$RANGES_FILE"

# Debug: Echo the ranges
echo "Ranges:"
for range in "${ranges[@]}"; do
    echo "$range"
done

# Process each range
previous_end_time="00:00:00"
for range in "${ranges[@]}"; do
    IFS=' ' read -r start_time end_time <<< "$range"
    
    # Process the segment before the current range
    if [ "$previous_end_time" != "$start_time" ]; then
        process_sped_up_segment "$previous_end_time" "$start_time"
    fi
    
    # Process the current range as normal speed
    process_normal_segment "$start_time" "$end_time"
    
    # Update the previous end time
    previous_end_time="$end_time"
done

# Process the segment after the last range
if [ "$previous_end_time" != "$input_duration" ]; then
    process_sped_up_segment "$previous_end_time" "$input_duration"
fi

# Concatenate all segments into the final output file
ffmpeg -f concat -safe 0 -i "$FINAL_CONCAT_LIST" -c copy "$OUTPUT_FILE" -y
if [ $? -ne 0 ]; then
    echo "Error concatenating segments"
    exit 1
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete. Output file: $OUTPUT_FILE"
