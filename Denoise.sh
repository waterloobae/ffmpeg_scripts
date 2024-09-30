#!/bin/bash

# Arguments
INPUT_FILE="$1"  # Input video file
OUTPUT_FILE="$2"  # Output video file

# Check if all arguments are provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <input_file> <output_file>"
  echo "Example: $0 input.mp4 output.mp4"
  exit 1
fi

# Construct the ffmpeg command
FFMPEG_CMD="ffmpeg -i \"$INPUT_FILE\" -af \"afftdn=nf=-20\" -c:v copy \"$OUTPUT_FILE\""

# Echo the full ffmpeg command for debugging
echo "Debug command: $FFMPEG_CMD"

# Execute the ffmpeg command
eval "$FFMPEG_CMD"

# Check if ffmpeg command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to reduce wind noise in video."
  exit 1
fi

echo "Wind noise reduction completed successfully. Output file: $OUTPUT_FILE"