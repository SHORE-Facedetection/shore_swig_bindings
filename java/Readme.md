# Shore for Java
Creates a Java Archive (JAR) and a shared library to use the Shore library from
Java.

## Prerequisites
The Java build was tested on Ubuntu 22.04 and a suitable Dockerfile is
provided.

For non-Docker builds, the following packages/applications are required:
* A C++ Compiler and Linker  (e.g. via `build-essentials`)
* A Java SDK (e.g. the [OpenJDK Development Kit](https://openjdk.java.net/))
* [Git](https://git-scm.com/)
* [CMake](https://cmake.org/)
* [Swig](https://swig.org)
* zip/unzip

## Build and Run Instructions
Make sure that a Java SDK is installed and that the path to the respective
binaries (`java`, `javac`) is included in your systems's `PATH` environment
variable.
Extract the SHORE SDK to `ShoreSDK` or point the CMake variable `SHORE_SDK_PATH`
to a valid SHORE SDK folder.

```bash
mkdir build && cd build
cmake ..
make -j && make install
# Run the command line demo
cd ../INSTALL
java -Djava.library.path=. -jar ShoreCmdline.jar sample.png

```

## Usage
In general, the Java bindings offer an API similar to the C++ API. The main
differences are explained in the following.

### Naming
To avoid confusion with `java.lang.Object`, SHORE's object class is mapped to
a `ShoreObject` class. For the sake of consistency, all other classes are
renamed the same way:

| C++ class          | Java class        |
| ----------         | ----------        |
| `Shore::Engine`    | `ShoreEngine`     |
| `Shore::Object`    | `ShoreObject`     |
| `Shore::Region`    | `ShoreRegion`     |
| `Shore::Marker`    | `ShoreMarker`     |
| `Shore::Content`   | `ShoreContent`    |

### Data Types
 Where applicable, Java specific equivalents for C++ data types are used (e.g. a
 `nullptr` return value in C++ maps to `null` in Java).

The parameters for all Java methods generally match their C++ counterparts, but
there are some things to keep in mind:
* Zero terminated C-style strings passed to/returned from methods as
  `char const*` are expected/returned as `java.lang.String` objects.
* The non-zero terminated image data buffer passed to the `Process()` method
  is expected to be a `ByteBuffer` object allocated via
  `ByteBuffer.allocateDirect()`. Using a `byte[]` array instead of a ByteBuffer
  object is possible by adjusting the respective typemap in the [Shore.i
  interface file](Shore.i#L16).
* `float const*` values returned by the `GetRating*()` methods are returned as
  `java.lang.Float` objects.
* The `Shore.SetMessageCall()` method expects an instance of an
  `IMessageCallback` object.

### Methods
The class documentation can be built by enabling the `BUILD_JAVADOC` CMake
variable. As stated in the limitations section, the documentation is an
automated translation of the Doxygen class documentation from the header files
into Java's Javadoc format. Due to the nature of this conversion, we usually
recommend using the C++ documentation received together with the SDK directly.

### Sample usage

```java
import de.fraunhofer.iis.shore.wrapper.*;

// Create the engine, parameters may vary, please check the documentation
ShoreEngine engine = Shore.CreateFaceEngine(...);

//optional: set a callback message to process Shore's messages
Shore.SetMessageCall(new IMessageCallback() {
            @Override
            public void MessageCallback(String s) {
                System.out.println(s);
            }
        });

// images must be passed as directly allocated ByteBuffer objects containing
// the raw data (grayscale or RGB)
ByteBuffer image = ByteBuffer.allocateDirect(...);

... // fill buffer with image data...

// Process a raw image buffer - parameters follwing the width and height
// highly depend on the format of the input data. Please check the
// documentation for a detailed description
// The call to Process() usually happens in a loop of course
ShoreContent content = engine.Process(image, width, height, ...);

// iterate over all objects found in the image
if(content != null) {
    for(int i=0; i < content.GetObjectCount(); ++i) {
        ShoreObject object = content.GetObject(i);
        //get and print the bounding box of the ith object
        ShoreRegion r = object.GetRegion();
        System.out.println("Region: top: " + r.GetTop() +
                            " bottom: " + r.GetBottom() +
                                " left: " + r.GetLeft() +
                              " right: " + r.GetRight() +
            "\n");

        //iterate over and print all attributes of the object
        for(int j=0; j < object.GetAttributeCount(); ++j) {
            String key = object.GetAttributeKey(j);
            String value = object.GetAttribute(j);
            System.out.println(key + " = " + value + "\n");
        }

        //iterate over and print all rating for the object
        for(int k = 0; k < object.GetRatingCount(); ++k) {
            String key = object.GetRatingKey(k);
            Float value = object.GetRating(k);
            System.out.println(key + " = " +value + "\n");
        }
    }
}

// Once the engine is no longer needed, it should be deleted to free
// all resources on the native side
Shore.DeleteEngine(enigne);
//Alternatively, all engines that were created can be deleted at once
Shore.DeleteEngines();
```

## Limitations and Known Issues
The Java bindings enable Java developers to use the SHORE library for real-time
face detection and analysis in their applications. The bindings are, however,
not a care free package and come with some limitations:

* The only supported an tested OS is Linux (specifically Ubuntu 22.04)
* The current implementation only works with a shared SHORE library
* The JavaDoc generation is a mere translation of the doxygen comments from the
  header files

