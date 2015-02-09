;+
; NAME:
;   MGH_FORMAT_FLOAT
;
; PURPOSE:
;   This function returns a string representation of an integer
;   numeric value. It is designed for use in widget applications,
;   where one wants an editable value, with no extraneous digits, that
;   can be converted easily back to numeric form.
;
; CALLING SEQUENCE:
;   Result = mgh_format_integer(Value)
;
; POSITIONAL PARAMETERS:
;   Value (input, numeric, scalar or array)
;     The value to be formatted.
;
; RETURN VALUE:
;   The function returns a string with the same shape as the input.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2013-08:
;       Written.
;-
function mgh_format_integer, value, FORMAT=format

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(format) eq 0 then format = '(I0.0)'
  
  result = strtrim(string(round(value), FORMAT=format), 2)
  
  return, result

end

