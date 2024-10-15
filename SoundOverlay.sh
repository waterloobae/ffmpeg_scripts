#!/bin/bash

AUDIO_DIR="/Volumes/Multimedia/25-AKASO/sound/YouTube"

# Function to select 3 random audio files and combine them
combine_random_audio() {
  if [[ ! -d "$AUDIO_DIR" ]]; then
    echo "Directory not found: $AUDIO_DIR"
    exit 1
  fi

  # Ensure coreutils is installed and gshuf is available
  if ! command -v gshuf &> /dev/null; then
    echo "gshuf (GNU coreutils) is not installed. Please install it using 'brew install coreutils' on macOS."
    exit 1
  fi

  # Select 3 random audio files from the directory
  AUDIO_FILES=()
  while IFS= read -r -d $'\0' file; do
    AUDIO_FILES+=("$file")
  done < <(find "$AUDIO_DIR" -name "*.mp3" -print0 | gshuf -z -n 3)

  if [[ ${#AUDIO_FILES[@]} -ne 3 ]]; then
    echo "Could not find three audio files in $AUDIO_DIR"
    exit 1
  fi

  TEMP_LIST=$(mktemp)
  for FILE in "${AUDIO_FILES[@]}"; do
    echo "file '$FILE'" >> "$TEMP_LIST"
  done

  OUTPUT_FILE="combined_audio.mp3"
  ffmpeg -f concat -safe 0 -i "$TEMP_LIST" -c copy "$OUTPUT_FILE"
  rm "$TEMP_LIST"

  echo "Combined audio saved as $OUTPUT_FILE"
}

# Function to overlay and repeat audio on video
overlay_audio_on_video() {
  # Implementation for overlaying and repeating audio on video
  read -p "Enter the path to the video file: " VIDEO_FILE
  read -p "Enter the path to the output video file: " OUTPUT_VIDEO
  read -p "Enter the path to the audio file: " AUDIO_FILE

  if [[ ! -f "$VIDEO_FILE" ]]; then
    echo "Video file not found: $VIDEO_FILE"
    exit 1
  fi

  if [[ ! -f "$AUDIO_FILE" ]]; then
    echo "Audio file not found: $AUDIO_FILE"
    exit 1
  fi

  # Get the duration of the video
  VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")

  # Get the duration of the audio
  AUDIO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE")

  # Calculate how many times the audio needs to be repeated
  REPEAT_COUNT=$(echo "($VIDEO_DURATION / $AUDIO_DURATION) + 1" | bc)

  # Create a file list for repeated audio in the current directory
  TEMP_AUDIO_LIST="temp_audio_list.txt"
  : > "$TEMP_AUDIO_LIST"  # Truncate or create the file

  for ((i=0; i<REPEAT_COUNT; i++)); do
    echo "file '$AUDIO_FILE'" >> "$TEMP_AUDIO_LIST"
  done

  # Concatenate the repeated audio files
  REPEATED_AUDIO="repeated_audio.mp3"
  ffmpeg -f concat -safe 0 -i "$TEMP_AUDIO_LIST" -c copy "$REPEATED_AUDIO"
  rm "$TEMP_AUDIO_LIST"

  # Overlay the repeated audio on the video
  ffmpeg -i "$VIDEO_FILE" -i "$REPEATED_AUDIO" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "$OUTPUT_VIDEO"

  echo "Output video saved as $OUTPUT_VIDEO"
  echo "Overlaying and repeating audio on video..."
}

# Main menu
while true; do
  echo "Choose an option:"
  echo "1. Combine 3 random audio files"
  echo "2. Overlay and repeat audio on video"
  echo "3. Exit"
  read -p "Enter choice [1-3]: " choice

  case $choice in
    1) combine_random_audio ;;
    2) overlay_audio_on_video ;;
    3) exit 0 ;;
    *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
  esac
done