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

# Function to convert HH:MM:SS or HH:MM:SS.mmm to seconds
time_to_seconds() {
    local time=$1
    local IFS=:
    local arr=($time)
    local seconds=$(echo "${arr[0]} * 3600 + ${arr[1]} * 60 + ${arr[2]}" | bc)
    echo $seconds
}

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

    # Validate start and end times
    if ! [[ "$START_TIME" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid start time format: $START_TIME"
        exit 1
    fi
    if ! [[ "$END_TIME" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then
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
        ffmpeg -hwaccel auto -i "$SEGMENT_FILE" -vf "fade=t=in:st=0:d=1, fade=t=out:st=$(echo "$SEGMENT_DURATION - 1" | bc):d=1" -fps_mode cfr -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 192k "$FADED_SEGMENT_FILE" -y
    else
        # Split the segment into three parts: first 1 second, middle, and last 1 second
        FIRST_PART="$TEMP_DIR/first_$j.mp4"
        MIDDLE_PART="$TEMP_DIR/middle_$j.mp4"
        LAST_PART="$TEMP_DIR/last_$j.mp4"
        FADED_FIRST="$TEMP_DIR/faded_first_$j.mp4"
        FADED_LAST="$TEMP_DIR/faded_last_$j.mp4"

        # Extract first and last one-second segments
        ffmpeg -hwaccel auto -ss 0 -t 1 -i "$SEGMENT_FILE" -fps_mode cfr -c copy "$FIRST_PART" -y
        ffmpeg -hwaccel auto -ss $(echo "$SEGMENT_DURATION - 1" | bc) -t 1 -i "$SEGMENT_FILE" -fps_mode cfr -c copy "$LAST_PART" -y

        # Extract middle part (excluding the first and last seconds)
        ffmpeg -hwaccel auto -ss 1 -t $(echo "$SEGMENT_DURATION - 2" | bc) -i "$SEGMENT_FILE" -fps_mode cfr -c copy "$MIDDLE_PART" -y

        # Apply fade effects to the first and last parts
        ffmpeg -hwaccel auto -i "$FIRST_PART" -vf "fade=t=in:st=0:d=1" -fps_mode cfr -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 192k "$FADED_FIRST" -y
        ffmpeg -hwaccel auto -i "$LAST_PART" -vf "fade=t=out:st=0:d=1" -fps_mode cfr -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 192k "$FADED_LAST" -y

        # Check if the faded parts were created successfully
        if [ ! -f "$FADED_FIRST" ] || [ ! -f "$MIDDLE_PART" ] || [ ! -f "$FADED_LAST" ]; then
            echo "Error: Failed to create faded parts for segment $j"
            exit 1
        fi
    fi

    # Create a list of parts for concatenation
    CONCAT_LIST="$TEMP_DIR/concat_list_$j.txt"
    echo "file '$FADED_FIRST'" >> "$CONCAT_LIST"
    echo "file '$MIDDLE_PART'" >> "$CONCAT_LIST"
    echo "file '$FADED_LAST'" >> "$CONCAT_LIST"

    # Concatenate the parts into the final faded segment
    CONCATENATED_SEGMENT="$TEMP_DIR/segment_${j}_faded.mp4"
    ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" -fps_mode cfr -c copy "$CONCATENATED_SEGMENT" -y

    # Check if the concatenated segment was created successfully
    if [ ! -f "$CONCATENATED_SEGMENT" ]; then
        echo "Error: Failed to create concatenated segment $CONCATENATED_SEGMENT"
        exit 1
    fi
done

# Create a list of all faded segments for final concatenation
FINAL_CONCAT_LIST="$TEMP_DIR/final_concat_list.txt"
for ((k=0; k<i; k++)); do
    echo "file '$TEMP_DIR/segment_${k}_faded.mp4'" >> "$FINAL_CONCAT_LIST"
done

# Concatenate all faded segments into the final output
ffmpeg -f concat -safe 0 -i "$FINAL_CONCAT_LIST" -fps_mode cfr -c copy "$OUTPUT_FILE" -y

# Check if the final output file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Failed to create final output file $OUTPUT_FILE"
    exit 1
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete. Output file: $OUTPUT_FILE"