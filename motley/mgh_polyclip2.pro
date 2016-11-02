;+
; NAME:
;   MGH_POLYCLIP2
;
; PURPOSE:
;   Clip an arbitrary polygon on the X-Y plane to a line of arbitrary
;   orientation using the Sutherland-Hodgman algorithm.
;
; CATEGORY:
;   Graphics, Region of Interest, Geometry
;
; CALLING SEQUENCE:
;   result = MGH_POLYCLIP2(clip, poly, COUNT=count)
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
;   clip (input, 3-element numeric vector)
;     This parameter describes the line to be clipped to. The polygon is
;     clipped to the half-plane (clip[0] x + clip[1] y + clip[2]) < 0.
;
; KEYWORD PARAMETERS
;   COUNT (output, integer)
;     The number of vertices in the clipped polygon.
;
; PROCEDURE:
;   The polygon is clipped using the Sutherland-Hodgman algorithm.
;
;   This function is similar to MGH_POLYCLIP, which was written first
;   & clips to vertical or horizontal lines only. It turns out that
;   MGH_POLYCLIP2 is competitive with MGH_POLYCLIP in terms of speed
;   so the former may supersede the latter.
;
;   Both polygon-clipping functions are based on JD Smith's
;   implementation of the Sutherland-Hodgman algorithm in his POLYCLIP
;   function. He can take most of the credit and none of the blame.
;
;###########################################################################
; Copyright (c) 2002-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-08:
;     Written.
;   Mark Hadfield, 2013-06:
;     - The result array is now allocated before looping through the input
;       vertices, wherease before it was progressively built up by concatenation.
;       This change results in an enormous speed-up for large (> 10,000) polygons.
;-
function mgh_polyclip2, poly, clip, COUNT=count, DOUBLE=double

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(poly) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'poly'

  if size(clip, /N_ELEMENTS) ne 3 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'clip'

  ;; If the polygon argument is a scalar then return -1

  count = 0
  if size(poly, /N_DIMENSIONS) eq 0 then return, -1

  ;; Vector "pp" is the position of each vertex along the
  ;; perpendicular to the clipping line. Vector "ps" is the same for
  ;; the shifted vertices

  pp = reform(clip[0]*poly[0,*]+clip[1]*poly[1,*]+clip[2])
  ps = shift(pp, 1)

  ;; Vector "in" specifies whether each vertex is inside the clipped
  ;; half-plane.  Vector "inx" specifies whether an intersection with
  ;; the clipping line is made by the segment joining each vertex
  ;; with the one before.

  in = pp lt 0
  inx = in xor (ps lt 0)

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
      ap = ps[k]/(ps[k]-pp[k])
      ci = ap*poly[*,k] + (1-ap)*pols[*,k]
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

