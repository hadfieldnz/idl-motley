;+
; NAME:
;   MGH_POLYCLIP
;
; PURPOSE:
;   Clip an arbitrary polygon on the X-Y plane to a line parallel
;   to the X or Y axis using the Sutherland-Hodgman algorithm.
;
; CATEGORY:
;   Graphics, Region of Interest, Geometry
;
; CALLING SEQUENCE:
;   result = MGH_POLYCLIP(poly, clip, dir, neg, COUNT=count)
;
; RETURN VALUE
;   The function returns the clipped polygon as a [2,n] array. The
;   second dimension will equal the value of the COUNT argument, except
;   where COUNT is 0 in which case the return value is -1.
;
; POSITIONAL ARGUMENTS
;   poly (input, floating array)
;     A [2,m] vector defining the polygon to be clipped.
;
;   cval (input, numeric sclar)
;     The value of X or Y at which clipping is to occur
;
;   dir (input, integer scalar)
;     Specifies whether clipping value is an X (dir = 0) or Y (dir =
;     1) value.
;
;   neg (input, integer scalar)
;     Set this argument to 1 to clip to the negtive side, 0 to clip to
;     the positive side.
;
; KEYWORD PARAMETERS
;   COUNT (output, integer)
;     The number of vertices in the clipped polygon.
;
; PROCEDURE:
;   The polygon is clipped using the Sutherland-Hodgman algorithm.
;
;   This function is based on JD Smith's implementation of the
;   Sutherland-Hodgman algorithm in his POLYCLIP function. He can
;   take all of the credit and none of the blame.
;
;###########################################################################
; Copyright (c) 2001-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-10:
;     Written, based on JD Smith's POLYClIP.
;   Mark Hadfield, 2013-06:
;     - The result array is now allocated before looping through the input
;       vertices, wherease before it was progressively built up by concatenation.
;       This change results in an enormous speed-up for large (> 10,000) polygons.
;     - Order of positional arguments changed (poly is now first) to match
;       MGH_POLYCLIP2.
;-
function mgh_polyclip, poly, cval, dir, neg, COUNT=count, DOUBLE=double

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(poly) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'poly'

  ;; If the polygon argument is a scalar then return -1

  count = 0
  if size(poly, /N_DIMENSIONS) eq 0 then return, -1

  ;; Vector "in" specifies whether each vertex is inside the clipped
  ;; half-plane.  Vector "inx" specifies whether an intersection with
  ;; the clipping line is made by the segment joining each vertex
  ;; with the one before.

  in = neg ? reform(poly[dir,*] lt cval) : reform(poly[dir,*] gt cval)
  inx = in xor shift(in, 1)

  ;; The total number of vertices in the result will be the sum of the
  ;; "in" and "inx" vectors

  count = total(inx, /INTEGER) + total(in, /INTEGER)
  if count eq 0 then return, -1

  ;; We can now allocate the result array

  item = poly[0] * (keyword_set(double) ? 0.0D : 0.0)
  result = replicate(item, 2, count)

  ;; Precalculate an array of shifted vertices, used in calculating
  ;; intersection points in the loop.

  pols = shift(poly, 0, 1)

  ;; Loop thru vertices in the input polygon

  np = n_elements(in)

  n = 0

  for k=0,np-1 do begin

    ;; If this segment crosses the clipping line, add the intersection
    ;; to the output list. I tried calculating the intersection points
    ;; outside the loop in an array operation but it turned out slower.

    if inx[k] then begin
      s0 = pols[0,k]
      s1 = pols[1,k]
      p0 = poly[0,k]
      p1 = poly[1,k]
      case dir of
        0B: ci = [cval,s1+(p1-s1)/(p0-s0)*(cval-s0)]
        1B: ci = [s0+(p0-s0)/(p1-s1)*(cval-s1),cval]
      endcase
      result[*,n] = ci
      n ++
    endif

    ;; If this vertex is inside the clipped half-plane add it to the
    ;; list

    if in[k] then begin
      result[*,n] = poly[*,k]
      n ++
    endif

  endfor

  if n ne count then message, 'WTF?!'

  return, result

end

