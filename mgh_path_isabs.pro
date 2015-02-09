; svn $Id$
;+
; ROUTINE NAME:
;   MGH_PATH_ISABS
;
; PURPOSE:
;   Determine whether a name represents an absolute path on the
;   current OS.
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   result = MGH_PATH_ISABS(str)
;
; ARGUMENTS:
;   str (input, scalar or array string)
;     The string to be tested.
;
; RETURN VALUE:
;   The function returns a byte scalar or array with the same
;   shape as the input. The value is 1B if the string represents an
;   absolute path, otherwise 0B.
;
; PROCEDURE:
;   On Windows the functions tests whether the string starts with
;   '?\:' or '\\'. On Unix it tests for a leading '/'.
;
; RESTRICTIONS:
;   Works on Windows and Unix only. It shouldn't be too hard to extend
;   it for other OS families.
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
;   Mark Hadfield, 2002-01:
;     Written.
;-
function MGH_PATH_ISABS, str

   compile_opt DEFINT32
   compile_opt STRICTARR

   result = mgh_reproduce(0B,str)

   sep = path_sep()

   for i=0,n_elements(str)-1 do begin

      case !version.os_family of

         'Windows': result[i] = $
           strmid(str[i],1,2) eq ':'+sep or strmid(str[i],0,2) eq sep+sep

         else: result[i] = strmid(str[i],0,1) eq sep

      endcase

   endfor

   return, result

end
