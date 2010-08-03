#!/usr/bin/env perl

# Copyright (C) 2010 James Kastrantas
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

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
