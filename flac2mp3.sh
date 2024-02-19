find . -type f -name "*.flac" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vn -c:a libmp3lame -ab 320k -y "${FILE%.flac}.mp3" && rm "${FILE}";' _ '{}' \;
