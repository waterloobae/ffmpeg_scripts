#!/bin/bash

# Arguments
INPUT_FILE="$1"  # Input video file
OUTPUT_FILE="$2"  # Output video file
START_TIME="$3"  # Start time for text overlay (e.g., 00:00:05)
END_TIME="$4"  # End time for text overlay (e.g., 00:00:10)
TEXT="$5"  # Text to overlay

# Set font size and color
FONT_SIZE=92
FONT_COLOR="white"  # Change color to a valid name
BOX=1  # Enable box around text
BOX_COLOR="black@0.5"  # Semi-transparent black box

# Check if all arguments are provided
if [ $# -ne 5 ]; then
  echo "Usage: $0 <input_file> <output_file> <start_time> <end_time> <text>"
  echo "Example: $0 input.mp4 output.mp4 00:00:05 00:00:10 'Sample Text'"
  exit 1
fi

# Function to convert hh:mm:ss to seconds
convert_to_seconds() {
  local time=$1
  local IFS=:  # Internal Field Separator
  read -r hh mm ss <<< "$time"
  echo $((10#${hh} * 3600 + 10#${mm} * 60 + 10#${ss}))
}

# Convert start and end times to seconds
START_TIME_SECONDS=$(convert_to_seconds "$START_TIME")
END_TIME_SECONDS=$(convert_to_seconds "$END_TIME")

# Escape single quotes in the text
ESCAPED_TEXT=$(echo "$TEXT" | sed "s/'/\\\'/g")

# Create a temporary directory for intermediate files
TEMP_DIR=$(mktemp -d)

# Split the video into three segments
ffmpeg -i "$INPUT_FILE" -t "$START_TIME" -c copy "$TEMP_DIR/before.mp4"
ffmpeg -i "$INPUT_FILE" -ss "$START_TIME" -to "$END_TIME" -c copy "$TEMP_DIR/center.mp4"
ffmpeg -i "$INPUT_FILE" -ss "$END_TIME" -c copy "$TEMP_DIR/after.mp4"

# Overlay text on the center segment
ffmpeg -i "$TEMP_DIR/center.mp4" -vf "drawtext=text='$ESCAPED_TEXT':fontcolor=$FONT_COLOR:fontsize=$FONT_SIZE:box=$BOX:boxcolor=$BOX_COLOR:x=(w-text_w)/2:y=(h-text_h)-10" -c:a copy "$TEMP_DIR/center_text.mp4"

# Concatenate the segments
echo "file '$TEMP_DIR/before.mp4'" > "$TEMP_DIR/concat_list.txt"
echo "file '$TEMP_DIR/center_text.mp4'" >> "$TEMP_DIR/concat_list.txt"
echo "file '$TEMP_DIR/after.mp4'" >> "$TEMP_DIR/concat_list.txt"


# Concatenate the segments using the concat filter
ffmpeg -i "$TEMP_DIR/before.mp4" -i "$TEMP_DIR/center_text.mp4" -i "$TEMP_DIR/after.mp4" -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[v][a]" -map "[v]" -map "[a]" "$OUTPUT_FILE"
# ffmpeg -f concat -safe 0 -i "$TEMP_DIR/concat_list.txt" -c copy "$OUTPUT_FILE"

# Clean up temporary files
rm -rf "$TEMP_DIR"

# Check if ffmpeg command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to overlay text on video."
  exit 1
fi

echo "Text overlay completed successfully. Output file: $OUTPUT_FILE"