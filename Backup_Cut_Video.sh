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

# Second loop: Apply fade effects to trimmed segments
for ((j=0; j<i; j++)); do
    SEGMENT_FILE="$TEMP_DIR/segment_$j.mp4"
    FADED_SEGMENT_FILE="$TEMP_DIR/segment_${j}_faded.mp4"
    
    # Get the duration of the segment
    SEGMENT_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SEGMENT_FILE")
    FADE_OUT_START=$(echo "$SEGMENT_DURATION - 1" | bc) # 1 second before the end
    FADE_OUT_DURATION=1  # Fade-out duration
    FADE_IN_DURATION=1   # Fade-in duration

    echo "Applying fade effects to segment $j: duration=$SEGMENT_DURATION, fade_out_start=$FADE_OUT_START"

    # Apply both fade in and fade out for other segments
    ffmpeg -hwaccel auto -i "$SEGMENT_FILE" -vf "fade=t=in:st=0:d=$FADE_IN_DURATION, fade=t=out:st=$FADE_OUT_START:d=$FADE_OUT_DURATION" -c:v libx264 -preset slow -crf 23 -c:a copy "$FADED_SEGMENT_FILE" -y
done

# Create a list of all faded segments for concatenation
CONCAT_LIST="$TEMP_DIR/concat_list.txt"
for ((k=0; k<i; k++)); do
    echo "file '$TEMP_DIR/segment_${k}_faded.mp4'" >> "$CONCAT_LIST"
done

# Concatenate all faded segments into the final output
ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$OUTPUT_FILE" -y

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete. Output file: $OUTPUT_FILE"
