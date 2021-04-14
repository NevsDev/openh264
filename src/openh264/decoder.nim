import codec_def, codec_app_def, codec_api
import turbojpeg
import coutils/shared_types

type
  FramePosInfo = tuple[pos: uint32, endpos: uint32]

  H264Decoder* = ptr H264DecoderObj
  H264DecoderObj* = object
    p_dec: ptr ISVCDecoder
    p_sDecParam: SDecodingParam
    p_sDstBufInfo: SBufferInfo
    p_bufSize: uint
    p_buffer: ptr UncheckedArray[uint8]
    p_fps: float
    p_frames: List[FramePosInfo]  # Position of frames
    p_currentFrame: int

proc reset(d: H264Decoder) =
  if d.p_dec != nil:
    d.p_dec.uninitialize()
    WelsDestroyDecoder(d.p_dec)
  d.p_bufSize = 0
  d.p_currentFrame = 0
  d.p_frames.setLen(0)
  d.p_fps = 30

proc initFrames(d: H264Decoder) =
  d.p_frames.setLen(0)
  var i = 1'u32
  while i < d.p_bufSize:
    if d.p_buffer[i] == 0 and d.p_buffer[i + 1] == 0 and d.p_buffer[i + 2] == 0 and d.p_buffer[i + 3] == 1:
      if d.p_frames.len == 0:
        d.p_frames.add((0'u32, i))
      else:
        var index = d.p_frames.len - 1
        d.p_frames.add((d.p_frames[index].endpos, i))
    # proc decodeParser*(a1: ptr ISVCDecoder; pSrc: ptr UncheckedArray[uint8]; iSrcLen: int; pDstInfo: var SParserBsInfo): DECODING_STATE {.inline.} = 
    # TODO parse source and extract infos
    i.inc



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~ High Level API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc destroy*(d: var H264Decoder) =
  if d.p_dec != nil:
    d.p_dec.WelsDestroyDecoder()
  if d.p_buffer != nil:
    d.p_buffer.dealloc()
  d.freeShared()

proc h264Decoder*(): H264Decoder =
  result = createShared(H264DecoderObj)

proc frames*(d: H264Decoder): int =
  result = d.p_frames.len

proc duration*(d: H264Decoder): float =
  result = d.p_fps * d.p_frames.len.float

proc atEnd*(d: H264Decoder): bool =
  result = d.p_currentFrame >= d.p_frames.len


proc init*(h264dec: H264Decoder, src_buffer: pointer | ptr UncheckedArray[uint8], src_buffer_size: uint) =
  h264dec.reset()
  WelsCreateDecoder(h264dec.p_dec)

  h264dec.p_sDecParam.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_AVC
  h264dec.p_sDecParam.sVideoProperty.size = src_buffer_size.cuint
  h264dec.p_bufSize = src_buffer_size
  h264dec.p_buffer = cast[ptr UncheckedArray[uint8]](src_buffer)

  discard h264dec.p_dec.initialize(h264dec.p_sDecParam)
  h264dec.initFrames()

proc decodeI420*(h264dec: H264Decoder, i420_output: var array[3, ptr UncheckedArray[uint8]], width: var int, height: var int, stride: var array[3, cint]): bool =
  while true:
    if h264dec.p_currentFrame >= h264dec.p_frames.len:
      var iEndOfStreamFlag = true
      h264dec.p_dec.setOption(DECODER_OPTION_END_OF_STREAM, iEndOfStreamFlag.addr)
      return false

    var 
      pos = h264dec.p_frames[h264dec.p_currentFrame].pos
      slice = h264dec.p_frames[h264dec.p_currentFrame].endpos - pos
    if dsErrorFree != h264dec.p_dec.decodeFrameNoDelay(h264dec.p_buffer[pos].addr, slice.int, h264dec.p_sDstBufInfo.pDst, h264dec.p_sDstBufInfo):
      echo "Decoding error"
    h264dec.p_currentFrame.inc

    # var nowTime = (cpuTime() * 100).uint
    # sDstBufInfo.inTimestamp = sDstBufInfo.inTimestamp + nowTime - lastTime
    # lastTime = nowTime
    # var frame_num: cint
    # var stat: SDecoderStatistics

    # discard pSvcDecoder.getOption(DECODER_OPTION_FRAME_NUM, frame_num.addr)
    # # discard pSvcDecoder.getOption(DECODER_OPTION_GET_STATISTICS, stat.addr)
    # echo "Frames ", frame_num

    # echo "here ", pos, " ", slice, " ", h264dec.p_currentFrame
    if h264dec.p_sDstBufInfo.frameReady:
      width = h264dec.p_sDstBufInfo.iWidth
      height = h264dec.p_sDstBufInfo.iHeight
      i420_output = h264dec.p_sDstBufInfo.pDst
      stride = h264dec.p_sDstBufInfo.iStride
      return true
    else:
      discard
    discard h264dec.p_dec.flushFrame(h264dec.p_sDstBufInfo.pDst, h264dec.p_sDstBufInfo)
    
    var frame_num: cint
    discard h264dec.p_dec.getOption(DECODER_OPTION_FRAME_NUM, frame_num.addr)
    if frame_num < 0:
      continue
    else:
      break

proc decodeJpeg*(h264dec: H264Decoder, jpeg_output: var ptr UncheckedArray[uint8], jpeg_size: var uint, width, height: var int, jpegQual: TJQuality = 80): bool =
  var 
    i420_output: array[3, ptr UncheckedArray[uint8]]
    strides: array[3, cint]
  if not h264dec.decodeI420(i420_output, width, height, strides):
    return false
  return i4202jpeg(i420_output, width, height, jpeg_output, jpeg_size, jpegQual, strides)

proc decodeRGB*(h264dec: H264Decoder, rgb_output: var ptr UncheckedArray[uint8], width, height: var int): bool =
  var 
    i420_output: array[3, ptr UncheckedArray[uint8]]
    strides: array[3, cint]
    rgb_size: uint
  if not h264dec.decodeI420(i420_output, width, height, strides):
    return false
  return i4202rgb(i420_output, strides, width, height, rgb_output, rgb_size)
