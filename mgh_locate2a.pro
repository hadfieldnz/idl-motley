;+
; NAME:
;   MGH_LOCATE2A
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
;     The default is NaN. This keyword is ignored if the OUTSIDE_NEAREST
;     keyword is set.
;
;   OUTSIDE_NEAREST (input, switch)
;     Set this keyword to return the nearest grid location for points
;     outside the input grid.
;
; RETURN_VALUE:
;   The function returns a floating array representing the output
;   locations as fractional indices on the grid represented by the XIN
;   & YIN arrays. The result is dimensioned [2,m] or [2,m,n] where [m]
;   or [m,n] are the dimensions of the output locations.
;
; PROCEDURE:
;   For each (x,y) pair in turn search for the location in 2D index space
;   where the distance function d(x,y) = (xin-x)^2 + (yin-x)^2 is
;   minimised.
;
; PERFORMANCE
;   I have tested this function using a [439,439] moderately curved
;   input grid (NZ region SST--see MGH_EXAMPLE_LOCATE2). Time taken is
;   linear with number of output points @ 1050 per second on a Pentium
;   4 2.67 GHz.
;
;   See also MGH_LOCATE2 which has essentially the same functionality
;   but is faster on larger output grids.
;
;###########################################################################
; Copyright (c) 2002-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-12:
;     Written.
;   Mark Hadfield, 2015-07:
;     - Updated and documentation of keywords completed.
;     - Added OUTSIdE_NEAREST functionality.
;-
function mgh_locate2a_evaluate, p

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   common mgh_locate2a_common, $
        cxin, cyin, cxval, cyval, cxmiss, cymiss , cxrange, cyrange

   ;; Evaluate x & y variables at point p. Out-of-bounds
   ;; points are set to MISSING values.

   xx = interpolate(cxin, p[0], p[1], MISSING=cxmiss)
   yy = interpolate(cyin, p[0], p[1], MISSING=cymiss)

   ;; I tried hand-coding the interpolation because I thought it might
   ;; be faster than INTERPOLATE, given that we want a result at one
   ;; point only. But it turns out to be slower by a factor of ~1.6.

   ;; Return a distance function. I also tried abs(dx)+abs(dy).  This
   ;; is evaluated faster than dx^2+dy^2 but the lack of smoothness
   ;; slows down the minimisation.

   return, ((xx-cxval)/cxrange)^2 + ((yy-cyval)/cyrange)^2

end

function mgh_locate2a, xin, yin, $
     DELTA=delta, DIMENSION=dimension, GRID=grid, START=start, XOUT=xout, YOUT=yout, $
     DOUBLE=double, ITERATIONS=iterations, MISSING=missing, OUTSIDE_NEAREST=outside_nearest

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  common mgh_locate2a_common, $
    cxin, cyin, cxval, cyval, cxmiss, cymiss , cxrange, cyrange

  if n_elements(missing) eq 0 then $
    missing = keyword_set(double) ? !values.d_nan : !values.f_nan

  ;; Process input grid

  if size(xin, /N_DIMENSIONS) ne 2 then message, 'XIN must be 2D'
  if size(yin, /N_DIMENSIONS) ne 2 then message, 'YIN must be 2D'

  dims = size(xin, /DIMENSIONS)

  if max(abs(size(yin, /DIMENSIONS) - dims)) gt 0 then $
    message, 'XIN and YIN do not match'

  ;; Abbreviations for input grid dimensions

  n0 = dims[0]  &  n1 = dims[1]

  ;; Process output-grid keywords and set up result array

  if n_elements(xout)*n_elements(yout) gt 0 then begin

    if keyword_set(grid) then begin
      xx = xout # mgh_reproduce(1,yout)
      yy = mgh_reproduce(1,xout) # yout
      nout = n_elements(xout)*n_elements(yout)
      dout = [n_elements(xout),n_elements(yout)]
    endif else begin
      xx = xout
      yy = yout
      nout = n_elements(xx)
      dout = [nout]
    endelse

  endif else begin

    if n_elements(dimension) eq 0 then dimension = 51
    if n_elements(start) eq 0 then start = [min(xin),min(yin)]
    if n_elements(delta) eq 0 then $
         delta = [max(xin)-min(xin),max(yin)-min(yin)]/(dimension-1)

    if n_elements(dimension) eq 1 then dimension = [dimension,dimension]
    if n_elements(start) eq 1 then start = [start,start]
    if n_elements(delta) eq 1 then delta = [delta,delta]

    xx = start[0]+delta[0]*lindgen(dimension[0]) # replicate(1,dimension[1])
    yy = replicate(1,dimension[0]) # start[1]+delta[1]*lindgen(dimension[1])

    nout = dimension[0]*dimension[1]
    dout = dimension

  endelse

  ;; Set up result array. Make sure it is (at least) single-precision
  ;; floating point

  result = replicate(1.*missing, 2, nout)

  ;; Load grid data into common block arrays

  cxin = xin
  cyin = yin

  ;; Specify missing values for the interpolation function
  ;; These are set well outside the range of real X & Y values to
  ;; discourage the minimiser from seeking a minimum outside the domain.

  cxmiss = 1000*max(xin) - 999*min(xin)
  cymiss = 1000*max(yin) - 999*min(yin)

  ;; Calculate numbers specifying the sizes of the grid
  ;; in the x & y dimensions. These is included in the distance
  ;; function to ensure x & y distances are more or less evenly weighted.

  cxrange = abs(max(xin)-min(xin))
  cyrange = abs(max(yin)-min(yin))

  ;; Set up X & Y arrays describing the grid perimeter

  xper = [ xin[0:n0-2,0], $
           reform(xin[n0-1,0:n1-2]), $
           reverse(xin[1:n0-1,n1-1]), $
           reverse(reform(xin[0,*])) ]
  yper = [ yin[0:n0-2,0], $
           reform(yin[n0-1,0:n1-2]), $
           reverse(yin[1:n0-1,n1-1]), $
           reverse(reform(yin[0,*])) ]

  if arg_present(iterations) then iterations = lonarr(num)

  ;; Process one output point at a time

  for i=0,nout-1 do begin

    if ~ keyword_set(outside_nearest) && ~ mgh_poly_inside(xx[i], yy[i], xper, yper, /EDGE) then continue

    ;; Load current position into common block

    cxval = xx[i]
    cyval = yy[i]

    ;; The starting point for the minimisation is saved
    ;; between loop iterations, on the assumption that consecutive
    ;; points are likely to be close to each other. The initial value is near
    ;; the middle of the domain

    if n_elements(p) eq 0 then p = float(dims)/2

    ;; Starting direction:

    xi = [[1,0],[0,1]]

    ;; Minimize using Powell's procedure (function POWELL). I also
    ;; tried a couple of other methods:
    ;;   * Minimising using the AMOEBA function (much slower and
    ;;   less reliable) .
    ;;   * Brute force: evaluating the distance to each (x,y) at
    ;;   every point on the grid then taking the minimum in the
    ;;   resulting array (also slower).

    powell, p, xi, 1.0E-5, fmin, 'mgh_locate2a_evaluate', DOUBLE=double, ITER=it

    result[0,i] = p

    if arg_present(iterations) then iterations[i] = it

  endfor

  return, reform(result, [2,dout])

end
