; svn $Id$
;+
; NAME:
;   MGH_TRIANGULATE_RECTANGLE
;
; PURPOSE:
;   This function returns a triangulation for a 2D rectangular grid.
;
; CALLING SEQUENCE:
;   Result = MGH_TRIANGULATE_RECTANGLE(dims)
;
; POSITIONAL PARAMETERS:
;   dims (input, 2-element integer vector)
;     Dimensions of the grid. Minimum value for each element is 2.
;
; KEYWORD PARAMETERS:
;   POLYGONS (input, switch)
;     Set this keyword to return a polygon-descriptor array as
;     required by an IDLgrPolygon object. Default is to return a
;     list of triangles as required by GRIDDATA.
;
; RETURN_VALUE:
;   The function returns a long integer array. Dimensions are
;   [4,2*(m-1)*(n-1)] if the POLYGONS keyword is set and
;   [3,2*(m-1)*(n-1)] if it is not, where [m,n] are the input
;   dimensions.
;
; PERFORMANCE:
;   Approx linear with number of vertices @ 10^6 vertices per second
;   on Pentium 3 800 MHz.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-07:
;     Written.
;   Mark Hadfield, 2008-04:
;     For the case of polygon-descriptor output (POLYGONS keyword set), the
;     output is no longer reformed to one dimension, as this is unnecessary.
;   Mark Hadfield, 2010-07:
;     Assignment of values to the POLYGON output now uses explicit index ranges
;     for greater clarity.
;-
function mgh_triangulate_rectangle, dims, POLYGONs=polygons

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(dims) ne 2 then $
        message, 'Argument dims must have 2 elements'

   if min(dims) lt 2 then $
        message, 'Argument dims must be 2 or more in both directions'

   m = dims[0]
   n = dims[1]

   ;; Create vertex array. Dimensions correspond to:
   ;;   0: Number of vertices in triangle (3)
   ;;   1: Number of triangles in each cell (2)
   ;;   2: Number of cells in each row (m-1)
   ;;   3: Number of rows (n-1)

   triangles = lonarr(3, 2, m-1, n-1)

   ;; Loop over rows. It is not difficult to unroll this loop, but
   ;; it turns out to be faster not to.

   for j=0,n-2 do begin

      ;; Calculate l0, the index of the vertices at the lower left
      ;; corner of each cell in this row.

      l0 = j*m + lindgen(1,1,m-1)

      ;; Each triangle must be counterclockwise for use by GRIDDDATA

      triangles[0,0,0,j] = l0
      triangles[1,0,0,j] = l0 + 1
      triangles[2,0,0,j] = l0 + m
      triangles[0,1,0,j] = l0 + 1
      triangles[1,1,0,j] = l0 + m + 1
      triangles[2,1,0,j] = l0 + m

   endfor

   ;; Rearrange result into required form & return.

   triangles = reform(triangles, 3, 2*(m-1)*(n-1), /OVERWRITE)

   case keyword_set(polygons) of

      0: return, triangles

      1: begin

         poly = lonarr(4, 2*(m-1)*(n-1))

         poly[0,*] = 3
         poly[1:3,*] = temporary(triangles)

         return, poly

      end

   endcase

end
