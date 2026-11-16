#!/usr/bin/env bash
set -eo pipefail

workspace="${SMARTCAR_WS:-$HOME/smartcar_ws}"
video_device="${VIDEO_DEVICE:-/dev/video0}"

if [[ ! -r /opt/ros/noetic/setup.bash || ! -r "$workspace/devel/setup.bash" ]]; then
  printf 'ROS or the workspace is not ready. Run scripts/setup.sh first.\n' >&2
  exit 1
fi
if [[ ! -r "$video_device" || ! -w "$video_device" ]]; then
  printf 'Camera %s is unavailable. Run scripts/doctor.sh.\n' "$video_device" >&2
  exit 1
fi

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
# shellcheck disable=SC1090
source "$workspace/devel/setup.bash"
exec roslaunch usb_cam smartcar.launch video_device:="$video_device" "$@"
