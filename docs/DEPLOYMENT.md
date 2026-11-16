# 部署说明

## 前置条件

安装Ubuntu 20.04和ROS Noetic。桌面环境建议安装 `ros-noetic-desktop-full`，因为比赛项目使用turtlesim、RViz和image_view。

确认ROS可用：

```bash
source /opt/ros/noetic/setup.bash
rosversion -d
```

## 自动部署

```bash
./scripts/setup.sh --install-deps
```

脚本会安装项目依赖、创建 `~/smartcar_ws`、链接ROS包并执行Release构建。它不会修改ROS发行版，也不会覆盖已有的不同 `usb_cam` 包。

## 无管理员权限部署

管理员预先安装依赖后运行：

```bash
./scripts/setup.sh --workspace ~/smartcar_ws
```

## 摄像头格式

默认使用MJPEG 640x480 30FPS。部分摄像头的MJPEG元数据不规范并产生FFmpeg警告时，改用YUYV：

```bash
./scripts/run.sh pixel_format:=yuyv framerate:=30
```

运行以下命令查看设备支持格式：

```bash
v4l2-ctl --device /dev/video0 --list-formats-ext
```

## 常见问题

**没有 `/dev/video0`**：摄像头未连接，或WSL2尚未通过usbipd挂载。

**Permission denied**：把当前用户加入video组，然后重新登录：

```bash
sudo usermod -aG video "$USER"
```

**ROS找不到包**：重新执行部署脚本，或手动加载工作空间：

```bash
source ~/smartcar_ws/devel/setup.bash
```

**图形窗口不显示**：使用 `view:=false` 进行无界面运行，或确认WSLg、DISPLAY或WAYLAND_DISPLAY可用。
