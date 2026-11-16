# 2026智能小车挑战赛现场操作指南

本工具按初赛三个评分项目准备，现场只需要把裁判公布的名称填入命令。所有项目必须在同一台电脑上操作，总时间为30分钟。

## 赛前检查

```bash
cd /path/to/smartcar-competition-kit
./scripts/setup.sh
./scripts/doctor.sh
./scripts/test.sh
```

两个命令都成功后，摄像头、ROS、XML分类器和人脸检测链路均可用。

## 现场创建指定名称的项目

将下面四个名称替换为裁判现场公布的名称。若裁判没有指定第三个包名，可自定一个符合ROS命名规则的名称。

```bash
cd /path/to/smartcar-competition-kit
./tools/competition/prepare_competition.sh \
  裁判指定工作空间名 \
  裁判指定小龟包名 \
  裁判指定人脸包名 \
  裁判指定bag包名
```

ROS包名只能使用小写字母、数字和下划线，并且必须以字母开头。脚本会创建完整的 `src`、`build`、`devel`，生成三个包并完成编译。

## 项目一 小龟画图

```bash
source ~/裁判指定工作空间名/devel/setup.bash
roslaunch 裁判指定小龟包名 draw.launch
```

程序绘制一个六边形和相交圆形，包含六条直线、闭合多边形和曲线，符合“直曲线组合、五边及以上”的最高图形档。

## 项目二 人脸识别算法部署

```bash
source ~/裁判指定工作空间名/devel/setup.bash
roslaunch 裁判指定人脸包名 face.launch
```

默认使用稳定的 `YUYV 640x480 30FPS`。源码位于指定包的 `src/face_detection_node.cpp`，其中包含比赛要求的XML绝对路径：

该绝对路径由生成脚本根据仓库实际位置写入，不依赖部署者用户名或固定目录。

显示窗口中出现摄像头画面，并在人脸位置显示蓝框，即完成摄像头出图和人脸检测。

## 项目三 rosbag和RViz

先向裁判展示文件信息：

```bash
rosbag info /path/to/smartcar-competition-kit/data/qcrros.bag
```

文件时长约7.77秒，话题为 `/camera/image_raw`，类型为 `sensor_msgs/Image`。

按基础评分要求启动空白RViz：

```bash
source ~/裁判指定工作空间名/devel/setup.bash
roslaunch 裁判指定bag包名 view_bag_manual.launch
```

在RViz中手动操作：

1. 点击左下角 Add。
2. 选择 By display type。
3. 选择 Image 并确认。
4. 在 Image Topic 中手动输入 `/camera/image_raw`。

不要用 By Topic 直接添加；规则中手动输入话题得6分，By Topic只得1分。

脚本自动配置演示可使用：

```bash
roslaunch 裁判指定bag包名 view_bag_auto.launch
```

## 现场验证和时间安排

```bash
/path/to/smartcar-competition-kit/tools/competition/verify_competition.sh \
  ~/裁判指定工作空间名 \
  裁判指定小龟包名 \
  裁判指定人脸包名 \
  裁判指定bag包名 \
  /path/to/smartcar-competition-kit/data/qcrros.bag
```

赛前可运行完整的三项目运行测试：

```bash
/path/to/smartcar-competition-kit/tools/competition/runtime_test.sh \
  ~/裁判指定工作空间名 \
  裁判指定小龟包名 \
  裁判指定人脸包名 \
  裁判指定bag包名
```

建议时间分配：前4分钟生成和编译；4至9分钟验证；9至14分钟展示小龟；14至20分钟展示人脸；20至25分钟展示bag和RViz；最后5分钟向裁判展示三个包的源码、CMakeLists和自动化脚本。
