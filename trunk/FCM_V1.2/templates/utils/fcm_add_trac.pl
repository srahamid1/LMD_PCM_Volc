#!/usr/bin/perl
# ------------------------------------------------------------------------------
# NAME
#   fcm_add_trac.pl
#
# SYNOPSIS
#   fcm_add_trac.pl [OPTIONS] <system>
#   fcm_add_trac.pl -h
#
# DESCRIPTION
#   See $usage for further information.
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
use Getopt::Long;
use File::Basename;
use File::Spec;
use Config::IniFiles;

# In-house modules
use lib File::Spec->catfile (
  dirname (
    (grep {-x File::Spec->catfile ($_, 'fcm')} split (/:/, $ENV{PATH})) [0]
  ),
  'lib',
);
use Fcm::Util;

# ------------------------------------------------------------------------------

# Program information
my $this      = basename ($0);
my $year      = (localtime)[5] + 1900;
my $copyright = <<EOF;

(C) Crown copyright $year Met Office. All rights reserved.
EOF
my $usage     = <<EOF;
NAME
  $this: add a new Trac browser for a FCM project

SYNOPSIS
  $this [OPTIONS] <project> # normal usage
  $this [-h]                # print help and exit

DESCRIPTION
  This script adds a new Trac browser for a project managed by FCM. The name of
  the project is specified in the first argument.
  
  With the except of --authorised and --help, all options to the script take at
  least one argument. If an option can take more than one argument, the
  arguments should be specified in a comma-separated list.

OPTIONS
  -a, --authorised      - specify an "authorised" permission. Only those users
                          granted this permission will have "_CREATE" and
                          "_MODIFY" access. The default is to grant all
                          authenticated users "_CREATE" and "_MODIFY" access.

  -c, --component       - specify one or more components.

  -d, --description     - specify a description of the project.

  -e, --smtp-always-cc  - specify one or more e-mail addresses, where e-mails
                          will be sent to on ticket changes.

  -h, --help            - prints the usage string and exits.

  -m, --milestone       - specify one or more milestones.

  -s, --svn-repos       - specify the Subversion repository location. Use an
                          empty string if no Subversion repository is needed.

  -u, --admin-user      - specify one or more admin users.

  -v, --version         - specify one or more versions.
$copyright
EOF

# ------------------------------------------------------------------------------

# Options
my ($authorised, $help, $description, $svn_repos);
my (@admin_users, @components, @emails, @milestones, @versions);

GetOptions (
  'a|authorised'       => \$authorised,
  'c|component=s'      => \@components,
  'd|description=s'    => \$description,
  'e|smtp-always-cc=s' => \@emails,
  'h|help'             => \$help,
  'm|milestone=s'      => \@milestones,
  's|svn-repos=s'      => \$svn_repos,
  'u|admin-user=s'     => \@admin_users,
  'v|version=s'        => \@versions,
);

@admin_users = split (/,/, join (',', @admin_users));
@components  = split (/,/, join (',', @components));
@emails      = split (/,/, join (',', @emails));
@milestones  = split (/,/, join (',', @milestones));
@versions    = split (/,/, join (',', @versions));

if ($help) {
  print $usage;
  exit;
}

# Arguments
my $project = $ARGV[0];
if (not $project) {
  print $usage;
  exit;
}

# ------------------------------------------------------------------------------

# Useful variables
my $svn_root  = '/data/local/fcm/svn/live';
my $trac_root = File::Spec->catfile ((getpwnam ('fcm'))[7], 'trac', 'live');

# Parse the central configuration file
my $central_ini = Config::IniFiles->new (
  '-file' => File::Spec->catfile ($trac_root, 'trac.ini'),
);

# ------------------------------------------------------------------------------

MAIN: {
  # Check for the existence of Trac for the current project
  # ----------------------------------------------------------------------------
  my $trac_project = File::Spec->catfile ($trac_root, $project);
  die $this, ': ', $trac_project, ': already exists, abort' if -d $trac_project;

  # Check for the existence of SVN for the current project
  # ----------------------------------------------------------------------------
  my $svn_project = defined ($svn_repos)
                    ? $svn_repos
                    : File::Spec->catfile ($svn_root, $project . '_svn');
  die $this, ': ', $svn_project, ': does not exist, abort'
    if $svn_project and not -d $svn_project;

  # Set up "trac-admin" command for this project
  # ----------------------------------------------------------------------------
  my @admin_cmd = ('trac-admin', $trac_project);

  # Create project's Trac
  my $trac_templates = '/usr/share/trac/templates';

  my @command = (
    @admin_cmd,
    'initenv',
    $project,
    'sqlite:db/trac.db',
    ($svn_project ? ('svn', $svn_project) : ('', '')),
    $trac_templates,
  );

  &run_command (\@command, PRINT => 1);

  # Ensure the new Trac has the correct group and permissions
  &run_command ([qw/chgrp -R apache/, $trac_project], PRINT => 1);
  &run_command ([qw/chmod -R g+w/, $trac_project], PRINT => 1);

  # Components
  # ----------------------------------------------------------------------------
  my @cur_cmd = (@admin_cmd, 'component');

  # Remove example components
  for my $component (qw/component1 component2/) {
    &run_command ([@cur_cmd, 'remove', $component], PRINT => 1);
  }

  # Add specified components
  for my $component (@components) {
    &run_command ([@cur_cmd, 'add', $component, ''], PRINT => 1);
  }

  # List components
  &run_command ([@cur_cmd, 'list'], PRINT => 1);

  # Versions
  # ----------------------------------------------------------------------------
  @cur_cmd = (@admin_cmd, 'version');

  # Remove example versions
  for my $version (qw/1.0 2.0/) {
    &run_command ([@cur_cmd, 'remove', $version], PRINT => 1);
  }

  # Add specified versions
  for my $version (@versions) {
    &run_command ([@cur_cmd, 'add', $version], PRINT => 1);
  }

  # List versions
  &run_command ([@cur_cmd, 'list'], PRINT => 1);

  # Milestones
  # ----------------------------------------------------------------------------
  @cur_cmd = (@admin_cmd, 'milestone');

  # Remove example milestones
  for my $milestone (qw/milestone1 milestone2 milestone3 milestone4/) {
    &run_command ([@cur_cmd, 'remove', $milestone], PRINT => 1);
  }

  # Add specified milestones
  for my $milestone (@milestones) {
    &run_command ([@cur_cmd, 'add', $milestone], PRINT => 1);
  }

  # List milestones
  &run_command ([@cur_cmd, 'list'], PRINT => 1);

  # Priority
  # ----------------------------------------------------------------------------
  @cur_cmd = (@admin_cmd, 'priority');

  # Change default priorities
  my %priorities = (
    blocker  => 'highest',
    critical => 'high',
    major    => 'normal',
    minor    => 'low',
    trivial  => 'lowest',
  );
  while (my ($old, $new) = each %priorities) {
    &run_command ([@cur_cmd, 'change', $old, $new], PRINT => 1);
  }

  # List priorities
  &run_command ([@cur_cmd, 'list'], PRINT => 1);

  # Severity
  # ----------------------------------------------------------------------------
  @cur_cmd = (@admin_cmd, 'severity');

  # Add serverities
  for my $severity (qw/blocker critical major normal minor trivial/) {
    &run_command ([@cur_cmd, 'add', $severity], PRINT => 1);
  }

  # List serverities
  &run_command ([@cur_cmd, 'list'], PRINT => 1);

  # Permission
  # ----------------------------------------------------------------------------
  @cur_cmd = (@admin_cmd, 'permission');

  # Add permissions to admin users
  for my $user (@admin_users) {
    &run_command ([@cur_cmd, 'add', $user, 'admin'], PRINT => 1);
  }
  &run_command ([@cur_cmd, qw/add admin TRAC_ADMIN/], PRINT => 1);

  # Remove wiki/ticket create/modify permissions from anonymous users
  for my $per (qw/TICKET_CREATE TICKET_MODIFY WIKI_CREATE WIKI_MODIFY/) {
    &run_command ([@cur_cmd, qw/remove anonymous/, $per], PRINT => 1);
  }

  # Add wiki/ticket create/modify permissions to authenticated/authorised users
  for my $per (qw/TICKET_CREATE TICKET_MODIFY WIKI_CREATE WIKI_MODIFY/) {
    &run_command (
      [@cur_cmd, 'add', ($authorised ? 'authorised' : 'authenticated'), $per],
      PRINT => 1,
    );
  }

  # List permissions
  &run_command ([@cur_cmd, 'list'], PRINT => 1);

  # Misc modifications to "trac.ini"
  # ----------------------------------------------------------------------------
  my $local_file = File::Spec->catfile ($trac_project, 'conf', 'trac.ini');

  # Read and parse "trac.ini"
  my $local_ini = Config::IniFiles->new ('-file' => $local_file);

  # Descriptive name for the current project
  my $descr          = $description ? $description : $project;

  # Default component
  my $def_component  = @components ? $components [0] : '';

  # List of e-mail addresses to always cc
  my $smtp_always_cc = @emails ? join (',', @emails) : '';

  # List of "default" config, in [section, option, value]
  my @config = (
    ['notification', 'smtp_always_cc'        , $smtp_always_cc],
    ['project'     , 'descr'                 , $descr],
    ['ticket'      , 'default_component'     , $def_component],
  );

  for (@config) {
    my ($section, $option, $value) = @{ $_ };

    # Add new section, if necessary
    $local_ini->AddSection ($section)
      if not $local_ini->SectionExists ($section);

    if (defined ($local_ini->val ($section, $option))) {
      # Modify existing option
      $local_ini->setval ($section, $option, $value);

    } else {
      # Add new option
      $local_ini->newval ($section, $option, $value);
    }
  }

  # Remove duplicated sections/options in the configuration file
  for my $section (($local_ini->Sections)) {
    # Remove comments
    $local_ini->DeleteSectionComment ($section);

    # Leave section in local configuration file if it does not exist in the
    # central configuration file
    next unless $central_ini->SectionExists ($section);

    for my $parameter (($local_ini->Parameters ($section))) {
      # Remove comments
      $local_ini->DeleteParameterComment ($section, $parameter);

      # Leave parameter in local configuration file if it does not exist in the
      # central configuration file
      my $central_value = $central_ini->val ($section, $parameter);
      next unless defined $central_value;

      # Remove local parameter if it is the same as the central one
      if ($central_value eq $local_ini->val ($section, $parameter)) {
        print 'Remove parameter: ', $parameter, ' in section: ', $section, "\n";
        $local_ini->delval ($section, $parameter);
      }
    }

    # Remove section if it is empty
    if (not ($local_ini->Parameters ($section))) {
      print 'Remove section: ', $section, "\n";
      $local_ini->DeleteSection ($section);
    }
  }

  # Rename original "trac.ini" to "trac.ini.orig"
  rename $local_file, $local_file . '.orig';

  # Output modifications to "trac.ini"
  $local_ini->WriteConfig ($local_file);
}

# Finally...
# ------------------------------------------------------------------------------
print $this, ': finished normally.', "\n";
exit;

# ------------------------------------------------------------------------------

__END__
