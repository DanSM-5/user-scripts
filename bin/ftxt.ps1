#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Create or open a text file in a standard location.

.DESCRIPTION
  Creates text files in a standard location to store notes.
  If the file already exists, it will open it.

.PARAMETER Filename
  Optional parameter to specify file name. If not provided, it will use a random name with a UUID.

.INPUTS
  None

.OUTPUTS
  None

.EXAMPLE
  ntxt

.EXAMPLE
  ntxt filename.md

.NOTES
  Cross platform script.
  Use `PREFERRED_EDITOR` or `EDITOR` environment variable to configure the text editor to use.
  Use `TXT_LOCATION` to configure the path to the txt directory that will store the text files.
  Use it in conjunction with `ftxt` command to search for created files.

#>

# TODO: Implement

