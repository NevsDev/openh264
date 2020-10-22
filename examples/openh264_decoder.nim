import openh264, streams
import turbojpeg

# https://github.com/cisco/openh264/blob/master/test/decoder/DecUT_DecExt.cpp


# Step 1: decoder 
# open source
var 
  rawFile = readFile("test.h264")
  src_buffer = cast[ptr UncheckedArray[uint8]](rawFile[0].addr)
  src_bffer_size = rawFile.len.uint

# prepare output
var sDstBufInfo: SBufferInfo

# Step 2: create decoder 
var pSvcDecoder: ptr ISVCDecoder
WelsCreateDecoder(pSvcDecoder)

# Step 3: declare required parameter, used to differentiate Decoding only and Parsing only
var sDecParam: SDecodingParam 
sDecParam.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_AVC
sDecParam.sVideoProperty.size = src_bffer_size.cuint

# Step 4: initialize the parameter and decoder context, allocate memory
discard pSvcDecoder.initialize(sDecParam)


# Step 5: do actual decoding process in slice level; this can be done in a loop until data ends
import times
var lastTime: uint64 = (cpuTime() * 100).uint64
var counter = 0

var iBufPos, iSliceSize: uint = 0
while true:
  if iBufPos >= src_bffer_size:
    var iEndOfStreamFlag = true
    pSvcDecoder.setOption(DECODER_OPTION_END_OF_STREAM, iEndOfStreamFlag.addr)
    break
  var i = 1'u32
  while i < src_bffer_size:
    if src_buffer[iBufPos + i] == 0 and src_buffer[iBufPos + i + 1] == 0 and src_buffer[iBufPos + i + 2] == 0 and src_buffer[iBufPos + i + 3] == 1:
      break
    i.inc
  iSliceSize = i
  if dsErrorFree != pSvcDecoder.decodeFrameNoDelay(src_buffer[iBufPos].addr, iSliceSize.int, sDstBufInfo.pDst, sDstBufInfo):
    echo "Decoding error"
  iBufPos += iSliceSize
 
  # var nowTime = (cpuTime() * 100).uint
  # sDstBufInfo.inTimestamp = sDstBufInfo.inTimestamp + nowTime - lastTime
  # lastTime = nowTime
  var frame_num: cint
  var stat: SDecoderStatistics

  discard pSvcDecoder.getOption(DECODER_OPTION_FRAME_NUM, frame_num.addr)
  # discard pSvcDecoder.getOption(DECODER_OPTION_GET_STATISTICS, stat.addr)
  echo "Frames ", frame_num

  if sDstBufInfo.frameReady:    
    echo counter, " ", iBufPos, " ", sDstBufInfo
    counter.inc
    discard i4202jpegFile(sDstBufInfo.pDst, sDstBufInfo.iWidth, sDstBufInfo.iHeight, "test.jpeg", jpegQual = 80, sDstBufInfo.iStride)

  discard pSvcDecoder.flushFrame(sDstBufInfo.pDst, sDstBufInfo)

pSvcDecoder.uninitialize()
WelsDestroyDecoder(pSvcDecoder)

