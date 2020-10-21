import turbojpeg, streams
import codec_def, codec_app_def, codec_api

## Example of encoding single image to h264
template doWhile(cond, body) =
  body
  while cond:
    body

var 
  g_enc {.threadvar.}: ptr ISVCEncoder
  g_param {.threadvar.}: SEncParamExt
  g_pic {.threadvar.}: SSourcePicture
  g_info {.threadvar.}: SFrameBSInfo
  g_i420_buffer {.threadvar.}: ptr UncheckedArray[uint8]
  g_width {.threadvar.}: int
  g_height {.threadvar.}: int
  g_timePerFrame {.threadvar.}: clonglong


proc g_encoder(): ptr ISVCEncoder =
  if g_enc == nil:
    discard WelsCreateSVCEncoder(g_enc)
  return g_enc

proc h264EncoderInit*(width, height: int, fps: float) {.gcsafe.} =
  g_encoder().getDefaultParams(g_param)
  
  g_param.iUsageType = CAMERA_VIDEO_REAL_TIME
  g_param.iPicWidth = width.cint
  g_param.iPicHeight = height.cint
  # g_param.iTargetBitrate = 540000
  g_param.iRCMode = RC_OFF_MODE
  g_param.fMaxFrameRate = fps
  g_param.iTemporalLayerNum = 3 ## temporal layer number, max temporal layer = 4
  g_param.iSpatialLayerNum = 1 ## spatial layer number,1<= iSpatialLayerNum <= MAX_SPATIAL_LAYER_NUM, MAX_SPATIAL_LAYER_NUM = 4
  g_param.iComplexityMode = LOW_COMPLEXITY
  # g_param.uiIntraPeriod*: cuint ## period of Intra frame
  g_param.iNumRefFrame = AUTO_REF_PIC_COUNT
  # g_param.eSpsPpsIdStrategy = CONSTANT_ID ## different stategy in adjust ID in SPS/PPS: 0- constant ID, 1-additional ID, 6-mapping and additional
  g_param.bPrefixNalAddingCtrl = false ## false:not use Prefix NAL; true: use Prefix NAL
  g_param.bEnableSSEI = true ## false:not use SSEI; true: use SSEI -- TODO: planning to remove the interface of SSEI
  g_param.bSimulcastAVC = false ## (when encoding more than 1 spatial layer) false: use SVC syntax for higher layers; true: use Simulcast AVC
  g_param.iPaddingFlag = 0 ## 0:disable padding;1:padding
  g_param.iEntropyCodingModeFlag = 0 ## 0:CAVLC  1:CABAC.
  g_param.bEnableFrameSkip = false                   ## False: don't skip frame even if VBV buffer overflow.True: allow skipping frames to keep the bitrate within limits

  g_param.bEnableDenoise = true                      ## denoise control
  g_param.bEnableBackgroundDetection = true         ## background detection control //VAA_BACKGROUND_DETECTION //BGD cmd
  g_param.bEnableAdaptiveQuant = true               ## adaptive quantization control
  g_param.bEnableFrameCroppingFlag = true           ## enable frame cropping flag: TRUE always in application
  g_param.bEnableSceneChangeDetect = true
  g_param.bIsLosslessLink = true                    ##  LTR advanced setting
  
  var 
    sliceMode = SM_SINGLE_SLICE
    frameRate = fps.cfloat

  # SM_SIZELIMITED_SLICE with multi-thread is still under testing
  if sliceMode != SM_SINGLE_SLICE and sliceMode != SM_SIZELIMITED_SLICE:
      g_param.iMultipleThreadIdc = 2

  for i in 0..<g_param.iSpatialLayerNum:
    g_param.sSpatialLayers[i].iVideoWidth = width.cint shr (g_param.iSpatialLayerNum - 1 - i)
    g_param.sSpatialLayers[i].iVideoHeight = height.cint shr (g_param.iSpatialLayerNum - 1 - i)
    g_param.sSpatialLayers[i].fFrameRate = frameRate
    g_param.sSpatialLayers[i].iSpatialBitrate = g_param.iTargetBitrate

    g_param.sSpatialLayers[i].sSliceArgument.uiSliceMode = sliceMode
    if sliceMode == SM_SIZELIMITED_SLICE:
        g_param.sSpatialLayers[i].sSliceArgument.uiSliceSizeConstraint = 600
        g_param.uiMaxNalSize = 1500

  g_param.iTargetBitrate *= g_param.iSpatialLayerNum;
  discard g_enc.initializeExt(g_param)


  # init pic for encoding
  g_i420_buffer = cast[ptr UncheckedArray[uint8]](realloc(g_i420_buffer, 3 * width * height))
  g_width = width
  g_height = height
  g_timePerFrame = (1000.0 / fps).clonglong

  g_pic.uiTimeStamp = 0
  g_pic.iColorFormat = EVideoFormatType.videoFormatI420
  g_pic.iPicWidth = width.cint
  g_pic.iPicHeight = height.cint

  g_pic.iStride[0] = width.cint            
  g_pic.iStride[1] = width.cint div 2
  g_pic.iStride[2] = width.cint div 2
  g_pic.iStride[3] = 0
  g_pic.pData[3] = nil


proc h264Encodei420*(i420_data: ptr UncheckedArray[uint8], i420_size: int, stream: Stream): bool {.gcsafe.} =
  g_pic.pData[0] = i420_data[0].addr
  g_pic.pData[1] = i420_data[i420_size * 2 div 3].addr
  g_pic.pData[2] = i420_data[i420_size * 10 div 12].addr

  if g_encoder().encodeFrame(g_pic, g_info) and g_info.eFrameType != videoFrameTypeSkip: 
    for iLayer in 0..<g_info.iLayerNum:
      var
        pLayerBsInfo = g_info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      stream.writeData(pLayerBsInfo.pBsBuf, iLayerSize)
    g_pic.uiTimeStamp += g_timePerFrame
    return true
  else:
    return false


proc h264EncodeRGB*(rgb_data: pointer, stream: Stream): bool {.gcsafe.} =
  var i420_size: uint

  if not turbojpeg.rgb2yuv(rgb_data, g_width, g_height, g_i420_buffer, i420_size, TJSAMP_420, FAST_FLAGS):
    return false

  g_pic.pData[0] = g_i420_buffer[0].addr
  g_pic.pData[1] = g_i420_buffer[i420_size * 2 div 3].addr
  g_pic.pData[2] = g_i420_buffer[i420_size * 10 div 12].addr

  if g_encoder().encodeFrame(g_pic, g_info) and g_info.eFrameType != videoFrameTypeSkip: 
    for iLayer in 0..<g_info.iLayerNum:
      var
        pLayerBsInfo = g_info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      stream.writeData(pLayerBsInfo.pBsBuf, iLayerSize)
    g_pic.uiTimeStamp += g_timePerFrame
    return true
  else:
    return false

proc h264EncodeJpeg*(jpeg_data: pointer, jpeg_size: uint, stream: Stream): bool {.gcsafe.} =
  var 
    i420_size: uint
    success = turbojpeg.jpeg2i420(jpeg_data, jpeg_size, g_i420_buffer, i420_size, g_width, g_height, FAST_FLAGS)
  if not success:
    return false

  g_pic.pData[0] = g_i420_buffer[0].addr
  g_pic.pData[1] = g_i420_buffer[i420_size * 2 div 3].addr
  g_pic.pData[2] = g_i420_buffer[i420_size * 10 div 12].addr

  if g_encoder().encodeFrame(g_pic, g_info) and g_info.eFrameType != videoFrameTypeSkip: 
    for iLayer in 0..<g_info.iLayerNum:
      var
        pLayerBsInfo = g_info.sLayerInfo[iLayer].addr
        iLayerSize = 0
        iNalIdx = pLayerBsInfo.iNalCount - 1
      
      doWhile iNalIdx >= 0:
        iLayerSize += pLayerBsInfo.pNalLengthInByte[iNalIdx]
        iNalIdx -= 1

      stream.writeData(pLayerBsInfo.pBsBuf, iLayerSize)
    g_pic.uiTimeStamp += g_timePerFrame
    return true
  else:
    return false

# proc deinitEncoder*() =
#   if g_enc != nil:
#     discard g_enc.uninitialize()
#     WelsDestroySVCEncoder(g_enc)
#     g_enc = nil