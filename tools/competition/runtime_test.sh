#!/usr/bin/env bash
set -eo pipefail

if [[ $# -ne 4 ]]; then
  printf 'Usage: %s <workspace-path> <turtle-package> <face-package> <bag-package>\n' "$0" >&2
  exit 2
fi

workspace="$1"
turtle_package="$2"
face_package="$3"
bag_package="$4"
current_pid=""
current_log=""

cleanup()
{
  if [[ -n "$current_pid" ]] && kill -0 "$current_pid" 2>/dev/null; then
    kill "$current_pid" 2>/dev/null || true
    wait "$current_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [[ ! -r /opt/ros/noetic/setup.bash || ! -r "$workspace/devel/setup.bash" ]]; then
  printf 'ROS or the competition workspace is not built.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
# shellcheck disable=SC1090
source "$workspace/devel/setup.bash"

run_and_wait_for_topic()
{
  label="$1"
  topic="$2"
  shift 2
  current_log="/tmp/smartcar-competition-${label}.log"
  "$@" >"$current_log" 2>&1 &
  current_pid=$!
  sleep 3
  if ! kill -0 "$current_pid" 2>/dev/null; then
    cat "$current_log" >&2
    printf '[ERROR] %s exited during startup.\n' "$label" >&2
    exit 1
  fi
  if ! timeout 15s rostopic echo -n 1 "$topic" >/dev/null; then
    cat "$current_log" >&2
    printf '[ERROR] %s did not publish %s.\n' "$label" "$topic" >&2
    exit 1
  fi
  printf '[OK] %s published %s\n' "$label" "$topic"
  cleanup
  current_pid=""
  sleep 1
}

run_and_wait_for_topic turtle /turtle1/pose \
  roslaunch "$turtle_package" draw.launch headless:=true
run_and_wait_for_topic face /face_detection/image \
  roslaunch "$face_package" face.launch view:=false
run_and_wait_for_topic bag /camera/image_raw \
  roslaunch "$bag_package" play_bag.launch

printf 'Runtime test passed for turtle drawing, face detection and rosbag playback.\n'
