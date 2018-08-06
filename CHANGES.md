# Change log for the Motley Library

Mark Hadfield

Motley is a library of IDL code written largely by Mark Hadfield at NIWA. This document describes major and/or widespread changes to the
routines in the library. For a routine-specific change log, see the individual documentation headers.

Entries are in reverse chronological order (most recent first).

### *2017-08-06*

The library can now be installed with the new IDL Package Manager, to be bundled with IDL 8.7.1. Version 1.0 has been released.

### *2017-06-30*

The library is now being maintained by Git and stored on GitHub (hadfieldnz/idl-motley). It contains 59238 lines of code and comments
(including empty lines) in 252 .pro files.

### *2016-11-02*

Moved all routines in the library to one of three new subdirectories: motley, examples and external. The new directory structure is more elegant,
in my opinion. However the change has the unfortunate side effect of breaking the connection between the old and new file locations in Mercurial
(for which a rename or move is implemented as deleting one file and adding another).

### *2016-04-26*

Fixed a bug in MGH_PNPOLY, reported by Matt Considine and Andrew Cool: an unintended integer division was occurring when polygon vertices were integers.

### *2016-02-29*

The Motley library now requires IDL >= 8.5.
I removed checksum32 and mgh_struct_hash and added a new MGH_HASHCODE function that uses the hashcode static method of the IDL_Variable class.

### *2015-04-23*

Added a copy of CHECKSUM32 from the IDL Astronomy Library, required by MGH_STRUCT_HASH.

### *2015-02-10*

Preparing for uploading code to Sourceforge.

The MGH_LINE_COEFF and MGH_POLYFILLA have been moved into the Motley library from my personal IDL library.

Removed avi.dll, as it only works on Win32, and I think doesn't work on that anymore either.

### *2011-07-26*

A lot more IDL 8 dependencies have been introduced.

The ToArray method of the MGH_Vector class has been overhauled and now supports a FLATTEN keyword, directing it to generate a 1D array from a
collection of arrays of different sizes and shapes. This proves very useful in compiling and processing large collections of bathymetry data.

### *2010-11-08*

Getting ready to publish the code on David Fanning's site, if he'll let me. The code now depends on IDL 8 in several places, and on
IDL 8.0.1 in at least one place (multi-page PDF output of animations in MGH_Player).

### *2010-10-28*

The MGHncFile and MGHncReadFile classes can now handle either 'INT' or 'SHORT' as the datatype specifier for 2-byte, integer netCDF variables.
This is to cope with changes in the NCDF_VARINQ function, which has returned one or other in different IDL versions and now (IDL 8.0) returns 'INT'.

### *2010-10-20*

I made the first backwards-incompatible changes: class MGH_GUI_Base now inherits IDL_Object (giving instances of the class access to
operator overloading and the dot notation); MGH_Window now exports to PDF using the new IDLgrPDF class.

### *2010-10-18*

I have (finally) installed IDL 8.0 on my computer. All code to date is compatible with IDL 7.1 or earlier (most of it works with
versions back to 6.x). With the big changes in 8.0, I will not be attempting to maintain compatibility with pre-8.0 versions in future.

### *2010-09-15*

There have been quite a few undocumented changes over the last year.
One significant recent one is the fixing of a performance bug in the MGHncSequence class: the VarGet method was calling a function that
effectively looped over the files in the sequence, inside a loop over the same files. This crippled performance when the number of files in the
sequence approached 1000 or so.

### *2009-09-28*

In an effort to streamline code for dealing with grids, I added two new functions: MGH_SUBSET2 (a 2D counterpart for MGH_SUBSET) and MGH_PERIM.
Also, the “point inside polygon” functions MGH_POLY_INSIDE and MGH_PNPOLY were made more flexible in how they require the polygon vertex data
and the argument order was changed: the polygon vertex array(s) come at the end.

### *2009-08-24*

Motley code now being stored in an SVN repository. SVN ID information is recorded in a comment on the first line of each .pro file.

### *2009-07-13*

Fixed a few netCDF bugs reported by Foldy Lajos.

### *2009-04-28*

Changes have been made to the MGHgrGraph class to accommodate the change in IDLgrWindow resolution in IDL version 7.1. (Previously the value
was queried from the OS but in 7.1 it is set to a fixed 72 dpi). A new routine called MGH_GRAPH_DEFAULT provides defaults for several of MGHgrGraph's properties. In the case of the SCALE and FONTSIZE properties these are version-dependent.

### *2007-11-28*

David Fanning's PROGRAMROOTDIR is no longer used by any of the routines, so is no longer bundled with the libary.

### *2007-06-13*

This version of the library is now being used and developed under IDL 6.4 (but uses few, if any, features from versions later than 6.2).
I fixed a bug in MGHncFile reported by Matthew Savoie: UNLIMITED property incorrect when the first dimension in the file is unlimited.
I cleaned up a lot of broken or non-functional code in the MGH_DGplayer class. It's all working as it should now, I think.

### *2006-05-08*

This version of the library is now being used and developed under IDL 6.3 (however it does not yet include any features specific to that
version). The AVI-writing code in MGH_Player now uses Oleg Kornilov's AVI DLL, called via a class called MGHaviWriteFile. There must be a
copy of the DLL in the Motley library directory.

### *2006-03-10*

Getting ready for another release. Sticky-directory code has been added to the file-saving code for all file types in MGH_Window and MGH_Player.

### *2004-11-08*

I am starting to add “sticky directory” support to the file-saving process. A new system variable, !MGH_PREFS, is now created by MGH_MOTLEY.
It has a tag called “sticky” that specifies if sticky directories are to be enabled. Code is being added to the file-saving code for various
GUIs to change the directory name if necessary. This is all currently in prototype form: it has not been implemented fully and details may change.
Other preferences may be added and I may try to use the IDL 6.1 support for application user directories.

### *2004-08-30*

Removed the MGH_RANDOM_NAME routine in favour of Craig Markwardt’s CMUNIQUE_ID.

### *2004-06-28*

Fixes to MGH_NCDF_SAVE and a new example program, MGH_EXAMPLE_NCSAVE.

### *2004-06-25*

Added a routine called MGH_LOOP, which starts a widget application that executes a widget-processing loop. This allows non-blocking widgets to be used to examine data while execution is stopped at a breakpoint.

### *2004-06-24*

I have implemented and tested a number of IDL 6.1 new features, especially keyboard accelerators, which have proved especially useful for the MGH_animator object.

### *2004-05-14*

This copy of the library now being developed with IDL 6.1.

### *2004-03-18*

Tested recent changes and bundled up a new version.

### *2003-08-19*

With IDL 6.0 having been out for a while, this version of the library has now been published on my WWW site.

### *2003-06-12*

This version of the library makes extensive use of IDL 6.0 features. Latest change is to remove the MGH_FILE_LINES function.

### *2003-05-12*

This version of the library is now being developed under IDL 6.0. First change: delete the MGH_NOT function and start making use of the new logical operators.

### *2003-02-17*

The library now has a publicly accessible home on David Fanning's site.

### *2003-01-12*

Added MGH_NOT, my implementation of the “logical not” operation described in my article on David Fanning’s site

### *2002-12-24*

I finally decided it is rather silly to make all routines in this library backward-incompatible with the STRICTARRSUBS compiler option, so I stripped all occurrences out.

### *2002-12-23*

The library now does a better job of supporting alternative colour-table files. It recognises a routine, MGH_CT_FILE, which returns the name of colour-table files and a system variable, !MGH_CT_FILE, which specifies the user's default. The MGH_GUI_Palette_Editor widget application recognises this variable and requires a modified palette editor, MGH_CW_PALETTE_EDITOR.

### *2002-12-18*

Inspired by a recent discussion on comp.lang.idl-pvwave, I have revised the MGH_TXT_RESTORE function (now much faster) and written a new function, MGH_FILE_LINES, which replaces MGH_N_LINES. MGH_FILE_LINES calls the new FILE_LINES function if applicable, otherwise it achieves the same effect with IDL code.

### *2002-12-10*

I have been preparing the library for release. Support routines have been moved to the same directory as everything else; the only such routine currently included is Liam Gumley's IMDISP, used in example code.

### *2002-11-25*

Installed IDL 5.6 final. The Motley code now makes use of several IDL 5.6 features, notably the STRICTARRSUBS compiler option.

### *2002-10-09*

Testing & developing library under IDL 5.6 beta. Since IDL 5.6 has a PRODUCT routine, all references to Craig Markwardt's CMPRODUCT have been removed.

### *2002-02-01*

I have now access to Linux via a dual-boot arrangement and have been testing out this library on it. Some inappropriate settings in the object graphics applications were discovered and eliminated.

### *2002-01-14*

Having installed XEmacs & IDLWAVE, I have been reformatting the routines in this library as I visit them.

### *2000-10-19*

The MGHgrGLaxis class and the MGH_EXAMPLE_GLAXIS routine, which were pulled from the library a year ago because they didn't work in IDL 5.4, have been reinstated. It seems they worked all along!

### *2001-10-15*

I added a subdirectory called "support" to contain other people's routines that are required by the Motley library. I added Craig Markwardt's CMPRODUCT to this directory then deleted my MGH_PRODUCT and all references to it.

### *2001-09-25*

Library name changed to "Motley". There is now an initialisation procedure called MGH_MOTLEY. It reads in message-block info and sets up a printer. I expect to expand this routine in future.

### *2001-09-01*

This version of the library is now being developed on IDL 5.5 beta. An aggressive (but easily reversible) programme of replacing _EXTRA with _STRICT_EXTRA means it is not backward-compatible. This has caught several bugs! Also note that IDL 5.5 has fixed the keyword precedence bug I identified with inheritance by reference so I am now using this everywhere.

### *2001-07-16*

In the past month I have modified all my GUI code substantially, incorporating the changes mentioned in the previous entry and many others besides. See comments in MGH_GUI_Base.

### *2001-06-14*

Having examined Martin Schultz's GUI objects I am revisiting some of my widget-object code (see MGHwidgetBase). Changes made so far include:
* Allow each widget to specify its own event-handler method by  storing a structure in the UVALUE.
* Change the convention for the return values of event-handler methods. They used to return 1 to indicate that the event has been handled, otherwise 0. Now they follow the convention used by IDL's event-handler functions, i.e. return any non-structure value (conventionally 0) to indicate that the event has been handled, otherwise return a structure (often the original event structure) which can then be handled by other event-handlers.
The latter change introduces a significant backward-incompatibility. I have modified the main graphics display classes—i.e. MGHgrWindow, MGHgrAnimator and MGHgrDatamator—and some but not all of the others. (Actually it seems to break less code than one would expect, possibly because most old-style widget handlers return 1, which indicates completion under both schemes.)

### *2001-05-31*

I added some new time-handling functions, with names beginning with MGH_DT. I am attempting to handle time zones in a rational way but this is turning out to be difficult.

### *2001-05-01*

Following from the previous comment, I have further changed a few classes (MGHgrDensityPlane, MGHgrColorPlane, MGHgrColorPolygon) so that they pass their _EXTRA keywords to the superclass and not to the embedded atom. This has doubtless introduced further bugs, which I am squashing as I find them.

### *2001-03-13*

Discovered and fixed a bug that was uncovered by changes to the MGHgrAnimator class. Many of my composite atom objects (like MGHgrDensityPlane) inherit from IDLgrModel but their GetProperty and SetProperty methods pass _EXTRA keywords to the embedded atom. This was done so that the composite atom could expose as much of the embedded atom's functionality as possible. However it may be unwise. For example in the case of MGHgrDensityPlane objects, code like the following

> odensity->GetProperty, PARENT=parent

was returning a reference to the embedded atom's parent, whereas MGHgrAnimator was expecting (reasonably) that it would return the MGHgrDensityPlane's parent. I have fixed the behaviour of MGHgrDensityPlane & a few other similar classes so that they give the latter behaviour. I note it here because similar pitfalls have bitten me before and probably will do again.

### *2001-01-31*

Mouse-event handling for the MGHgrWindow and MGHgrAnimator classes has been overhauled. The event handers are now objects; the classes defining these objects are now collected in the procedure MGH_MOUSE_HANDLER_LIBRARY.

### *2000-12-15*

Various improvements to the MGHgrAnimator class including the CUMULATIVE and DISPLAY keywords.

### *2000-12-08*

I added the MGHgrImageAnimator class and an example program.

### *2000-11-30*

I added a new function called MGH_STRUCT_BUILD that builds up an anonymous structure from a list of tag names and a pointer array of the same size containing data. I took advantage of this function to rewrite the MGHncFile class's Retrieve method, which becomes much more readable and flexible as a result. I moved my MGH_NCDF_RESTORE and MGH_NCDF_SAVE (which I have used for many years) into the library.

### *2000-11-07*

Copied files to http://katipo.niwa.cri.nz/~hadfield/gust/software/idl/.
IDL 5.3 version moved to http://katipo.niwa.cri.nz/~hadfield/gust/software/idl53/.

### *2000-10-24*

Various minor changes following release of IDL 5.4. The MGHgrGLaxis class and the MGH_EXAMPLE_GLAXIS routine have been pulled from the library because 5.4 final appears to have removed support for subclassing of the (undocumented) IDLgrAxis::Draw method.

### *2000-09-04*

Code-timing routines MGH_TIME_FUNCTION and MGH_TIME_PROCEDURE have been yanked from the library and replaced by the much simpler MGH_TIC and MGH_TOC.

### *2000-08-28*

I have been revisiting keyword precedence. If one can rely on inherited keywords always overriding explicit keywords then one can simplify code and achieve more flexible control of the components of complicated objects (e.g. MGH_Plot). In doing so I discovered what I think is a bug in the implementation of inheritance by reference. See routine MGH_EXAMPLE_KEYWORDS and recent newsgroup discussions. The upshot of this is, I think, that when keywords are used only to pass information into a routine (e.g. a SetProperty or Init method) then value inheritance should always be used, even if this entails some performance cost. I have had a quick run through the code applying this convention.

### *2000-08-14*

Added a couple of date-time routines, MGH_DT_JULDAY and MGH_DT_CALDAT to the library. Added an example using MGHgrGLaxis for date-time plotting.  This example requires IDL 5.4 or later.

### *2000-08-10*

I introduced the MGHgrMSaxis class ("MS" stands for "master-slave"). An axis belonging to the class can keep track of objects (slaves) that have been associated with it and updates the slaves if any of the its relevant properties are changed. The MGHgrGraph classes have been modified so they can use master-slave axes--the default is still not to.  The modifications were surprisingly easy and localised because the graph class already scales atoms to axes when it adds the atoms to the graph.  The purpose of the MS axes is to make it easier to organise modify complex graphs, without having to keep information about associations at the higher levels. I have already used it to good effect in the MGH_Plot class.
In the course of checking library integrity I discovered to my surprise that the PRODUCT routine that I have used here & there is not* a standard IDL routine. I checked around for good PRODUCT routines and eventually created an MGH_PRODUCT based on Craig Markwardt's CMPRODUCT.

### *2000-08-08*

Renamed RefreshWidgets methods throughout the library to UpdateWidgets.  This method reviews and updates widget appearance based on the state of the application. I think the new name reflects this better. The method should not normally be called from outside the object methods so the name change should not cause a problem.
Removed the NewText method from the MGHgrGraph2D and MGHgrGraph2D classes (which therefore now inherit MGHgrGraph::NewText unchanged). The ability to add titles is now provided in a separate method called NewTitle. For rationale see documentation for MGHgrGraph2D or MGHgrGraph2D. This change will cause older codes to put titles in the wrong place.

### *2000-08-04*

Did a bit of cleaning up, eliminating a few routines of doubtful utility and also getting rid of procedure wrappers for graphics objects.

### *2000-08-03*

Pulled out all the date-time (MGHDT...) routines plus related graphics routines pending a rewrite.

### *2000-08-02*

Created this file. The library currently includes 25889 lines of code & comments (but a lot of them are empty!) in 134 .pro files.
I recently did a pretty major restructuring of the graph classes, replacing existing classes MGHgrView, MGHgrGraph, MGHgrFixedGraph & MGHgrGraph3D with MGHgrGraph (similar to the old MGHgrView), MGHgrGraph2D (merges the old MGHgrGraph & MGHgrFixedGraph) and MGHgrGraph3D (similar to the old class of the same name but much of the logic has been moved to the superclass MGHgrGraph). Nevertheless most codes built on the old classes should work fine, once names MGHgrFixedGraph and MGHgrView are replaced by MGHgrGraph2D and MGHgrGraph, respectively.

