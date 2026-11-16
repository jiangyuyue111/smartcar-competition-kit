#!/usr/bin/env bash
set -o pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="${SMARTCAR_WS:-$HOME/smartcar_ws}"
video_device="${VIDEO_DEVICE:-/dev/video0}"
bag_file="${COMPETITION_BAG:-$repository_root/data/qcrros.bag}"
errors=0
warnings=0

pass() { printf '[OK] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '[ERROR] %s\n' "$1"; errors=$((errors + 1)); }

if [[ -r /opt/ros/noetic/setup.bash ]]; then
  # shellcheck disable=SC1091
  source /opt/ros/noetic/setup.bash
  pass "ROS ${ROS_DISTRO:-unknown} is available"
else
  fail "ROS Noetic is not installed"
fi

if [[ -r "$workspace/devel/setup.bash" ]]; then
  # shellcheck disable=SC1090
  source "$workspace/devel/setup.bash"
  pass "Workspace is built: $workspace"
else
  fail "Workspace is not built; run scripts/setup.sh"
fi

for command_name in catkin_make roslaunch rospack python3 cmake v4l2-ctl; do
  command -v "$command_name" >/dev/null 2>&1 \
    && pass "Found $command_name" \
    || fail "Missing command: $command_name"
done

if [[ -r "$video_device" && -w "$video_device" ]]; then
  pass "Camera is accessible: $video_device"
  v4l2-ctl --device "$video_device" --all >/dev/null 2>&1 \
    && pass "Camera responds to V4L2" \
    || fail "Camera does not respond to V4L2"
else
  warn "Camera is unavailable: $video_device"
fi

cascade="$repository_root/ros_ws/src/usb_cam/config/haarcascade_frontalface_default.xml"
[[ -f "$cascade" ]] && pass "Face cascade is present" || fail "Face cascade is missing"

rospack find usb_cam >/dev/null 2>&1 \
  && pass "ROS can discover usb_cam" \
  || fail "ROS cannot discover usb_cam"

if [[ -f "$bag_file" ]]; then
  command -v rosbag >/dev/null 2>&1 \
    && pass "Competition bag is present: $bag_file" \
    || fail "rosbag is unavailable"
else
  warn "Optional competition bag is not present: $bag_file"
fi

printf '\nSummary: %d error(s), %d warning(s)\n' "$errors" "$warnings"
((errors == 0))
