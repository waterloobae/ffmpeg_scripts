#!/bin/bash

# Function to display menu and get user choice
function show_menu {
    echo "Select a command to execute:"
    echo "1) Concatenate: ffmpeg -f concat -i <input_text_file> -c copy <output_video_file>"
    echo "2) Extract Sound: ffmpeg -i <input_video_file> -q:a 0 -map a <output_sound_file>"
    echo "3) Combine Sound: ffmpeg -i <input_video_file1> -i <input_sound_file2> -c copy -map 0:v:0 -map 1:a:0 <output_video_file>"
    echo "4) Trim: ffmpeg -ss <start_time> -to <end_time> -i <input_video_file> -c copy <output_video_file>"
    echo "5) Mute: ffmpeg -i <input_video_file> -vcodec copy -an <output_video_file>"
    read -p "Enter choice [1-5]: " choice
}

show_menu

# Execute the selected command
case $choice in
    1)
        read -p "Enter input text file: " INPUT_FILE
        read -p "Enter output video file: " OUTPUT_FILE
        echo "Concatenating files..."
        ffmpeg -hwaccel auto -f concat -i "$INPUT_FILE" -c copy "$OUTPUT_FILE"
        ;;
    2)
        read -p "Enter input video file: " INPUT_FILE
        read -p "Enter output sound file: " OUTPUT_FILE
        echo "Extracting sound from video..."
        ffmpeg -hwaccel auto -i "$INPUT_FILE" -q:a 0 -map a "$OUTPUT_FILE"
        ;;
    3)
        read -p "Enter first input video file: " INPUT_FILE1
        read -p "Enter second input sound file: " INPUT_FILE2
        read -p "Enter output video file: " OUTPUT_FILE
        echo "Combining video and sound..."

        # This command will combine the video and audio files
        ffmpeg -hwaccel auto -i "$INPUT_FILE1" -i "$INPUT_FILE2" -c:v copy -c:a aac -b:a 256k -map 0:v:0 -map 1:a:0 "$OUTPUT_FILE"
        # ffmpeg -hwaccel auto -i "$INPUT_FILE1" -i "$INPUT_FILE2" -c copy -map 0:v:0 -map 1:a:0 "$OUTPUT_FILE"
        ;;
    4)
        read -p "Enter start time 00:00:00 : " START_TIME
        read -p "Enter end time 00:00:00 : " END_TIME
        read -p "Enter input video file: " INPUT_FILE
        read -p "Enter output video file: " OUTPUT_FILE
        echo "Trimming video..."
        ffmpeg -hwaccel auto -ss "$START_TIME" -to "$END_TIME" -i "$INPUT_FILE" -c copy "$OUTPUT_FILE"
        ;;
    5)
        read -p "Enter input video file: " INPUT_FILE
        read -p "Enter output video file: " OUTPUT_FILE
        echo "Muting video..."
	ffmpeg -hwaccel auto -i "$INPUT_FILE" -vcodec copy -an "$OUTPUT_FILE" 
	;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

echo "Command executed successfully."

