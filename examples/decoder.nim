import openh264, streams
import turbojpeg

# Step 1:d ecoder declaration

# open source
var 
  rawFile = readFile("test.h264")
  src_buffer = rawFile[0].addr
  src_bffer_size = rawFile.len.uint


var 
  sDstBufInfo: SBufferInfo
  sDstParseInfo: SParserBsInfo

# sDstParseInfo.pDstBuff = new unsigned char[PARSE_SIZE]; # In Parsing only, allocate enough buffer to save transcoded bitstream for a frame

# prepare output
var 
  pData: array[3, ptr UncheckedArray[uint8]]   #output: [0~2] for Y,U,V buffer for Decoding only
  dst_buffer: ptr UncheckedArray[uint8]
  dst_buffer_size: uint

# Step 2: create decoder 
var pSvcDecoder: ptr ISVCDecoder
WelsCreateDecoder(pSvcDecoder)

# Step 3: declare required parameter, used to differentiate Decoding only and Parsing only
var sDecParam: SDecodingParam 
sDecParam.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_AVC
# for Parsing only, the assignment is mandatory


# Step 4: initialize the parameter and decoder context, allocate memory
discard pSvcDecoder.initialize(sDecParam)

# Step 5: do actual decoding process in slice level; this can be done in a loop until data ends
# for Decoding only
var iRet = pSvcDecoder.decodeFrameNoDelay(src_buffer, src_bffer_size.int, pData, sDstBufInfo)

# decode failed
if iRet != dsErrorFree:
  echo "decode error: ", iRet
 
# for Decoding only, pData can be used for render.
var handle = tjInitCompress()
if sDstBufInfo.iBufferStatus == 1:
  var
    width = 600
    height = 600
  echo "success: " , tjCompressFromYUVPlanes(handle, srcPlanes = pData, width, strides = nil, height, subsamp = TJSAMP_420, dst_buffer, dst_buffer_size, jpegQual = 80, flags = 0)
  
  var f = openFileStream("test.jpeg", fmWrite)
  f.writeData(dst_buffer, dst_buffer_size.int)
  f.close()




WelsDestroyDecoder(pSvcDecoder)

