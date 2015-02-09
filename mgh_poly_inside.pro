;+
; NAME:
;   MGH_POLY_INSIDE
;
; PURPOSE:
;   Determine whether a point or set of points is inside a polygon.
;
; CALLING SEQUENCE:
;   result = mgh_poly_inside(x, y, xp, yp)
;   result = mgh_poly_inside(x, y, xyp)
;
; POSITIONAL PARAMETERS:
;   x, y (input, numeric scalar or array
;     X, Y position(s) defining the point(s) to be tested.
;
;   xp, yp (input, numeric vector)
;   xyp (input, numeric array)
;     The polygons vertices as 2 separate vectors (xp, yp) OR a single
;     [2,n] array.
;
; KEYWORD PARAMETERS:
;   EDGE (input, switch)
;     Set this keyword to accept edge (& vertex) points as
;     "inside". Default is to reject them. 
;
;   NAN (input, switch)
;     Set this keyword to specify that all points for which X or Y is
;     not finite (eg Nan, Inf) are to return 0.  Default is to process
;     non-finite points, which leads to floating point errors and an
;     undefined result for that point.
;
; RETURN VALUE:
;   The function returns an array of the same shape as X. Each element
;   is 0 if the point is outside the polygon, 1 if it is inside the polygon.
;
; PROCEDURE:
;   This routine calculates the displacement vectors from each point
;   to all the vertices of the polygon and then takes angles between
;   each pair of successive vectors. The sum of the angles is zero for
;   a point outside the polygon, and +/- 2*pi for a point inside. A
;   point on an edge will have one such angle equal to +/- pi. Points
;   on a vertex have a zero displacement vector.
;
; REFERENCES:
;   Note that the question of how to determine whether a point is
;   inside or outside a polygon was discussed on comp.lang.idl-pvwave
;   in October 1999. The following is quoted from a post by Randall
;   Frank <randall-frank@computer.org>:
;
;       I would suggest you read the Graphics FAQ on this issue and
;       also check Graphics Gem (I think volume 1) for a more detailed
;       explanation of this problem.  The upshot is that there really
;       are three core methods and many variants.  In general, you can
;       sum angles, sum signed areas or clip a line.  There are good
;       code examples of all these approaches on the net which can be
;       coded into IDL very quickly.  It also depends on how you
;       intend to use the function.  If, you are going to repeatedly
;       test many points, you are better off using one of the sorted
;       variants of the line clipping techniques.  In general, the
;       line clipping techniques are the fastest on the average, but
;       have poor worst case performance without the sorting overhead.
;       The angle sum is one of the slowest methods unless you can get
;       creative and avoid the transcendentals (and you can).  The
;       area sum approach generally falls in between.  In IDL code, I
;       believe you can vectorize the latter with some setup overhead,
;       making it the fastest for .pro code when testing multiple
;       points with one point per call.
;
;   Further resources:
;    - "Misc Notes - WR Franklin",
;      http://www.ecse.rpi.edu/Homepages/wrf/misc.html: includes a
;      reference (broken @ Jul 2001) to his point-in-polygon code.
;    - Comp.graphics.algorithms FAQ,
;      http://www.faqs.org/faqs/graphics/algorithms-faq/: See subject
;      2.03
;
; SEE ALSO:
;   MGH_PNPOLY, which implements a line-clipping technique and is much
;   faster.
;
; TO DO:
;   Reduce copying of input data by segregating the calculations into a
;   separate function.
;
;###########################################################################
; Copyright (c) 1995-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1995-06:
;     Written based on ideas in MATLAB routine INSIDE.M in the WHOI
;     Oceanography Toolbox v1.4 (R. Pawlowicz, 14 Mar 94,
;     rich@boreas.whoi.edu).
;   Mark Hadfield, 2000-12:
;     Updated.
;   Mark Hadfield, 2001-07:
;     Changed argument order: polygon vertices are now before test
;     position(s).
;   Mark Hadfield, 2009-09:
;     Changed argument order back. Polygon can now be entered as a
;     [2,n] array.
;   Mark Hadfield, 2015-02:
;     Updated source code format.
;-
function mgh_poly_inside, x, y, xp, yp, $
     DOUBLE=double, EDGE_INSIDE=edge, NAN=nan

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
    
  n = n_elements(x)
  
  ;; Make a local copy of the polygon data in seaparate 1D arrays and close arrays
  ;; if necessary.
  
  xyp2d = size(xp, /N_DIMENSIONS) eq 2
  
  if xyp2d then begin
    if (size(xp, /DIMENSIONS))[0] ne 2 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgdimsize', 'xp'
    xpp = reform(xp[0,*])
    ypp = reform(xp[1,*])
  endif else begin
    if size(xp, /N_DIMENSIONS) ne 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'xp'
    if n_elements(yp) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'yp'
    if ~ array_equal(size(xp, /DIMENSIONS), size(yp, /DIMENSIONS)) then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'xp', 'yp'
    xpp = xp
    ypp = yp
  endelse
  
  npp = n_elements(xpp)
  
  if (xpp[npp-1] ne xpp[0]) || (ypp[npp-1] ne ypp[0]) then begin
    xpp = [xpp,xpp[0]]
    ypp = [ypp,ypp[0]]
    npp = npp+1
  endif
  
  if npp lt 4 then $
    message, 'The polygon when closed must have 4 or more vertices'
    
  ;; Copy input data into 1D arrays; if the NaN keyword is set, choose only
  ;; finite points.
  
  xx = x[*]
  yy = y[*]
  
  if keyword_set(nan) then begin
    l_finite = where(finite(xx) and finite(yy), n_finite)
    case n_finite of
      0: return, mgh_reproduce(0, x)
      n:
      else: begin
        xx = xx[l_finite]
        yy = yy[l_finite]
      end
    endcase
  endif
  
  ;; Construct arrays dimensioned (npp,n) holding
  ;; x & y displacements from points to vertices
  
  one = keyword_set(double) ? 1.0D : 1.0
  
  dx = xpp#make_array(n, VALUE=one) - make_array(npp, VALUE=one)#temporary(xx)
  dy = ypp#make_array(n, VALUE=one) - make_array(npp, VALUE=one)#temporary(yy)
  
  ;; Calculate angles. Randall says we could eliminate
  ;; transcendentals here--I wonder how?
  
  angles = (atan(dy,dx))
  angles = angles[1:npp-1,*] - angles[0:npp-2,*]
  
  ;; Force angles into range [-pi,+pi)
  
  oor = where(angles le -!dpi, count)
  if count gt 0 then angles[oor] += 2*!dpi
  oor = where(angles gt !dpi,count)
  if count gt 0 then angles[oor] -= 2*!dpi
  
  ;; The following operation generates an array with value 1
  ;; for each point where angles sum to a non-zero value (inside
  ;; the polygon) and zero elsewhere
  
  inside = round(total(angles/!dpi,1,/DOUBLE)) ne 0
  
  ;; Are any of the points currently considered to be outside
  ;; the polygon actually on an edge or a vertex?
  
  if keyword_set(edge) then begin
    for i=0,n-1 do begin
      if (~ inside[i]) then begin
        dummy = where(angles[*,i] eq -!dpi, count)
        if count gt 0 then begin
          inside[i] = 1
        endif else begin
          dummy = where((abs(dx[*,i])+abs(dy[*,i])) eq 0, count)
          if count gt 0 then inside[i] = 1
        endelse
      endif
    endfor
  endif
  
  ;; Result has same dimensions as input
  result = mgh_reproduce(0B, x)
  
  ;; Load values into result & return
  
  if keyword_set(nan) then begin
    result[l_finite] = inside
  endif else begin
    result[*] = inside
  endelse
  
  return, result

end
