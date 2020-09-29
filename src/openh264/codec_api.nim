## !
## @page License
##
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

import dynlib, openh264_dynlib

import codec_app_def, codec_def

# when defined(_WIN32) or defined(__cdecl):
#   const EXTAPI* = __cdecl
# else:
const EXTAPI* = true

## *
##  @file codec_api.h
##
## *
##  @page Overview
##    * This page is for openh264 codec API usage.
##    * For how to use the encoder,please refer to page UsageExampleForEncoder
##    * For how to use the decoder,please refer to page UsageExampleForDecoder
##    * For more detail about ISVEncoder,please refer to page ISVCEncoder
##    * For more detail about ISVDecoder,please refer to page ISVCDecoder
##
## *
##  @page DecoderUsageExample
##
##  @brief
##    * An example for using the decoder for Decoding only or Parsing only
##
##  Step 1:decoder declaration
##  @code
##
##   //decoder declaration
##   ISVCDecoder *pSvcDecoder;
##   //input: encoded bitstream start position; should include start code prefix
##   unsigned char *pBuf =...;
##   //input: encoded bit stream length; should include the size of start code prefix
##   int iSize =...;
##   //output: [0~2] for Y,U,V buffer for Decoding only
##   unsigned char *pData[3] =...;
##   //in-out: for Decoding only: declare and initialize the output buffer info, this should never co-exist with Parsing only
##   SBufferInfo sDstBufInfo;
##   memset(&sDstBufInfo, 0, sizeof(SBufferInfo));
##   //in-out: for Parsing only: declare and initialize the output bitstream buffer info for parse only, this should never co-exist with Decoding only
##   SParserBsInfo sDstParseInfo;
##   memset(&sDstParseInfo, 0, sizeof(SParserBsInfo));
##   sDstParseInfo.pDstBuff = new unsigned char[PARSE_SIZE]; //In Parsing only, allocate enough buffer to save transcoded bitstream for a frame
##
##  @endcode
##
##  Step 2:decoder creation
##  @code
##   WelsCreateDecoder(&pSvcDecoder);
##  @endcode
##
##  Step 3:declare required parameter, used to differentiate Decoding only and Parsing only
##  @code
##   SDecodingParam sDecParam = {0};
##   sDecParam.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_AVC;
##   //for Parsing only, the assignment is mandatory
##   sDecParam.bParseOnly = true;
##  @endcode
##
##  Step 4:initialize the parameter and decoder context, allocate memory
##  @code
##   pSvcDecoder->Initialize(&sDecParam);
##  @endcode
##
##  Step 5:do actual decoding process in slice level;
##         this can be done in a loop until data ends
##  @code
##   //for Decoding only
##   iRet = pSvcDecoder->DecodeFrameNoDelay(pBuf, iSize, pData, &sDstBufInfo);
##   //or
##   iRet = pSvcDecoder->DecodeFrame2(pBuf, iSize, pData, &sDstBufInfo);
##   //for Parsing only
##   iRet = pSvcDecoder->DecodeParser(pBuf, iSize, &sDstParseInfo);
##   //decode failed
##   If (iRet != 0){
##       //error handling (RequestIDR or something like that)
##   }
##   //for Decoding only, pData can be used for render.
##   if (sDstBufInfo.iBufferStatus==1){
##       //output handling (pData[0], pData[1], pData[2])
##   }
##  //for Parsing only, sDstParseInfo can be used for, e.g., HW decoding
##   if (sDstBufInfo.iNalNum > 0){
##       //Hardware decoding sDstParseInfo;
##   }
##   //no-delay decoding can be realized by directly calling DecodeFrameNoDelay(), which is the recommended usage.
##   //no-delay decoding can also be realized by directly calling DecodeFrame2() again with NULL input, as in the following. In this case, decoder would immediately reconstruct the input data. This can also be used similarly for Parsing only. Consequent decoding error and output indication should also be considered as above.
##   iRet = pSvcDecoder->DecodeFrame2(NULL, 0, pData, &sDstBufInfo);
##   //judge iRet, sDstBufInfo.iBufferStatus ...
##  @endcode
##
##  Step 6:uninitialize the decoder and memory free
##  @code
##   pSvcDecoder->Uninitialize();
##  @endcode
##
##  Step 7:destroy the decoder
##  @code
##   DestroyDecoder(pSvcDecoder);
##  @endcode
##
##
## *
##  @page EncoderUsageExample1
##
##  @brief
##   * An example for using encoder with basic parameter
##
##  Step1:setup encoder
##  @code
##   ISVCEncoder*  encoder_;
##   int rv = WelsCreateSVCEncoder (&encoder_);
##   assert (rv == 0);
##   assert (encoder_ != NULL);
##  @endcode
##
##  Step2:initilize with basic parameter
##  @code
##   SEncParamBase param;
##   memset (&param, 0, sizeof (SEncParamBase));
##   param.iUsageType = usageType; //from EUsageType enum
##   param.fMaxFrameRate = frameRate;
##   param.iPicWidth = width;
##   param.iPicHeight = height;
##   param.iTargetBitrate = 5000000;
##   encoder_->Initialize (&param);
##  @endcode
##
##  Step3:set option, set option during encoding process
##  @code
##   encoder_->SetOption (ENCODER_OPTION_TRACE_LEVEL, &g_LevelSetting);
##   int videoFormat = videoFormatI420;
##   encoder_->SetOption (ENCODER_OPTION_DATAFORMAT, &videoFormat);
##  @endcode
##
##  Step4: encode and  store ouput bistream
##  @code
##   int frameSize = width * height * 3 / 2;
##   BufferedData buf;
##   buf.SetLength (frameSize);
##   assert (buf.Length() == (size_t)frameSize);
##   SFrameBSInfo info;
##   memset (&info, 0, sizeof (SFrameBSInfo));
##   SSourcePicture pic;
##   memset (&pic, 0, sizeof (SsourcePicture));
##   pic.iPicWidth = width;
##   pic.iPicHeight = height;
##   pic.iColorFormat = videoFormatI420;
##   pic.iStride[0] = pic.iPicWidth;
##   pic.iStride[1] = pic.iStride[2] = pic.iPicWidth >> 1;
##   pic.pData[0] = buf.data();
##   pic.pData[1] = pic.pData[0] + width * height;
##   pic.pData[2] = pic.pData[1] + (width * height >> 2);
##   for(int num = 0;num<total_num;num++) {
##      //prepare input data
##      rv = encoder_->EncodeFrame (&pic, &info);
##      assert (rv == cmResultSuccess);
##      if (info.eFrameType != videoFrameTypeSkip) {
##       //output bitstream handling
##      }
##   }
##  @endcode
##
##  Step5:teardown encoder
##  @code
##   if (encoder_) {
##       encoder_->Uninitialize();
##       WelsDestroySVCEncoder (encoder_);
##   }
##  @endcode
##
##
## *
##  @page EncoderUsageExample2
##
##  @brief
##      * An example for using the encoder with extension parameter.
##      * The same operation on Step 1,3,4,5 with Example-1
##
##  Step 2:initialize with extension parameter
##  @code
##   SEncParamExt param;
##   encoder_->GetDefaultParams (&param);
##   param.iUsageType = usageType;
##   param.fMaxFrameRate = frameRate;
##   param.iPicWidth = width;
##   param.iPicHeight = height;
##   param.iTargetBitrate = 5000000;
##   param.bEnableDenoise = denoise;
##   param.iSpatialLayerNum = layers;
##   //SM_DYN_SLICE don't support multi-thread now
##   if (sliceMode != SM_SINGLE_SLICE && sliceMode != SM_DYN_SLICE)
##       param.iMultipleThreadIdc = 2;
##
##   for (int i = 0; i < param.iSpatialLayerNum; i++) {
##       param.sSpatialLayers[i].iVideoWidth = width >> (param.iSpatialLayerNum - 1 - i);
##       param.sSpatialLayers[i].iVideoHeight = height >> (param.iSpatialLayerNum - 1 - i);
##       param.sSpatialLayers[i].fFrameRate = frameRate;
##       param.sSpatialLayers[i].iSpatialBitrate = param.iTargetBitrate;
##
##       param.sSpatialLayers[i].sSliceCfg.uiSliceMode = sliceMode;
##       if (sliceMode == SM_DYN_SLICE) {
##           param.sSpatialLayers[i].sSliceCfg.sSliceArgument.uiSliceSizeConstraint = 600;
##           param.uiMaxNalSize = 1500;
##       }
##   }
##   param.iTargetBitrate *= param.iSpatialLayerNum;
##   encoder_->InitializeExt (&param);
##   int videoFormat = videoFormatI420;
##   encoder_->SetOption (ENCODER_OPTION_DATAFORMAT, &videoFormat);
##
##  @endcode
##
type
  ISVCEncoder* = ptr ISVCEncoderVtbl
  ISVCEncoderVtbl {.bycopy.} = object
    Initialize: proc (a1: ptr ISVCEncoder; pParam: ptr SEncParamBase): cint {.cdecl.}
    InitializeExt: proc (a1: ptr ISVCEncoder; pParam: ptr SEncParamExt): cint {.cdecl.}
    GetDefaultParams: proc (a1: ptr ISVCEncoder; pParam: ptr SEncParamExt): cint {.cdecl.}
    Uninitialize: proc (a1: ptr ISVCEncoder): cint {.cdecl.}
    EncodeFrame: proc (a1: ptr ISVCEncoder; kpSrcPic: ptr SSourcePicture; pBsInfo: ptr SFrameBSInfo): cint {.cdecl.}
    EncodeParameterSets: proc (a1: ptr ISVCEncoder; pBsInfo: ptr SFrameBSInfo): cint {.cdecl.}
    ForceIntraFrame: proc (a1: ptr ISVCEncoder; bIDR: bool): cint {.cdecl.}
    SetOption: proc (a1: ptr ISVCEncoder; eOptionId: ENCODER_OPTION; pOption: pointer): cint {.cdecl.}
    GetOption: proc (a1: ptr ISVCEncoder; eOptionId: ENCODER_OPTION; pOption: pointer): cint {.cdecl.}

  ISVCDecoder* = ptr ISVCDecoderVtbl
  ISVCDecoderVtbl {.bycopy.} = object
    Initialize: proc (a1: ptr ISVCDecoder; pParam: ptr SDecodingParam): clong {.cdecl.}
    Uninitialize: proc (a1: ptr ISVCDecoder): clong {.cdecl.}
    DecodeFrame: proc (a1: ptr ISVCDecoder; pSrc: ptr UncheckedArray[uint8]; iSrcLen: cint; ppDst: array[3, ptr UncheckedArray[uint8]]; pStride: ptr cint; iWidth: ptr cint; iHeight: ptr cint): DECODING_STATE {.cdecl.}
    DecodeFrameNoDelay: proc (a1: ptr ISVCDecoder; pSrc: pointer; iSrcLen: cint; ppDst: array[3, ptr UncheckedArray[uint8]]; pDstInfo: ptr SBufferInfo): DECODING_STATE {.cdecl.} 
    DecodeFrame2: proc (a1: ptr ISVCDecoder; pSrc: pointer; iSrcLen: cint; ppDst: array[3, ptr UncheckedArray[uint8]]; pDstInfo: ptr SBufferInfo): DECODING_STATE {.cdecl.}
    FlushFrame: proc (a1: ptr ISVCDecoder; ppDst: array[3, ptr UncheckedArray[uint8]]; pDstInfo: ptr SBufferInfo): DECODING_STATE {.cdecl.}
    DecodeParser: proc (a1: ptr ISVCDecoder; pSrc: ptr UncheckedArray[uint8]; iSrcLen: cint; pDstInfo: ptr SParserBsInfo): DECODING_STATE {.cdecl.}
    DecodeFrameEx: proc (a1: ptr ISVCDecoder; pSrc: pointer; iSrcLen: cint; pDst: ptr UncheckedArray[uint8]; iDstStride: cint; iDstLen: ptr cint; iWidth: ptr cint; iHeight: ptr cint; iColorFormat: ptr EVideoFormatType): DECODING_STATE {.cdecl.}
    SetOption: proc (a1: ptr ISVCDecoder; eOptionId: DECODER_OPTION; pOption: pointer): clong {.cdecl.}
    GetOption: proc (a1: ptr ISVCDecoder; eOptionId: DECODER_OPTION; pOption: pointer): clong {.cdecl.}



proc initialize*(a1: ptr ISVCEncoder; pParam: var SEncParamBase): int {.inline, discardable.} = 
  a1.Initialize(a1, pParam.addr).int
proc initializeExt*(a1: ptr ISVCEncoder; pParam: var SEncParamExt): int {.inline, discardable.} = 
  a1.InitializeExt(a1, pParam.addr).int
proc getDefaultParams*(a1: ptr ISVCEncoder; pParam: var SEncParamExt): int {.inline.} = 
  a1.GetDefaultParams(a1, pParam.addr).int
proc uninitialize*(a1: ptr ISVCEncoder): int {.inline.} = 
  a1.Uninitialize(a1).int
proc encodeFrame*(a1: ptr ISVCEncoder, kpSrcPic: var SSourcePicture, pBsInfo: var SFrameBSInfo): bool {.inline.} = 
  result = a1.EncodeFrame(a1, kpSrcPic.addr, pBsInfo.addr) == 0
proc encodeParameterSets*(a1: ptr ISVCEncoder, pBsInfo: var SFrameBSInfo): int {.inline.} = 
  a1.EncodeParameterSets(a1, pBsInfo.addr).int
proc forceIntraFrame*(a1: ptr ISVCEncoder, bIDR: bool): int {.inline.} = 
  a1.ForceIntraFrame(a1, bIDR).int
proc setOption*(a1: ptr ISVCEncoder, eOptionId: ENCODER_OPTION, pOption: pointer): int {.inline.} = 
  a1.SetOption(a1, eOptionId, pOption).int
proc getOption*(a1: ptr ISVCEncoder, eOptionId: ENCODER_OPTION, pOption: pointer): int {.inline.} = 
  a1.GetOption(a1, eOptionId, pOption).int


proc initialize*(a1: ptr ISVCDecoder; pParam: var SDecodingParam): int {.inline.} = 
  a1.Initialize(a1, pParam.addr).int
proc uninitialize*(a1: ptr ISVCDecoder): int {.inline, discardable.} = 
  a1.Uninitialize(a1).int
proc decodeFrame*(a1: ptr ISVCDecoder; pSrc: ptr UncheckedArray[uint8], iSrcLen: int; ppDst: array[3, ptr UncheckedArray[uint8]], pStride, iWidth, iHeight: var int): DECODING_STATE {.inline.} = 
  var pstr, width, height: cint
  result = a1.DecodeFrame(a1, pSrc, iSrcLen.cint, ppDst, pstr.addr, width.addr, height.addr)
  pStride = pstr.int
  iWidth = width.int
  iHeight = height.int
proc decodeFrameNoDelay*(a1: ptr ISVCDecoder; pSrc: pointer; iSrcLen: int; ppDst: array[3, ptr UncheckedArray[uint8]]; pDstInfo: var SBufferInfo): DECODING_STATE {.inline.} =
  result = a1.DecodeFrameNoDelay(a1, pSrc, iSrcLen.cint, ppDst, pDstInfo.addr)
proc decodeFrame2*(a1: ptr ISVCDecoder; pSrc: ptr UncheckedArray[uint8] | ptr char; iSrcLen: int; ppDst: array[3, ptr UncheckedArray[uint8]]; pDstInfo: var SBufferInfo): DECODING_STATE {.inline.} = 
  result = a1.DecodeFrame2(a1, pSrc, iSrcLen.cint, ppDst, pDstInfo.addr)
proc flushFrame*(a1: ptr ISVCDecoder; ppDst: array[3, ptr UncheckedArray[uint8]]; pDstInfo: var SBufferInfo): DECODING_STATE {.inline.} = 
  result = a1.FlushFrame(a1, ppDst, pDstInfo.addr)
proc decodeParser*(a1: ptr ISVCDecoder; pSrc: ptr UncheckedArray[uint8]; iSrcLen: int; pDstInfo: var SParserBsInfo): DECODING_STATE {.inline.} = 
  result = a1.DecodeParser(a1, pSrc, iSrcLen.cint, pDstInfo.addr)
proc decodeFrameEx*(a1: ptr ISVCDecoder; pSrc: pointer, iSrcLen: int; pDst: ptr UncheckedArray[uint8]; iDstStride: int, iDstLen, iWidth, iHeight: var int, iColorFormat: var EVideoFormatType): DECODING_STATE {.inline.} = 
  var len, width, height: cint
  result = a1.DecodeFrameEx(a1, pSrc, iSrcLen.cint, pDst, iDstStride.cint, len.addr, width.addr, height.addr, iColorFormat.addr)
  iDstLen = len.int
  iWidth = width.int
  iHeight = height.int
proc setOption*(a1: ptr ISVCDecoder, eOptionId: DECODER_OPTION, pOption: pointer): int {.inline.} = 
  result = a1.SetOption(a1, eOptionId, pOption).int
proc getOption*(a1: ptr ISVCDecoder; eOptionId: DECODER_OPTION; pOption: pointer): int {.inline.} = 
  result = a1.GetOption(a1, eOptionId, pOption).int


#################################################################################################################################################
type
  WelsTraceCallback* = proc (ctx: pointer; level: cint; string: cstring) {.cdecl, stdcall.}

type CreateSVCEncoder = proc(ppEncoder: ptr ptr ISVCEncoder): cint {.gcsafe, stdcall.}
let welsCreateSVCEncoder = cast[CreateSVCEncoder](openh264lib.symAddr("WelsCreateSVCEncoder"))
proc WelsCreateSVCEncoder*(ppEncoder: var ptr ISVCEncoder): bool {.inline, discardable.} = 
  result = welsCreateSVCEncoder(ppEncoder.addr) == 0

type destroySVCEncoder = proc(pEncoder: ptr ISVCEncoder) {.gcsafe, stdcall.}
let welsDestroySVCEncoder = cast[destroySVCEncoder](openh264lib.symAddr("WelsDestroySVCEncoder"))
proc WelsDestroySVCEncoder*(pEncoder: ptr ISVCEncoder) {.inline.} = 
  welsDestroySVCEncoder(pEncoder)

type getDecoderCapability = proc(pDecCapability: ptr SDecoderCapability): cint {.gcsafe, stdcall.}
let welsGetDecoderCapability = cast[getDecoderCapability](openh264lib.symAddr("WelsGetDecoderCapability"))
proc WelsGetDecoderCapability*(pDecCapability: ptr SDecoderCapability): bool {.inline, discardable.} =
  result = welsGetDecoderCapability(pDecCapability) == 0

type createDecoder = proc(ppDecoder: ptr ptr ISVCDecoder): clong {.gcsafe, stdcall.}
let welsCreateDecoder = cast[createDecoder](openh264lib.symAddr("WelsCreateDecoder")) 
proc WelsCreateDecoder*(ppDecoder: var ptr ISVCDecoder): bool {.inline, discardable.} =
  result = welsCreateDecoder(ppDecoder.addr) == 0

type destroyDecoder = proc(pDecoder: ptr ISVCDecoder) {.gcsafe, stdcall.}
let welsDestroyDecoder = cast[destroyDecoder](openh264lib.symAddr("WelsDestroyDecoder")) 
proc WelsDestroyDecoder*(pDecoder: ptr ISVCDecoder) {.inline.} =
  welsDestroyDecoder(pDecoder)


type getCodecVersion = proc(): OpenH264Version {.gcsafe, stdcall.}
let welsGetCodecVersion = cast[getCodecVersion](openh264lib.symAddr("WelsGetCodecVersion")) 
proc WelsGetCodecVersion*(): OpenH264Version {.inline.} =
  # return  The linked codec version
  welsGetCodecVersion()

type getCodecVersionEx = proc(pVersion: ptr OpenH264Version) {.gcsafe, stdcall.}
let welsGetCodecVersionEx = cast[getCodecVersionEx](openh264lib.symAddr("WelsGetCodecVersionEx")) 
  # proc(pVersion: ptr OpenH264Version)
proc WelsGetCodecVersionEx*(pVersion: var OpenH264Version) {.inline.} =
  welsGetCodecVersionEx(pVersion.addr)