import openh264, streams
import turbojpeg

var 
  outputFile = newFileStream("img2video.h264", fmWrite)
  width, height: int
  i420_img_size: uint # = width * height * 3 div 2  # 12 bits per pixel
  pictureData: ptr UncheckedArray[uint8]
  encoder = h264Encoder()


if jpegFile2i420("rsc/lion.jpg", pictureData, i420_img_size, width, height):
  echo i420_img_size, " ", width, " ", height
  encoder.init(width, height, 30)
  for i in 0'u8..<255'u8:
    if encoder.encodei420(pictureData, i420_img_size.int, outputFile):
      discard

outputFile.close()
encoder.destroy()