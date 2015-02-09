;+
; NAME:
;   MGH_RECIPrOCAL
;
; PURPOSE:
;   This function is designed for use with the DATA_TRANSFORMaTION
;   keyword of various graphics routines. Given a numeric value, it
;   returns the reciprocal, or multiplicative inverse.
;
; CALLING SEQUENCE:
;   result = mgh_reciprocal(value)
;
; POSITIONAL PARAMETERS:
;   value (input, numeric scalar or array)
;     The number(s) whose reciprocal is to be determined.
;
; RETURN VALUE:
;   I don't think I really need to spell it out.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2014-07:
;     Written.
;-
function mgh_reciprocal, value

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  
  my_val = double(value)
  
  l_zero = where(my_val eq 0, n_zero)
  if n_zero gt 0 then begin
    mac = machar(/DOUBLE)
    my_val[l_zero] = mac.eps
  endif
  
  return, 1/my_val

end

