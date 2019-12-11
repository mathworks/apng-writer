# Animated PNG Writer

The MATLAB<sup>&reg;</sup> class `animatedPNGWriter` is for creating [animated PNG files](https://wiki.mozilla.org/APNG_Specification). Such files have similar applications as animated GIF files, but with typically higher quality and often smaller file sizes. Most web browsers support animated PNG files the same way they support animated GIF files.

The class `animatedPNGWriter` requires the utility program "APNG Assembler" from http://apngasm.sourceforge.net, which is available under separate license terms. When you use `animatedPNGWriter` the first time, it will attempt to automatically download this utility program if it does not already exist in the expected location.
