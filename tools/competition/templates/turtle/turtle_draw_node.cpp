#include <cmath>

#include <geometry_msgs/Twist.h>
#include <ros/ros.h>
#include <std_srvs/Empty.h>
#include <turtlesim/SetPen.h>
#include <turtlesim/TeleportAbsolute.h>

namespace
{
constexpr double kPi = 3.14159265358979323846;

void publishFor(ros::Publisher& publisher, double linear, double angular, double seconds)
{
  geometry_msgs::Twist command;
  command.linear.x = linear;
  command.angular.z = angular;
  const ros::WallTime end = ros::WallTime::now() + ros::WallDuration(seconds);
  ros::WallRate rate(50.0);
  while (ros::ok() && ros::WallTime::now() < end)
  {
    publisher.publish(command);
    ros::spinOnce();
    rate.sleep();
  }
  publisher.publish(geometry_msgs::Twist());
  ros::WallDuration(0.1).sleep();
}

bool setPen(ros::ServiceClient& client, int red, int green, int blue, int width, bool off)
{
  turtlesim::SetPen request;
  request.request.r = red;
  request.request.g = green;
  request.request.b = blue;
  request.request.width = width;
  request.request.off = off;
  return client.call(request);
}

bool teleport(ros::ServiceClient& client, double x, double y, double theta)
{
  turtlesim::TeleportAbsolute request;
  request.request.x = x;
  request.request.y = y;
  request.request.theta = theta;
  return client.call(request);
}
}  // namespace

int main(int argc, char** argv)
{
  ros::init(argc, argv, "turtle_draw_node");
  ros::NodeHandle node;
  ros::Publisher velocity = node.advertise<geometry_msgs::Twist>("/turtle1/cmd_vel", 10);
  ros::ServiceClient clear = node.serviceClient<std_srvs::Empty>("/clear");
  ros::ServiceClient pen = node.serviceClient<turtlesim::SetPen>("/turtle1/set_pen");
  ros::ServiceClient move = node.serviceClient<turtlesim::TeleportAbsolute>("/turtle1/teleport_absolute");

  if (!clear.waitForExistence(ros::Duration(10.0)) ||
      !pen.waitForExistence(ros::Duration(10.0)) ||
      !move.waitForExistence(ros::Duration(10.0)))
  {
    ROS_ERROR("turtlesim services did not become available");
    return 1;
  }

  std_srvs::Empty empty;
  clear.call(empty);
  setPen(pen, 0, 0, 0, 3, true);
  teleport(move, 2.5, 3.5, 0.0);
  setPen(pen, 20, 90, 220, 4, false);

  // Six straight sides form a closed hexagon.
  for (int side = 0; side < 6 && ros::ok(); ++side)
  {
    publishFor(velocity, 1.5, 0.0, 2.5 / 1.5);
    publishFor(velocity, 0.0, 1.5, (kPi / 3.0) / 1.5);
  }

  // A circle overlaps the polygon, creating a straight-and-curved composition.
  setPen(pen, 0, 0, 0, 3, true);
  teleport(move, 8.8, 5.5, kPi / 2.0);
  setPen(pen, 220, 50, 50, 4, false);
  publishFor(velocity, 1.3, 1.0, 2.0 * kPi);

  setPen(pen, 0, 0, 0, 3, true);
  teleport(move, 5.5, 5.5, 0.0);
  ROS_INFO("Completed a six-sided straight-and-curved competition drawing");
  return 0;
}
