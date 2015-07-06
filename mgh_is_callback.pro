;+
; FUNCTION:
;   MGH_IS_CALLBACK
;
; PURPOSE:
;   This function determines whether a variable represents a widget
;   callback, in the sense used elsewhere in my widget code. The
;   function has been created and given its name to allow clearer
;   event-handling code.
;
; CALLING SEQUENCE:
;   Result = mgh_is_callback(value)
;
; POSITIONAL PARAMETERS:
;   var (input)
;     The variable to be examined.
;
; RETURN VALUE:
;   This function returns 1 if the variable is a single-element
;   MGH_WIDGET_CALLBACK structure, otherwise 0.
;
;###########################################################################
; Copyright (c) 2001 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001=06:
;     Written.
;   Mark Hadfield, 2013-11:
;     Code updated.
;-
function mgh_is_callback, value

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(value) eq 1 then begin
    if size(value, /TYPE) eq 8 then begin
      if tag_names(value, /STRUCTURE_NAME) eq 'MGH_WIDGET_CALLBACK' then begin
        return, 1B
      endif
    endif
  endif

  return, 0B

end


