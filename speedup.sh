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

OUTPUT_FILE="speedup_output.mp4"
FINAL_CONCAT_LIST="$TEMP_DIR/final_concat_list.txt"

# Empty the concat list file
> "$FINAL_CONCAT_LIST"

# Function to convert mm:ss to seconds
convert_to_seconds() {
    local time=$1
    local IFS=:  # Internal Field Separator
    read -r mm ss <<< "$time"
    echo $((10#${mm} * 60 + 10#${ss}))
}

# Function to process a normal speed segment
process_normal_segment() {
    local start_time="$1"
    local end_time="$2"
    local segment_file="$TEMP_DIR/normal_${start_time}_${end_time}.mp4"
    
    # Generate normal speed segment with re-encoding
    ffmpeg -hwaccel auto -r "$FRAMERATE" -ss "$start_time" -to "$end_time" -i "$INPUT_FILE" -r "$FRAMERATE" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "$segment_file" -y
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
    local segment_file="$TEMP_DIR/sped_${start_time}_${end_time}.mp4"
    
    # Generate sped-up segment with 20x speed increase and no audio
    # ffmpeg -hwaccel auto -r "$FRAMERATE" -ss "$start_time" -to "$end_time" -i "$INPUT_FILE" -r "$FRAMERATE" -filter:v "setpts=0.2*PTS" -an -c:v libx264 -preset medium -crf 18 "$segment_file" -y
    ffmpeg -hwaccel auto -r "$FRAMERATE" -ss "$start_time" -to "$end_time" -i "$INPUT_FILE" -r "$FRAMERATE" -filter:v "setpts=0.2*PTS" -filter:a "atempo=5.0" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "$segment_file" -y

    if [ $? -ne 0 ]; then
        echo "Error processing sped-up segment: $start_time to $end_time"
        exit 1
    fi
    
    # Add sped-up segment to the list
    echo "file '$segment_file'" >> "$FINAL_CONCAT_LIST"
}

# Read the ranges file and store in an array
# ranges=()
# while IFS= read -r line; do
#     ranges+=("$line")
# done < "$RANGES_FILE"

# Read the ranges file and store in an array, ignoring empty lines
ranges=()
while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ]; then
        ranges+=("$line")
    fi
done < "$RANGES_FILE"


# Convert start and end times to seconds and store in an array
ranges_in_seconds=()
for range in "${ranges[@]}"; do
    IFS=' ' read -r start_time end_time <<< "$range"
    start_time_seconds=$(convert_to_seconds "$start_time")
    end_time_seconds=$(convert_to_seconds "$end_time")
    ranges_in_seconds+=("$start_time_seconds $end_time_seconds")
done

# Debug: Echo the ranges in seconds
echo "Ranges in seconds:"
for range in "${ranges_in_seconds[@]}"; do
    echo "$range"
done

# Process each range
previous_end_time=0
for range in "${ranges_in_seconds[@]}"; do
    IFS=' ' read -r start_time end_time <<< "$range"
    
    # Process the segment before the current range
    if [ "$previous_end_time" -lt "$start_time" ]; then
        # process_sped_up_segment "$previous_end_time" "$start_time"
        process_normal_segment "$previous_end_time" "$start_time"        
    fi
    
    # Process the current range as normal speed
    # process_normal_segment "$start_time" "$end_time"
    process_sped_up_segment "$start_time" "$end_time"

    # Update the previous end time
    previous_end_time="$end_time"
done

# Process the segment after the last range
input_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
input_duration_seconds=$(printf "%.0f" "$input_duration")
if [ "$previous_end_time" -lt "$input_duration_seconds" ]; then
    # process_sped_up_segment "$previous_end_time" "$input_duration_seconds"
    process_normal_segment "$previous_end_time" "$input_duration_seconds"    
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
