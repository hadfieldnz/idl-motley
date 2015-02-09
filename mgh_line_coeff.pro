;+
; NAME:
;   MGH_LINE_COEFF
;
; DESCRIPTION:
;    Given a pair of points in an X-Y plane, return the coefficients
;    of the equation ax + by + c = 0 defining a line through the
;    points.
;
;    This is a utility function used in describing polygon-clipping
;    operations. See MGH_POLYFILLG.
;
; CALLING SEQUENCE:
;    result = mgh_mgh_line_coeff(x0, y0, x1, y1)
;
; POSITiONAL PARAMETERS:
;   x0,y0,x1,y1 (input, numeric scalar)
;     Coordinates of points (x0,y0) and (x1,y1)
;
; RETURN VALUE:
;    The function returns a 3-element numeric vector containing the
;    coefficients of the line. The sign of the coefficents is such
;    that quantity s = (ax + by + c) increases to the right of the
;    vector (x0,y0) -> (x1,y1)
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2002-08:
;      Written
;    Mark Hadfield, 2015-02:
;      - Moved to Motley library, where it should have been all along.
;      - Source code updated/
;-
function mgh_line_coeff, x0, y0, x1, y1

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  
  if x1 eq x0 then begin
    m = (x1-x0)/(y1-y0)
    return, [1,-m,m*y0-x0] * (y1 gt y0 ? 1 : -1)
  endif else begin
    m = (y1-y0)/(x1-x0)
    return, [-m,1,m*x0-y0] * (x1 gt x0 ? -1 : 1)
  endelse

end

