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

# Define the duration for fade-in and fade-out segments
fade_duration=2

# Generate 2-second mosaic fade-in from the first frame
ffmpeg -hwaccel auto -i "$INPUT_FILE" -vf "select=eq(n\,0),loop=50:1:0,tile=1x1,fade=t=in:st=0:d=$fade_duration" -t $fade_duration -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "fadein.mp4" -y

# Generate 2-second fade-out from the last 2 seconds
ffmpeg -hwaccel auto -sseof -$fade_duration -i "$INPUT_FILE" -t $fade_duration -vf "fade=t=out:st=0:d=$fade_duration" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "fadeout.mp4" -y

# Generate the middle segment without the last 2 seconds
middle_duration=$(echo "$input_duration - $fade_duration" | bc)
ffmpeg -hwaccel auto -i "$INPUT_FILE" -t $middle_duration -c copy "middle.mp4" -y
# ffmpeg -hwaccel auto -i "$INPUT_FILE" -t $middle_duration -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "middle.mp4" -y

# Create a file list for concatenation
CONCAT_LIST="concat_list.txt"
echo "file 'fadein.mp4'" > "$CONCAT_LIST"
echo "file 'middle.mp4'" >> "$CONCAT_LIST"
echo "file 'fadeout.mp4'" >> "$CONCAT_LIST"

# Debug: Print the contents of the concat list
echo "Concat list:"
cat "$CONCAT_LIST"

# Concatenate the fade-in, middle, and fade-out segments
ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" -c copy -movflags +faststart "$OUTPUT_FILE" -y

# Check if the output file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Failed to create output file $OUTPUT_FILE"
    rm -f "fadein.mp4" "middle.mp4" "fadeout.mp4" "$CONCAT_LIST"
    exit 1
fi

# Clean up temporary files
rm -f "fadein.mp4" "middle.mp4" "fadeout.mp4" "$CONCAT_LIST"

echo "Processing complete. Output file: $OUTPUT_FILE"