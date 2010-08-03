#!/usr/bin/env perl
# Build the d3minst script.
# Copy the installer to d3minst and append the Perl modules to it so
# everything fits nicely in one file.


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


use IO::File;
use Carp;


# Filehandle for the assembled installer.
my $d3minst_fh = IO::File->new(
    'd3minst',
    '>'
);

check_file($d3minst_fh);

my @files_to_append = qw(
    installer.pl
    GKPOPackage/Base.pm
    GKPOPackage/File.pm
    GKPOPackage.pm
);


foreach my $file (@files_to_append) {
    # Filehandle for the module that is being appended to the installer.
    my $module_fh = IO::File->new(
        $file,
        '<'
    );
    
    my $line;
    APPEND_MODULES:
    while ($line = readline $module_fh) {
        # Since everything is in one file, skip the use statements so the
        # installer is parsed properly.
        if ($line =~ m/\Ause GKPOPackage/) {
            next APPEND_MODULES;
        }
        
        print $d3minst_fh $line;
    }
    
    $module_fh->close();
    
    # Separate the package from the previous package.
    print $d3minst_fh "\n" x 10;
}

$d3minst_fh->close();

sub check_file {
    my ($fh) = @_;
    
    unless ($fh) {
        croak "Could not open file.  $!";
    }
}
