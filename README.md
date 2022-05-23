# organize_chd
A script to create and organize CHD files from Redump-named BIN/CUE files

This script has been tested on BSD-like systems (primarily macOS), and while it may work on Linux, that hasn't been verified.  It requires zsh 5.8 or greater to run, and a working chdman binary in your path if you want to compress files to CHDs.

*Warning:* Do not attempt any of the organization methods except from the directory you want your games organized under.  In other words, if you run this from a directory that has images from multiple systems in subdirectories under it, you'll end up merging your systems' libraries together.

## Example usage:

```
organize_chd.zsh -d /Volumes/MiSTer/Games/PSX -c -r -n -s
```

## Parameters:

```
-d - The base directory (passed as a parameter to this option) to search from to find images, and the immediate base directory to organize images under
-c - Compress BIN/CUE files into CHD files (note that this will exit the script on any errors; if restarted, it will skip any games with existing CHD files)
-r - Enable organization by region (NTSC-U, NTSC-J, PAL)
-n - Merge games with multiple discs into a single directory with all discs in it
-s - Delete source BIN/CUE files and remove empty directories
```

## Known issues:

- There was one report of unwanted file deletion.  I rewrote the code that I think might have been responsible, but it's worth having a backup, just in case.
- This script currently doesn't handle filenames with dollar signs in them well.  The shell interprets the names as variable names, which it's unable to expand.

## Attributions:

The disc number merging code came from a script by swsp.