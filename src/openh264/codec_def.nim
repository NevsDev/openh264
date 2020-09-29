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
##  @file  codec_def.h
##
## *
##  Enumerate the type of video format
##


type
  EVideoFormatType* {.size: sizeof(cint).} = enum
    ## rgb color formats
    videoFormatRGB = 1,                                               
    videoFormatRGBA = 2, videoFormatRGB555 = 3, videoFormatRGB565 = 4,
    ## yuv color formats
    videoFormatBGR = 5, videoFormatBGRA = 6, videoFormatABGR = 7, videoFormatARGB = 8, videoFormatYUY2 = 20, 
    ## the same as IYUV
    videoFormatYVYU = 21, videoFormatUYVY = 22, videoFormatI420 = 23, 
    ## only used in SVC decoder testbed
    videoFormatYV12 = 24, videoFormatInternal = 25,                   
    ## new format for output by DXVA decoding
    videoFormatNV12 = 26,                                             
    videoFormatVFlip = 0x80000000


##  Enumerate  video frame type
type
  EVideoFrameType* {.size: sizeof(cint).} = enum
    videoFrameTypeInvalid,    ## encoder not ready or parameters are invalidate
    videoFrameTypeIDR,        ## IDR frame in H.264
    videoFrameTypeI,          ## I frame type
    videoFrameTypeP,          ## P frame type
    videoFrameTypeSkip,       ## skip the frame based encoder kernel
    videoFrameTypeIPMixed     ## a frame where I and P slices are mixing, not supported yet


##  Enumerate  return type
type
  CM_RETURN* {.size: sizeof(cint).} = enum
    cmResultSuccess,                    ## successful
    cmInitParaError,                    ## parameters are invalid
    cmUnknownReason, cmMallocMemeError, ## malloc a memory error
    cmInitExpected,                     ## initial action is expected
    cmUnsupportedData


##  Enumulate the nal unit type
type
  ENalUnitType* {.size: sizeof(cint).} = enum
    ## ref_idc != 0
    NAL_UNKNOWN = 0, NAL_SLICE = 1, NAL_SLICE_DPA = 2, NAL_SLICE_DPB = 3, NAL_SLICE_DPC = 4, NAL_SLICE_IDR = 5, 
    ## ref_idc == 0
    NAL_SEI = 6,                
    NAL_SPS = 7, NAL_PPS = 8


## NRI: eNalRefIdc
type
  ENalPriority* {.size: sizeof(cint).} = enum
    NAL_PRIORITY_DISPOSABLE = 0, 
    NAL_PRIORITY_LOW = 1, 
    NAL_PRIORITY_HIGH = 2,
    NAL_PRIORITY_HIGHEST = 3


template IS_PARAMETER_SET_NAL*(eNalRefIdc, eNalType: untyped): untyped =
  ((eNalRefIdc == NAL_PRIORITY_HIGHEST) and
      (eNalType == (NAL_SPS or NAL_PPS) or eNalType == NAL_SPS))

template IS_IDR_NAL*(eNalRefIdc, eNalType: untyped): untyped =
  ((eNalRefIdc == NAL_PRIORITY_HIGHEST) and (eNalType == NAL_SLICE_IDR))

const
  FRAME_NUM_PARAM_SET* = (-1)
  FRAME_NUM_IDR* = 0

##  eDeblockingIdc
const
  DEBLOCKING_IDC_0* = 0
  DEBLOCKING_IDC_1* = 1
  DEBLOCKING_IDC_2* = 2

  DEBLOCKING_OFFSET* = (6)
  DEBLOCKING_OFFSET_MINUS* = (-6)

type
  ERR_TOOL* = cushort           ##  Error Tools definition

const
  ET_NONE* = 0x00000000         ## NONE Error Tools
  ET_IP_SCALE* = 0x00000001     ## IP Scalable
  ET_FMO* = 0x00000002          ## Flexible Macroblock Ordering
  ET_IR_R1* = 0x00000004        ## Intra Refresh in predifined 2% MB
  ET_IR_R2* = 0x00000008        ## Intra Refresh in predifined 5% MB
  ET_IR_R3* = 0x00000010        ## Intra Refresh in predifined 10% MB
  ET_FEC_HALF* = 0x00000020     ## Forward Error Correction in 50% redundency mode
  ET_FEC_FULL* = 0x00000040     ## Forward Error Correction in 100% redundency mode
  ET_RFS* = 0x00000080

type
  SliceInfo* {.bycopy.} = object
    ## Information of coded Slice(=NAL)(s)
    pBufferOfSlices*: ptr cuchar  ## base buffer of coded slice(s)
    iCodedSliceCount*: cint       ## number of coded slices
    pLengthOfSlices*: ptr cuint   ## array of slices length accordingly by number of slice
    iFecType*: cint               ## FEC type[0, 50%FEC, 100%FEC]
    uiSliceIdx*: cuchar           ## index of slice in frame [FMO: 0,..,uiSliceCount-1; No FMO: 0]
    uiSliceCount*: cuchar         ## count number of slice in frame [FMO: 2-8; No FMO: 1]
    iFrameIndex*: char            ## index of frame[-1, .., idr_interval-1]
    uiNalRefIdc*: cuchar          ## NRI, priority level of slice(NAL)
    uiNalType*: cuchar            ## NAL type
    uiContainingFinalNal*: cuchar ## whether final NAL is involved in buffer of coded slices, flag used in Pause feature in T27

  PSliceInfo* = ptr SliceInfo

type
  SRateThresholds* {.bycopy.} = object
    ## thresholds of the initial, maximal and minimal rate
    iWidth*: cint                 ## frame width
    iHeight*: cint                ## frame height
    iThresholdOfInitRate*: cint   ## threshold of initial rate
    iThresholdOfMaxRate*: cint    ## threshold of maximal rate
    iThresholdOfMinRate*: cint    ## threshold of minimal rate
    iMinThresholdFrameRate*: cint ## min frame rate min
    iSkipFrameRate*: cint         ## skip to frame rate min
    iSkipFrameStep*: cint         ## how many frames to skip

  PRateThresholds* = ptr SRateThresholds

type
  SSysMEMBuffer* {.bycopy.} = object
    ##  Structure for decoder memery
    iWidth*: cint                 ## width of decoded pic for display
    iHeight*: cint                ## height of decoded pic for display
    iFormat*: EVideoFormatType    ## type is "EVideoFormatType"
    iStride*: array[2, cint]      ## stride of 2 component

  INNER_C_UNION_test_215* {.bycopy, union.} = object
    sSystemBuffer*: SSysMEMBuffer   ##  memory info for one picture

  SBufferInfo* {.bycopy.} = object
    ## Buffer info
    iBufferStatus*: cint                        ## 0: one frame data is not ready; 1: one frame data is ready
    uiInBsTimeStamp*: culonglong                ## input BS timestamp
    uiOutYuvTimeStamp*: culonglong              ## output YUV timestamp, when bufferstatus is 1
    UsrData*: INNER_C_UNION_test_215            ##  output buffer info
    pDst*: array[3, ptr UncheckedArray[uint8]]  ## point to picture YUV data


proc frameReady*(info: var SBufferInfo): bool {.inline.} =
  # frame data is ready
  result = info.iBufferStatus == 1

proc inTimestamp*(info: var SBufferInfo): uint64 {.inline.} =
  ## input BS timestamp
  result = info.uiInBsTimeStamp.uint64
proc `inTimestamp=`*(info: var SBufferInfo, time: uint64) {.inline.} =
  ## input BS timestamp
  info.uiInBsTimeStamp = time.culonglong

proc outTimestamp*(info: var SBufferInfo): uint64 {.inline.} =
  ## output YUV timestamp, when bufferstatus is ready
  result = info.uiOutYuvTimeStamp.uint64

proc iWidth*(info: var SBufferInfo): int {.inline.} = 
  ## width of decoded pic for display
  result = info.UsrData.sSystemBuffer.iWidth.int
proc iHeight*(info: var SBufferInfo): int {.inline.} = 
  ## height of decoded pic for display
  result = info.UsrData.sSystemBuffer.iHeight.int
  
proc iFormat*(info: var SBufferInfo): EVideoFormatType {.inline.} = 
  ## type is "EVideoFormatType"
  result = info.UsrData.sSystemBuffer.iFormat

proc iStride*(info: var SBufferInfo): array[3, cint] {.inline.} = 
  ## stride 
  result[0] = info.UsrData.sSystemBuffer.iStride[0]
  result[1] = info.UsrData.sSystemBuffer.iStride[1]
  result[2] = info.UsrData.sSystemBuffer.iStride[1]


var kiKeyNumMultiple*: array[6, uint8] = [1.uint8, 1, 2, 4, 8, 16] ##  In a GOP, multiple of the key frame number, derived from the number of layers(index or array below)
