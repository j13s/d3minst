#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;


use GKPOPackage;

# Ubuntu Lucid path, otherwise use the path from the command line to the
# Mercenary PKG file.
my $pkg_file = GKPOPackage->new({
    'pkg' => ($ARGV[0]) ? $ARGV[0] : '/media/D3_MERCS/d3merc.pkg',
});


my @files = $pkg_file->get_files();

my @merc_files = qw(
    merc.hog
    mi.mve
    me.mve
    bluedev.mn3
    bluedev.txt
    bside.mn3
    bsidectf.mn3
    chaos.mn3
    havoc.mn3
    kata12.mn3
    kata12.txt
    mayhem.mn3
    merc.mn3
    poe.mn3
    stonecutter.mn3
    stonecutter.txt
    tri-pod.mn3
    tri-pod.txt
);

my %good_files = map { $_ => 1} (@merc_files);

foreach my $f (@files) {
    next unless defined $good_files{$f->filename()};
    print $f->filename(), "\n";
#    print "\tSize: ", $f->size(), "\n";
#    print "\tOffset: ", $f->file_offset(), "\n";

    $f->write_out_file();
}
