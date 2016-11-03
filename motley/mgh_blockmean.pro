;+
; NAME:
;   MGH_BLOCKMEAN
;
; DESCRIPTION:
;    Given (x,y,z) data--where x & y are vectors representing position
;    on a 2D plane and z is a matching vector representing a scalar
;    value at each position--and a 2D rectilinear or curvilinear grid,
;    this function filters the input data and returns a reduced set of
;    (x,y,z) values, where locations lying within the same grid cell
;    have been combined into an average.
;
;    This function is inspired by the GMT blockmean command:
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/man/blockmean.html
;
;    The grid is defined by a combination of the conventional DELTA,
;    DIMENSION, START, XOUT and YOUT keywords (as used by GRIDDATA,
;    except that the GRID keyword is omitted here because it can be
;    inferred from the dimensionality of XOUT and YOUT). In the
;    present case these define the positions of the cell vertices
;    and the averaging is done over the cells, i.e we are using
;    pixel node registration:
;      http://gmt.soest.hawaii.edu/gmt/html/GMT_Docs.html#x1-188000B.2.2
;
;###########################################################################
; Copyright (c) 2011 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; CALLING SEQUENCE:
;    result = mgh_blockmean(x, y, z, w)
;
; POSITiONAL PARAMETERS:
;   x,y (input, numeric vector)
;     Horizontal position of data.
;
;   z (input, numeric vector)
;     Horizontal position
;
;   w (input, numeric vector, optional)
;     Weights for weighted averaging
;
; KEYWORD PARAMETERS:
;    COUNT (output, integer scalar)
;      Number of output values.
;
;    DELTA (input, 1 or 2-element numeric vector)
;      Grid spacing in the X & Y directions. This keyword, along with
;      DIMENSION and START, can be used to define uniformly spaced
;      rectilinear grids.
;
;    DIMENSION (input, 1 or 2-element integer vector)
;      Grid dimensions (number of vertices) in the X & Y
;      directions. This keyword, along with DELTA and START, can be
;      used to define uniformly spaced rectilinear grids.
;
;    START (input, 1 or 2-element numeric vector)
;      Grid origin in the X & Y directions. This keyword, along with
;      DELTA and DIMENSION, can be used to define uniformly spaced
;      rectilinear grids.
;
;    XOUT, YOUT (input, 1-D or 2-D numeric arrays)
;      Grid vertex positions, allowing grids with non-uniform spacing
;      and curvilinear grids.
;
; RETURN VALUE:
;    The function returns a [3,n] array containing the filtered
;    (x,y,z) data. Note that the order of the original data will
;    be lost.
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2011-07:
;      Written
;-
function mgh_blockmean, x, y, z, w, $
     DELTA=delta, DIMENSION=dimension, START=start, $
     COUNT=count, XOUT=xout, YOUT=yout

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n_data = n_elements(x)

   if n_elements(y) ne n_data then $
        message, 'Input vectors do not agree'

   if n_elements(z) ne n_data then $
        message, 'Input vectors do not agree'

   use_weight = n_elements(w) gt 0

   if use_weight && n_elements(w) ne n_data then $
        message, 'Input vectors do not agree'

   ;; Generate the output grid and locate each data point within it

   if n_elements(xout)*n_elements(yout) eq 0 then begin

      ;; Rectilinear grid with uniform spacing

      my_dimension = $
           n_elements(dimension) gt 0 ? dimension : 26
      my_start = $
           n_elements(start) gt 0 ? start : [min(x),min(y)]
      my_delta = $
           n_elements(delta) gt 0 $
           ? delta $
           : ([max(x),max(y)]-my_start)/double(my_dimension-1)

      if n_elements(my_dimension) eq 1 then my_dimension = [my_dimension,my_dimension]
      if n_elements(my_start) eq 1 then my_start = [my_start,my_start]
      if n_elements(my_delta) eq 1 then my_delta = [my_delta,my_delta]

      ;; Calculate location with simple arithmetic

      xx = (x-my_start[0])/double(my_delta[0])
      yy = (y-my_start[1])/double(my_delta[1])

      mgh_undefine, my_start, my_delta

   endif else begin

      ndx = size(xout, /N_DIMENSIONS)
      ndy = size(yout, /N_DIMENSIONS)

      if ndx ne ndy then message, 'X & Y output grids do not agree'

      xy2d = (ndx eq 2)

      if xy2d then begin

         ;; Curvilinear grid

         dimx = size(xout, /DIMENSIONS)
         dimy = size(yout, /DIMENSIONS)

         if ~ array_equal(dimx, dimy) then $
              message, 'X & Y output grids do not agree'

         my_dimension = dimx

         loc = mgh_locate2(x, y, XOUT=xout, YOUT=yout)
         xx = reform(loc[0,*])
         yy = reform(loc[1,*])
         mgh_undefine, loc

      endif else begin

         ;; Rectilinear grid with possibly non-uniform spacing

         my_dimension = [ndx,ndy]

         xx = mgh_locate2(x, XOUT=xout)
         yy = mgh_locate2(y, XOUT=yout)

      endelse

   endelse

   ;; In all cases we now have the grid dimensions (my_dimension) and
   ;; the (floating-point) position of each data point in the grid's
   ;; index space (xx & yy)

   ;; Round down the grid-relative position, selecting only points inside
   ;; the area bounded by the grid. Points on the right-hand and top
   ;; edges of the grid area are rejected, as they are (apparently)
   ;; by GMT's blockmean.

   ii = replicate(-1, n_data)
   l = where(xx ge 0 and xx lt my_dimension[0]-1, n)
   if n gt 0 then $
        ii[l] = floor(xx[l])

   jj = replicate(-1, n_data)
   l = where(yy ge 0 and yy lt my_dimension[1]-1, n)
   if n gt 0 then $
        jj[l] = floor(yy[l])

   mgh_undefine, l, n

   ;; Work through cells, accumulating data

   x_sum = dblarr([my_dimension-1])
   y_sum = dblarr([my_dimension-1])
   z_sum = dblarr([my_dimension-1])
   w_sum = dblarr([my_dimension-1])

   for d=0,n_data-1 do begin
      if ii[d] ge 0 && jj[d] ge 0 then begin
         ww = use_weight ? w[d] : 1
         x_sum[ii[d],jj[d]] += ww*x[d]
         y_sum[ii[d],jj[d]] += ww*y[d]
         z_sum[ii[d],jj[d]] += ww*z[d]
         w_sum[ii[d],jj[d]] += ww
      endif
   endfor

   ;; Select non-empty cells and return results. Sometimes I am in awe
   ;; of my own cleverness!

   l_full = where(w_sum gt 0, count)

   if count eq 0 then return, -1

   return, transpose([[reform(x_sum[l_full]/w_sum[l_full], count)], $
                      [reform(y_sum[l_full]/w_sum[l_full], count)], $
                      [reform(z_sum[l_full]/w_sum[l_full], count)]])

end
