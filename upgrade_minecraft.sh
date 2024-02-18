#!/bin/bash

# Get today's date in YYYYMMDD format
TODAY=$(date +"%Y%m%d")

# Define source and destination directories
SOURCE_DIR="/var/opt/minecraft/crafty/crafty-4/servers/67902c85-8922-410b-a8f6-58601594c331"
DEST_DIR="/var/opt/minecraft/crafty/crafty-4/servers/67902c85-8922-410b-a8f6-58601594c331/upgrade_backup_$TODAY"
CHOSEN_DIR="/home/nick/chosen"

# Create the backup directory
mkdir "$DEST_DIR"

# Move specified folders to the backup directory
mv "$SOURCE_DIR/config" "$SOURCE_DIR/defaultconfigs" "$SOURCE_DIR/kubejs" "$SOURCE_DIR/mods" "$SOURCE_DIR/scripts" "$DEST_DIR"

# Check if the move operation was successful
if [ $? -eq 0 ]; then
  echo "Backup created successfully at: $DEST_DIR"
else
  echo "Backup creation failed."
  exit 1
fi

# Move all files starting with forge- to the backup directory
mv "$SOURCE_DIR/forge-"* "$DEST_DIR"

# Check if the move operation was successful
if [ $? -eq 0 ]; then
  echo "Forge files moved successfully to: $DEST_DIR"
else
  echo "Moving forge files failed."
  exit 1
fi

# Copy specified folders and files from ~/chosen to the destination directory
cp -r "$CHOSEN_DIR/config" "$CHOSEN_DIR/defaultconfigs" "$CHOSEN_DIR/forge-"* "$CHOSEN_DIR/kubejs" "$CHOSEN_DIR/mods" "$CHOSEN_DIR/scripts" "$SOURCE_DIR"

# Check if the copy operation was successful
if [ $? -eq 0 ]; then
  echo "Files copied successfully from ~/chosen to $SOURCE_DIR"
else
  echo "File copy failed."
  exit 1
fi

# Copy simplebackups-common.toml file from backup folder to config directory
cp "$DEST_DIR/config/simplebackups-common.toml" "$SOURCE_DIR/config/"

# Check if the copy operation was successful
if [ $? -eq 0 ]; then
  echo "simplebackups-common.toml copied successfully to $SOURCE_DIR/config/"
else
  echo "Copying simplebackups-common.toml failed."
  exit 1
fi

