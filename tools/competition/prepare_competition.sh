#!/usr/bin/env bash
set -eo pipefail

usage()
{
  printf 'Usage: %s <workspace-name-or-path> <turtle-package> <face-package> <bag-package> [bag-file]\n' "$0" >&2
  exit 2
}

if [[ $# -lt 4 || $# -gt 5 ]]; then
  usage
fi

workspace_input="$1"
turtle_package="$2"
face_package="$3"
bag_package="$4"
toolkit_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$toolkit_dir/../.." && pwd)"
repository_dir="$repository_root/ros_ws/src/usb_cam"
cascade_path="$(realpath "$repository_dir/config/haarcascade_frontalface_default.xml")"
bag_path="${5:-${COMPETITION_BAG:-$repository_root/data/qcrros.bag}}"

if [[ "$workspace_input" = /* ]]; then
  workspace="$workspace_input"
else
  workspace="$HOME/$workspace_input"
fi

validate_package_name()
{
  if [[ ! "$1" =~ ^[a-z][a-z0-9_]*$ ]]; then
    printf 'Invalid ROS package name: %s\n' "$1" >&2
    printf 'Use lowercase letters, digits and underscores; start with a letter.\n' >&2
    exit 2
  fi
}

validate_package_name "$turtle_package"
validate_package_name "$face_package"
validate_package_name "$bag_package"
if [[ "$turtle_package" == "$face_package" || "$turtle_package" == "$bag_package" ||
      "$face_package" == "$bag_package" ]]; then
  printf 'The three package names must be different.\n' >&2
  exit 2
fi

if [[ ! -r /opt/ros/noetic/setup.bash ]]; then
  printf 'ROS Noetic is not available.\n' >&2
  exit 1
fi
if [[ ! -f "$cascade_path" ]]; then
  printf 'Face cascade is missing: %s\n' "$cascade_path" >&2
  exit 1
fi
if [[ ! -f "$bag_path" ]]; then
  printf 'Competition bag is missing: %s\n' "$bag_path" >&2
  printf 'The bag package cannot be generated without this file; the turtle and face packages do not depend on it.\n' >&2
  printf 'Fix it in one of these ways:\n' >&2
  printf '  1. Put the bag at: %s\n' "$repository_root/data/qcrros.bag" >&2
  printf '  2. Pass the bag path as the fifth argument.\n' >&2
  printf '  3. Set COMPETITION_BAG to the bag path.\n' >&2
  exit 1
fi
bag_path="$(realpath "$bag_path")"

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
mkdir -p "$workspace/src"
if [[ ! -e "$workspace/src/CMakeLists.txt" ]]; then
  (cd "$workspace/src" && catkin_init_workspace)
fi

usb_cam_link="$workspace/src/usb_cam"
if [[ -L "$usb_cam_link" ]]; then
  if [[ "$(readlink -f "$usb_cam_link")" != "$repository_dir" ]]; then
    printf '%s links to a different usb_cam repository.\n' "$usb_cam_link" >&2
    exit 1
  fi
elif [[ -e "$usb_cam_link" ]]; then
  printf '%s already exists and is not a symbolic link.\n' "$usb_cam_link" >&2
  exit 1
else
  ln -s "$repository_dir" "$usb_cam_link"
fi

require_fresh_package()
{
  if [[ -e "$workspace/src/$1" ]]; then
    printf 'Package directory already exists; use a fresh name or workspace: %s\n' \
      "$workspace/src/$1" >&2
    exit 1
  fi
}

require_fresh_package "$turtle_package"
require_fresh_package "$face_package"
require_fresh_package "$bag_package"

render_template()
{
  sed \
    -e "s|@PACKAGE_NAME@|$2|g" \
    -e "s|@CASCADE_PATH@|$cascade_path|g" \
    -e "s|@BAG_PATH@|$bag_path|g" \
    "$1" >"$3"
}

mkdir -p "$workspace/src/$turtle_package/src" "$workspace/src/$turtle_package/launch"
render_template "$toolkit_dir/templates/turtle/CMakeLists.txt.in" "$turtle_package" \
  "$workspace/src/$turtle_package/CMakeLists.txt"
render_template "$toolkit_dir/templates/turtle/package.xml.in" "$turtle_package" \
  "$workspace/src/$turtle_package/package.xml"
render_template "$toolkit_dir/templates/turtle/draw.launch.in" "$turtle_package" \
  "$workspace/src/$turtle_package/launch/draw.launch"
cp "$toolkit_dir/templates/turtle/turtle_draw_node.cpp" \
  "$workspace/src/$turtle_package/src/turtle_draw_node.cpp"

mkdir -p "$workspace/src/$face_package/src" "$workspace/src/$face_package/launch"
render_template "$toolkit_dir/templates/face/CMakeLists.txt.in" "$face_package" \
  "$workspace/src/$face_package/CMakeLists.txt"
render_template "$toolkit_dir/templates/face/package.xml.in" "$face_package" \
  "$workspace/src/$face_package/package.xml"
render_template "$toolkit_dir/templates/face/face.launch.in" "$face_package" \
  "$workspace/src/$face_package/launch/face.launch"
render_template "$toolkit_dir/templates/face/face_detection_node.cpp.in" "$face_package" \
  "$workspace/src/$face_package/src/face_detection_node.cpp"

mkdir -p "$workspace/src/$bag_package/launch" "$workspace/src/$bag_package/rviz"
render_template "$toolkit_dir/templates/bag/CMakeLists.txt.in" "$bag_package" \
  "$workspace/src/$bag_package/CMakeLists.txt"
render_template "$toolkit_dir/templates/bag/package.xml.in" "$bag_package" \
  "$workspace/src/$bag_package/package.xml"
render_template "$toolkit_dir/templates/bag/view_bag_manual.launch.in" "$bag_package" \
  "$workspace/src/$bag_package/launch/view_bag_manual.launch"
render_template "$toolkit_dir/templates/bag/view_bag_auto.launch.in" "$bag_package" \
  "$workspace/src/$bag_package/launch/view_bag_auto.launch"
render_template "$toolkit_dir/templates/bag/play_bag.launch.in" "$bag_package" \
  "$workspace/src/$bag_package/launch/play_bag.launch"
cp "$toolkit_dir/templates/bag/camera_image.rviz" \
  "$workspace/src/$bag_package/rviz/camera_image.rviz"

cd "$workspace"
catkin_make -DCMAKE_BUILD_TYPE=Release

printf '\nCompetition workspace created successfully: %s\n' "$workspace"
printf 'Turtle: source %s/devel/setup.bash && roslaunch %s draw.launch\n' \
  "$workspace" "$turtle_package"
printf 'Face:   source %s/devel/setup.bash && roslaunch %s face.launch\n' \
  "$workspace" "$face_package"
printf 'Bag:    source %s/devel/setup.bash && roslaunch %s view_bag_manual.launch\n' \
  "$workspace" "$bag_package"
printf 'Verify: %s/verify_competition.sh %s %s %s %s %s\n' \
  "$toolkit_dir" "$workspace" "$turtle_package" "$face_package" "$bag_package" "$bag_path"
