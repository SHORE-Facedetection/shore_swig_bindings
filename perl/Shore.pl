#!/usr/bin/perl
use strict;
use warnings;
# this is a bit hacky - in a productive environment the module should
# be installed to a well known Perl module path
use Cwd 'abs_path';
use File::Basename;
use lib dirname(abs_path($0));
use Shore;

use Data::Dumper;
use Image::Magick;


sub messageCall {
    my $message = shift;
    print "SHORE message: $message";
}

if(@ARGV == 0) {
    print "Usage: $0 <IMAGEFILE> [IMAGEFILE...]\n";
    exit 0;
}

Shore::SetMessageCall(\&messageCall);

my $true = 1;
my $false = 0;
my $model = "Face.Front";
my $engine = Shore::CreateFaceEngine(0.00, 
                                  $true,
                                  2,
                                  $model,
                                  1,
                                  9,
                                  0,
                                  0,
                                  "Spatial",
                                  $false,
                                  "Off",
                                  "Off",
                                  "Off",
                                  "Off",
                                  "Dnn",
                                  "On",
                                  "Off",
                                  $false,
                                  $false);

my $image= Image::Magick->new;
$image->Read(@ARGV);

for(my $i=0; $image->[$i]; $i++) {
    my $width = $image->[$i]->Get('columns');
    my $height = $image->[$i]->Get('rows');
    my $raw = $image->[$i]->ImageToBlob(magick => 'RGB', depth => 8);

    print "$ARGV[$i]: $width x $height\n";
    my $content = $engine->Process($raw, $width, $height, 3, 3, 3*$width, 1, "RGB");
    print "Number of Objects: " . $content->GetObjectCount() . "\n";

    for (my $j=0; $j<$content->GetObjectCount(); $j++) {
        my $object = $content->GetObject($j);
        my $type = $object->GetType();
        my $region = $object->GetRegion();
        my $top = int($region->GetTop());
        my $left = int($region->GetLeft());
        my $bottom = int($region->GetBottom());
        my $right = int($region->GetRight());
        print "Object[$j]: $type @ $left,$top \n";
        $image->[$i]->Draw(stroke=>'red', fill=>"none", primitive=>'rectangle', 
                           points=>"$left,$top $right,$bottom");
        print "\tNumber of Ratings: " . $object->GetRatingCount() . "\n";
        for(my $k=0; $k<$object->GetRatingCount(); $k++) {
            my $float = $object->GetRating($k);
            print "\t\t" . $object->GetRatingKey($k) . " = " . $float . "\n";
        }
    }
    my $newname = dirname($ARGV[$i]) . "/annotated_" . basename($ARGV[$i]);
    $image->[$i]->Write($newname);
}

Shore::DeleteEngine($engine);

