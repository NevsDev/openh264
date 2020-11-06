import openh264

var
  src = readFile("rsc/buck_bunny.h264")
  src_buffer = cast[ptr UncheckedArray[uint8]](src[0].addr)
  src_buffer_size = src.len.uint

  jpeg_output: ptr UncheckedArray[uint8]
  jpeg_size: uint
  width, height: int

var decoder = h264Decoder()
decoder.init(src_buffer, src_buffer_size)

echo "Frames count: ", decoder.frames
echo "Duration: ", decoder.duration

var counter = 0
while not decoder.atEnd():
  if decoder.decodeJpeg(jpeg_output, jpeg_size, width, height, jpegQual = 80):
    var file = open("test_output/first_frame.jpg", fmWrite)
    discard file.writeBuffer(jpeg_output, jpeg_size)
    file.close()
    echo "extract first frame"
    # sleep(33)
    quit(0)
  else:
    discard
    # echo "could not decode first frame"
  echo "Frame: ", counter
  counter.inc

decoder.destroy()