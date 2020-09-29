import openh264, streams, times
import turbojpeg

# https://github.com/cisco/openh264/wiki/UsageExampleForEncoder
# https://gstreamer.freedesktop.org/documentation/additional/design/mediatype-video-raw.html?gi-language=c
# https://docs.microsoft.com/en-us/windows/win32/medfound/image-stride


## Example of encoding single image to h264


template doWhile(cond, body) =
  body
  while cond:
    body

var encoder: ptr ISVCEncoder


var 
  rv = WelsCreateSVCEncoder(encoder)
  total_num: int = 100

  width, height: int
  i420_img_size: uint # = width * height * 3 div 2  # 12 bits per pixel
  pictureData: ptr UncheckedArray[uint8]

if not jpegFile2i420("rsc/lion.jpg", pictureData, i420_img_size, width, height):
  echo "could not generate i420 image"
  quit(1)

echo "size: ", width, "x", height, " | ", i420_img_size

var param: SEncParamExt

param.iUsageType = CAMERA_VIDEO_REAL_TIME
param.fMaxFrameRate = 30
param.iPicWidth = width.cint
param.iPicHeight = height.cint
param.iTargetBitrate = 540000
param.iRCMode = RC_OFF_MODE
# param.bEnableDenoise = denoise
param.iNumRefFrame = 1
param.iSpatialLayerNum = 1

var 
  sliceMode = SM_SINGLE_SLICE
  frameRate = 30.cfloat

# SM_SIZELIMITED_SLICE with multi-thread is still under testing
if sliceMode != SM_SINGLE_SLICE and sliceMode != SM_SIZELIMITED_SLICE:
    param.iMultipleThreadIdc = 2

for i in 0..<param.iSpatialLayerNum:
  param.sSpatialLayers[i].iVideoWidth = width.cint # shr (param.iSpatialLayerNum - 1 - i)
  param.sSpatialLayers[i].iVideoHeight = height.cint # shr (param.iSpatialLayerNum - 1 - i)
  param.sSpatialLayers[i].fFrameRate = frameRate
  param.sSpatialLayers[i].iSpatialBitrate = param.iTargetBitrate

  param.sSpatialLayers[i].sSliceArgument.uiSliceMode = sliceMode
  if sliceMode == SM_SIZELIMITED_SLICE:
      param.sSpatialLayers[i].sSliceArgument.uiSliceSizeConstraint = 600
      param.uiMaxNalSize = 1500

param.iTargetBitrate *= param.iSpatialLayerNum;
discard encoder.initializeExt(param)

# var videoFormat = videoFormatI420
# discard encoder.setOption(ENCODER_OPTION_DATAFORMAT, videoFormat.addr)


var 
  info: SFrameBSInfo
  pic: SSourcePicture

pic.iColorFormat = EVideoFormatType.videoFormatI420
pic.iPicWidth = width.cint
pic.iPicHeight = height.cint

pic.iStride[0] = width.cint            
pic.iStride[1] = width.cint div 2
pic.iStride[2] = width.cint div 2
pic.iStride[3] = 0
pic.pData[0] = pictureData
pic.pData[1] = pictureData[i420_img_size * 2 div 3].addr
pic.pData[2] = pictureData[i420_img_size * 10 div 12].addr
pic.pData[3] = nil

pic.uiTimeStamp = (cpuTime() * 1000).clonglong 

var fileStream = newFileStream("test.h264", fmWrite)

for num in 0..<total_num:
  # prepare input data
  rv = encoder.encodeFrame(pic, info)
  assert(rv == true)
  if info.eFrameType != videoFrameTypeSkip: 
    # output bitstream
    for iLayer in 0..<info.iLayerNum:
      var 
        pLayerBsInfo: ptr SLayerBSInfo = info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      var outBuf = pLayerBsInfo.pBsBuf
      # echo "Layer ", iLayerSize
      fileStream.writeData(outBuf, iLayerSize)


if encoder != nil:
  discard encoder.uninitialize()
  WelsDestroySVCEncoder(encoder)

fileStream.close()