;+
; NAME:
;   MGH_RECIPROCAL_POSITIVE
;
; PURPOSE:
;   A function like MGH_RECIPROCAL, intended for use with the
;   DATA_TRANSFORMATION keyword of various graphics routines to produce
;   plots of the reciprocal of a variable, but intended specifically
;   to handle (ie. ignore) zeroes or negative values in data
;   that should be positive definite.
;
; CALLING SEQUENCE:
;   result = mgh_reciprocal_positive(value)
;
; POSITIONAL PARAMETERS:
;   value (input, numeric scalar or array)
;     The number(s) whose reciprocal is to be determined.
;
; RETURN VALUE:
;   The reciprocal of the input, with the input clipped at the floating point
;   EPS value.
;
;###########################################################################
; Copyright (c) 2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2014-07:
;     Written.
;-
function mgh_reciprocal_positive, value

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  mac = machar()

  return, 1.0/(value > mac.eps)

end

