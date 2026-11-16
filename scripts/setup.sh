#!/usr/bin/env bash
set -eo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="${SMARTCAR_WS:-$HOME/smartcar_ws}"
install_dependencies=false

usage()
{
  printf 'Usage: %s [--install-deps] [--workspace PATH]\n' "$0" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-deps)
      install_dependencies=true
      shift
      ;;
    --workspace)
      [[ $# -ge 2 ]] || usage
      workspace="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

if [[ ! -r /opt/ros/noetic/setup.bash ]]; then
  printf 'ROS Noetic was not found at /opt/ros/noetic. Install ROS before running setup.\n' >&2
  exit 1
fi

if [[ "$install_dependencies" == true ]]; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential cmake ffmpeg git opencv-data pkg-config v4l-utils \
    libavcodec-dev libavutil-dev libswscale-dev libopencv-dev \
    ros-noetic-camera-info-manager ros-noetic-cv-bridge ros-noetic-image-transport \
    ros-noetic-image-view ros-noetic-rosbash ros-noetic-roscpp ros-noetic-roslaunch \
    ros-noetic-sensor-msgs ros-noetic-std-msgs ros-noetic-std-srvs \
    ros-noetic-turtlesim ros-noetic-rviz
fi

# shellcheck disable=SC1091
source /opt/ros/noetic/setup.bash
mkdir -p "$workspace/src"
workspace_package="$workspace/src/usb_cam"
source_package="$repository_root/ros_ws/src/usb_cam"

if [[ -L "$workspace_package" ]]; then
  if [[ "$(readlink -f "$workspace_package")" != "$source_package" ]]; then
    printf '%s links to another package. Remove it or choose another workspace.\n' \
      "$workspace_package" >&2
    exit 1
  fi
elif [[ -e "$workspace_package" ]]; then
  printf '%s already exists and will not be overwritten.\n' "$workspace_package" >&2
  exit 1
else
  ln -s "$source_package" "$workspace_package"
fi

if [[ ! -e "$workspace/src/CMakeLists.txt" ]]; then
  (cd "$workspace/src" && catkin_init_workspace)
fi

cd "$workspace"
catkin_make -DCMAKE_BUILD_TYPE=Release

printf '\nDeployment complete.\n'
printf 'Workspace: %s\n' "$workspace"
printf 'Run: SMARTCAR_WS=%q %q/scripts/doctor.sh\n' "$workspace" "$repository_root"
