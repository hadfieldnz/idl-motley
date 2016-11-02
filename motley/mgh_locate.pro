;+
; NAME:
;   MGH_LOCATE
;
; PURPOSE:
;   This function calculates translates positions in physical space into
;   the "index space" of a 1D vector.
;
; CALLING SEQUENCE:
;   Result = MGH_LOCATE(xin)
;
; POSITIONAL PARAMETERS:
;   xin (input, 1-D numeric array)
;     X positions of the vertices of the input grid. The X values
;     should be monotonic (if not, results will be unpredictable);
;     they need not be uniform.
;
; KEYWORD PARAMETERS:
;   The following keywords define the locations in physical space of
;   the output grid, cf. the GRIDDATA routine: DELTA, DIMENSION, START, XOUT.
;
;   In addition:
;     EXTRAPOLATE (input, switch)
;       Set this keyword to cause output locations outside the
;       range of input values to be determined by extrapolation.
;
;     MISSING (input, numeric scalar)
;       Value used for locations outside the range of input
;       values. Ignored if the EXTRAPOLATE keyword is set.
;       Default is NaN.
;
;     SPLINE (input, switch)
;       Set this keyword to use spline interpolation; default is linear.
;       Setting both the SPLINE and EXTRAPOLATE keywords together
;       causes an error.
;
; RETURN_VALUE:
;   The function returns a double-precision, floating array representing the
;   output location as fractional indices on the grid represented by
;   XIN. The result has the same dimensions as the output locations.
;
; PROCEDURE:
;   Construct variable representing position in i direction &
;   interpolate.
;
;###########################################################################
; Copyright (c) 2002-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-07:
;     Written.
;   Mark Hadfield, 2003-01:
;     Now calls IDL library routine INTERPOL instead of MGH_INTERPOL.
;   Mark Hadfield, 2004-03:
;     Added SPLINE keyword.
;   Mark Hadfield, 2015-06:
;     The result is now always in double precision.
;-
function mgh_locate, xin, $
     EXTRAPOLATE=extrapolate, MISSING=missing, SPLINE=spline, $
     DELTA=delta, DIMENSION=dimension, START=start, XOUT=xout

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(extrapolate) eq 0 then extrapolate = 0B

  if n_elements(missing) eq 0 then missing = !values.d_nan

  if n_elements(spline) eq 0 then spline = 0B

  if keyword_set(spline) && keyword_set(extrapolate) then $
    message, 'Extrapolation is unsafe with spline interpolation'

  ;; Process input grid.

  if size(xin, /N_ELEMENTS) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'xin'

  if size(xin, /N_DIMENSIONS) ne 1 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'xin'

  ;; Process output grid

  if n_elements(xout) eq 0 then begin
    if n_elements(dimension) eq 0 then dimension = 51
    if n_elements(start) eq 0 then start = min(xin)
    if n_elements(delta) eq 0 then $
      delta = (max(xin)-min(xin))/double(dimension-1)
    xx = start + delta*lindgen(dimension)
  endif else begin
    xx = xout
  endelse

  n_in = n_elements(xin)

  result = interpol(dindgen(n_in), xin, xx, SPLINE=spline)

  if ~ keyword_set(extrapolate) then begin
    l_outside = where(result lt 0 or result gt (n_in-1), n_outside)
    if n_outside gt 0 then result[l_outside] = missing
  endif

  return, result

end
