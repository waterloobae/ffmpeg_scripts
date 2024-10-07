#!/bin/bash

# Arguments
INPUT_FILE="$1"
RANGES_FILE="$2"
OUTPUT_FILE="$3"

# Temporary directory for intermediate files
TEMP_DIR=$(mktemp -d)

# Function to convert mm:ss to seconds
time_to_seconds() {
    local time=$1
    local IFS=:  # Internal Field Separator
    read -r mm ss <<< "$time"
    echo $((10#${mm} * 60 + 10#${ss}))
}

# Read the ranges file and store in an array
RANGES=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Ignore empty lines
    if [ -n "$line" ]; then
        RANGES+=("$line")
    fi
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

    # Validate start and end times
    if ! [[ "$START_TIME" =~ ^[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid start time format: $START_TIME"
        exit 1
    fi
    if ! [[ "$END_TIME" =~ ^[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid end time format: $END_TIME"
        exit 1
    fi

    # Convert start and end times to seconds
    START_TIME_SECONDS=$(time_to_seconds "$START_TIME")
    END_TIME_SECONDS=$(time_to_seconds "$END_TIME")

    # Trim the segment first
    SEGMENT_FILE="$TEMP_DIR/segment_$i.mp4"
    ffmpeg -hwaccel auto -ss "$START_TIME_SECONDS" -to "$END_TIME_SECONDS" -i "$INPUT_FILE" -fps_mode cfr -c copy "$SEGMENT_FILE" -y

    # Check if the segment file was created successfully
    if [ ! -f "$SEGMENT_FILE" ]; then
        echo "Error: Failed to create segment file $SEGMENT_FILE"
        exit 1
    fi

    i=$((i + 1))
done

# Second loop: Process remaining segments
PREVIOUS_END_TIME=0
i=0
for RANGE in "${RANGES[@]}"; do
    START_TIME=$(echo "$RANGE" | awk '{print $1}')
    END_TIME=$(echo "$RANGE" | awk '{print $2}')

    START_TIME_SECONDS=$(time_to_seconds "$START_TIME")
    END_TIME_SECONDS=$(time_to_seconds "$END_TIME")

    # Process the segment before the current range
    if [ "$PREVIOUS_END_TIME" -lt "$START_TIME_SECONDS" ]; then
        SEGMENT_FILE="$TEMP_DIR/remaining_$i.mp4"
        ffmpeg -hwaccel auto -ss "$PREVIOUS_END_TIME" -to "$START_TIME_SECONDS" -i "$INPUT_FILE" -fps_mode cfr -c copy "$SEGMENT_FILE" -y
        echo "file '$SEGMENT_FILE'" >> "$TEMP_DIR/concat_list.txt"
        i=$((i + 1))
    fi

    # Update the previous end time
    PREVIOUS_END_TIME="$END_TIME_SECONDS"
done

# Process the segment after the last range
INPUT_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
INPUT_DURATION_SECONDS=$(printf "%.0f" "$INPUT_DURATION")
if [ "$PREVIOUS_END_TIME" -lt "$INPUT_DURATION_SECONDS" ]; then
    SEGMENT_FILE="$TEMP_DIR/remaining_$i.mp4"
    ffmpeg -hwaccel auto -ss "$PREVIOUS_END_TIME" -to "$INPUT_DURATION_SECONDS" -i "$INPUT_FILE" -fps_mode cfr -c copy "$SEGMENT_FILE" -y
    echo "file '$SEGMENT_FILE'" >> "$TEMP_DIR/concat_list.txt"
fi

# Concatenate all remaining segments into the final output file
ffmpeg -f concat -safe 0 -i "$TEMP_DIR/concat_list.txt" -c copy "$OUTPUT_FILE" -y
if [ $? -ne 0 ]; then
    echo "Error concatenating segments"
    exit 1
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete. Output file: $OUTPUT_FILE"