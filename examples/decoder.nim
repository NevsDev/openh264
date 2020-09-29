import openh264, streams
import turbojpeg

# https://github.com/cisco/openh264/blob/master/test/decoder/DecUT_DecExt.cpp


# Step 1: decoder 
# open source
var 
  rawFile = readFile("test.h264")
  src_buffer = rawFile[0].addr
  src_bffer_size = rawFile.len.uint


# prepare output
var sDstBufInfo: SBufferInfo

# sDstParseInfo.pDstBuff = new unsigned char[PARSE_SIZE]; # In Parsing only, allocate enough buffer to save transcoded bitstream for a frame


# Step 2: create decoder 
var pSvcDecoder: ptr ISVCDecoder
WelsCreateDecoder(pSvcDecoder)


# Step 3: declare required parameter, used to differentiate Decoding only and Parsing only
var sDecParam: SDecodingParam 
sDecParam.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_SVC
sDecParam.sVideoProperty.size = src_bffer_size.cuint

# Step 4: initialize the parameter and decoder context, allocate memory
discard pSvcDecoder.initialize(sDecParam)


# Step 5: do actual decoding process in slice level; this can be done in a loop until data ends
import times
var lastTime: uint64 = (cpuTime() * 100).uint64
while dsErrorFree == pSvcDecoder.decodeFrameNoDelay(src_buffer, src_bffer_size.int, sDstBufInfo.pDst, sDstBufInfo):
  # var iRet = pSvcDecoder.decodeFrame2(src_buffer, src_bffer_size.int, pData, sDstBufInfo)
  # var frames: cint
  # echo "Options: ", pSvcDecoder.getOption(DECODER_OPTION_NUM_OF_FRAMES_REMAINING_IN_BUFFER, frames.addr)
  # echo "frames: ", frames

  # echo sDstBufInfo.iHeight
  # echo sDstBufInfo.iWidth
  # echo sDstBufInfo.iFormat
  var nowTime = (cpuTime() * 100).uint
  sDstBufInfo.inTimestamp = sDstBufInfo.inTimestamp + nowTime - lastTime
  lastTime = nowTime
  echo sDstBufInfo.inTimestamp
  echo sDstBufInfo.outTimestamp
  
  # decode failed
  # if iRet != dsErrorFree:
  #   echo "decode error: ", $iRet

  # for Decoding only, pData can be used for render.

  if sDstBufInfo.frameReady:    
    discard i4202jpegFile(sDstBufInfo.pDst, sDstBufInfo.iWidth, sDstBufInfo.iHeight, "test.jpeg", jpegQual = 80, sDstBufInfo.iStride)


  # discard pSvcDecoder.flushFrame(sDstBufInfo.pDst, sDstBufInfo)



pSvcDecoder.uninitialize()
WelsDestroyDecoder(pSvcDecoder)

