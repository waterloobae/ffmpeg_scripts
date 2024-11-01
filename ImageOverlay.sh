#!/bin/bash

# Function to overlay an image at a custom position
overlay_image_position() {
  read -p "Enter video file path: " VIDEO_FILE
  read -p "Enter image file path: " IMAGE_FILE
  echo "Choose overlay position:"
  echo "1. Top-left corner"
  echo "2. Top-right corner"
  echo "3. Bottom-left corner"
  echo "4. Bottom-right corner"
  echo "5. Center"
  read -p "Enter your choice [1-5]: " position_choice
  
  case $position_choice in
    1) overlay_position="0:0" ;;
    2) overlay_position="W-w:0" ;;
    3) overlay_position="0:H-h" ;;
    4) overlay_position="W-w:H-h" ;;
    5) overlay_position="(W-w)/2:(H-h)/2" ;;
    *) echo "Invalid choice!"; exit 1 ;;
  esac

  OUTPUT_FILE="overlay_position_output.mp4"
  ffmpeg -i "$VIDEO_FILE" -i "$IMAGE_FILE" -filter_complex "overlay=$overlay_position" -codec:a copy "$OUTPUT_FILE"
  
  echo "Output video saved as $OUTPUT_FILE"
}

# Function to overlay image with transparency
overlay_image_with_transparency() {
  read -p "Enter video file path: " VIDEO_FILE
  read -p "Enter image file path: " IMAGE_FILE
  read -p "Enter overlay position (x:y), e.g., 10:10: " overlay_position

  OUTPUT_FILE="overlay_transparency_output.mp4"
  ffmpeg -i "$VIDEO_FILE" -i "$IMAGE_FILE" -filter_complex "overlay=$overlay_position" -codec:a copy "$OUTPUT_FILE"
  
  echo "Output video saved as $OUTPUT_FILE"
}

# Function to overlay image for a specific duration
overlay_image_duration() {
  read -p "Enter video file path: " VIDEO_FILE
  read -p "Enter image file path: " IMAGE_FILE
  read -p "Enter overlay position (x:y), e.g., 10:10: " overlay_position
  read -p "Enter start time in seconds (e.g., 5): " start_time
  read -p "Enter end time in seconds (e.g., 10): " end_time

  OUTPUT_FILE="overlay_duration_output.mp4"
  ffmpeg -i "$VIDEO_FILE" -i "$IMAGE_FILE" -filter_complex "[0][1]overlay=$overlay_position:enable='between(t,$start_time,$end_time)'" -codec:a copy "$OUTPUT_FILE"
  
  echo "Output video saved as $OUTPUT_FILE"
}

# Function to overlay multiple images sequentially
overlay_multiple_images() {
  read -p "Enter video file path: " VIDEO_FILE
  read -p "Enter first image file path: " IMAGE1
  read -p "Enter second image file path: " IMAGE2
  read -p "Enter third image file path: " IMAGE3
  read -p "Enter fourth image file path: " IMAGE4
  read -p "Enter overlay position (x:y), e.g., 10:10: " overlay_position
  read -p "Enter start time in seconds (e.g., 5): " start_time

  OUTPUT_FILE="overlay_multiple_output.mp4"
  ffmpeg -i "$VIDEO_FILE" -i "$IMAGE1" -i "$IMAGE2" -i "$IMAGE3" -i "$IMAGE4" -filter_complex \
  "[0][1]overlay=$overlay_position:enable='between(t,$start_time,$((start_time+5)))',[0][2]overlay=$overlay_position:enable='between(t,$((start_time+5)),$((start_time+10)))',[0][3]overlay=$overlay_position:enable='between(t,$((start_time+10)),$((start_time+15)))',[0][4]overlay=$overlay_position:enable='between(t,$((start_time+15)),$((start_time+20)))'" \
  -codec:a copy "$OUTPUT_FILE"
  
  echo "Output video saved as $OUTPUT_FILE"
}

# Function to display the menu
show_menu() {
  echo "Choose an option:"
  echo "1. Overlay an image at a custom position"
  echo "2. Overlay image with transparency"
  echo "3. Overlay image for a specific duration"
  echo "4. Overlay multiple images sequentially"
  echo "5. Exit"
}

# Main menu loop
while true; do
  show_menu
  read -p "Enter choice [1-5]: " choice
  case $choice in
    1)
      overlay_image_position
      ;;
    2)
      overlay_image_with_transparency
      ;;
    3)
      overlay_image_duration
      ;;
    4)
      overlay_multiple_images
      ;;
    5)
      echo "Exiting script."
      exit 0
      ;;
    *)
      echo "Invalid option. Please choose 1-5."
      ;;
  esac
done