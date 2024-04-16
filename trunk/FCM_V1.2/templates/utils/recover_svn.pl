#!/usr/bin/perl
# ------------------------------------------------------------------------------
# NAME
#   recover_svn.pl
#
# SYNOPSIS
#   recover_svn.pl [<list of projects>]
#
# DESCRIPTION
#   This command is used to recover live repositories from backups and dumps,
#   using the following logic:
#     1. If one or more <projects> are not specified, check the backup directory
#        for list of projects and available backups.
#     2. For each available project (or the specified <projects>), check if its
#        live repository exists. If so, performs an integrity check.
#     3. If the live repository does not exist or if the integrity check fails,
#        recover by copying the backup into the live location.
#     4. Determine the youngest revision of the live repository.
#     5. Search the dump directory to see if there are dumps for newer
#        reversions. If so, load them back to the live repository.
#
# COPYRIGHT
#   (C) Crown copyright Met Office. All rights reserved.
#   For further details please refer to the file COPYRIGHT.txt
#   which you should have received as part of this distribution.
# ------------------------------------------------------------------------------

# Standard pragmas:
use strict;
use warnings;

# Standard modules:
use File::Basename;
use File::Spec;
use File::Path;

# ------------------------------------------------------------------------------

# Top level locations of live repositories, backups, dumps and hook scripts
my $logname  = 'fcm';
my $svn_live = File::Spec->catfile (
  File::Spec->rootdir (), qw/data local/, $logname, qw/svn live/,
);
my $svn_back = File::Spec->catfile ((getpwnam $logname) [7], qw/svn backups/);
my $svn_dump = File::Spec->catfile ((getpwnam $logname) [7], qw/svn dumps/);
my $hook_dir = File::Spec->catfile (
  (getpwnam $logname) [7], qw/FCM work Admin src hook/,
);

# Arguments
my %projects = map {$_, 1} @ARGV;

# Search the backup directory to see what are available
opendir DIR, $svn_back
  or die $svn_back, ': cannot read directory (', $!, '), abort';
my %backups = ();
while (my $file = readdir 'DIR') {
  next if $file =~ /^\./;
  next if $file !~ /\.tgz$/;
  next unless -f File::Spec->catfile ($svn_back, $file);

  (my $project = $file) =~ s/\.tgz$//;

  # If project arguments specified, skip projects that are not in the list
  next if %projects and not exists $projects{$project};

  # Store project name and its backup location
  $backups{$project} = File::Spec->catfile ($svn_back, $file);
}
closedir DIR;

# Create the live directory if it does not exist
mkpath $svn_live or die $svn_live, ': cannot create, abort' if not -d $svn_live;

# Exit if no backups found (for list of specified projects)
if (not keys %backups) {
  print 'No backup',
        (keys %projects ? join (' ', (' for', sort keys %projects)) : ''),
        ' found in ', $svn_back, "\n";
  exit;
}

# Search the live directory to see what are available
for my $project (sort keys %backups) {
  my $live_dir = File::Spec->catfile ($svn_live, $project);

  # Recovery required if $live_dir does not exist
  my $recovery = not -d $live_dir;

  # Perform an integrity check if $live_dir exist
  $recovery = system ('svnadmin', 'verify', $live_dir) unless $recovery;

  if (not $recovery) {
    print $project, ': live repository appears to be fine.', "\n";
    next;
  }

  # Recover to a temporary location first
  my $temp_dir = $live_dir . '.tmp';

  if (-d $temp_dir) {
    # Remove $temp_dir if it exists
    print 'Removing ', $temp_dir, ' ...', "\n";
    rmtree $temp_dir;
  }

  # Un-tar the backup
  print 'Extracting from the backup archive ', $backups{$project}, "\n";
  ! system (
    qw/tar -x -z -C/, dirname ($backups{$project}), '-f', $backups{$project},
  ) or die 'Cannot extract from the backup archive', $backups{$project};

  (my $backup_dir = $backups{$project}) =~ s/\.tgz$//;

  # Recover from backup
  print 'Copying ', $backup_dir, ' to ', $temp_dir, ' ...', "\n";
  my @command = ('svnadmin', 'hotcopy', $backup_dir, $temp_dir);
  system (@command);
  die join (' ', @command), ' failed (', $?, '), abort' if $?;

  rmtree $backup_dir;

  # Determine the youngest revision of the repository
  @command     = ('svnlook', 'youngest', $temp_dir);
  my $youngest = qx(@command)
    or die $temp_dir, ': cannot determine youngest revision (', $?, ')';

  # Search dump directory to see if there are any later dumps available
  my $dump_dir = File::Spec->catfile ($svn_dump, $project);
  
  if (opendir DIR, $dump_dir) {
    my @revs = grep {m/^\d+$/ and $_ > $youngest} readdir DIR;
    closedir DIR;

    # If newer dumps available, load each one back to the repository
    for my $rev (sort {$a <=> $b} @revs) {
      print 'Loading dump for revision ', $rev, ' to ', $temp_dir, ' ...', "\n";
      my $command = 'svnadmin load ' . $temp_dir .
                    ' <' . File::Spec->catfile ($dump_dir, $rev);
      system ($command);
      die $command, ' failed (', $?, '), abort' if $?;
    }

  } else {
      warn $project, ': dump directory not available for project';
  }

  # Move temporary directory to live
  if (-d $live_dir) {
    # Remove $live_dir if it exists
    print 'Removing ', $live_dir, ' ...', "\n";
    rmtree $live_dir;

    die $live_dir, ': cannot remove' if -d $live_dir;
  }

  print 'Moving ', $temp_dir, ' to ', $live_dir, ' ...', "\n";
  rename $temp_dir, $live_dir or die $temp_dir, ': cannot move to: ', $live_dir;
}

# Reinstate the hook scripts
my @command = (
  File::Spec->catfile (dirname ($0), 'install_hook.pl'),
  $hook_dir,
  $svn_live,
);

exec @command or die 'Cannot exec install_hook.pl (', $!, ')';

__END__
