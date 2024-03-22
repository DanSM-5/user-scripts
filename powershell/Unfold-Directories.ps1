<#
.SYNOPSIS
  Unfolds all subdirectories under target directory

.DESCRIPTION
  Script will move all the content from subdirectories to the target, then delete the subdirectories.
  It provides a Recurse option to unfold all subdirectories until there are no more subdirectories left in target

.PARAMETER DirectoryName
  Path of target directory. By default it runs under current working directory.

.PARAMETER Recurse
  Keep unfolding subdirectories until there are no more subdirectories left in target (Like running script n times until no more subdirectories).

.INPUTS
  None

.OUTPUTS
  None

.EXAMPLE
  Unfold-Directories

  # Unfolds all subdirectories under current working directory

.EXAMPLE
  Unfold-Directories -DirectoryName C:\some\path

  # Runs the script for target 'C:\some\path'

.EXAMPLE
  Unfold-Directories C:\some\path

  # Adding '-DirectoryName' argument is optional

.EXAMPLE
  Unfold-Directories C:\some\path -Recurse

  # Check if there are more subdirectories after unfold. If so, run again until no more subdirectories are left.

.NOTES
  The script is designed to don't delete files but only empty directories. You should be careful and make a security copy first before running.

#>

param(
  [String]
  $DirectoryName = '.',
  [Switch]
  $Recurse = $false
)

# Get absolute path
$parent = [IO.Path]::GetFullPath([IO.Path]::Combine((Get-Location -PSProvider FileSystem).ProviderPath, $DirectoryName))

$directoriesToUnfold = Get-ChildItem -Path $parent -Directory -Force -ErrorAction SilentlyContinue

do {
  # Move all files from nested directories to parent and delete after
  foreach ($path in $directoriesToUnfold) {
    Move-Item -Path "$path\*" -Destination $parent -Force
    # Only delete if directory is trully empty
    if ((Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue) -eq $null) {
      Remove-Item -Path $path -Recurse -Force
    }
  }

  # If recurse, check all new directories again
  # else set to $null to end loop
  $directoriesToUnfold = if ($Recurse) {
    Get-ChildItem -Path $parent -Directory -Force -ErrorAction SilentlyContinue
  } else { $null }
} while ($directoriesToUnfold)

