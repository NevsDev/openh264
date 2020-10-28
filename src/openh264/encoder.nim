import turbojpeg, streams
import codec_def, codec_app_def, codec_api

template doWhile(cond, body) =
  body
  while cond:
    body

type 
  H264Encoder* = ref H264EncoderObj
  H264EncoderObj* = object
    enc: ptr ISVCEncoder
    param: SEncParamExt
    pic: SSourcePicture
    info: SFrameBSInfo
    i420_buffer: ptr UncheckedArray[uint8]
    width: int
    height: int
    timePerFrame: clonglong

proc cleanUp(e: H264Encoder) =
  if e.enc == nil:
    discard e.enc.uninitialize()
    WelsDestroySVCEncoder(e.enc)
    e.enc = nil
  if e.i420_buffer != nil:
    e.i420_buffer.dealloc()

proc reset(e: H264Encoder) =
  if e.enc != nil:
    discard e.enc.uninitialize()
    WelsDestroySVCEncoder(e.enc)
    e.enc = nil

proc h264Encoder*(): H264Encoder =
  result.new(cleanUp)

proc init*(h264enc: H264Encoder, width, height: int, fps: float) {.gcsafe.} =
  h264enc.reset()
  WelsCreateSVCEncoder(h264enc.enc)

  h264enc.enc.getDefaultParams(h264enc.param)
  
  h264enc.param.iUsageType = CAMERA_VIDEO_REAL_TIME
  h264enc.param.iPicWidth = width.cint
  h264enc.param.iPicHeight = height.cint
  # h264enc.param.iTargetBitrate = 540000
  h264enc.param.iRCMode = RC_OFF_MODE
  h264enc.param.fMaxFrameRate = fps
  h264enc.param.iTemporalLayerNum = 3 ## temporal layer number, max temporal layer = 4
  h264enc.param.iSpatialLayerNum = 1 ## spatial layer number,1<= iSpatialLayerNum <= MAX_SPATIAL_LAYER_NUM, MAX_SPATIAL_LAYER_NUM = 4
  h264enc.param.iComplexityMode = LOW_COMPLEXITY
  # h264enc.param.uiIntraPeriod*: cuint ## period of Intra frame
  h264enc.param.iNumRefFrame = AUTO_REF_PIC_COUNT
  # h264enc.param.eSpsPpsIdStrategy = CONSTANT_ID ## different stategy in adjust ID in SPS/PPS: 0- constant ID, 1-additional ID, 6-mapping and additional
  h264enc.param.bPrefixNalAddingCtrl = false ## false:not use Prefix NAL; true: use Prefix NAL
  h264enc.param.bEnableSSEI = true ## false:not use SSEI; true: use SSEI -- TODO: planning to remove the interface of SSEI
  h264enc.param.bSimulcastAVC = false ## (when encoding more than 1 spatial layer) false: use SVC syntax for higher layers; true: use Simulcast AVC
  h264enc.param.iPaddingFlag = 0 ## 0:disable padding;1:padding
  h264enc.param.iEntropyCodingModeFlag = 0 ## 0:CAVLC  1:CABAC.
  h264enc.param.bEnableFrameSkip = false                   ## False: don't skip frame even if VBV buffer overflow.True: allow skipping frames to keep the bitrate within limits

  h264enc.param.bEnableDenoise = true                      ## denoise control
  h264enc.param.bEnableBackgroundDetection = true         ## background detection control //VAA_BACKGROUND_DETECTION //BGD cmd
  h264enc.param.bEnableAdaptiveQuant = true               ## adaptive quantization control
  h264enc.param.bEnableFrameCroppingFlag = true           ## enable frame cropping flag: TRUE always in application
  h264enc.param.bEnableSceneChangeDetect = true
  h264enc.param.bIsLosslessLink = true                    ##  LTR advanced setting
  
  var 
    sliceMode = SM_SINGLE_SLICE
    frameRate = fps.cfloat

  # SM_SIZELIMITED_SLICE with multi-thread is still under testing
  if sliceMode != SM_SINGLE_SLICE and sliceMode != SM_SIZELIMITED_SLICE:
      h264enc.param.iMultipleThreadIdc = 2

  for i in 0..<h264enc.param.iSpatialLayerNum:
    h264enc.param.sSpatialLayers[i].iVideoWidth = width.cint shr (h264enc.param.iSpatialLayerNum - 1 - i)
    h264enc.param.sSpatialLayers[i].iVideoHeight = height.cint shr (h264enc.param.iSpatialLayerNum - 1 - i)
    h264enc.param.sSpatialLayers[i].fFrameRate = frameRate
    h264enc.param.sSpatialLayers[i].iSpatialBitrate = h264enc.param.iTargetBitrate

    h264enc.param.sSpatialLayers[i].sSliceArgument.uiSliceMode = sliceMode
    if sliceMode == SM_SIZELIMITED_SLICE:
        h264enc.param.sSpatialLayers[i].sSliceArgument.uiSliceSizeConstraint = 600
        h264enc.param.uiMaxNalSize = 1500

  h264enc.param.iTargetBitrate *= h264enc.param.iSpatialLayerNum;
  discard h264enc.enc.initializeExt(h264enc.param)

  # init pic for encoding
  h264enc.i420_buffer = cast[ptr UncheckedArray[uint8]](realloc(h264enc.i420_buffer, 3 * width * height))
  h264enc.width = width
  h264enc.height = height
  h264enc.timePerFrame = (1000.0 / fps).clonglong

  h264enc.pic.uiTimeStamp = 0
  h264enc.pic.iColorFormat = EVideoFormatType.videoFormatI420
  h264enc.pic.iPicWidth = width.cint
  h264enc.pic.iPicHeight = height.cint

  h264enc.pic.iStride[0] = width.cint            
  h264enc.pic.iStride[1] = width.cint div 2
  h264enc.pic.iStride[2] = width.cint div 2
  h264enc.pic.iStride[3] = 0
  h264enc.pic.pData[3] = nil


proc encodei420*(h264enc: H264Encoder, i420_data: ptr UncheckedArray[uint8], i420_size: int, stream: Stream): bool {.gcsafe.} =
  h264enc.pic.pData[0] = i420_data[0].addr
  h264enc.pic.pData[1] = i420_data[i420_size * 2 div 3].addr
  h264enc.pic.pData[2] = i420_data[i420_size * 10 div 12].addr

  if h264enc.enc.encodeFrame(h264enc.pic, h264enc.info) and h264enc.info.eFrameType != videoFrameTypeSkip: 
    for iLayer in 0..<h264enc.info.iLayerNum:
      var
        pLayerBsInfo = h264enc.info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      stream.writeData(pLayerBsInfo.pBsBuf, iLayerSize)
    return true
  else:
    return false


proc encodeRGB*(h264enc: H264Encoder, rgb_data: pointer, stream: Stream): bool {.gcsafe.} =
  var i420_size: uint

  if not turbojpeg.rgb2yuv(rgb_data, h264enc.width, h264enc.height, h264enc.i420_buffer, i420_size, TJSAMP_420, FAST_FLAGS):
    return false

  h264enc.pic.pData[0] = h264enc.i420_buffer[0].addr
  h264enc.pic.pData[1] = h264enc.i420_buffer[i420_size * 2 div 3].addr
  h264enc.pic.pData[2] = h264enc.i420_buffer[i420_size * 10 div 12].addr

  if h264enc.enc.encodeFrame(h264enc.pic, h264enc.info) and h264enc.info.eFrameType != videoFrameTypeSkip: 
    for iLayer in 0..<h264enc.info.iLayerNum:
      var
        pLayerBsInfo = h264enc.info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      stream.writeData(pLayerBsInfo.pBsBuf, iLayerSize)
    h264enc.pic.uiTimeStamp += h264enc.timePerFrame
    return true
  else:
    return false

proc encodeJpeg*(h264enc: H264Encoder, jpeg_data: pointer, jpeg_size: uint, stream: Stream): bool {.gcsafe.} =
  var 
    i420_size: uint
    success = turbojpeg.jpeg2i420(jpeg_data, jpeg_size, h264enc.i420_buffer, i420_size, h264enc.width, h264enc.height, FAST_FLAGS)
  if not success:
    return false

  h264enc.pic.pData[0] = h264enc.i420_buffer[0].addr
  h264enc.pic.pData[1] = h264enc.i420_buffer[i420_size * 2 div 3].addr
  h264enc.pic.pData[2] = h264enc.i420_buffer[i420_size * 10 div 12].addr

  if h264enc.enc.encodeFrame(h264enc.pic, h264enc.info) and h264enc.info.eFrameType != videoFrameTypeSkip: 
    for iLayer in 0..<h264enc.info.iLayerNum:
      var
        pLayerBsInfo = h264enc.info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      stream.writeData(pLayerBsInfo.pBsBuf, iLayerSize)
    h264enc.pic.uiTimeStamp += h264enc.timePerFrame
    return true
  else:
    return false
