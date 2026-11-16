#!/usr/bin/env bash
set -eo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="${SMARTCAR_WS:-$HOME/smartcar_ws}"
video_device="${VIDEO_DEVICE:-/dev/video0}"

"$repository_root/scripts/setup.sh" --workspace "$workspace"

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
# shellcheck disable=SC1090
source "$workspace/devel/setup.bash"

roslaunch --nodes usb_cam smartcar.launch >/dev/null
CATKIN_WS="$workspace" "$repository_root/ros_ws/src/usb_cam/scripts/smoke_test.sh"

if [[ -r "$video_device" && -w "$video_device" ]]; then
  CATKIN_WS="$workspace" VIDEO_DEVICE="$video_device" \
    "$repository_root/ros_ws/src/usb_cam/scripts/integration_test.sh"
else
  printf '[SKIP] Camera integration test: %s is unavailable.\n' "$video_device"
fi

printf 'Repository tests passed.\n'
