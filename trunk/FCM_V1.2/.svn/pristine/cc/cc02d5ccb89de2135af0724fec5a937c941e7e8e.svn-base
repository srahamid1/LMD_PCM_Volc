#!/usr/bin/perl
# ------------------------------------------------------------------------------
# NAME
#   background_updates.pl
#
# SYNOPSIS
#   background_updates.pl <repos> <logdir>
#
# DESCRIPTION
#   Performs any background tasks required after each commit to the FCM
#   respository. A lock file is used to prevent mulitple instances of this
#   program from running.
#
# COPYRIGHT
#   (C) Crown copyright Met Office. All rights reserved.
#   For further details please refer to the file COPYRIGHT.txt
#   which you should have received as part of this distribution.
# ------------------------------------------------------------------------------

# Standard pragmas
use strict;
use warnings;

# Standard modules
use File::Basename;
use File::Spec::Functions;
use File::Path;

# ------------------------------------------------------------------------------

# Usage
my $this = basename $0;

# ------------------------------------------------------------------------------

# Arguments
my ($repos, $logdir) = @ARGV;
die $this, ': incorrect usage' unless $repos and $logdir;

# ------------------------------------------------------------------------------

# Lock file
my $lockfile = catfile ($logdir, $repos . '.lock');
my $locked   = undef;

# Do nothing if lock file exists
if (-e $lockfile) {
  print "$this: Found lock file ($lockfile). Exiting.\n";
  exit;
}

# Create lock file
open FILE, '>', $lockfile
  or die $this, ': unable to create lock file ', $lockfile;
close FILE;
$locked = 1;

# ------------------------------------------------------------------------------

my $wc_main      = '/home/h03/fcm/FCM/work/FCM';   # Location of main working copy
my $wc_admin     = '/home/h03/fcm/FCM/work/Admin'; # Location of admin working copy

my $install_hook = '/home/h03/fcm/FCM/work/Admin/src/utils/install_hook.pl';
my $hooksrc_top  = '/home/h03/fcm/FCM/work/Admin/src/hook';
my $hookdest_top = '/data/local/fcm/svn/live';

my $fcm_html2pdf = '/home/h03/fcm/FCM/work/Admin/src/utils/fcm_html2pdf';

my @html2pdf = (
  {
    PATTERN => 'doc/user_guide',
    INPUT   => '/home/h03/fcm/FCM/work/FCM/doc/user_guide/index.html',
    OUTPUT  => 'fcm-user-guide',
  },
  {
    PATTERN => 'doc/collaboration',
    INPUT   => '/home/h03/fcm/FCM/work/FCM/doc/collaboration/index.html',
    OUTPUT  => 'fcm-collaboration',
  },
  {
    PATTERN => 'doc/standards/fortran_standard\.html',
    INPUT   => '/home/h03/fcm/FCM/work/FCM/doc/standards/fortran_standard.html',
    OUTPUT  => 'fcm-fortran-standard',
  },
  {
    PATTERN => 'doc/standards/perl_standard\.html',
    INPUT   => '/home/h03/fcm/FCM/work/FCM/doc/standards/perl_standard.html',
    OUTPUT  => 'fcm-perl-standard',
  },
);

my @remotes      = (   # list of remote machines
  # 1st remote machine
  {
    MACHINE => 'tx01',               # machine name
    LOGNAME => 'fcm',                # logname
    WC      => '~/FCM/work',         # working copy location
    OPTIONS => [qw#-a -v
                --timeout=1800
		--exclude='.*'
		--exclude='FCM/doc'
		--delete-excluded#], # options to "rsync"
  },

  # 2nd remote machine, etc
  #{
  #  MACHINE => '',     # machine name
  #  LOGNAME => '',     # logname
  #  WC      => '',     # working copy location
  #  OPTIONS => [],     # options to "rsync"
  #},
);

$ENV{RSYNC_RSH} = 'rsh'; # Remote shell for "rsync"

while (1) {
  # Perform "svn update" on working copy of the "trunk" of the main project
  print "$this: Updating main working copy ...\n";
  my @update_main = qx(svn update $wc_main);
  die $this, ': unable to update working copy of FCM/trunk' if $?;

  # Perform "svn update" on working copy of the "trunk" of the Admin project
  print "$this: Updating admin working copy ...\n";
  my @update_admin = qx(svn update $wc_admin);
  die $this, ': unable to update working copy of Admin/trunk' if $?;

  # Remove last line from each output, which should be info of the revision
  pop @update_main;
  pop @update_admin;

  # No updates, exit loop
  if (not @update_main and not @update_admin) {
    print "$this: No updates detected. Exiting.\n";
    last;
  }

  # Set FCM release number, if necessary
  if (@update_main) {
    # Get last changed revision
    my @info = qx(svn info $wc_main);
    my $rev;

    for (@info) {
      next unless /^Last Changed Rev: (\d+)$/;

      $rev = $1;
      last;
    }

    # Update src/etc/fcm_rev
    print "$this: updating the FCM release number file ...\n";
    my $fcm_rev = catfile ($wc_main, 'src/etc/fcm_rev');
    open FILE, '>', $fcm_rev or die $fcm_rev, ': cannot open';
    print FILE $rev, "\n";
    close FILE or die $fcm_rev, ': cannot close';
  }

  # Re-create PDF files if necessary
  for (@html2pdf) {
    my $pattern = $_->{PATTERN};
    next unless grep m/$pattern/, @update_main;

    print $this, ': Re-creating PDF for ', $_->{OUTPUT}, '...', "\n";
    my @command = ($fcm_html2pdf, $_->{INPUT}, $_->{OUTPUT});
    system @command;
    die $this, ': unable to execute ', join (' ', @command) if $?;
  }

  # Re-install hook scripts if necessary
  if (grep m#src/hook#, @update_admin) {
    print "$this: Re-install hook scripts ...\n";
    my @command = ($install_hook, $hooksrc_top, $hookdest_top);
    system @command;
    die $this, ': unable to execute ', join (' ', @command) if $?;
  }

  if (@update_main) {
    # Update remote platforms, if necessary
    my $rsh = 'rsh';
    for my $remote (@remotes) {
      next unless $remote->{MACHINE} and $remote->{WC};
      print "$this: Updating working copy on $remote->{MACHINE} ...\n";

      # Create the top level directory for the remote working copy (if necessary)
      {
        my @command = ($rsh, $remote->{MACHINE});
        push @command, ('-l', $remote->{LOGNAME}) if $remote->{LOGNAME};
        push @command, (qw/mkdir -p/, $remote->{WC});
        system @command;
        die $this, ': unable to execute ', join (' ', @command) if $?;
      }

      # Sync the working copy to the remote platform
      {
        my @command = ('rsync');
        push @command, @{ $remote->{OPTIONS} } if @{ $remote->{OPTIONS} };
        my $rwcpath = $remote->{LOGNAME};
        $rwcpath   .= '@' . $remote->{MACHINE} . ':' . $remote->{WC};
        push @command, ($wc_main, $rwcpath);
        system join (' ', @command);
        die $this, ': unable to execute ', join (' ', @command) if $?;
      }
    }
  }
}

# ------------------------------------------------------------------------------

END {
  # Remove lock file on exit
  unlink $lockfile if $locked;
}

# ------------------------------------------------------------------------------
