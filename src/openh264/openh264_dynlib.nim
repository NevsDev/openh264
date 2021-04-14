import os, strutils, dynlib

const binPath = "openh264_bin/"

template getBinDir(): string =
  var currFileDir = splitFile(instantiationInfo(fullPaths = true).filename).dir
  joinPath(currFileDir, binPath)

const Is64Bit = sizeof(int) == 8
when defined(Linux):
  when defined(arm):
    when Is64Bit:
      const openh264* = "./libopenh264-2.1.1-linux-arm64.6.so"
    else:
      const openh264* = "./libopenh264-2.1.1-linux-arm.6.so"
  elif Is64Bit:
    const openh264* = "./libopenh264-2.1.1-linux64.6.so"
  else:
    const openh264* = "./libopenh264-2.1.1-linux32.6.so"
elif defined(Windows):
  when Is64Bit:
    const openh264* = "openh264-2.1.1-win64.dll"
  else:
    const openh264 = "openh264-2.1.1-win32.dll"
elif defined(MacOsX):
  when Is64Bit:
    const openh264* = "libopenh264-2.1.1-osx64.6.dylib"
  else:
    const openh264* = "libopenh264-2.1.1-osx32.6.dylib"
else:
  {.error: "This platform is not supported now.".} 



const dynLibPath = openh264

when not defined(noEmbedH264):
  const rawLibPath = joinPath(getBinDir(), openh264)
  when dirExists(rawLibPath):
    const rawLib = staticRead(rawLibPath) 
  else:
    const rawLib = staticRead(rawLibPath.replace("\\", "/")) # crosscompiling on unix/linux
  if not fileExists(dynLibPath):
    writeFile(dynLibPath, rawLib)

let openh264lib* = loadLib(dynLibPath)
