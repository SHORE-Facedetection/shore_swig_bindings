# Shore for Perl
Creates a Perl module (`Shore.pm`)  and a shared library to use the Shore 
library from Perl.

## Prerequisites
The Perl build was tested on Ubuntu 22.04 and a suitable Dockerfile is
provided.

For non-Docker builds, the following packages/applications are required:
* A C++ Compiler and Linker  (e.g. via `build-essentials`)
* [Perl 5](https://perl.org)
* [Git](https://git-scm.com/)
* [CMake](https://cmake.org/)
* [Swig](https://swig.org)
* zip/unzip

## Build and Run Instructions
Extract the SHORE SDK to `ShoreSDK` or point the CMake variable `SHORE_SDK_PATH`
to a valid SHORE SDK folder.

```bash
mkdir build && cd build
cmake ..
make -j install
# Run the command line demo
cd ../INSTALL
perl Shore.pl sample.png

```

## Usage

In general, the Perl bindings offer an API similar to the C++ API. We do not 
offer a separate Perl module documentation as most functionalities are a 
one to one mapping of the C++ API.

The minor differences are explained in the following:
* All values passed to/received from methods are expected to be default
  Perl scalar values.
* Return values that would be a `nullptr` in C++ map to undefined scalars that
  should be checked via Perl's `defined()` function
* `Shore::SetMessageCall()` should be called with a reference to a subroutine
  that takes one parameter.


### Sample
```perl
# import the module (check Shore.pl for details)
use Shore;

# optional: define and set a callback function to receive messages from SHORE
sub message_call {
    my $message = shift;
    print "SHORE message: $message";
}
Shore::SetMessageCall(\&message_call);

# create the engine - check the documentation for details on the parameters
my $engine = Shore::CreateFaceEngine(...);

my $raw = ... # fill a buffer with image data

# Process a raw image buffer - parameters following the width and height
# highly depend on the format of the input data. Please check the
# documentation for a detailed description
# The call to Process() usually happens in a loop of course
my $content = $engine->Process($raw, $width, $height, ...);

# iterate over all objects
for (my $i=0; $i<$content->GetObjectCount(); $i++) {
    my $object = $content->GetObject($i);

    # get and print the region of the ith object
    my $region = $object->GetRegion();
    my $top = int($region->GetTop());
    my $left = int($region->GetLeft());
    my $bottom = int($region->GetBottom());
    my $right = int($region->GetRight());
    print "Object[$j]: $type @ $left,$top $right,$bottom\n";

    # iterate over and print all attributes
    for(my $j=0; $j<$object->GetAttributeCount(); $j++) {
        my $key = $object->GetAttributeKey($j);
        my $value = $object->GetAttribute($j);
        print("\t$key = $value\n");
    }
    # iterate over and print all ratings
    for(my $k=0; $k<$object->GetRatingCount(); $k++) {
        my $key = $object->GetRatingKey($k);
        my $value = $object->GetRating($k);
        print("\t$key = $value\n");
    }
}

# finally, delete the engine once it's no longer needed 
Shore::DeleteEngine($engine);

```


## Limitations and Known Issues
The Perl bindings enable Perl developers to use the SHORE library for real-time
face detection and analysis in their applications. The bindings are, however,
not a care free package and come with some limitations:

* The only supported an tested OS is Linux (specifically Ubuntu 22.04)
* The current implementation only works with a shared SHORE library

