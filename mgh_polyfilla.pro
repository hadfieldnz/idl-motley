;+
; NAME:
;   MGH_POLYFILLA
;
; DESCRIPTION:
;    Given a 2-D polygon and a rectangular grid, this function returns
;    an array indicating which of the pixels in the grid is inside the
;    polygon.
;    
;    See also MGH_POLYFILLG.
;
; CALLING SEQUENCE:
;    result = mgh_polyfilla(x, y, sx, sy[, FRACTION=fraction][, PACK=1|0])
;
; POSITiONAL PARAMETERS:
;   x,y (input, numeric vectors)
;     Vectors defining the polygon in the "subscript space" of the
;     grid.
;
;    sx,sy (input, integer scalars)
;      Dimensions of the pixel grid on which the polygon is
;      superposed.
;
; KEYWORD PARAMETERS:
;    FRACTION (output, floating array)
;      For each pixel index, return the fractional area of that
;      pixel contained inside the polygon, between 0 and 1. This
;      parameter has the same shape as the return values
;
;    COUNT (output, sclar integer)
;      The number of pixels inside the polygon.
;
;    PACK (input, switch)
;      Determines the form in which the results are returned. If PACK
;      is 0, the return value is a byte array of dimensions [sx,sy]
;      specifying whether each pixel is inside the polygon. If PACK is
;      1 (default), the return value is an integer array containing
;      the 1-D indices of all pixels
;
; RETURN VALUE:
;    The function determines which pixels are (at least partially)
;    inside the polygon. The form of the return value depends on the
;    setting of the PACK switch.
;
;###########################################################################
; Copyright (c) 2001-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2001-10:
;      Written, based on JD Smith's POLYFILLAA function.
;    Mark Hadfield, 2015-02:
;      Source code format updated.
;-
function mgh_polyfilla, x, y, sx, sy, $
  FRACTION=fraction, COUNT=count, PACK=pack

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(pack) eq 0 then pack = 1B
  
  ;; Calculate loop bounds
  
  i0 = floor(min(x,max=maxx)) > 0
  i1 = ceil(maxx) < (sx-1)
  
  j0 = floor(min(y,max=maxy)) > 0
  j1 = ceil(maxy) < (sy-1)
  
  ap = arg_present(fraction)
  
  mask = bytarr(sx,sy)
  fraction = fltarr(sx,sy)
  
  pol = [transpose(x),transpose(y)]
  
  for j=j0,j1 do begin
    for i=i0,i1 do begin
      pc = pol
      pc = mgh_polyclip(pc, i, 0, 0, COUNT=n_vert)
      if n_vert eq 0 then continue
      pc = mgh_polyclip(pc, i+1, 0, 1, COUNT=n_vert)
      if n_vert eq 0 then continue
      pc = mgh_polyclip(pc, j, 1, 0, COUNT=n_vert)
      if n_vert eq 0 then continue
      pc = mgh_polyclip(pc, j+1, 1, 1, COUNT=n_vert)
      if n_vert eq 0 then continue
      mask[i,j] = 1B
      if ap then begin
        px = reform(pc[0,*])
        py = reform(pc[1,*])
        fraction[i,j] = 0.5*abs(total(px*shift(py,-1) - py*shift(px,-1)))
      endif
    endfor
  endfor
  
  if keyword_set(pack) then begin
    indices = where(temporary(mask), count)
    fraction = count gt 0 ? fraction[indices] : -1
    return, indices
  endif else begin
    if arg_present(count) then void = where(mask, count)
    return, mask
  endelse
  
end
