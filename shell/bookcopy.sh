#!/bin/sh
find /mnt/d/media/audiobook_original/ -type f \( -iname \*.m4b -o -iname \*.mp3 -o -iname \*.mp4 -o -iname \*.m4a -o -iname \*.ogg \) -exec cp -n "{}" /mnt/d/media/audiobook_temp/ \;
