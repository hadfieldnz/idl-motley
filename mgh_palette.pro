; svn $Id$
;+
; NAME:
;   MGH_PALETTE
;
; PURPOSE:
;   This function generates and returns a palette object. It is now a
;   wrapper for functionality in MGHgrPalette::Init.
;
; CATEGORY:
;   Graphics, Color Specification.
;
; CALLING SEQUENCE:
;   Result = MGH_PALETTE(Index)
;
; ARGUMENTS:
;   Index (input)
;     A positive integer or name specifying a colour table in file
;     $IDL_DIR/resource/colors/colors1.tbl.
;
; KEYWORDS:
;   All keywords are passed to MGHgrPalette::Init.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the 
;     accuracy of the software, the use to which the software may 
;     be put or the results to be obtained from the use of the 
;     software.  Accordingly NIWA accepts no liability for any loss 
;     or damage (whether direct of indirect) incurred by any person 
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the 
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1998-08:
;     Written.
;   Mark Hadfield, 2001-10:
;     The function now uses only the colour tables pre-defined in
;     colors1.tbl. Code to generate customised colour tables has now
;     been moved to procedure MGH_CUSTOM_CT, which loads these tables
;     into the file.
;   Mark Hadfield, 2001-11:
;     Most of this routine's functionality has now been moved to
;     MGHgrPalette::Init.
;-

function MGH_PALETTE, Index, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(index) eq 0 then index = 0

   return, obj_new('MGHgrPalette', index, _STRICT_EXTRA=extra)

end

