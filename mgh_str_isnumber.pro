;+
; ROUTINE NAME:
;   MGH_STR_ISNUMBER
;
; PURPOSE:
;   Determine whether a string represents a valid number.
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   result = MGH_STR_ISNUMBER(str)
;
; ARGUMENTS:
;   str (input, string scalar or array)
;     The string to be tested.
;
; KEYWORDS:
;   TYPE (input, numeric scalar)
;     This keyword specifies the numeric data type to which the string
;     is to be converted. It is passed to the FIX function to carry
;     out the conversion. The default is 5 (double). For a list of IDL
;     data types see the documentation for the SIZE function.
;
;   VALUE (output, double)
;     Set this keyword to a named variable to return the value. The
;     data type is as specified by the TYPE keyword. The shape is the
;     same as the input.
;
; RETURN VALUE:
;   The function returns a byte scalar or array with the same
;   shape as the input. The value is 1B if the string has been
;   successfully converted to a number, otherwise 0B.
;
;###########################################################################
; Copyright (c) 2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-05:
;     Written, based on STRNUMBER in the IDL Astronomy Library.
;   Mark Hadfield, 2002-01:
;     Added the TYPE keyword to control the numeric type.
;-
function mgh_str_isnumber, str, TYPE=type, VALUE=value

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(type) eq 0 then type = 5
  
  result = mgh_reproduce(0B, str)
  
  apv = arg_present(value)
  
  if apv then value = mgh_reproduce(fix(0, TYPE=type), str)
  
  for i=0,n_elements(str)-1 do begin
  
    ;; An empty string is a special case: it is accepted by FIX but
    ;; we want to reject it.
    if strlen(str[i]) gt 0 then begin
      on_ioerror, skip
      val = fix(str[i], TYPE=type)
      result[i] = 1B
      skip: on_ioerror, null
      if apv then if result[i] then value[i] = val
    endif
    
  endfor
  
  return, result

 end
