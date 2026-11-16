#!/usr/bin/env bash
set -o pipefail

errors=0
warnings=0
video_device="${VIDEO_DEVICE:-/dev/video0}"
workspace="${CATKIN_WS:-$HOME/catkin_ws}"
package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass() { printf '[OK] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '[ERROR] %s\n' "$1"; errors=$((errors + 1)); }

if grep -qi microsoft /proc/version 2>/dev/null; then
  pass "Running inside WSL2"
else
  warn "This environment does not appear to be WSL2"
fi

if [[ -r /opt/ros/noetic/setup.bash ]]; then
  # shellcheck disable=SC1091
  source /opt/ros/noetic/setup.bash
  set -u
  pass "ROS ${ROS_DISTRO:-unknown} is available"
else
  fail "ROS Noetic is missing: /opt/ros/noetic/setup.bash was not found"
fi

if [[ -r "$workspace/devel/setup.bash" ]]; then
  # shellcheck disable=SC1090
  set +u
  source "$workspace/devel/setup.bash"
  set -u
  pass "Catkin workspace is built: $workspace"
else
  fail "Catkin workspace is not built; run scripts/build.sh"
fi

for command_name in catkin_make roslaunch rospack python3 cmake; do
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "Found $command_name"
  else
    fail "Missing required command: $command_name"
  fi
done

if command -v v4l2-ctl >/dev/null 2>&1; then
  pass "Found v4l2-ctl"
else
  warn "v4l-utils is not installed; camera capability checks will be limited"
fi

if [[ -e "$video_device" ]]; then
  if [[ -r "$video_device" && -w "$video_device" ]]; then
    pass "Camera device is accessible: $video_device"
  else
    fail "Camera exists but is not readable/writable: $video_device"
  fi
  if command -v v4l2-ctl >/dev/null 2>&1; then
    v4l2-ctl --device "$video_device" --all >/dev/null 2>&1 \
      && pass "Camera responds to V4L2" \
      || fail "Camera does not respond to V4L2: $video_device"
  fi
else
  fail "Camera device is missing: $video_device (attach the USB camera to this WSL distro first)"
fi

if [[ -f "$package_dir/config/haarcascade_frontalface_default.xml" ]]; then
  pass "Face cascade data is present"
else
  fail "Face cascade data is missing from the package"
fi

if command -v rospack >/dev/null 2>&1 && rospack find usb_cam >/dev/null 2>&1; then
  pass "ROS can discover the usb_cam package"
else
  fail "ROS cannot discover usb_cam; run scripts/build.sh and open a new shell"
fi

if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
  pass "A graphical display is available"
else
  warn "No graphical display detected; keep view:=false for headless operation"
fi

printf '\nSummary: %d error(s), %d warning(s)\n' "$errors" "$warnings"
((errors == 0))
