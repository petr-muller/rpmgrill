# -*- perl -*-
#
# RPM::Grill::Plugin::SpecFileSanity - runs rpm -q to look for errors
#
# FIXME: Should this be combined with SpecFileEncoding.pm ?
#
# $Id$
#
# Real-world packages that trigger errors in this module:
# See t/RPM::Grill/Plugin/90real-world.t
#
package RPM::Grill::Plugin::SpecFileSanity;

use base qw(RPM::Grill);

use strict;
use warnings;
our $VERSION = "0.01";

use Carp;
use File::Basename;
use IPC::Run qw(run timeout);

###############################################################################
# BEGIN user-configurable section

# Sequence number for this plugin
sub order {5}

# One-line description of this plugin
sub blurb { return "runs 'rpm -q' against specfile, for sanity check" }

# FIXME
sub doc {
    return <<"END_DOC" }
FIXME FIXME FIXME
END_DOC

# END   user-configurable section
###############################################################################

# Program name of our caller
( our $ME = $0 ) =~ s|.*/||;

#
# run 'rpm -q ....' on the specfile; report any errors found
#
sub analyze {
    my $self = shift;    # in: FIXME

    my $specfile_path     = $self->specfile->path;
    my $specfile_basename = basename($specfile_path);

    my @rpm = qw(rpm -q --specfile);
    my @cmd = ( @rpm, $specfile_path );
    my ( $stdout, $stderr );
    run \@cmd, \undef, \$stdout, \$stderr, timeout(600);    # 10 min.
    my $exit_status = $?;

    # Good exit status, and nothing in stderr: woot!  Nothing to report!
    if ( $exit_status == 0 && !$stderr ) {
        return;
    }

    # Either exit status was nonzero (bad), or something was in stderr.
    # Hopefully both.
    if ( !$stderr ) {

        # Bad exit status, but nothing in stderr
        if ( $exit_status == -1 ) {

            # Unable to run command
            $self->gripe(
                {   code => 'CannotRunRpm',
                    diag => "Unable to run rpm command",
                }
            );
            return;
        }

        my ( $rc, $sig, $core )
            = ( $exit_status >> 8, $exit_status & 127, $exit_status & 128 );

        my $msg = '';
        $msg .= " exited with status $rc" if $rc;
        $msg .= " exited on signal $sig"  if $sig;
        $msg .= " (core dumped)"          if $core;

        $self->gripe(
            {   code => 'BadExitStatusFromRpm',
                diag => "command '@rpm $specfile_basename' $msg",
            }
        );
        return;
    }

    # FIXME: we have stderr.  if exit status == 0, treat as warnings?
    my $what = ( $exit_status == 0 ? 'Warnings' : 'Errors' );

    # FIXME: if we see specfile:NN: , excerpt that line?

    # FIXME: replace pathname in $stderr with just $basename
    $stderr =~ s{\b$specfile_path\b}{$specfile_basename}g;

    my %notfound;
    while ($stderr =~ s{\s*(sh:\s+.*?:\s+(No such file or directory|command not found))\n}{}) {
        $notfound{$1}++;
    }
    for my $msg (sort keys %notfound) {
        if ((my $n = $notfound{$msg}) > 1) {
            $msg .= " ($n instances)";
        }
        $self->gripe(
            { code => 'RpmParseDependency',
              diag => "Possible macro expansion failure running '@rpm $specfile_basename'",
              excerpt => $msg,
              # FIXME: hint => "maybe (pkg) is not installed"?
          }
        );

    }

    # No more errors?
    return if ! $stderr;


    $self->gripe(
        {   code    => "RpmParse$what",
            diag    => "$what running '@rpm $specfile_basename'",
            excerpt => $stderr,
        }
    );
}

1;

###############################################################################
#
# Documentation
#

=head1	NAME

FIXME - FIXME

=head1	SYNOPSIS

    use Fixme::FIXME;

    ....

=head1	DESCRIPTION

FIXME fixme fixme fixme

=head1	CONSTRUCTOR

FIXME-only if OO

=over 4

=item B<new>( FIXME-args )

FIXME FIXME describe constructor

=back

=head1	METHODS

FIXME document methods

=over 4

=item	B<method1>

...

=item	B<method2>

...

=back


=head1	EXPORTED FUNCTIONS

=head1	EXPORTED CONSTANTS

=head1	EXPORTABLE FUNCTIONS

=head1	FILES

=head1	SEE ALSO

L<>

=head1	AUTHOR

Ed Santiago <santiago@redhat.com>

=cut