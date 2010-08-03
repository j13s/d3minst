package GKPOPackage::Base;

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

use Carp;
use Fcntl qw(SEEK_SET);

# Read a number of bytes from a filehandle.  Will optionally use an
# offset.
sub _read_data {
    my ($self, $pkg_fh, $num_to_read, $offset) = @_;
    
    my $bytes_read; # Stores the number of bytes read.
    my $data;       # Stores the data read.
    
    # Read from offset, else read from last point read in filehandle.
    if (defined $offset) {
        $pkg_fh->seek($offset, SEEK_SET);
        $bytes_read = $pkg_fh->read($data, $num_to_read);
    }
    else {
        $bytes_read = $pkg_fh->read($data, $num_to_read);
    }
    
    # Exit if incorrent number of bytes were read.
    unless ($bytes_read == $num_to_read) {
        croak "Error reading $pkg_fh->filename()";
    }
    
    return $data;
}


# Read the filesize from the metadata.  It is stored in little-endian
# order.  Assuming a 32 bit value.
sub _read_number {
    my ($self, $args_ref) = @_;
    
    my $fh          = $args_ref->{'fh'};
    my $pos         = $args_ref->{'pos'};
    
    my $value = $self->_read_data(
        $fh,
        4,      # Values are stored as 32 bits
        $pos,
    );
    
    $value = $self->unpack_to_big_endian($value);
    
    return $value;
}


# Reverse the byte order and unpack as a 32bit value.
sub unpack_to_big_endian {
    my ($self, $value) = @_;
    
    # Reverse the byte order.
    $value = join("",
        reverse(
            split(
                //, $value
            )
        )
    );
    
    # Now unpack it into a form perl can understand.
    return hex unpack("H*", $value);    
}

1;
