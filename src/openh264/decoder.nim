import codec_def, codec_app_def, codec_api
import turbojpeg

type
  FrameInfo = tuple[pos: uint32, endpos: uint32]

  H264Decoder* = ref H264DecoderObj
  H264DecoderObj* = object
    dec: ptr ISVCDecoder
    sDstBufInfo: SBufferInfo
    sDecParam: SDecodingParam
    bufSize: uint
    buffer: ptr UncheckedArray[uint8]
    frames: seq[FrameInfo]  # Position of frames
    currentFrame: int

var gdec {.threadvar.}: H264Decoder

proc default_decoder(): H264Decoder =
  if gdec == nil:
    gdec = new(H264DecoderObj)
  result = gdec

proc decoder(d: H264Decoder): ptr ISVCDecoder =
  if d.dec == nil:
    WelsCreateDecoder(d.dec)
  result = d.dec

proc reset(d: H264Decoder) =
  if d.dec != nil:
    d.dec.uninitialize()
    WelsDestroyDecoder(d.dec)
  d.bufSize = 0
  d.currentFrame = 0
  d.frames.setLen(0)

proc initFrames(d: H264Decoder) =
  var i = 1'u32
  while i < d.bufSize:
    if d.buffer[i] == 0 and d.buffer[i + 1] == 0 and d.buffer[i + 2] == 0 and d.buffer[i + 3] == 1:
      if d.frames.len == 0:
        d.frames.add((0'u32, i))
      else:
        var index = d.frames.len - 1
        d.frames.add((d.frames[index].endpos, i))
    i.inc

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~ High Level API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc h264DecoderInit*(src_buffer: pointer, src_buffer_size: uint) =
  var h264dec = default_decoder()
  h264dec.reset()

  h264dec.sDecParam.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_AVC
  h264dec.sDecParam.sVideoProperty.size = src_buffer_size.cuint
  h264dec.bufSize = src_buffer_size
  h264dec.buffer = cast[ptr UncheckedArray[uint8]](src_buffer)

  discard h264dec.decoder.initialize(h264dec.sDecParam)
  h264dec.initFrames()

proc h264DecodeI420*(i420_output: var array[3, ptr UncheckedArray[uint8]], width: var int, height: var int, stride: var array[3, cint]): bool =
  var h264dec = default_decoder()

  if h264dec.currentFrame >= h264dec.frames.len:
    var iEndOfStreamFlag = true
    h264dec.dec.setOption(DECODER_OPTION_END_OF_STREAM, iEndOfStreamFlag.addr)
    return false

  var 
    pos = h264dec.frames[h264dec.currentFrame].pos
    slice = h264dec.frames[h264dec.currentFrame].endpos - pos
  if dsErrorFree != h264dec.dec.decodeFrameNoDelay(h264dec.buffer[pos].addr, slice.int, h264dec.sDstBufInfo.pDst, h264dec.sDstBufInfo):
    echo "Decoding error"
  h264dec.currentFrame.inc
 
  # var nowTime = (cpuTime() * 100).uint
  # sDstBufInfo.inTimestamp = sDstBufInfo.inTimestamp + nowTime - lastTime
  # lastTime = nowTime
  # var frame_num: cint
  # var stat: SDecoderStatistics

  # discard pSvcDecoder.getOption(DECODER_OPTION_FRAME_NUM, frame_num.addr)
  # # discard pSvcDecoder.getOption(DECODER_OPTION_GET_STATISTICS, stat.addr)
  # echo "Frames ", frame_num

  if h264dec.sDstBufInfo.frameReady:
    width = h264dec.sDstBufInfo.iWidth
    height = h264dec.sDstBufInfo.iHeight
    i420_output = h264dec.sDstBufInfo.pDst
    stride = h264dec.sDstBufInfo.iStride
    result = true

  discard h264dec.dec.flushFrame(h264dec.sDstBufInfo.pDst, h264dec.sDstBufInfo)

proc h264DecodeJpeg*(jpeg_output: var ptr UncheckedArray[uint8], jpeg_size: var uint, width, height: var int, jpegQual: TJQuality = 80): bool =
  var 
    i420_output: array[3, ptr UncheckedArray[uint8]]
    strides: array[3, cint]
  if not h264DecodeI420(i420_output, width, height, strides):
    return false
  if i4202jpeg(i420_output, width, height, jpeg_output, jpeg_size, jpegQual, strides):
    return false
  return true

proc h264DecodeRGB*(rgb_output: var ptr UncheckedArray[uint8], width, height: var int): bool =
  var 
    i420_output: array[3, ptr UncheckedArray[uint8]]
    strides: array[3, cint]
    rgb_size: uint

  if not h264DecodeI420(i420_output, width, height, strides):
    return false
  if not i4202rgb(i420_output, strides, width, height, rgb_output, rgb_size):
    return false
  return true