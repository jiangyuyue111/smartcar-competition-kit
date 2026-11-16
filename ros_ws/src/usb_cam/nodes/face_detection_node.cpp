#include <exception>
#include <stdexcept>
#include <string>
#include <vector>

#include <cv_bridge/cv_bridge.h>
#include <image_transport/image_transport.h>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/objdetect.hpp>
#include <ros/package.h>
#include <ros/ros.h>
#include <sensor_msgs/image_encodings.h>

namespace usb_cam
{

class FaceDetectionNode
{
public:
  FaceDetectionNode()
    : private_node_("~"), image_transport_(node_), show_window_(false)
  {
    const std::string default_cascade =
        ros::package::getPath("usb_cam") + "/config/haarcascade_frontalface_default.xml";

    private_node_.param("cascade_file", cascade_file_, default_cascade);
    private_node_.param("input_topic", input_topic_, std::string("/usb_cam/image_raw"));
    private_node_.param("output_topic", output_topic_, std::string("/face_detection/image"));
    private_node_.param("show_window", show_window_, false);
    private_node_.param("scale_factor", scale_factor_, 1.1);
    private_node_.param("min_neighbors", min_neighbors_, 3);
    private_node_.param("min_face_size", min_face_size_, 30);

    if (scale_factor_ <= 1.0)
    {
      throw std::runtime_error("~scale_factor must be greater than 1.0");
    }
    if (min_neighbors_ < 0 || min_face_size_ <= 0)
    {
      throw std::runtime_error("~min_neighbors must be non-negative and ~min_face_size must be positive");
    }
    if (!face_cascade_.load(cascade_file_))
    {
      throw std::runtime_error("unable to load cascade file: " + cascade_file_);
    }

    image_publisher_ = image_transport_.advertise(output_topic_, 1);
    image_subscriber_ = image_transport_.subscribe(input_topic_, 1,
        &FaceDetectionNode::imageCallback, this);

    ROS_INFO("Face detection is listening on '%s' and publishing '%s'",
        input_topic_.c_str(), output_topic_.c_str());
  }

  ~FaceDetectionNode()
  {
    if (show_window_)
    {
      cv::destroyWindow("Face detection");
    }
  }

private:
  void imageCallback(const sensor_msgs::ImageConstPtr& message)
  {
    try
    {
      const cv_bridge::CvImageConstPtr source =
          cv_bridge::toCvShare(message, sensor_msgs::image_encodings::BGR8);
      cv::Mat grayscale;
      cv::cvtColor(source->image, grayscale, cv::COLOR_BGR2GRAY);
      cv::equalizeHist(grayscale, grayscale);

      std::vector<cv::Rect> faces;
      face_cascade_.detectMultiScale(
          grayscale,
          faces,
          scale_factor_,
          min_neighbors_,
          cv::CASCADE_SCALE_IMAGE,
          cv::Size(min_face_size_, min_face_size_));

      cv::Mat annotated = source->image.clone();
      for (const cv::Rect& face : faces)
      {
        cv::rectangle(annotated, face, cv::Scalar(255, 0, 0), 2);
      }

      image_publisher_.publish(
          cv_bridge::CvImage(message->header, sensor_msgs::image_encodings::BGR8, annotated)
              .toImageMsg());

      if (show_window_)
      {
        cv::imshow("Face detection", annotated);
        cv::waitKey(1);
      }
    }
    catch (const cv_bridge::Exception& error)
    {
      ROS_ERROR_THROTTLE(5.0, "cv_bridge error: %s", error.what());
    }
    catch (const cv::Exception& error)
    {
      ROS_ERROR_THROTTLE(5.0, "OpenCV error: %s", error.what());
    }
  }

  ros::NodeHandle node_;
  ros::NodeHandle private_node_;
  image_transport::ImageTransport image_transport_;
  image_transport::Subscriber image_subscriber_;
  image_transport::Publisher image_publisher_;
  cv::CascadeClassifier face_cascade_;
  std::string cascade_file_;
  std::string input_topic_;
  std::string output_topic_;
  bool show_window_;
  double scale_factor_;
  int min_neighbors_;
  int min_face_size_;
};

}  // namespace usb_cam

int main(int argc, char** argv)
{
  ros::init(argc, argv, "face_detection");
  try
  {
    usb_cam::FaceDetectionNode node;
    ros::spin();
  }
  catch (const std::exception& error)
  {
    ROS_FATAL("Failed to start face detection: %s", error.what());
    return 1;
  }
  return 0;
}
