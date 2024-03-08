# Shore on Android
Creates an Android Archive (AAR) in order to use the SHORE library on
Android devices.

## Prerequisites
The Android build was tested on Ubuntu 22.04 and a suitable Dockerfile is
provided. In order to build the Docker image, a copy of the
[Android NDK](https://developer.android.com/ndk/downloads) must be provided
to the build script.

For non-Docker builds, the following packages/applications are required:
* A C++ Compiler and Linker  (e.g. via `build-essentials`)
* A Java SDK (e.g. the [OpenJDK Development Kit](https://openjdk.java.net/))
* The [Android NDK](https://developer.android.com/ndk/downloads)
* [Git](https://git-scm.com/)
* [CMake](https://cmake.org/)
* [Swig](https://swig.org)
* zip/unzip

## Build Instructions
1. Please note that the build systems requires the Java bindings and 
expects the ```java/``` folder to be located next to the `android/` folder:
```
swig
  ├── android/
  ├── java/
```

2. Create the correct directory structure and extract the SHORE SDKs
(multiples are possible) to the respective folders.
 ```
 ShoreSDK/
  ├── arm64-v8a
  │   ├── Copyright
  │   ├── Doc
  │   ├── Lib
  │   └── Model
  └── armeabi-v7a
      ├── Copyright
      ├── Doc
      ├── Lib
      └── Model

```
Be sure to name the individual directories according to the
[EABI](https://developer.android.com/ndk/guides/abis) they are targeting.

3. Configure the project
```bash
mkdir build && cd build
cmake .. -DNDK_BUILD=/path/to/the/android/ndk/ndk-build \
         -DSHORE_SDK_PATH=`pwd`/../ShoreSDK/ \
         -DSHORE_VERSION=200 \
         -DAPP_PLATFORM=android-23
```
Except for the `NDK_BUILD` variable, all other values are optional.

4. Build and install
```bash
make -j INSTALL
```

## Project Integration
Once built, the `ShoreAndroid.aar` file needs to be imported into your Android
project:

**In Android Studio**

 * Navigate to `File -> New -> New Module -> Import .JAR/.AAR Package`
 * Then select the `ShoreAndroid.aar` file.

**Or manually**
 * Create folder `app/src/main/libs` in the root directory of your project.
 * Copy provided `ShoreAndroid.aar` to `app/src/main/libs` directory.

Add newly created modules to the dependencies in your app/build.gradle
```groovy
dependencies {
    ...
    implementation(name:"ShoreAndroid",ext:"aar")
}
```
Add following packaging options:
```groovy
    android.packagingOptions{
        pickFirst 'lib/**/libc++_shared.so'
    }
```

## Usage
Please refer to the [Readme for the Java bindings](../java/Readme.md) for
a brief usage description.

## Shore Model Integration
In order to make the usage as simple as possible, all models contained in the
SHORE SDK are included in the `*.so` files created for the respective target ABI.
This also includes the `ShapeLocator` model which makes the resulting `*.aar`
file quite large if multiple target ABIs are defined. Consider removing unneeded
ABIs to reduce the output file size of the `*.aar` file or remove the
embedding of the model entirely and ship the `CTM` file together with your
application.


## Limitations and Known Issues
The Android bindings enable Android developers to use the SHORE library for 
real-time face detection and analysis in their applications. The bindings are, 
however, not a care free package and come with some limitations:

* The only supported EABIs are `armeabi-v7`, `arm64-v8a` and `x64_86`
* The limitations from the Java bindings also apply to the Android bindings

