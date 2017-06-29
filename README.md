# The MGH-Motley IDL Library 

Motley is a library of IDL code written largely by me at NIWA. It is provided to the IDL community under the [MIT Open Source License](http://www.opensource.org/licenses/mit-license.php)

The library is a collection of the routines that I use regularly and that I think might be of interest to others. There are several Object Graphics classes, a base class for widget applications and several applications built on it, functions that make it easy to represent scaled data on axes, classes for accessing netCDF files and several utility routines. You will notice that the names begin with my initials, MGH. This is not egotism (well, OK, just a little) but an attempt to avoid naming conflicts with other software collections. 

This version of the library requires IDL 8.5. It has been developed & tested on Windows 7 and Linux. If it doesn’t work on your platform, I’d love to hear about it. 

I have made no effort to keep the routines in Motley independent of each other, so if you want to use one you're advised to install the lot. The procedure is: 
1.	Download the files to a directory and add it to your IDL path. 
3.	Before using any of the routines in the library in any IDL session, run the initialisation routine with the command "mgh_motley". You may eventually want to add this command to your startup script. 

Generally the Motley library does not require any routines outside the standard IDL library. Occasionally I make exceptions; in this case my policy is to bundle a copy of the required routine in the "external" subdirectory, with permission of the author. I try to keep these bundled routines up to date, but you may want to check the author’s WWW site for a more recent copy. Currently the bundled routines are: 
 *	IMDISP by Liam Gumley, used in an example program. 
 *	CMUNIQUE_ID by Craig Markwardt.

Finally, the library includes a modified form of RSI’s CW_PALETTE_EDITOR. The modified routine is called MGH_CW_PALETTE_EDITOR and is included with permission of RSI, who retain copyright. For a list of the modifications, see the modified source code. 
________________________________________
Mark Hadfield 2017-06-29

