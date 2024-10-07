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

# Debug: Print the input and output file paths
echo "Input file: $INPUT_FILE"
echo "Output file: $OUTPUT_FILE"

# Get the duration of the input file
input_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
input_duration_seconds=$(printf "%.0f" "$input_duration")

# Generate 2-second fade-in from the first frame
ffmpeg -i "$INPUT_FILE" -vf "select=eq(n\,0),loop=50:1:0,fade=t=in:st=0:d=2" -t 2 -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "fadein.mp4" -y

# Extract the last frame and generate 2-second fade-out
ffmpeg -sseof -1 -i "$INPUT_FILE" -vf "loop=50:1:0,fade=t=out:st=0:d=2" -t 2 -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "fadeout.mp4" -y

# Create a file list for concatenation
CONCAT_LIST="concat_list.txt"
echo "file 'fadein.mp4'" > "$CONCAT_LIST"
echo "file '$INPUT_FILE'" >> "$CONCAT_LIST"
echo "file 'fadeout.mp4'" >> "$CONCAT_LIST"

# Debug: Print the contents of the concat list
echo "Concat list:"
cat "$CONCAT_LIST"

# Concatenate the fade-in, original video, and fade-out
ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$OUTPUT_FILE" -y

# Check if the output file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Failed to create output file $OUTPUT_FILE"
    rm -f "fadein.mp4" "fadeout.mp4" "$CONCAT_LIST"
    exit 1
fi

# Clean up temporary files
rm -f "fadein.mp4" "fadeout.mp4" "$CONCAT_LIST"

echo "Processing complete. Output file: $OUTPUT_FILE"