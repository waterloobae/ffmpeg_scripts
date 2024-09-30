#!/bin/bash

# Usage: ./Cut_Video.sh input_video.mp4 ranges.txt

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input_video.mp4 ranges.txt"
    exit 1
fi

INPUT_FILE="$1"
RANGES_FILE="$2"
TEMP_DIR=$(mktemp -d)
OUTPUT_FILE="output_video.mp4"

# Read ranges from the input file into an array
RANGES=()
while IFS= read -r line; do
    RANGES+=("$line")
done < "$RANGES_FILE"

# Echo the ranges for debugging
echo "Time Ranges Read from File:"
for RANGE in "${RANGES[@]}"; do
    echo "$RANGE"
done

# First loop: Trim the segments
i=0
for RANGE in "${RANGES[@]}"; do
    START_TIME=$(echo "$RANGE" | awk '{print $1}')
    END_TIME=$(echo "$RANGE" | awk '{print $2}')
    
    echo "Trimming segment $i: start=$START_TIME, end=$END_TIME"

    # Trim the segment first
    SEGMENT_FILE="$TEMP_DIR/segment_$i.mp4"
    ffmpeg -hwaccel auto -ss "$START_TIME" -to "$END_TIME" -i "$INPUT_FILE" -c copy "$SEGMENT_FILE" -y

    # Increment index
    i=$((i + 1))
done

# Second loop: Extract and process the first and last one-second parts
for ((j=0; j<i; j++)); do
    SEGMENT_FILE="$TEMP_DIR/segment_$j.mp4"
    SEGMENT_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SEGMENT_FILE")
    SEGMENT_DURATION=${SEGMENT_DURATION%.*} # Convert to integer duration

    if [ "$SEGMENT_DURATION" -le 2 ]; then
        # If the segment is less than or equal to 2 seconds, just process the whole segment
        FADED_SEGMENT_FILE="$TEMP_DIR/segment_${j}_faded.mp4"
        ffmpeg -hwaccel auto -i "$SEGMENT_FILE" -vf "fade=t=in:st=0:d=1, fade=t=out:st=$(echo "$SEGMENT_DURATION - 1" | bc):d=1" -c:v libx264 -preset slow -crf 23 -c:a copy "$FADED_SEGMENT_FILE" -y
    else
        # Split the segment into three parts: first 1 second, middle, and last 1 second
        FIRST_PART="$TEMP_DIR/first_$j.mp4"
        MIDDLE_PART="$TEMP_DIR/middle_$j.mp4"
        LAST_PART="$TEMP_DIR/last_$j.mp4"
        FADED_FIRST="$TEMP_DIR/faded_first_$j.mp4"
        FADED_LAST="$TEMP_DIR/faded_last_$j.mp4"

        # Extract first and last one-second segments
        ffmpeg -hwaccel auto -ss 0 -t 1 -i "$SEGMENT_FILE" -c copy "$FIRST_PART" -y
        ffmpeg -hwaccel auto -ss $(echo "$SEGMENT_DURATION - 1" | bc) -t 1 -i "$SEGMENT_FILE" -c copy "$LAST_PART" -y

        # Extract middle part (excluding the first and last seconds)
        ffmpeg -hwaccel auto -ss 1 -t $(echo "$SEGMENT_DURATION - 2" | bc) -i "$SEGMENT_FILE" -c copy "$MIDDLE_PART" -y

        # Apply fade effects to the first and last parts
        ffmpeg -hwaccel auto -i "$FIRST_PART" -vf "fade=t=in:st=0:d=1" -c:v libx264 -preset slow -crf 23 -c:a copy "$FADED_FIRST" -y
        ffmpeg -hwaccel auto -i "$LAST_PART" -vf "fade=t=out:st=0:d=1" -c:v libx264 -preset slow -crf 23 -c:a copy "$FADED_LAST" -y
    fi

    # Create a list of parts for concatenation
    CONCAT_LIST="$TEMP_DIR/concat_list_$j.txt"
    echo "file '$FADED_FIRST'" >> "$CONCAT_LIST"
    echo "file '$MIDDLE_PART'" >> "$CONCAT_LIST"
    echo "file '$FADED_LAST'" >> "$CONCAT_LIST"

    # Concatenate the parts into the final faded segment
    CONCATENATED_SEGMENT="$TEMP_DIR/segment_${j}_faded.mp4"
    ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$CONCATENATED_SEGMENT" -y
done

# Create a list of all faded segments for final concatenation
FINAL_CONCAT_LIST="$TEMP_DIR/final_concat_list.txt"
for ((k=0; k<i; k++)); do
    echo "file '$TEMP_DIR/segment_${k}_faded.mp4'" >> "$FINAL_CONCAT_LIST"
done

# Concatenate all faded segments into the final output
ffmpeg -f concat -safe 0 -i "$FINAL_CONCAT_LIST" -c copy "$OUTPUT_FILE" -y

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete. Output file: $OUTPUT_FILE"
