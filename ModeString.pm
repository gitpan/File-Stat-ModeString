package File::Stat::ModeString;

=head1 NAME

File::Stat::ModeString - conversion file stat(2) mode to/from string representation.

=head1 SYNOPSIS

 use File::Stat::ModeString;

 $string  = mode_to_string  ( $st_mode );
 $st_mode = string_to_mode  ( $string  );
 $type    = mode_to_typechar( $st_mode );

 die "Invalid mode in $string"
	if is_mode_string_valid( $string );

=head1 DESCRIPTION

This module provides a few functions for conversion between
binary and literal representations of file mode bits,
including file type.

All of them use only symbolic constants for mode bits
from B<File::Stat::Bits>.


=head1 FUNCTIONS

=cut

use strict;
use Carp;
use File::Stat::Bits;


BEGIN
{
    use Exporter;
    use vars qw($VERSION @ISA @EXPORT);

    $VERSION = do { my @r = (q$Revision: 0.15 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

    @ISA = ('Exporter');

    @EXPORT = qw( &is_mode_string_valid
		  &mode_to_typechar &mode_to_string &string_to_mode
		);
}


=head2

is_mode_string_valid( $string )

Returns true if argument matches mode string pattern.

=cut
sub is_mode_string_valid
{
    my $string = shift;

    return $string =~ m/^[dcb\-pls]([r-][w-][xsS-]){2}?[r-][w-][xtT-]$/;
}


=head2

$type = mode_to_typechar( $mode )

Returns file type character of binary mode, '?' on unknown file type.

=cut
sub mode_to_typechar
{
    my $mode = shift;

    return 'd' if S_ISDIR ($mode);
    return 'c' if S_ISCHR ($mode);
    return 'b' if S_ISBLK ($mode);
    return '-' if S_ISREG ($mode);
    return 'p' if S_ISFIFO($mode);
    return 'l' if S_ISLNK ($mode);
    return 's' if S_ISSOCK($mode);
    return '?';
}


sub have_bit
{
    my ($mode, $mask) = @_;

    return ($mode & $mask) == $mask;
}

sub have_bit_char
{
    my ($mode, $mask, $char) = @_;

    return (($mode & $mask) == $mask) ? $char : '-';
}


=head2

$string = mode_to_string( $mode )

Converts binary mode value to string representation.
'?' in file type field on unknown file type.

=cut
sub mode_to_string
{
    my $mode = shift;
    my $string;

    $string = mode_to_typechar($mode);

    {	# user
	$string .= have_bit_char($mode, S_IRUSR(), 'r');
	$string .= have_bit_char($mode, S_IWUSR(), 'w');

	my $x = 1 if have_bit($mode, S_IXUSR());
	my $s = 1 if have_bit($mode, S_ISUID());

	$string .= 'x', last if  $x and !$s;
	$string .= 's', last if  $x and  $s;
	$string .= 'S', last if !$x and  $s;
	$string .= '-';
    }

    {	# group
	$string .= have_bit_char($mode, S_IRGRP(), 'r');
	$string .= have_bit_char($mode, S_IWGRP(), 'w');

	my $x = 1 if have_bit($mode, S_IXGRP());
	my $s = 1 if have_bit($mode, S_ISGID());

	$string .= 'x', last if  $x and !$s;
	$string .= 's', last if  $x and  $s;
	$string .= 'S', last if !$x and  $s;
	$string .= '-';
    }

    {	# other
	$string .= have_bit_char($mode, S_IROTH(), 'r');
	$string .= have_bit_char($mode, S_IWOTH(), 'w');

	my $x = 1 if have_bit($mode, S_IXOTH());
	my $t = 1 if have_bit($mode, S_ISVTX());

	$string .= 'x', last if  $x and !$t;
	$string .= 't', last if  $x and  $t;
	$string .= 'T', last if !$x and  $t;
	$string .= '-';
    }

    return $string;
}


=head2

$mode = string_to_mode( $string )

Converts string representation of file mode to binary one.
Prints warning and returns I<undef> on unknown character.

=cut
sub string_to_mode
{
    my $string = shift;
    my @list   = split //, $string;
    my $mode   = 0;

    {	# type
	my $char = shift @list;
	$mode |= S_IFDIR (), last if 'd' eq $char;
	$mode |= S_IFCHR (), last if 'c' eq $char;
	$mode |= S_IFBLK (), last if 'b' eq $char;
	$mode |= S_IFREG (), last if '-' eq $char;
	$mode |= S_IFIFO (), last if 'p' eq $char;
	$mode |= S_IFLNK (), last if 'l' eq $char;
	$mode |= S_IFSOCK(), last if 's' eq $char;

	carp "Invalid character in file type position of mode $string";
	return undef;
    }

    {	# user read
	my $char = shift @list;
	$mode |= S_IRUSR, last if 'r' eq $char;
			  last if '-' eq $char;

	carp "Invalid character in user read position of mode $string";
	return undef;
    }

    {	# user write
	my $char = shift @list;
	$mode |= S_IWUSR, last if 'w' eq $char;
			  last if '-' eq $char;

	carp "Invalid character in user write position of mode $string";
	return undef;
    }

    {	# user execute
	my $char = shift @list;
	$mode |= S_IXUSR        , last if 'x' eq $char;
	$mode |= S_IXUSR|S_ISUID, last if 's' eq $char;
	$mode |=         S_ISUID, last if 'S' eq $char;
				  last if '-' eq $char;

	carp "Invalid character in user execute position of mode $string";
	return undef;
    }


    {	# group read
	my $char = shift @list;
	$mode |= S_IRGRP, last if 'r' eq $char;
			  last if '-' eq $char;

	carp "Invalid character in group read position of mode $string";
	return undef;
    }

    {	# group write
	my $char = shift @list;
	$mode |= S_IWGRP, last if 'w' eq $char;
			  last if '-' eq $char;

	carp "Invalid character in group write position of mode $string";
	return undef;
    }

    {	# group execute
	my $char = shift @list;
	$mode |= S_IXGRP        , last if 'x' eq $char;
	$mode |= S_IXGRP|S_ISGID, last if 's' eq $char;
	$mode |=         S_ISGID, last if 'S' eq $char;
				  last if '-' eq $char;

	carp "Invalid character in group execute position of mode $string";
	return undef;
    }


    {	# others read
	my $char = shift @list;
	$mode |= S_IROTH, last if 'r' eq $char;
			  last if '-' eq $char;

	carp "Invalid character in others read position of mode $string";
	return undef;
    }

    {	# others write
	my $char = shift @list;
	$mode |= S_IWOTH, last if 'w' eq $char;
			  last if '-' eq $char;

	carp "Invalid character in others write position of mode $string";
	return undef;
    }

    {	# others execute
	my $char = shift @list;
	$mode |= S_IXOTH        , last if 'x' eq $char;
	$mode |= S_IXOTH|S_ISVTX, last if 't' eq $char;
	$mode |=         S_ISVTX, last if 'T' eq $char;
				  last if '-' eq $char;

	carp "Invalid character in others execute position of mode $string";
	return undef;
    }

    return $mode;
}


=head1 SEE ALSO

L<stat(2)>;

L<File::Stat::Bits(3)>;

L<Stat::lsMode(3)>;

=head1 AUTHOR

Dmitry Fedorov <fedorov@inp.nsk.su>

=head1 COPYRIGHT

Copyright (c) 2003, Dmitry Fedorov <fedorov@inp.nsk.su>

=head1 LICENCE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

=head1 DISCLAIMER

The author disclaims any responsibility for any mangling of your system
etc, that this script may cause.

=cut


1;

