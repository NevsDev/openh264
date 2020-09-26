## !
##  \copy
##      Copyright (c)  2013, Cisco Systems
##      All rights reserved.
##
##      Redistribution and use in source and binary forms, with or without
##      modification, are permitted provided that the following conditions
##      are met:
##
##         * Redistributions of source code must retain the above copyright
##           notice, this list of conditions and the following disclaimer.
##
##         * Redistributions in binary form must reproduce the above copyright
##           notice, this list of conditions and the following disclaimer in
##           the documentation and/or other materials provided with the
##           distribution.
##
##      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
##      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
##      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
##      FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
##      COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
##      INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
##      BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
##      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
##      CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
##      LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
##      ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
##      POSSIBILITY OF SUCH DAMAGE.
##
##

## *
##  @file  codec_app_def.h
##  @brief Data and /or structures introduced in Cisco OpenH264 application
##

import codec_def

##  Constants

const
  MAX_TEMPORAL_LAYER_NUM* = 4
  MAX_SPATIAL_LAYER_NUM* = 4
  MAX_QUALITY_LAYER_NUM* = 4
  MAX_LAYER_NUM_OF_FRAME* = 128
  MAX_NAL_UNITS_IN_LAYER* = 128
  MAX_RTP_PAYLOAD_LEN* = 1000
  AVERAGE_RTP_PAYLOAD_LEN* = 800
  SAVED_NALUNIT_NUM_TMP* = (
    (MAX_SPATIAL_LAYER_NUM * MAX_QUALITY_LAYER_NUM) + 1 + MAX_SPATIAL_LAYER_NUM) ## SPS/PPS + SEI/SSEI + PADDING_NAL
  MAX_SLICES_NUM_TMP* = ((MAX_NAL_UNITS_IN_LAYER - SAVED_NALUNIT_NUM_TMP) div 3)
  AUTO_REF_PIC_COUNT* = -1
  UNSPECIFIED_BIT_RATE* = 0

## *
##  @brief Struct of OpenH264 version
##
## /
## / E.g. SDK version is 1.2.0.0, major version number is 1, minor version number is 2, and revision number is 0.

type
  OpenH264Version* {.bycopy.} = object
    uMajor*: cuint             ## The major version number
    uMinor*: cuint             ## The minor version number
    uRevision*: cuint          ## The revision number
    uReserved*: cuint          ## The reserved number, it should be 0.


## *
##  @brief Decoding status
##

type                          ## *
    ##  Errors derived from bitstream parsing
    ##
  DECODING_STATE* {.size: sizeof(cint).} = enum
    dsErrorFree = 0x00000000,           ## bit stream error-free
    dsFramePending = 0x00000001,        ## need more throughput to generate a frame output,
    dsRefLost = 0x00000002,             ## layer lost at reference frame with temporal id 0
    dsBitstreamError = 0x00000004,      ## error bitstreams(maybe broken internal frame) the decoder cared
    dsDepLayerLost = 0x00000008,        ## dependented layer is ever lost
    dsNoParamSets = 0x00000010,         ## no parameter set NALs involved
    dsDataErrorConcealed = 0x00000020,  ## current data error concealed specified
    dsRefListNullPtrs = 0x00000040,     ##ref picure list contains null ptrs within uiRefCount range
                                        ## *
                                        ##  Errors derived from logic level
                                        ##
    dsInvalidArgument = 0x00001000,     ## invalid argument specified
    dsInitialOptExpected = 0x00002000,  ## initializing operation is expected
    dsOutOfMemory = 0x00004000,         ## out of memory due to new request
                                        ## *
                                        ##  ANY OTHERS?
                                        ##
    dsDstBufNeedExpan = 0x00008000


## *
##  @brief Option types introduced in SVC encoder application
##
type
  ENCODER_OPTION* {.size: sizeof(cint).} = enum
    ENCODER_OPTION_DATAFORMAT = 0, ENCODER_OPTION_IDR_INTERVAL,   ## IDR period,0/-1 means no Intra period (only the first frame); lager than 0 means the desired IDR period, must be multiple of (2^temporal_layer)
    ENCODER_OPTION_SVC_ENCODE_PARAM_BASE,                         ## structure of Base Param
    ENCODER_OPTION_SVC_ENCODE_PARAM_EXT,                          ## structure of Extension Param
    ENCODER_OPTION_FRAME_RATE,                                    ## maximal input frame rate, current supported range: MAX_FRAME_RATE = 30,MIN_FRAME_RATE = 1
    ENCODER_OPTION_BITRATE, ENCODER_OPTION_MAX_BITRATE,
    ENCODER_OPTION_INTER_SPATIAL_PRED, ENCODER_OPTION_RC_MODE,
    ENCODER_OPTION_RC_FRAME_SKIP, ENCODER_PADDING_PADDING,        ## 0:disable padding;1:padding
    ENCODER_OPTION_PROFILE,                                       ## assgin the profile for each layer
    ENCODER_OPTION_LEVEL,                                         ## assgin the level for each layer
    ENCODER_OPTION_NUMBER_REF,                                    ## the number of refererence frame
    ENCODER_OPTION_DELIVERY_STATUS,                               ## the delivery info which is a feedback from app level
    ENCODER_LTR_RECOVERY_REQUEST, ENCODER_LTR_MARKING_FEEDBACK,
    ENCODER_LTR_MARKING_PERIOD, ENCODER_OPTION_LTR,               ## 0:disable LTR;larger than 0 enable LTR; LTR number is fixed to be 2 in current encoder
    ENCODER_OPTION_COMPLEXITY, ENCODER_OPTION_ENABLE_SSEI,        ## enable SSEI: true--enable ssei; false--disable ssei
    ENCODER_OPTION_ENABLE_PREFIX_NAL_ADDING,                      ## enable prefix: true--enable prefix; false--disable prefix
    ENCODER_OPTION_SPS_PPS_ID_STRATEGY,                           ## different stategy in adjust ID in SPS/PPS: 0- constant ID, 1-additional ID, 6-mapping and additional
    ENCODER_OPTION_CURRENT_PATH, ENCODER_OPTION_DUMP_FILE,        ## dump layer reconstruct frame to a specified file
    ENCODER_OPTION_TRACE_LEVEL,                                   ## trace info based on the trace level
    ENCODER_OPTION_TRACE_CALLBACK,                                ## a void (*)(void* context, int level, const char* message) function which receives log messages
    ENCODER_OPTION_TRACE_CALLBACK_CONTEXT,                        ## context info of trace callback
    ENCODER_OPTION_GET_STATISTICS,                                ## read only
    ENCODER_OPTION_STATISTICS_LOG_INTERVAL,                       ## log interval in millisecond
    ENCODER_OPTION_IS_LOSSLESS_LINK,                              ## advanced algorithmetic settings
    ENCODER_OPTION_BITS_VARY_PERCENTAGE                           ## bit vary percentage


## *
##  @brief Option types introduced in decoder application
##
type
  DECODER_OPTION* {.size: sizeof(cint).} = enum
    DECODER_OPTION_END_OF_STREAM = 1,                           ## end of stream flag
    DECODER_OPTION_VCL_NAL,                                     ## feedback whether or not have VCL NAL in current AU for application layer
    DECODER_OPTION_TEMPORAL_ID,                                 ## feedback temporal id for application layer
    DECODER_OPTION_FRAME_NUM,                                   ## feedback current decoded frame number
    DECODER_OPTION_IDR_PIC_ID,                                  ## feedback current frame belong to which IDR period
    DECODER_OPTION_LTR_MARKING_FLAG,                            ## feedback wether current frame mark a LTR
    DECODER_OPTION_LTR_MARKED_FRAME_NUM,                        ## feedback frame num marked by current Frame
    DECODER_OPTION_ERROR_CON_IDC,                               ## indicate decoder error concealment method
    DECODER_OPTION_TRACE_LEVEL, DECODER_OPTION_TRACE_CALLBACK,  ## a void (*)(void* context, int level, const char* message) function which receives log messages
    DECODER_OPTION_TRACE_CALLBACK_CONTEXT,                      ## context info of trace callbac
    DECODER_OPTION_GET_STATISTICS,                              ## feedback decoder statistics
    DECODER_OPTION_GET_SAR_INFO,                                ## feedback decoder Sample Aspect Ratio info in Vui
    DECODER_OPTION_PROFILE,                                     ## get current AU profile info, only is used in GetOption
    DECODER_OPTION_LEVEL,                                       ## get current AU level info,only is used in GetOption
    DECODER_OPTION_STATISTICS_LOG_INTERVAL,                     ## set log output interval
    DECODER_OPTION_IS_REF_PIC,                                  ## feedback current frame is ref pic or not
    DECODER_OPTION_NUM_OF_FRAMES_REMAINING_IN_BUFFER,           ## number of frames remaining in decoder buffer when pictures are required to re-ordered into display-order.
    DECODER_OPTION_NUM_OF_THREADS                               ## number of decoding threads. The maximum thread count is equal or less than lesser of (cpu core counts and 16).


## *
##  @brief Enumerate the type of error concealment methods
##
type
  ERROR_CON_IDC* {.size: sizeof(cint).} = enum
    ERROR_CON_DISABLE = 0, ERROR_CON_FRAME_COPY, ERROR_CON_SLICE_COPY,
    ERROR_CON_FRAME_COPY_CROSS_IDR, ERROR_CON_SLICE_COPY_CROSS_IDR,
    ERROR_CON_SLICE_COPY_CROSS_IDR_FREEZE_RES_CHANGE,
    ERROR_CON_SLICE_MV_COPY_CROSS_IDR,
    ERROR_CON_SLICE_MV_COPY_CROSS_IDR_FREEZE_RES_CHANGE


## *
##  @brief Feedback that whether or not have VCL NAL in current AU
##
type
  FEEDBACK_VCL_NAL_IN_AU* {.size: sizeof(cint).} = enum
    FEEDBACK_NON_VCL_NAL = 0, FEEDBACK_VCL_NAL, FEEDBACK_UNKNOWN_NAL


## *
##  @brief Type of layer being encoded
##
type
  LAYER_TYPE* {.size: sizeof(cint).} = enum
    NON_VIDEO_CODING_LAYER = 0, VIDEO_CODING_LAYER = 1


## *
##  @brief Spatial layer num
##
type
  LAYER_NUM* {.size: sizeof(cint).} = enum
    SPATIAL_LAYER_0 = 0, SPATIAL_LAYER_1 = 1, SPATIAL_LAYER_2 = 2, SPATIAL_LAYER_3 = 3,
    SPATIAL_LAYER_ALL = 4


## *
##  @brief Enumerate the type of video bitstream which is provided to decoder
##
type
  VIDEO_BITSTREAM_TYPE* {.size: sizeof(cint).} = enum
    VIDEO_BITSTREAM_AVC = 0, VIDEO_BITSTREAM_SVC = 1

const
  VIDEO_BITSTREAM_DEFAULT* = VIDEO_BITSTREAM_SVC

## *
##  @brief Enumerate the type of key frame request
##
type
  KEY_FRAME_REQUEST_TYPE* {.size: sizeof(cint).} = enum
    NO_RECOVERY_REQUSET = 0, LTR_RECOVERY_REQUEST = 1, IDR_RECOVERY_REQUEST = 2,
    NO_LTR_MARKING_FEEDBACK = 3, LTR_MARKING_SUCCESS = 4, LTR_MARKING_FAILED = 5


## *
##  @brief Structure for LTR recover request
##
type
  SLTRRecoverRequest* {.bycopy.} = object
    uiFeedbackType*: cuint     ## IDR request or LTR recovery request
    uiIDRPicId*: cuint         ## distinguish request from different IDR
    iLastCorrectFrameNum*: cint
    iCurrentFrameNum*: cint    ## specify current decoder frame_num.
    iLayerId*: cint            ## specify the layer for recovery request


## *
##  @brief Structure for LTR marking feedback
##
type
  SLTRMarkingFeedback* {.bycopy.} = object
    uiFeedbackType*: cuint     ## mark failed or successful
    uiIDRPicId*: cuint         ## distinguish request from different IDR
    iLTRFrameNum*: cint        ## specify current decoder frame_num
    iLayerId*: cint            ## specify the layer for LTR marking feedback


## *
##  @brief Structure for LTR configuration
##
type
  SLTRConfig* {.bycopy.} = object
    bEnableLongTermReference*: bool ## 1: on, 0: off
    iLTRRefNum*: cint               ## TODO: not supported to set it arbitrary yet


## *
##  @brief Enumerate the type of rate control mode
##
type
  RC_MODES* {.size: sizeof(cint).} = enum
    RC_OFF_MODE = -1,               ## rate control off mode
    RC_QUALITY_MODE = 0,            ## quality mode
    RC_BITRATE_MODE = 1,            ## bitrate mode
    RC_BUFFERBASED_MODE = 2,        ## no bitrate control,only using buffer status,adjust the video quality
    RC_TIMESTAMP_MODE = 3,          ## rate control based timestamp
    RC_BITRATE_MODE_POST_SKIP = 4   ## this is in-building RC MODE, WILL BE DELETED after algorithm tuning!


## *
##  @brief Enumerate the type of profile id
##
type
  EProfileIdc* {.size: sizeof(cint).} = enum
    PRO_UNKNOWN = 0, PRO_BASELINE = 66, PRO_MAIN = 77, PRO_SCALABLE_BASELINE = 83,
    PRO_SCALABLE_HIGH = 86, PRO_EXTENDED = 88, PRO_HIGH = 100, PRO_HIGH10 = 110,
    PRO_HIGH422 = 122, PRO_HIGH444 = 144, PRO_CAVLC444 = 244


## *
##  @brief Enumerate the type of level id
##
type
  ELevelIdc* {.size: sizeof(cint).} = enum
    LEVEL_UNKNOWN = 0, LEVEL_1_B = 9, LEVEL_1_0 = 10, LEVEL_1_1 = 11, LEVEL_1_2 = 12,
    LEVEL_1_3 = 13, LEVEL_2_0 = 20, LEVEL_2_1 = 21, LEVEL_2_2 = 22, LEVEL_3_0 = 30,
    LEVEL_3_1 = 31, LEVEL_3_2 = 32, LEVEL_4_0 = 40, LEVEL_4_1 = 41, LEVEL_4_2 = 42,
    LEVEL_5_0 = 50, LEVEL_5_1 = 51, LEVEL_5_2 = 52


## *
##  @brief Enumerate the type of wels log
##
const
  WELS_LOG_QUIET* = 0x00000000  ## quiet mode
  WELS_LOG_ERROR* = 1 shl 0       ## error log iLevel
  WELS_LOG_WARNING* = 1 shl 1     ## Warning log iLevel
  WELS_LOG_INFO* = 1 shl 2        ## information log iLevel
  WELS_LOG_DEBUG* = 1 shl 3       ## debug log, critical algo log
  WELS_LOG_DETAIL* = 1 shl 4      ## per packet/frame log
  WELS_LOG_RESV* = 1 shl 5        ## resversed log iLevel
  WELS_LOG_LEVEL_COUNT* = 6
  WELS_LOG_DEFAULT* = WELS_LOG_WARNING

## *
##  @brief Enumerate the type of slice mode
type
  SliceModeEnum* {.size: sizeof(cint).} = enum
    SM_SINGLE_SLICE = 0,        ## | SliceNum==1
    SM_FIXEDSLCNUM_SLICE = 1,   ## | according to SliceNum        | enabled dynamic slicing for multi-thread
    SM_RASTER_SLICE = 2,        ## | according to SlicesAssign    | need input of MB numbers each slice. In addition, if other constraint in SSliceArgument is presented, need to follow the constraints. Typically if MB num and slice size are both constrained, re-encoding may be involved.
    SM_SIZELIMITED_SLICE = 3,   ## | according to SliceSize       | slicing according to size, the slicing will be dynamic(have no idea about slice_nums until encoding current frame)
    SM_RESERVED = 4


##  @brief Structure for slice argument
type
  SSliceArgument* {.bycopy.} = object
    uiSliceMode*: SliceModeEnum                     ## by default, uiSliceMode will be SM_SINGLE_SLICE
    uiSliceNum*: cuint                              ## only used when uiSliceMode=1, when uiSliceNum=0 means auto design it with cpu core number
    uiSliceMbNum*: array[MAX_SLICES_NUM_TMP, cuint] ## only used when uiSliceMode=2; when =0 means setting one MB row a slice
    uiSliceSizeConstraint*: cuint                   ## now only used when uiSliceMode=4


##  @brief Enumerate the type of video format
type
  EVideoFormatSPS* {.size: sizeof(cint).} = enum
    VF_COMPONENT, VF_PAL, VF_NTSC, VF_SECAM, VF_MAC, VF_UNDEF, VF_NUM_ENUM


##  EVideoFormat is already defined/used elsewhere!
## *
##  @brief Enumerate the type of color primaries
##
type
  EColorPrimaries* {.size: sizeof(cint).} = enum
    CP_RESERVED0, CP_BT709, CP_UNDEF, CP_RESERVED3, CP_BT470M, CP_BT470BG,
    CP_SMPTE170M, CP_SMPTE240M, CP_FILM, CP_BT2020, CP_NUM_ENUM


## *
##  @brief Enumerate the type of transfer characteristics
##
type
  ETransferCharacteristics* {.size: sizeof(cint).} = enum
    TRC_RESERVED0, TRC_BT709, TRC_UNDEF, TRC_RESERVED3, TRC_BT470M, TRC_BT470BG,
    TRC_SMPTE170M, TRC_SMPTE240M, TRC_LINEAR, TRC_LOG100, TRC_LOG316,
    TRC_IEC61966_2_4, TRC_BT1361E, TRC_IEC61966_2_1, TRC_BT2020_10, TRC_BT2020_12,
    TRC_NUM_ENUM


## *
##  @brief Enumerate the type of color matrix
##
type
  EColorMatrix* {.size: sizeof(cint).} = enum
    CM_GBR, CM_BT709, CM_UNDEF, CM_RESERVED3, CM_FCC, CM_BT470BG, CM_SMPTE170M,
    CM_SMPTE240M, CM_YCGCO, CM_BT2020NC, CM_BT2020C, CM_NUM_ENUM


## *
##  @brief Enumerate the type of sample aspect ratio
##
type
  ESampleAspectRatio* {.size: sizeof(cint).} = enum
    ASP_UNSPECIFIED = 0, ASP_1x1 = 1, ASP_12x11 = 2, ASP_10x11 = 3, ASP_16x11 = 4,
    ASP_40x33 = 5, ASP_24x11 = 6, ASP_20x11 = 7, ASP_32x11 = 8, ASP_80x33 = 9, ASP_18x11 = 10,
    ASP_15x11 = 11, ASP_64x33 = 12, ASP_160x99 = 13, ASP_EXT_SAR = 255


## *
##  @brief  Structure for spatial layer configuration
##
type
  SSpatialLayerConfig* {.bycopy.} = object
    iVideoWidth*: cint                  ## width of picture in luminance samples of a layer
    iVideoHeight*: cint                 ## height of picture in luminance samples of a layer
    fFrameRate*: cfloat                 ## frame rate specified for a layer
    iSpatialBitrate*: cint              ## target bitrate for a spatial layer, in unit of bps
    iMaxSpatialBitrate*: cint           ## maximum  bitrate for a spatial layer, in unit of bps
    uiProfileIdc*: EProfileIdc          ## value of profile IDC (PRO_UNKNOWN for auto-detection)
    uiLevelIdc*: ELevelIdc              ## value of profile IDC (0 for auto-detection)
    iDLayerQp*: cint                    ## value of level IDC (0 for auto-detection)
    sSliceArgument*: SSliceArgument     ##  Note: members bVideoSignalTypePresent through uiColorMatrix below are also defined in SWelsSPS in parameter_sets.h.
    bVideoSignalTypePresent*: bool      ##  false => do not write any of the following information to the header
    uiVideoFormat*: cuchar              ##  EVideoFormatSPS; 3 bits in header; 0-5 => component, kpal, ntsc, secam, mac, undef
    bFullRange*: bool                   ##  false => analog video data range [16, 235]; true => full data range [0,255]
    bColorDescriptionPresent*: bool     ##  false => do not write any of the following three items to the header
    uiColorPrimaries*: cuchar           ##  EColorPrimaries; 8 bits in header; 0 - 9 => ???, bt709, undef, ???, bt470m, bt470bg,
                                        ##  smpte170m, smpte240m, film, bt2020
    uiTransferCharacteristics*: cuchar  ##  ETransferCharacteristics; 8 bits in header; 0 - 15 => ???, bt709, undef, ???, bt470m, bt470bg, smpte170m,
                                        ##  smpte240m, linear, log100, log316, iec61966-2-4, bt1361e, iec61966-2-1, bt2020-10, bt2020-12
    uiColorMatrix*: cuchar              ##  EColorMatrix; 8 bits in header (corresponds to FFmpeg "colorspace"); 0 - 10 => GBR, bt709,
                                        ##    undef, ???, fcc, bt470bg, smpte170m, smpte240m, YCgCo, bt2020nc, bt2020c
    bAspectRatioPresent*: bool          ## aspect ratio present in VUI
    eAspectRatio*: ESampleAspectRatio   ## aspect ratio idc
    sAspectRatioExtWidth*: cushort      ## use if aspect ratio idc == 255
    sAspectRatioExtHeight*: cushort     ## use if aspect ratio idc == 255


##  @brief Encoder usage type
type
  EUsageType* {.size: sizeof(cint).} = enum
    CAMERA_VIDEO_REAL_TIME,   ## camera video for real-time communication
    SCREEN_CONTENT_REAL_TIME, ## screen content signal
    CAMERA_VIDEO_NON_REAL_TIME, SCREEN_CONTENT_NON_REAL_TIME,
    INPUT_CONTENT_TYPE_ALL


##  @brief Enumulate the complexity mode
type
  ECOMPLEXITY_MODE* {.size: sizeof(cint).} = enum
    LOW_COMPLEXITY = 0,         ## the lowest compleixty,the fastest speed,
    MEDIUM_COMPLEXITY,        ## medium complexity, medium speed,medium quality
    HIGH_COMPLEXITY           ## high complexity, lowest speed, high quality


##  @brief Enumulate for the stategy of SPS/PPS strategy
type
  EParameterSetStrategy* {.size: sizeof(cint).} = enum
    CONSTANT_ID = 0,            ## constant id in SPS/PPS
    INCREASING_ID = 0x00000001, ## SPS/PPS id increases at each IDR
    SPS_LISTING = 0x00000002,   ## using SPS in the existing list if possible
    SPS_LISTING_AND_PPS_INCREASING = 0x00000003, SPS_PPS_LISTING = 0x00000006


##  TODO:  Refine the parameters definition.
## *
##  @brief SVC Encoding Parameters
type
  SEncParamBase* {.bycopy.} = object
    iUsageType*: EUsageType    ## application type; please refer to the definition of EUsageType
    iPicWidth*: cint           ## width of picture in luminance samples (the maximum of all layers if multiple spatial layers presents)
    iPicHeight*: cint          ## height of picture in luminance samples((the maximum of all layers if multiple spatial layers presents)
    iTargetBitrate*: cint      ## target bitrate desired, in unit of bps
    iRCMode*: RC_MODES         ## rate control mode
    fMaxFrameRate*: cfloat     ## maximal input frame rate

  PEncParamBase* = ptr SEncParamBase



##  @brief SVC Encoding Parameters extention
type
  SEncParamExt* {.bycopy.} = object
    iUsageType*: EUsageType                   ## same as in TagEncParamBase
    iPicWidth*: cint                          ## same as in TagEncParamBase
    iPicHeight*: cint                         ## same as in TagEncParamBase
    iTargetBitrate*: cint                     ## same as in TagEncParamBase
    iRCMode*: RC_MODES                        ## same as in TagEncParamBase
    fMaxFrameRate*: cfloat                    ## same as in TagEncParamBase
    iTemporalLayerNum*: cint                  ## temporal layer number, max temporal layer = 4
    iSpatialLayerNum*: cint                   ## spatial layer number,1<= iSpatialLayerNum <= MAX_SPATIAL_LAYER_NUM, MAX_SPATIAL_LAYER_NUM = 4
    sSpatialLayers*: array[MAX_SPATIAL_LAYER_NUM, SSpatialLayerConfig]
    iComplexityMode*: ECOMPLEXITY_MODE
    uiIntraPeriod*: cuint                     ## period of Intra frame
    iNumRefFrame*: cint                       ## number of reference frame used
    eSpsPpsIdStrategy*: EParameterSetStrategy ## different stategy in adjust ID in SPS/PPS: 0- constant ID, 1-additional ID, 6-mapping and additional
    bPrefixNalAddingCtrl*: bool               ## false:not use Prefix NAL; true: use Prefix NAL
    bEnableSSEI*: bool                        ## false:not use SSEI; true: use SSEI -- TODO: planning to remove the interface of SSEI
    bSimulcastAVC*: bool                      ## (when encoding more than 1 spatial layer) false: use SVC syntax for higher layers; true: use Simulcast AVC
    iPaddingFlag*: cint                       ## 0:disable padding;1:padding
    iEntropyCodingModeFlag*: cint             ## 0:CAVLC  1:CABAC.
                                              ##  rc control
    bEnableFrameSkip*: bool                   ## False: don't skip frame even if VBV buffer overflow.True: allow skipping frames to keep the bitrate within limits
    iMaxBitrate*: cint                        ## the maximum bitrate, in unit of bps, set it to UNSPECIFIED_BIT_RATE if not needed
    iMaxQp*: cint                             ## the maximum QP encoder supports
    iMinQp*: cint                             ## the minmum QP encoder supports
    uiMaxNalSize*: cuint                      ## the maximum NAL size.  This value should be not 0 for dynamic slice mode
                                              ## LTR settings
    bEnableLongTermReference*: bool           ## 1: on, 0: off
    iLTRRefNum*: cint                         ## the number of LTR(long term reference),TODO: not supported to set it arbitrary yet
    iLtrMarkPeriod*: cuint                    ## the LTR marked period that is used in feedback.
                                              ##  multi-thread settings
    iMultipleThreadIdc*: cushort              ## 1 # 0: auto(dynamic imp. internal encoder); 1: multiple threads imp. disabled; lager than 1: count number of threads;
    bUseLoadBalancing*: bool                  ## only used when uiSliceMode=1 or 3, will change slicing of a picture during the run-time of multi-thread encoding, so the result of each run may be different
                                              ##  Deblocking loop filter
    iLoopFilterDisableIdc*: cint              ## 0: on, 1: off, 2: on except for slice boundaries
    iLoopFilterAlphaC0Offset*: cint           ## AlphaOffset: valid range [-6, 6], default 0
    iLoopFilterBetaOffset*: cint              ## BetaOffset: valid range [-6, 6], default 0
                                              ## pre-processing feature
    bEnableDenoise*: bool                     ## denoise control
    bEnableBackgroundDetection*: bool         ## background detection control //VAA_BACKGROUND_DETECTION //BGD cmd
    bEnableAdaptiveQuant*: bool               ## adaptive quantization control
    bEnableFrameCroppingFlag*: bool           ## enable frame cropping flag: TRUE always in application
    bEnableSceneChangeDetect*: bool
    bIsLosslessLink*: bool                    ##  LTR advanced setting


##  @brief Define a new struct to show the property of video bitstream.
type
  SVideoProperty* {.bycopy.} = object
    size*: cuint               ## size of the struct
    eVideoBsType*: VIDEO_BITSTREAM_TYPE ## video stream type (AVC/SVC)


##  @brief SVC Decoding Parameters, reserved here and potential applicable in the future
type
  SDecodingParam* {.bycopy.} = object
    pFileNameRestructed*: cstring   ## file name of reconstructed frame used for PSNR calculation based debug
    uiCpuLoad*: cuint               ## CPU load
    uiTargetDqLayer*: cuchar        ## setting target dq layer id
    eEcActiveIdc*: ERROR_CON_IDC    ## whether active error concealment feature in decoder
    bParseOnly*: bool               ## decoder for parse only, no reconstruction. When it is true, SPS/PPS size should not exceed SPS_PPS_BS_SIZE (128). Otherwise, it will return error info
    sVideoProperty*: SVideoProperty ## video stream property

  PDecodingParam* = ptr SDecodingParam

## *
##  @brief Bitstream inforamtion of a layer being encoded
##
type
  SLayerBSInfo* {.bycopy.} = object
    uiTemporalId*: cuchar
    uiSpatialId*: cuchar
    uiQualityId*: cuchar
    eFrameType*: EVideoFrameType
    uiLayerType*: cuchar
                                                ##  The sub sequence layers are ordered hierarchically based on their dependency on each other so that any picture in a layer shall not be
                                                ##  predicted from any picture on any higher layer.
                                                ##
    iSubSeqId*: cint                            ## refer to D.2.11 Sub-sequence information SEI message semantics
    iNalCount*: cint                            ## count number of NAL coded already
    pNalLengthInByte*: ptr UncheckedArray[cint] ## length of NAL size in byte from 0 to iNalCount-1
    pBsBuf*: pointer                            ## buffer of bitstream contained

  PLayerBSInfo* = ptr SLayerBSInfo

##  @brief Frame bit stream info
type
  SFrameBSInfo* {.bycopy.} = object
    iLayerNum*: cint
    sLayerInfo*: array[MAX_LAYER_NUM_OF_FRAME, SLayerBSInfo]
    eFrameType*: EVideoFrameType
    iFrameSizeInBytes*: cint
    uiTimeStamp*: clonglong

  PFrameBSInfo* = ptr SFrameBSInfo

##   @brief Structure for source picture
type
  SSourcePicture* {.bycopy.} = object
    iColorFormat*: EVideoFormatType   ## color space type
    iStride*: array[4, cint]          ## stride for each plane pData
    pData*: array[4, pointer]         ## plane pData
    iPicWidth*: cint                  ## luma picture width in x coordinate
    iPicHeight*: cint                 ## luma picture height in y coordinate
    uiTimeStamp*: clonglong           ## timestamp of the source picture, unit: millisecond


##  @brief Structure for bit rate info
type
  SBitrateInfo* {.bycopy.} = object
    iLayer*: LAYER_NUM
    iBitrate*: cint            ## the maximum bitrate


##  @brief Structure for dump layer info
type
  SDumpLayer* {.bycopy.} = object
    iLayer*: cint
    pFileName*: cstring


##  @brief Structure for profile info in layer
type
  SProfileInfo* {.bycopy.} = object
    iLayer*: cint
    uiProfileIdc*: EProfileIdc ## the profile info


##  @brief  Structure for level info in layer
type
  SLevelInfo* {.bycopy.} = object
    iLayer*: cint
    uiLevelIdc*: ELevelIdc     ## the level info


##  @brief Structure for dilivery status
type
  SDeliveryStatus* {.bycopy.} = object
    bDeliveryFlag*: bool       ## 0: the previous frame isn't delivered,1: the previous frame is delivered
    iDropFrameType*: cint      ## the frame type that is dropped; reserved
    iDropFrameSize*: cint      ## the frame size that is dropped; reserved


##  @brief The capability of decoder, for SDP negotiation
type
  SDecoderCapability* {.bycopy.} = object
    iProfileIdc*: cint         ## profile_idc
    iProfileIop*: cint         ## profile-iop
    iLevelIdc*: cint           ## level_idc
    iMaxMbps*: cint            ## max-mbps
    iMaxFs*: cint              ## max-fs
    iMaxCpb*: cint             ## max-cpb
    iMaxDpb*: cint             ## max-dpb
    iMaxBr*: cint              ## max-br
    bRedPicCap*: bool          ## redundant-pic-cap


##  @brief Structure for parse only output
type
  SParserBsInfo* {.bycopy.} = object
    iNalNum*: cint                ## total NAL number in current AU
    pNalLenInByte*: ptr cint      ## each nal length
    pDstBuff*: ptr cuchar         ## outputted dst buffer for parsed bitstream
    iSpsWidthInPixel*: cint       ## required SPS width info
    iSpsHeightInPixel*: cint      ## required SPS height info
    uiInBsTimeStamp*: culonglong  ## input BS timestamp
    uiOutBsTimeStamp*: culonglong ## output BS timestamp

  PParserBsInfo* = ptr SParserBsInfo

##  @brief Structure for encoder statistics
type
  SEncoderStatistics* {.bycopy.} = object
    uiWidth*: cuint                   ## the width of encoded frame
    uiHeight*: cuint                  ## the height of encoded frame
                                      ## following standard, will be 16x aligned, if there are multiple spatial, this is of the highest
    fAverageFrameSpeedInMs*: cfloat   ## average_Encoding_Time
                                      ##  rate control related
    fAverageFrameRate*: cfloat        ## the average frame rate in, calculate since encoding starts, supposed that the input timestamp is in unit of ms
    fLatestFrameRate*: cfloat         ## the frame rate in, in the last second, supposed that the input timestamp is in unit of ms (? useful for checking BR, but is it easy to calculate?
    uiBitRate*: cuint                 ## sendrate in Bits per second, calculated within the set time-window
    uiAverageFrameQP*: cuint          ## the average QP of last encoded frame
    uiInputFrameCount*: cuint         ## number of frames
    uiSkippedFrameCount*: cuint       ## number of frames
    uiResolutionChangeTimes*: cuint   ## uiResolutionChangeTimes
    uiIDRReqNum*: cuint               ## number of IDR requests
    uiIDRSentNum*: cuint              ## number of actual IDRs sent
    uiLTRSentNum*: cuint              ## number of LTR sent/marked
    iStatisticsTs*: clonglong         ## Timestamp of updating the statistics
    iTotalEncodedBytes*: culong
    iLastStatisticsBytes*: culong
    iLastStatisticsFrameCount*: culong


##  @brief  Structure for decoder statistics
type
  SDecoderStatistics* {.bycopy.} = object
    uiWidth*: cuint                       ## the width of encode/decode frame
    uiHeight*: cuint                      ## the height of encode/decode frame
    fAverageFrameSpeedInMs*: cfloat       ## average_Decoding_Time
    fActualAverageFrameSpeedInMs*: cfloat ## actual average_Decoding_Time, including freezing pictures
    uiDecodedFrameCount*: cuint           ## number of frames
    uiResolutionChangeTimes*: cuint       ## uiResolutionChangeTimes
    uiIDRCorrectNum*: cuint               ## number of correct IDR received
                                          ## EC on related
    uiAvgEcRatio*: cuint                  ## when EC is on, the average ratio of total EC areas, can be an indicator of reconstruction quality
    uiAvgEcPropRatio*: cuint              ## when EC is on, the rough average ratio of propogate EC areas, can be an indicator of reconstruction quality
    uiEcIDRNum*: cuint                    ## number of actual unintegrity IDR or not received but eced
    uiEcFrameNum*: cuint                  ##
    uiIDRLostNum*: cuint                  ## number of whole lost IDR
    uiFreezingIDRNum*: cuint              ## number of freezing IDR with error (partly received), under resolution change
    uiFreezingNonIDRNum*: cuint           ## number of freezing non-IDR with error
    iAvgLumaQp*: cint                     ## average luma QP. default: -1, no correct frame outputted
    iSpsReportErrorNum*: cint             ## number of Sps Invalid report
    iSubSpsReportErrorNum*: cint          ## number of SubSps Invalid report
    iPpsReportErrorNum*: cint             ## number of Pps Invalid report
    iSpsNoExistNalNum*: cint              ## number of Sps NoExist Nal
    iSubSpsNoExistNalNum*: cint           ## number of SubSps NoExist Nal
    iPpsNoExistNalNum*: cint              ## number of Pps NoExist Nal
    uiProfile*: cuint                     ## Profile idc in syntax
    uiLevel*: cuint                       ## level idc according to Annex A-1
    iCurrentActiveSpsId*: cint            ## current active SPS id
    iCurrentActivePpsId*: cint            ## current active PPS id
    iStatisticsLogInterval*: cuint        ## frame interval of statistics log


##  in building, coming soon
## *
##  @brief Structure for sample aspect ratio (SAR) info in VUI
type
  SVuiSarInfo* {.bycopy.} = object
    uiSarWidth*: cuint              ## SAR width
    uiSarHeight*: cuint             ## SAR height
    bOverscanAppropriateFlag*: bool ## SAR overscan flag

  PVuiSarInfo* = ptr SVuiSarInfo
