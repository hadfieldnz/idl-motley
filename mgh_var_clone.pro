;+
; NAME:
;   MGH_VAR_CLONE
;
; PURPOSE:
;   Given an IDL variable, this function generates and returns a copy. It is
;   therefore handy when passing a variable to a routine and wanting to protect it
;   from modification
;
; CALLING SEQUENCE:
;   result = mgh_var_clone(var)
;
; POSITIONAL ARGUMENTS:
;   var (input, variable of any type):
;     Variable to be copied.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2013-07:
;     Written.
;-
function mgh_var_clone, var

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
   
  result = var 

  return, result
  
end


