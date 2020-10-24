## Openh264

Bindings of openh264 codec to nim.
For more details see ./examples/.. or in ./src/.. .

#### High Level API

see examples

#### Build
Don't worry, you don't have to do anything here. Just compile regular your stuff.

For the curious though:
Module contains compiled dynlib binaries for Windows, Linux (+arm), MacOs and Android (+arm).
A dynlib is embedd during compilation time. On programstart it checks the current dir and try to find dynlib, 
if dynlib is not found it unpacks the embedded one.
