#!/usr/bin/env bash
set -eo pipefail

if [[ $# -lt 4 || $# -gt 5 ]]; then
  printf 'Usage: %s <workspace-path> <turtle-package> <face-package> <bag-package> [bag-file]\n' "$0" >&2
  exit 2
fi

workspace="$1"
turtle_package="$2"
face_package="$3"
bag_package="$4"
toolkit_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$toolkit_dir/../.." && pwd)"
cascade_path="$(realpath "$repository_root/ros_ws/src/usb_cam/config/haarcascade_frontalface_default.xml")"
bag_file="${5:-${COMPETITION_BAG:-$repository_root/data/qcrros.bag}}"
video_device="${VIDEO_DEVICE:-/dev/video0}"
errors=0

pass() { printf '[OK] %s\n' "$1"; }
fail() { printf '[ERROR] %s\n' "$1"; errors=$((errors + 1)); }

if [[ -r /opt/ros/noetic/setup.bash && -r "$workspace/devel/setup.bash" ]]; then
  # shellcheck disable=SC1091
  source /opt/ros/noetic/setup.bash
  # shellcheck disable=SC1090
  source "$workspace/devel/setup.bash"
  pass "ROS and workspace environment"
else
  fail "Workspace has not been built: $workspace"
fi

for directory in src build devel; do
  [[ -d "$workspace/$directory" ]] \
    && pass "Workspace contains $directory" \
    || fail "Workspace is missing $directory"
done

for package in "$turtle_package" "$face_package" "$bag_package"; do
  rospack find "$package" >/dev/null 2>&1 \
    && pass "ROS can discover package $package" \
    || fail "ROS cannot discover package $package"
done

roslaunch --nodes "$turtle_package" draw.launch >/dev/null 2>&1 \
  && pass "Turtle launch file parses" \
  || fail "Turtle launch file does not parse"
roslaunch --nodes "$face_package" face.launch >/dev/null 2>&1 \
  && pass "Face launch file parses" \
  || fail "Face launch file does not parse"
roslaunch --nodes "$bag_package" view_bag_manual.launch >/dev/null 2>&1 \
  && pass "Bag and RViz launch file parses" \
  || fail "Bag and RViz launch file does not parse"
roslaunch --nodes "$bag_package" play_bag.launch >/dev/null 2>&1 \
  && pass "Headless bag launch file parses" \
  || fail "Headless bag launch file does not parse"

grep -F "$cascade_path" \
  "$workspace/src/$face_package/src/face_detection_node.cpp" >/dev/null 2>&1 \
  && pass "Face C++ source contains the required XML absolute path" \
  || fail "Face C++ source does not contain the XML absolute path"

if [[ -r "$video_device" && -w "$video_device" ]]; then
  pass "Camera $video_device is accessible"
else
  fail "Camera $video_device is not accessible"
fi

rosbag info "$bag_file" 2>/dev/null | \
  grep -F 'camera/image_raw' >/dev/null \
  && pass "Competition bag contains camera/image_raw" \
  || fail "Competition bag topic is missing"

printf '\nVerification summary: %d error(s)\n' "$errors"
((errors == 0))
