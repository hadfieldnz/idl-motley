; svn $Id$
;+
; ROUTINE NAME:
;   MGH_STR_ISWHITE
;
; PURPOSE:
;   Determine whether a string contains only "white" characters (ASCII
;   < 32).
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   result = MGH_STR_ISWHITE(str)
;
; ARGUMENTS:
;   str (input, scalar or array string)
;     The string to be tested.
;
; RETURN VALUE:
;   The function returns a byte scalar or array with the same
;   shape as the input. The value is 1B if the string contains only
;   "white" characters, otherwise 0B.
;
; PROCEDURE:
;   Convert to a byte array and search for elements > 32B.
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
;   Mark Hadfield, Mar 1994:
;     Written as STR_ISWHITE.
;   Mark Hadfield, Oct 1999:
;     Renamed MGH_STR_ISWHITE.
;-
function MGH_STR_ISWHITE, str

   compile_opt DEFINT32
   compile_opt STRICTARR

   result = mgh_reproduce(0B,str)

   for i=0,n_elements(str)-1 do $
     result[i] = total(byte(str[i]) gt 32B) eq 0

   return, result

end
