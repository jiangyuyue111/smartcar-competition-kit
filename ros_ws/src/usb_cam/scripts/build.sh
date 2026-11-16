#!/usr/bin/env bash
set -eo pipefail

workspace="${CATKIN_WS:-$HOME/catkin_ws}"
package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_package="$workspace/src/usb_cam"

if [[ ! -r /opt/ros/noetic/setup.bash ]]; then
  printf 'ROS Noetic is not installed at /opt/ros/noetic.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
set -u
mkdir -p "$workspace/src"

if [[ -L "$workspace_package" ]]; then
  current_target="$(readlink -f "$workspace_package")"
  if [[ "$current_target" != "$package_dir" ]]; then
    printf 'The workspace already links usb_cam to %s, expected %s.\n' \
      "$current_target" "$package_dir" >&2
    exit 1
  fi
elif [[ -e "$workspace_package" ]]; then
  printf '%s already exists and is not the expected symbolic link.\n' "$workspace_package" >&2
  exit 1
else
  ln -s "$package_dir" "$workspace_package"
fi

cd "$workspace"
catkin_make -DCMAKE_BUILD_TYPE=Release
printf '\nBuild complete. Run: source %s/devel/setup.bash\n' "$workspace"
