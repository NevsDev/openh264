import openh264, streams, strformat
import cortona_image

const
  width = 600
  height = 600

var
  outputFile = newFileStream("test_output/color.h264", fmWrite)
  encoder = h264Encoder()

encoder.init(width, height, 30)
for i in 0'u8..<255'u8:
  var rgb_img = image[RGB](width, height, rgb(i, i, i))
  if encoder.encodeRGB(rgb_img.caddr, outputFile):
    echo &"frame: {i:3} is ready"

outputFile.close()
encoder.destroy()