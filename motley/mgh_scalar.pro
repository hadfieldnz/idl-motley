;+
; NAME:
;   MGH_SCALAR
;
; PURPOSE:
;   This function converts a one-element array into a scalar.
;
;   Passing a multi-element array results in an error.
;
; CALLING SEQUENCE:
;   result = mgh_scalar(a)
;
; POSITIONAL PARAMETERS:
;   a (input, array of any type)
;     An array representing values on the grid.
;
; RETURN VALUE:
;   The function returns the first (and only) element as a scalar.
;
;###########################################################################
; Copyright (c) 2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2015-01:
;     Written.
;-
function mgh_scalar, a

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  n = n_elements(a)

  if n eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'

  if n gt 1 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'a'

  return, a[0]

end
