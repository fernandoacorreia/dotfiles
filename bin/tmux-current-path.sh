#!/bin/bash
# Displays tmux pane's current path

current_path="$1"
home_dir="$HOME"

if [[ "$current_path" == "$home_dir"* ]]; then
  # Path is under $HOME, replace $HOME with ~
  display_path="~${current_path#$home_dir}"
else
  # Path is not under $HOME, display as is
  display_path="$current_path"
fi

echo "$display_path"
