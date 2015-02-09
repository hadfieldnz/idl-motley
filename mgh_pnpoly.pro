;+
; NAME:
;   MGH_PNPOLY
;
; PURPOSE:
;   Determine whether a point or set of points is inside a polygon.
;
; CALLING SEQUENCE:
;   result = mgh_pnpoly(x, y, xp, yp)
;   result = mgh_pnpoly(x, y, xyp)
;
; POSITIONAL PARAMETERS:
;   x, y (input, numeric scalar or array
;     X, Y position(s) defining the point(s) to be tested.
;
;   xp, yp (input, numeric vector)
;   xyp (input, numeric array)
;     The polygon vertices as 2 separate vectors (xp, yp) OR a single
;     [2,n] array.
;
; RETURN_VALUE:
;   The function returns an array of the same shape as X. Each element
;   is 0 if the point is outside the polygon, 1 if it is inside the
;   polygon.  The comp.graphics.algorithms has the following to say
;   about points on the boundary:
;
;       "It returns 1 for strictly interior points, 0 for strictly
;       exterior, and 0 or 1 for points on the boundary.  The boundary
;       behavior is complex but determined; in particular, for a
;       partition of a region into polygons, each point is "in"
;       exactly one polygon. (See p.243 of [O'Rourke (C)] for a
;       discussion of boundary behavior.)"
;
; PROCEDURE:
;   Ray-crossing technique of WR Franklin from
;   Comp.graphics.algorithms FAQ.
;
; REFERENCES:
;    - "Misc Notes - WR Franklin",
;      http://www.ecse.rpi.edu/Homepages/wrf/misc.html: includes a
;      reference (broken @ Jul 2001) to his point-in-polygon code.
;    - Comp.graphics.algorithms FAQ,
;      http://www.faqs.org/faqs/graphics/algorithms-faq/: See subject
;      2.03
;
;###########################################################################
; Copyright (c) 1999-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Fardal, 1999-11:
;     Written as PNPOLY.
;   Mark Fardal, 2001-07:
;     Added header.
;   Mark Hadfield, 2001-07:
;     Renamed MGH_PNPOLY. Output now matches input in shape, not just
;     size.
;   Mark Hadfield, 2009-09:
;     - Changed order of parameters: points to be tested come before
;       polygon.
;     - Polygon can now be specified as a [2,n] array.
;-
function mgh_pnpoly_calculate, x, y, xp, yp

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  compile_opt HIDDEN

  n_pol = n_elements(xp)
  
  if n_pol lt 3 then $
    message, 'Need at least 3 points to define polygon.'
    
  inside = mgh_reproduce(0, x)
  
  j = n_pol-1
  for i=0,n_pol-1 do begin
    betw = where(((yp[i] le y) and (y lt yp[j])) or $
      ((yp[j] le y) and (y lt yp[i])), count)
    if count gt 0 then begin
      invslope = (xp[j]-xp[i]) / (yp[j]-yp[i])
      cond = where((x[betw]-xp[i]) lt invslope * (y[betw]-yp[i]), count)
      if count gt 0 then begin
        incr = betw[cond]
        inside[incr] ++
      endif
    endif
    j = i
  endfor
  
  return, byte(inside mod 2)

end

function mgh_pnpoly, x, y, xp, yp

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(x) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'x'
  if n_elements(y) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'y'
    
  if ~ array_equal(size(x, /DIMENSIONS), size(y, /DIMENSIONS)) then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'x', 'y'
    
  if n_elements(xp) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'xp'
    
  ;; Calculations are carried out in a separate function so that
  ;; temporary arrays are created only when necessary.
  
  xyp2d = size(xp, /N_DIMENSIONS) eq 2
  
  if xyp2d then begin
    if (size(xp, /DIMENSIONS))[0] ne 2 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgdimsize', 'xp'
    return, mgh_pnpoly_calculate(x, y, xp[0,*], xp[1,*])
  endif else begin
    if size(xp, /N_DIMENSIONS) ne 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'xp'
    if n_elements(yp) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'yp'
    if ~ array_equal(size(xp, /DIMENSIONS), size(yp, /DIMENSIONS)) then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'xp', 'yp'
    return, mgh_pnpoly_calculate(x, y, xp, yp)
  endelse

end
