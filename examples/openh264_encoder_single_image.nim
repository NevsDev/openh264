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

encoder.getDefaultParams(param)

param.iUsageType = CAMERA_VIDEO_REAL_TIME
param.iPicWidth = width.cint
param.iPicHeight = height.cint

# param.iTargetBitrate = 540000
param.iRCMode = RC_OFF_MODE
param.fMaxFrameRate = 30
param.iTemporalLayerNum = 3 ## temporal layer number, max temporal layer = 4
param.iSpatialLayerNum = 1 ## spatial layer number,1<= iSpatialLayerNum <= MAX_SPATIAL_LAYER_NUM, MAX_SPATIAL_LAYER_NUM = 4
# param.sSpatialLayers*: array[MAX_SPATIAL_LAYER_NUM, SSpatialLayerConfig]
param.iComplexityMode = LOW_COMPLEXITY
# param.uiIntraPeriod*: cuint                     ## period of Intra frame
param.iNumRefFrame = AUTO_REF_PIC_COUNT
# param.eSpsPpsIdStrategy = CONSTANT_ID ## different stategy in adjust ID in SPS/PPS: 0- constant ID, 1-additional ID, 6-mapping and additional
param.bPrefixNalAddingCtrl = false ## false:not use Prefix NAL; true: use Prefix NAL
param.bEnableSSEI = true ## false:not use SSEI; true: use SSEI -- TODO: planning to remove the interface of SSEI
param.bSimulcastAVC = false ## (when encoding more than 1 spatial layer) false: use SVC syntax for higher layers; true: use Simulcast AVC
param.iPaddingFlag = 0 ## 0:disable padding;1:padding
param.iEntropyCodingModeFlag = 0 ## 0:CAVLC  1:CABAC.

param.bEnableFrameSkip = false                   ## False: don't skip frame even if VBV buffer overflow.True: allow skipping frames to keep the bitrate within limits

param.bEnableDenoise = true                      ## denoise control
param.bEnableBackgroundDetection = true         ## background detection control //VAA_BACKGROUND_DETECTION //BGD cmd
param.bEnableAdaptiveQuant = true               ## adaptive quantization control
param.bEnableFrameCroppingFlag = true           ## enable frame cropping flag: TRUE always in application
param.bEnableSceneChangeDetect = true
param.bIsLosslessLink = true                    ##  LTR advanced setting

var 
  sliceMode = SM_SINGLE_SLICE
  frameRate = 30.cfloat

# SM_SIZELIMITED_SLICE with multi-thread is still under testing
if sliceMode != SM_SINGLE_SLICE and sliceMode != SM_SIZELIMITED_SLICE:
    param.iMultipleThreadIdc = 2

for i in 0..<param.iSpatialLayerNum:
  param.sSpatialLayers[i].iVideoWidth = width.cint shr (param.iSpatialLayerNum - 1 - i)
  param.sSpatialLayers[i].iVideoHeight = height.cint shr (param.iSpatialLayerNum - 1 - i)
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


var fileStream = newFileStream("test_output/test.h264", fmWrite)

for num in 0..<total_num:
  # prepare input data
  rv = encoder.encodeFrame(pic, info)
  pic.uiTimeStamp += 30;
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