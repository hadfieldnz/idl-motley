;+
; NAME:
;   MGH_SUBSET2
;
; PURPOSE:
;   Given a polygonal region (defined by a list of vertices in X & Y) and
;   a curvilinear grid (defined by 2-D position arrays X & Y), this
;   function returns the range of indices for the grid lines that intersect
;   the region
;
; CALLING SEQUENCE:
;   result = mgh_subset2(x, y, xp, yp)
;   result = mgh_subset2(x, y, xyp)
;
; POSITIONAL PARAMETERS:
;   x, y (input, numeric 2-D array
;     X, Y position(s) defining the polygon. Interpretation
;     depends on the setting of the RECTANGLE keyword.
;
;   xp, yp (input, numeric vector)
;   xyp (input, numeric array)
;     The polygon vertices as 2 separate vectors (xp, yp) OR a single
;     [2,n] array. Note that polygon vectors for the perimeter of
;     a rectangular region can be constructed with the MGH_PERIM function.
;
; KEYWORD PARAMETERS:
;   EMPTY (output, logical scalar)
;     Set this keyword to a named variable to return a logical value
;     indicating whether the range is empty. If the EMPTY parameter
;     is not present, and the range is actually empty, then an error
;     message is issued.
;
;   HALO (input, scalar integer)
;     Set this keyword to specify the number of extra rows and columns (if
;     available) to be included in the output range.
;
; RETURN_VALUE:
;   The function returns a 4-element integer vector representing the range
;   of indices in the 1st dimension then the second dimension.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2009-09:
;     Written.
;-
function mgh_subset2, x, y, xp, yp, EMPTY=empty, HALO=halo

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   
   if n_elements(x) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'x'
   if n_elements(y) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'y'

   if size(x, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'x'
   if size(y, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'y'

   if ~ array_equal(size(x, /DIMENSIONS), size(y, /DIMENSIONS)) then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'x', 'y'
        
   if n_elements(halo) eq 0 then halo = 0

   ;; Checking of the xp and yp parameters is left to the MGH_PNPOLY function 
   
   inside = mgh_pnpoly(x, y, xp, yp)
   
   if max(inside) eq 0 then begin
      if arg_present(empty) then begin
         empty = 1B
         return, -1
      endif else begin
         message, /INFORM, 'Range is empty'
      endelse
   endif
   
   ;; Locate first and last columns with at least one point inside the polygon
   
   irange = mgh_minmax(where(max(inside, DIMENSION=2)))
   jrange = mgh_minmax(where(max(inside, DIMENSION=1)))
   
   if halo gt 0 then begin

      dim = size(x, /DIMENSIONS)
   
      irange[0] = irange[0] - halo > 0
      irange[1] = irange[1] + halo < (dim[0]-1)
   
      jrange[0] = jrange[0] - halo > 0
      jrange[1] = jrange[1] + halo < (dim[1]-1)
   
   endif

   return, [irange,jrange]

end
