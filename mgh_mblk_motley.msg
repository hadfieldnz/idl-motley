; Message definition file for message block MGH_MBLK_MOTLEY
;
; This message block can be loaded using
; 
;   define_msgblk_from_file, file_which("mgh_mblk_motley.msg")
;
; and a message can be issued as follows
;
;   message, BLOCK='mgh_mblk_motley', NAME='mgh_m_initfail', 'MySuperClass'
;   message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'var'
;   message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'var'


@IDENT MGH_MBLK_MOTLEY

@PREFIX MGH_M_

@ INITFAIL      "Initialisation of superclass %s failed."

@ OBJREF_BAD    "Object reference %s is invalid"

@ UNDEFVAR      "Variable %s is undefined"

@ MISSINGARG    "Argument %s required for output is not present"

@ WRGNUMELEM    "Variable %s has wrong number of elements"

@ WRGNUMDIM     "Variable %s has wrong number of dimensions"

@ WRGDIMSIZE    "Variable %s has wrong dimensions"

@ MISMATCHARR   "Arrays %s & %s do not match"

@ WRONGTYPE     "Variable %s has incorrect datatype"

@ WRGNUMPARM    "Wrong number of positional parameters: %d"

@ BADINDEX      "Index %d is out of bounds."

@ BADVALUE      "Variable %s has an invalid value"

@ NCDF_NOVAR    "NetCDF variable '%s' not found"

@ UNSUPPORT     "Property %s is unsupported in this context"

@ FILE_NOREAD   "File '%s' cannot be read"



