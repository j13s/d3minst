#!/usr/bin/env perl

# d3minst - A Descent 3: Mercenary installer for Linux
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

use Text::Wrap;
use Getopt::Long;

use GKPOPackage;

our $VERSION = '1.0.0';

my $install;
my $verbose;

GetOptions(
    "install=s" => \$install,
    "verbose"   => \$verbose,
);

# Exit unless there is a specified installation directory. 
unless ($install) {
    print usage();
    exit;
}


# Ubuntu Lucid path, otherwise use the path from the command line to the
# Mercenary PKG file.
my $pkg_file = GKPOPackage->new({
    'pkg' => ($ARGV[0]) ? $ARGV[0] : '/media/D3_MERCS/d3merc.pkg',
});


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


foreach my $f ($pkg_file->get_files(@merc_files)) {
    if ($verbose) {
        print $install, "/";

        if ($f->path()) {
            print $f->path(), "/";
        }
    
        print $f->filename();
    }
    
    # Write file to installation directory.
    $f->write_out_file($install);
    
    if ($verbose) {
        print "\n";
    }
}


sub usage {
    print wrap ('', '',
        "d3minst $VERSION - A Descent 3: Mercenary installer for Linux.\n",
        "Copyright (C) 2010 James Kastrantas.  d3minst comes with ",
        "ABSOLUTELY NO WARRANTY.  This is free software, and you are ",
        "welcome to redistribute it under certain conditions; see COPYING ",
        "for details.\n\n",
        
        "Usage: d3minst --install=[dir] [path-to-d3merc.pkg]\n\n",
              
        "Options:\n",
        "--install=[dir]    Install to directory specified.\n",
        "--verbose          Have the installer describe what it's doing.\n"
    );
}