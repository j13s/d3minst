package GKPOPackage::File;

use strict;
use warnings;
use diagnostics;

use Carp;
use Fcntl qw(SEEK_SET);
use File::Path qw(make_path);

use base 'GKPOPackage::Base';

# A 32 bit value stores the length of the path string.  The path will
# describe where the file goes.  Little endian.
use constant PKGF_PATH_SIZE_POS      => 0;
use constant PKGF_PATH_SIZE_LENGTH => 4;
# Position in the metadata of where the path starts.  A null byte
# indicates no path.
use constant PKGF_PATH_STRING_POS    => 4;
                                
# Probably a checksum of some kind to check file integrity.
use constant PKGF_UNKNOWN_METADATA_LENGTH => 8;

my @attributes = qw(
    filename
    filesize
    path
    path_offset
    filesize_offset
    filename_offset
    file_offset
    meta_offset
    filename_length
);

sub new {
	my ($class, $args_ref) = @_;
	
	# Really, the only two attributes that should be set are these.  The rest
	# need to be found from the file.  pkg is the name of the PKG file, and
	# meta_offset is the start of the file record's metadata.
	my $self = {
		map {
	        ($_ => $args_ref->{$_}) if (defined $args_ref->{$_})
        } qw(meta_offset pkg)
	};
	
	bless $self, ref($class) || $class;
	
	# If the metadata offset is defined and there is an open filehandle,
	# initialize the object.
	if ($self->meta_offset() && defined $args_ref->{'fh'}) {
	    $self->_init($args_ref->{'fh'})
    }
    
	return $self;
}




sub _init {
    my ($self, $fh) = @_;
    
    my $m = $self->meta_offset();
    
    $self->{'path'} = $self->_read_path($m, $fh);
    $self->{'filename'} = $self->_read_filename($fh);
    $self->{'filesize'} = $self->_read_filesize($fh);
    
    $self->{'file_offset'} = $self->{'filesize_offset'}
                             + PKGF_UNKNOWN_METADATA_LENGTH
                             + 4    # Length of filesize offset.
}




# Return the path of the file, excluding the null character.
sub _read_path {
    my ($self, $m, $fh) = @_;
    
    # The path offset will always start in the same place, four bytes into the
    # metadata.
    $self->{'path_offset'} = $m + PKGF_PATH_SIZE_LENGTH;
    
    # Get and store the path, including the null character.  This has a
    # trailing backslash and a null terminator.
    my $path_length = $self->_read_number({
        'fh'        => $fh,
        'pos'       => $m + PKGF_PATH_SIZE_POS,
    });
    
    # Get the path string.
    my $path = $self->_read_string({
        'pos'       => $self->{'path_offset'},
        'length'    => $path_length,
        'fh'        => $fh,
    });
    
    # Since this is for Windows, the directories in a path are separated by a
    # backslash.  Transliterate these to forwards slashes.
    $path =~ tr{\\}{/};

    return $path;
}




# Return the filename from a PKG file using the metadata offset to read
# the filename from the PKG.
sub _read_filename {
    my ($self, $fh) = @_;
    
    # Calculate the offset of the filename string's size because the metadata
    # before it is of variable length.  Include the null byte in the path
    # string.
    $self->{'filename_size_offset'} = $self->{'path_offset'}
                                 + length($self->{'path'})
                                 + 1;
                        
    # Read the size of the filename string, including the null byte.
    my $filename_size = $self->_read_number({
        'fh'    => $fh,
        'pos'   => $self->{'filename_size_offset'},
    });
    
    # Filename string begins four bytes after the filesize offset.
    $self->{'filename_offset'} = $self->{'filename_size_offset'} + 4;
    
    # Read the filename.
    return $self->_read_string({
        'fh'        => $fh,
        'length'    => $filename_size,
        'pos'       => $self->{'filename_offset'}, 
    });
}




# Read the size of the packed file.
sub _read_filesize {
    my ($self, $fh) = @_;
    
    # Remember to include the null byte or else an off-by-one error results.
    $self->{'filesize_offset'} = $self->{'filename_offset'}
                                 + length($self->{'filename'})
                                 + 1;
                                 
    return $self->_read_number({
        'fh'    => $fh,
        'pos'   => $self->{'filesize_offset'},
    });
}



# Return the metadata offset for the file record.
sub meta_offset {
    my ($self) = @_;
    
    return $self->{'meta_offset'};
}

# Get the name of the file packed in the PKG file.
sub filename {
    my ($self,) = @_;
    
    return $self->{'filename'};
}

# Get the size of the file packed in the PKG file.
sub filesize {
    my ($self,) = @_;
    
    return $self->{'filesize'};
}

sub file_offset {
    my ($self,) = @_;
    
    return $self->{'file_offset'}
}

# Read a null-terminated string into memory and return it.
sub _read_string {
    my ($self, $args_ref) = @_;
    
    my $fh      = $args_ref->{'fh'};        # Filehandle
    my $pos     = $args_ref->{'pos'};       # Position in the PKG file
    my $length  = $args_ref->{'length'};    # Length of the string, including
                                            # the null byte
    my $s = $self->_read_data(
        $fh,
        $length,
        $pos,
    );
    
    chop $s;
    
    # Transliterate to lowercase otherwise files won't be found by Descent 3.
    $s =~ tr/[A-Z]/[a-z]/;
    return $s;
}


# Return the offset pointing to the next file record.  Returns undef if
# there are no more records.
sub _read_next_record_offset {
    my ($self, $fh) = @_;
    
    my $next_offset = $self->{'file_offset'} + $self->{'filesize'};
    
    if ($next_offset >= (-s $fh)) {
        return undef;
    }
    
    return $next_offset;
}

# Extract a file from the PKG file.
sub write_out_file {
    my ($self) = @_;
    
    # Open the parent PKG file.
    my $pkg_fh = IO::File->new($self->{'pkg'}, '<');
    
    unless ($pkg_fh) {
        croak "Could not open $self->{'pkg'}";
    }
    
    # A guess for a good buffer size is 32K.  I welcome suggestions.
    my $buffer_size = 2 ** 15;
    
    # If a path exists for this file and the path doesn't exist, create the
    # directory.
    if ($self->{'path'} && !(-e $self->{'path'})) {
        my $path = $self->{'path'};
        chop $path;
        make_path($path);
    }
    
    # Full path to filename to write.
    my $filename = "$self->{'path'}$self->{'filename'}";
    my $new_fh = IO::File->new($filename, '>');
    
    unless ($new_fh) {
        croak "Could not create $filename";
    }
    
    # Number of bytes left to write for file.
    my $bytes_left = $self->{'filesize'};
    
    # Seek to the start of the file in the PKG.
    $pkg_fh->seek($self->{'file_offset'}, SEEK_SET);
    
    # Keep writing out 32K chunks while there are still bytes left.
    do {
        # If there are fewer bytes left than the buffer size, change the
        # buffer size to the number of bytes left for the last time.
        if ($bytes_left - $buffer_size < 0) {
            $buffer_size = $bytes_left % $buffer_size;
        }
        
        # Read and write the buffer to the file.
        my $buffer = $self->_read_data(
            $pkg_fh,
            $buffer_size,
        );
        
        print $new_fh $buffer;
        
        # Decrement the number of bytes left.
        $bytes_left -= $buffer_size
    } while ($bytes_left);
    
    $new_fh->close();
    $pkg_fh->close();
}

1;