#!/bin/bash

# Arguments
INPUT_FILE="$1"  # Input video file
OUTPUT_FILE="$2"  # Output video file
TEXT_FILE="$3"  # Text file with start time, end time, and text contents

# Set font size and color
FONT_SIZE=92
FONT_COLOR="white"  # Change color to a valid name
BOX=1  # Enable box around text
BOX_COLOR="black@0.5"  # Semi-transparent black box

# Check if all arguments are provided
if [ $# -ne 3 ]; then
  echo "Usage: $0 <input_file> <output_file> <text_file>"
  echo "Example: $0 input.mp4 output.mp4 captions.txt"
  exit 1
fi

# Function to convert mm:ss to seconds
convert_to_seconds() {
  local time=$1
  local IFS=:  # Internal Field Separator
  read -r mm ss <<< "$time"
  echo $((10#${mm} * 60 + 10#${ss}))
}

# Read the text file and create an array of drawtext filters
drawtext_filters=()
while IFS= read -r line; do
  IFS=' ' read -r start_time end_time text <<< "$line"
  start_time_seconds=$(convert_to_seconds "$start_time")
  end_time_seconds=$(convert_to_seconds "$end_time")
  
  # Escape single quotes in the text
  ESCAPED_TEXT=$(echo "$text" | sed "s/'/\\\'/g")
  
  # Create drawtext filter for the current range
  drawtext_filter="drawtext=text='$ESCAPED_TEXT':fontcolor=$FONT_COLOR:fontsize=$FONT_SIZE:box=$BOX:boxcolor=$BOX_COLOR:boxborderw=10:x=(w-text_w)/2:y=h-text_h-60:enable='between(t,$start_time_seconds,$end_time_seconds)'"
  drawtext_filters+=("$drawtext_filter")
done < "$TEXT_FILE"

# Join all drawtext filters with commas
drawtext_filters_string=$(IFS=,; echo "${drawtext_filters[*]}")

# Check if drawtext_filters_string is not empty
if [ -z "$drawtext_filters_string" ]; then
  echo "No drawtext filters created. Please check the input text file."
  exit 1
fi

# Debug: Print the drawtext filters string
echo "Drawtext filters: $drawtext_filters_string"

# Execute FFmpeg command with all drawtext filters
ffmpeg -hwaccel auto -i "$INPUT_FILE" -vf "$drawtext_filters_string" -c:a copy "$OUTPUT_FILE"
if [ $? -ne 0 ]; then
  echo "Error applying text overlays"
  exit 1
fi
# Execute FFmpeg command with all drawtext filters
# ffmpeg -hwaccel auto -i "$INPUT_FILE" -vf "$drawtext_filters_string" -c:a copy "$OUTPUT_FILE"
# if [ $? -ne 0 ]; then
#   echo "Error applying text overlays"
#   exit 1
# fi

echo "Text overlay completed successfully. Output file: $OUTPUT_FILE"