# Package

version       = "0.4.2"
author        = "Sven Keller"
description   = "Openh264 codec bindings (compiletime autolink/no dependencies). Simple h264 codec highlevel api."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"
requires "https://github.com/svekel/turbojpeg >= 0.8.3"


task cross_compile_windows, "cross compilation":
  # Ubuntu: apt install mingw-w64
  # Use --cpu:i386 or --cpu:amd64 to switch the CPU architecture.
  
  exec "nim c -d:mingw examples/high_level_api_encoder.nim"
