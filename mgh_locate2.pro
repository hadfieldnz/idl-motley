;+
; NAME:
;   MGH_LOCATE2
;
; PURPOSE:
;   This function calculates positions in the "index space" of a 2D
;   curvilinear grid.
;
; CALLING SEQUENCE:
;   Result = MGH_LOCATE2(xin, yin)
;
; POSITIONAL PARAMETERS:
;   xin, yin (input, 2-D numeric arrays)
;     X & Y positions of the vertices of the curvilinear input grid.
;
; KEYWORD PARAMETERS:
;   To define the output locations, this function accepts the
;   following keywords and passes them to GRIDDATA: DELTA, DIMENSION,
;   GRID, START, XOUT, YOUT. In addition the following keywords are
;   supported:
;   
;   DOUBLE (input, switch)
;     For double-precision output.
;
;   MISSING (input, numeric scalar)
;     The value to assign to the result for points outside the input grid.
;     The default is NaN.
;
; RETURN_VALUE:
;   The function returns a floating array representing the output
;   locations as fractional indices on the grid represented by the XIN
;   & YIN arrays. The result is dimensioned [2,m] or [2,m,n] where [m]
;   or [m,n] are the dimensions of the output locations.
;
; PROCEDURE:
;   Construct variables representing position in i direction and
;   position in j direction and interpolate with GRIDDATA function
;
; PERFORMANCE
;   I have tested this function using a [439,439] moderately curved
;   input grid (NZ region SST--see MGH_EXAMPLE_LOCATE2). For large
;   output grids (20000 vertices or more) time taken increases linearly
;   @ 16,000 per second on a Pentium 4 2.67 GHz. For smaller output grids
;   time is sub-linear.
;
;   See also MGH_LOCATE2A which has essentially the same functionality
;   but is faster on small output grids.
;
;###########################################################################
; Copyright (c) 2002-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-07:
;     Written.
;   Mark Hadfield, 2015-07:
;     Updated and documentation of keywords completed.
;-
function mgh_locate2, xin, yin, MISSING=missing, $
     DELTA=delta, DIMENSION=dimension, DOUBLE=double, GRID=grid, $
     START=start, XOUT=xout, YOUT=yout

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(grid) eq 0 then grid = 0

  if n_elements(missing) eq 0 then $
    missing = keyword_set(double) ? !values.d_nan : !values.f_nan

  ;; Process input grid. Leave processing of output-grid keywords to
  ;; GRIDDATA below.

  if size(xin, /N_ELEMENTS) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'XIN'
  if size(xin, /N_DIMENSIONS) ne 2 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'XIN'
  if size(yin, /N_ELEMENTS) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'YIN'
  if size(yin, /N_DIMENSIONS) ne 2 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'YIN'

  dim = size(xin, /DIMENSIONS)

  if ~ array_equal(size(yin, /DIMENSIONS), dim) then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'XIN', 'YIN'

  ;; Triangulate data points. Given the simple grid geometry, this
  ;; can be done from first principles. This is much faster than
  ;; using the TRIANGULATE routine.

  triangles = mgh_triangulate_rectangle(dim)

  ;; Construct i-index and j-index variables and interpolate to
  ;; output grid. Handling of output points outside the input grid is
  ;; complicated by a bug in IDL 5.5. it should be possible to set
  ;; them to NaN by setting the MISSING keyword to this value.
  ;; However IDL 5.5's GRIDDATA flags these points as "outside" if
  ;; the grid locations are specified via XOUT and YOUT--see
  ;; procedure MGH_TEST_GRIDDATA_OUTSIDE. So we try to flag outside
  ;; points afterwards. The bug in GRIDDATA is to be fixed in the
  ;; next version of IDL.

  xloc = griddata(xin, yin, mgh_inflate(dim, findgen(dim[0]), 1), $
                  /LINEAR, TRIANGLES=triangles, MISSING=-1, $
                  DELTA=delta, DIMENSION=dimension, GRID=grid, START=start, $
                  XOUT=xout, YOUT=yout)

  yloc = griddata(xin, yin, mgh_inflate(dim, findgen(dim[1]), 2), $
                  /LINEAR, TRIANGLES=triangles, MISSING=-1, $
                  DELTA=delta, DIMENSION=dimension, GRID=grid, START=start, $
                  XOUT=xout, YOUT=yout)

  l_outside = where(xloc lt 0 or xloc gt dim[0]-1 or $
                    yloc lt 0 or yloc gt dim[1]-1, n_outside)
  if n_outside gt 0 then begin
    xloc[l_outside] = missing
    yloc[l_outside] = missing
  endif

  ;; Determine size & dimensions of result. We take these from the
  ;; xloc & yloc arrays, except for the special (but frequent) case
  ;; where the GRID keyword is not set and XOUT & YOUT are
  ;; specified. GRIDDATA always returns a 1-D result in this case
  ;; (whereas I think it should return a result matching XOUT & YOUT
  ;; in shape).

  onum = size(xloc, /N_ELEMENTS)
  odim = size(xloc, /DIMENSIONS)

  if ~ keyword_set(grid) && n_elements(xout) gt 0 then $
    odim = size(xout, /DIMENSIONS)

  ;; Combine and return xloc and yloc arrays.

  result = make_array(DIMENSION=[2,onum], DOUBLE=double)

  result[0,*] = xloc
  result[1,*] = yloc

  return, reform(result, [2,odim], /OVERWRITE)

end
