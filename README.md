# The IDL-Motley Library

## Synopsis

IDL-Motley is a library of IDL code written largely by me at NIWA. It is published under the
[MIT Open Source License](http://www.opensource.org/licenses/mit-license.php). It is now hosted on
GitHub in project [hadfieldnz/idl-motley](https://github.com/hadfieldnz/idl-motley)

The library is a collection of the routines that I use regularly and that I think might be of interest to others.
There are several Object Graphics classes, a base class for widget applications and several applications built
on it, functions that make it easy to represent scaled data on axes, classes for accessing netCDF files
and several utility routines. I am particularly proud of the animation capabilities. You will notice that the names
begin with my initials, MGH. This is not egotism
(well, OK, just a little) but an attempt to avoid naming conflicts with other software collections.

## Installation

I have made no effort to keep the routines in IDL-Motley independent of each other, so if you want to use one you're advised to
install the lot.

### Installation Method 1: IDL Package Manager

If you have IDL 8.7.1 (due out in September 2018) or later, you can install IDL-Motley with the IDL Package Manager, eg:

```
IDL> ipm, /INSTALL, 'https://github.com/hadfieldnz/idl-motley'
```

This will install a package named IDL-Motley in the !PACKAGE_PATH directory, typically ${HOME}/.idl/idl/packages.
The relevant subdirectories will also be added to the [!PATH](https://www.harrisgeospatial.com/docs/Managing_IDL_Paths.html).

### Installation Method 2: Cloning the source

If you don't have the IDL Package Manager the recommended method for installing IDL-Motley is to clone the repository, eg:

```
$ cd ${HOME}/IDL
$ git clone https://github.com/hadfieldnz/idl-motley.git
```

You will then need to add IDL-Motley directory (in the above case this is ${HOME}/IDL/idl-motley) to the [!PATH](https://www.harrisgeospatial.com/docs/Managing_IDL_Paths.html)
using the usual IDL Preferences mechanism.

### Installation Method 3: Downloading a Zip archive

GitHub also allows you to download a snapshot of the code [as a ZIP archive](https://github.com/hadfieldnz/idl-motley/archive/master.zip).
You then need to extract the code into a suitable directory and modify the !PATH as for Method 2.

### Library Initialisation

Before using any of the routines in the library in any IDL session, run the initialisation routine with the command "mgh_motley".
You may eventually want to add this command to your startup script.

## Dependencies

This version of the library requires IDL 8.5. It has been developed & tested on Windows 7 and Linux.
If it doesn’t work on your platform, I’d love to hear about it.

Generally the IDL-Motley library does not require any routines outside the standard IDL library. Occasionally I make exceptions; in
this case my policy is to bundle a copy of the required routine in the "external" subdirectory, with permission of the author.
I try to keep these bundled routines up to date, but you may want to check the author’s WWW site for a more recent copy.
Currently the bundled routines are:

* IMDISP by Liam Gumley, used in an example program.
* CMUNIQUE_ID by Craig Markwardt.

The library includes a modified form of RSI’s CW_PALETTE_EDITOR, called MGH_CW_PALETTE_EDITOR, and
is included with permission of RSI, who retain copyright. For a list of the modifications, see the modified source code.

The routines in the library for exporting images and animations require various
extrnal programs

* The GraphicsMagick "gm convert" command (http://www.graphicsmagick.org/)
* Klaus Ehrenfried's program "ppm2fli" for generating FLC animations, (http://vento.pi.tu-berlin.de/fli.html)
* The Info-Zip "zip" command (http://www.cdrom.com/pub/infozip/)

The user is responsible for ensuring that the command names as
specified here invoke the command in the shell spawned by
IDL. This can be done in a variety of ways depending on the
operating system and shell.

On Windows, the commands can be invoked through wrapper .bat files,
placed in a directory on the system PATH. Either Cygwin or Windows-native
(eg. GnuWin32) executables can be used.


________________________________________
Mark Hadfield 2018-08-06

