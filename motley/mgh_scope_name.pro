;+
; NAME:
;   MGH_SCOPE_NAME
;
; PURPOSE:
;   This function parses the output of SCOPE_TRACEBACK to
;   determine the name of the function/procedure from whichit was called.
;
; CALLING SEQUENCE:
;   result = mgh_scope_name(array)
;
; RETURN VALUE:
;   The function returns a string scalar with the caller's name.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-08:
;     Written.
;-
function mgh_scope_name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   info = scope_traceback()

   return, (strsplit(info[-2], /EXTRACT))[0]

end

