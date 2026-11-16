#!/usr/bin/env bash
set -eo pipefail

workspace="${CATKIN_WS:-$HOME/catkin_ws}"
roscore_log="/tmp/smartcar-roscore-smoke.log"
face_log="/tmp/smartcar-face-smoke.log"
core_pid=""
face_pid=""

cleanup()
{
  if [[ -n "$face_pid" ]] && kill -0 "$face_pid" 2>/dev/null; then
    kill "$face_pid" 2>/dev/null || true
    wait "$face_pid" 2>/dev/null || true
  fi
  if [[ -n "$core_pid" ]] && kill -0 "$core_pid" 2>/dev/null; then
    kill "$core_pid" 2>/dev/null || true
    wait "$core_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [[ ! -r /opt/ros/noetic/setup.bash || ! -r "$workspace/devel/setup.bash" ]]; then
  printf 'ROS or the catkin workspace is not ready. Run scripts/build.sh first.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
# shellcheck disable=SC1090
source "$workspace/devel/setup.bash"
set -u

roscore >"$roscore_log" 2>&1 &
core_pid=$!
sleep 2
if ! kill -0 "$core_pid" 2>/dev/null; then
  cat "$roscore_log" >&2
  printf 'roscore failed to stay running.\n' >&2
  exit 1
fi

rosrun usb_cam face_detection_node _show_window:=false >"$face_log" 2>&1 &
face_pid=$!
sleep 2
if ! kill -0 "$face_pid" 2>/dev/null; then
  cat "$face_log" >&2
  printf 'face_detection_node failed to stay running.\n' >&2
  exit 1
fi

printf 'Smoke test passed: roscore and face_detection_node started successfully.\n'
