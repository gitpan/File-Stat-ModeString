#!/usr/bin/perl

use strict;
use lib "./t"; use MakeMakerFix;
WriteMakefile('ModeString.pm', 'PREREQ_PM' => {'File::Stat::Bits' => 0},
                               'clean' => {'FILES' => "META.yml"} );

