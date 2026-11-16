#!/usr/bin/env bash
set -eo pipefail

workspace="${CATKIN_WS:-$HOME/catkin_ws}"
video_device="${VIDEO_DEVICE:-/dev/video0}"
launch_log="/tmp/smartcar-integration-test.log"
launch_pid=""

cleanup()
{
  status=$?
  if [[ -n "$launch_pid" ]] && kill -0 "$launch_pid" 2>/dev/null; then
    kill "$launch_pid" 2>/dev/null || true
    wait "$launch_pid" 2>/dev/null || true
  fi
  if ((status != 0)); then
    printf '\nIntegration test launch log:\n' >&2
    cat "$launch_log" >&2 || true
  fi
}
trap cleanup EXIT

if [[ ! -r /opt/ros/noetic/setup.bash || ! -r "$workspace/devel/setup.bash" ]]; then
  printf 'ROS or the catkin workspace is not ready. Run scripts/build.sh first.\n' >&2
  exit 1
fi
if [[ ! -r "$video_device" || ! -w "$video_device" ]]; then
  printf 'Camera device %s is unavailable. Run scripts/doctor.sh.\n' "$video_device" >&2
  exit 1
fi

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
# shellcheck disable=SC1090
source "$workspace/devel/setup.bash"
set -u

roslaunch usb_cam smartcar.launch video_device:="$video_device" view:=false \
  >"$launch_log" 2>&1 &
launch_pid=$!
sleep 3

if ! kill -0 "$launch_pid" 2>/dev/null; then
  printf 'The ROS launch process exited during startup.\n' >&2
  exit 1
fi

timeout 15s rostopic echo -n 1 /usb_cam/image_raw/header >/dev/null
timeout 15s rostopic echo -n 1 /face_detection/image/header >/dev/null

printf 'Integration test passed: raw and face-detection image topics both produced data.\n'
