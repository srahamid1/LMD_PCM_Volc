#!/usr/bin/python
# ------------------------------------------------------------------------------
# NAME
#   post-revprop-change.py
#
# SYNOPSIS
#   post-revprop-change.py REPOS REV USER PROPNAME ACTION <&0
#
# DESCRIPTION
#   This script updates the Trac SQLite database with the new revision log
#   following a change in svn:log. The old property value is passed via STDIN.
#
# COPYRIGHT
#   (C) Crown copyright Met Office. All rights reserved.
#   For further details please refer to the file COPYRIGHT.txt
#   which you should have received as part of this distribution.
# ------------------------------------------------------------------------------

# Standard modules
import commands
import os.path
import sqlite
import sys

def main ():
  '''Main program'''

  # Get command line arguments
  (repos, rev, user, propname, action) = sys.argv [1:6]

  # Handle only log message change
  if not (propname == 'svn:log' and action == 'M'):
    return

  # Get new message with "svnlook"
  message = commands.getoutput ('svnlook log -r ' + rev + ' ' + repos)
  if not message:
    return

  # Name of the project
  project = os.path.basename (repos)
  project = project.replace ('_svn', '')

  # Path to project Trac system
  trac    = os.path.join (os.path.expanduser ('~fcm'), 'trac', 'live', project)
  trac_db = os.path.join (trac, 'db', 'trac.db')

  # Update Trac database
  db      = sqlite.connect (trac_db)
  cursor  = db.cursor ()
  cursor.execute (
    "UPDATE revision SET message = %s WHERE rev == %s", message, rev
  )

  try:
    db.commit ()

  except:
    raise 'Failed to update log of revision ' + rev + ' in ' + trac_db + '.'

  else:
    print 'Updated log of revision ' + rev + ' in ' + trac_db + '.'

  return

# ------------------------------------------------------------------------------

if __name__ == '__main__' :
  main ()
