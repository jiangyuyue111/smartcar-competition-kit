# ROS智能小车比赛部署工具

这个仓库提供可复用的ROS Noetic摄像头、人脸检测、小龟绘图、rosbag和RViz比赛环境。它把开发环境检查、catkin构建、摄像头运行、三项目现场包生成和验收脚本放在同一个仓库中，适合在Ubuntu 20.04或WSL2中部署。

## 功能

- USB摄像头读取并发布 `/usb_cam/image_raw`
- Haar级联人脸检测并发布 `/face_detection/image`
- 根据现场指定名称生成新的catkin工作空间和三个比赛包
- 绘制由六边形和圆形组成的直曲线组合图案
- 播放比赛bag并提供手动或自动RViz配置
- 一键检查ROS、依赖、摄像头、分类器和工作空间
- 提供无摄像头冒烟测试和有摄像头端到端测试

## 支持环境

- Ubuntu 20.04
- ROS Noetic
- Bash
- 可选：Windows 11、WSL2和usbipd-win

ROS Noetic属于旧版ROS 1环境。本仓库为了兼容比赛规则继续使用Noetic；新项目长期维护时建议另行规划ROS 2迁移。

## 快速部署

```bash
git clone <repository-url> smartcar-competition-kit
cd smartcar-competition-kit
./scripts/setup.sh --install-deps
```

默认工作空间为 `~/smartcar_ws`，可指定其他位置：

```bash
./scripts/setup.sh --workspace ~/my_smartcar_ws
```

部署完成后运行环境检查：

```bash
./scripts/doctor.sh
```

启动摄像头和人脸检测：

```bash
./scripts/run.sh
```

启用WSLg图像窗口：

```bash
./scripts/run.sh view:=true
```

## WSL2摄像头

Windows管理员PowerShell首次执行：

```powershell
usbipd list
.\scripts\windows\attach-camera.ps1 -Distribution Ubuntu -BusId 1-6 -AutoAttach
```

`BusId` 必须以 `usbipd list` 的实际结果为准。摄像头挂载到WSL时，Windows相机应用暂时不能使用它。归还摄像头：

```powershell
.\scripts\windows\detach-camera.ps1 -BusId 1-6
```

## 比赛bag文件

普通Git托管通常不适合直接保存数百MB的bag文件。把比赛文件放到：

```text
data/qcrros.bag
```

如果团队需要版本化该文件，请使用Git LFS或单独的发布附件。

## 现场生成指定名称的项目

```bash
./tools/competition/prepare_competition.sh \
  competition_ws \
  turtle_package_name \
  face_package_name \
  bag_package_name
```

也可以将bag路径作为第五个参数传入：

```bash
./tools/competition/prepare_competition.sh \
  competition_ws turtle_pkg face_pkg bag_pkg /absolute/path/to/file.bag
```

详细步骤见 [docs/COMPETITION_GUIDE.md](docs/COMPETITION_GUIDE.md)。

## 仓库结构

```text
ros_ws/src/usb_cam/       ROS摄像头和人脸检测包
tools/competition/        现场包生成器和模板
scripts/                  部署、检查、运行与测试脚本
scripts/windows/          WSL摄像头挂载脚本
data/                     本地bag文件目录
docs/                     部署和比赛说明
```

## 测试

```bash
./scripts/test.sh
```

没有摄像头时会完成编译和节点冒烟测试，并跳过摄像头端到端测试；摄像头可访问时会验证原始图像和人脸检测图像均能发布。

## 许可证

本仓库使用BSD 3-Clause许可证。`usb_cam`基于ros-drivers/usb_cam并保留上游许可证与作者信息；OpenCV级联文件保留其原始许可证文本。
