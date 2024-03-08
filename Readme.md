# SHORE Swig bindings
This repository provides bindings to use the SHORE real-time library for face
detection and analysis from programming languages other than C and C++.
The bindings are generated via [SWIG](https://swig.org/). SWIG interface files
and CMake files are provided - compilation of the bindings, however, requires
the proprietary [SHORE SDK](https://iis.fraunhofer.de/shore).

## [Perl](perl/Readme.md)
* Status: alpha
* Tested on Linux
* Supports dynamic libraries only

## [Java](java/Readme.md)
* Status: alpha
* Tested on Linux
* Supports dynamic libraries only

## [Android](android/Readme.md)
* Status: alpha
* Tested on Linux
* Supports Aarch64, Armv7 and x86_64 EABIs 

## Build Instructions
We provide a Dockerfile for creating a container that includes all required
build tools:
```
cd docker
docker build --build-arg ANDROID_NDK=<PATH_TO_NDK.zip> -t shore_swig:1.0  .
```

Please refer to the individual Readme files for detailed information on the
build process.

## Disclaimer
All resources offered here should enable our customers to integrate the SHORE
library for real-time face detection and analysis into their own environments 
more quickly. However, we assume no liability for this voluntary offer. Please
understand that we also do not provide any additional support for the bindings.

## Troubleshooting

Please contact facedetection@iis.fraunhofer.de if you experience any issues.

## Contributions

Please note that we only accept pull requests that are licensed under the MIT
License.
