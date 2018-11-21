;+
; NAME:
;   MGH_GMT_NEARNEIGHBOR
;
; DESCRIPTION:
;    Invoke the GMT nearneighbor utility to generate gridded values from
;    irregularly spaced data, see...
;
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/man/nearneighbor.html
;
;    The grid is rectilinear and uniformly spaced and is defined
;    by a combination of the conventional DELTA, DIMENSION and START
;    keywords, as used by GRIDDATA.  The grid is gridline registered,
;    see...
;
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/GMT_Docs/node184.html
;
; CALLING SEQUENCE:
;    result = mgh_gmt_nearneighbor(x, y, z)
;
; POSITiONAL PARAMETERS:
;   x,y (input, numeric vector)
;     Horizontal position
;
;   z (input, numeric vector)
;     Horizontal position
;
; KEYWORD PARAMETERS:
;    DELTA (input, 1 or 2-element numeric vector)
;      Grid spacing in the X & Y directions.
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
;    XOUT, YOUT (output, numeric arrays)
;      Grid vertex positions.
;
;    PIXEL (input, switch)
;      Set this keyword for pixel registration.
;
;    SEARCH_RADIUS (input, numeric scalar)
;      Search radius in the same units as grid spacing. Default is sqrt(product(DELTA))
;
;    VERBOSE (input, switch)
;      Set this keyword for verbose output.
;
; RETURN VALUE:
;    The function returns a 2D array containing the gridded.
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2011-07:
;      Written
;-
function mgh_gmt_nearneighbor, x, y, z, $
     DELTA=delta, DIMENSION=dimension, START=start, $
     PIXEL=pixel, SEARCH_RADIUS=search_radius, VERBOSE=verbose, XOUT=xout, YOUT=yout

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n_data = n_elements(x)

   if n_elements(y) ne n_data then $
        message, 'Input vectors do not agree'

   if n_elements(z) ne n_data then $
        message, 'Input vectors do not agree'

   ;; Generate the output grid

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

   ;; Calculate limits

   my_limit = [my_start[0],my_start[0]+my_delta[0]*(my_dimension[0]-1), $
               my_start[1],my_start[1]+my_delta[1]*(my_dimension[1]-1)]

   if n_elements(search_radius) eq 0 then search_radius = 20*sqrt(product(my_delta))

   ;; Base name for temporary files

   base = filepath('mgh_gmt_nearneighbor_'+cmunique_id(), /TMP)

   ;; Write data in XYZ format

   openw, lun, base+'.xyz', /GET_LUN
   for i=0,n_elements(x)-1 do $
         printf, FORMAT='(%"%0.10f %0.10f %0.10f")', lun, x[i], y[i], z[i]
   free_lun, lun

   ;; Generate a gridded surface

   cmd = 'nearneighbor '
   if keyword_set(verbose) then $
        cmd += '-V '
   if keyword_set(pixel) then $
        cmd += '-F '
   fmt = '(%"%s.xyz -R%0.10f/%0.10f/%0.10f/%0.10f ' + $
         '-I%0.10f/%0.10f -S%0.10f -G%s.grd")'
   cmd += string(FORMAT=fmt, base, my_limit, my_delta, search_radius, base)
   if !version.os_family eq 'Windows' then begin
      spawn, LOG_OUTPUT=1, cmd
   endif else begin
      spawn, cmd
   endelse

   file_delete, base+'.xyz'

   ;; Retrieve the gridded surface & return the results

   grd = mgh_ncdf_restore(base+'.grd')

   file_delete, base+'.grd'

   if arg_present(xout) then xout = grd.x
   if arg_present(yout) then yout = grd.y

   return, grd.z

end
