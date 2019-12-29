timelapse
=========

**timelapse** is a Mac OS X command line utility to turn a series of images into a video.

It uses the AV Foundation to create MPEG-4 or Quicktime movies using the H.264, JPEG, Apple ProRes422, or Apple ProRes4444 codecs. The source images can be anything that NSImage can open; JPEG is most common.

## Downloading

You can download a binary installer package from https://github.com/jimstudt/timelapse/releases/ or build it 
from this archive.

## Status

**timelapse** currently has a single user. I use it several times a day to make movies from a series of image captures and it works beautifully for me. Maybe it will work for you too.

If you misuse an argument or make a mistake in the options, you are going to get a horrific excuse for an error message, usually embedded in a stack backtrace. Put it in an issue on github and I'll make nicer error for it.

I will not add features until someone asks for them. Feel free to browse the issue tracker and ask for what you need.

## Usage

There is a man page which you can read after you install the package. You can see a PDF version of it at https://github.com/jimstudt/timelapse/timelapse.pdf

I regenerate that with `man -t timelapse | pstopdf -o timelapse.pdf` when I do a release.

You should look at this copy of the man page: http://htmlpreview.github.com/?https://raw.github.com/jimstudt/timelapse/master/timelapse.html

It is tragically formatted, but you will get the idea.

## Building and Signing

This project is set up so I can build signed packages which, presumably, anyone can install and run on macos 10.15 (catalina) or later. If you are going to build it for yourself you probably want to go into your Project, Targets -> timelapse, Signing & Capabilities, and change "Signing Certificate" to "Sign to Run Locally".

The steps I go through to make the package are:

- build the **timelapse** target
- build the **Installer Package** target
- The unsigned package is in `build/timelapse.pkg`

You probably want to stop here, but I will go on and do this to make a notarized package.

- run the `Packaging/notarize.sh` script.
- wait for the confirmation email from Apple.
- run the `Packaging/staple.sh` script.
- The finished package is in `build/timelapse.pkg`

## History

I wrote **timelapse** years ago when QtKit was new. Since Mac OS 10.9, Mavericks, QtKit is deprecated, so I rewrote it to use AV Foundation instead. This git repository was restarted from scratch so you don't have to see any of that old cruft.

