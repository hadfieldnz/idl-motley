;+
; NAME:
;   MGH_GMT_SURFACE
;
; DESCRIPTION:
;    Invoke the GMT surface utility to generate gridded values from
;    irregularly spaced data, see...
;
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/man/surface.html
;
;    The grid is rectilinear and uniformly spaced and is defined
;    by a combination of the conventional DELTA, DIMENSION and START
;    keywords, as used by GRIDDATA.  The grid is gridline registered,
;    see...
;
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/GMT_Docs/node184.html
;
; CALLING SEQUENCE:
;    result = mgh_gmt_surface(x, y, z)
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
;    MULTIPLE (input, scalar integer)
;      Grid dimensions used in interpolation are forced to be 1 plus a multiple
;      of this value. Default is 16.
;
;    START (input, 1 or 2-element numeric vector)
;      Grid origin in the X & Y directions. This keyword, along with
;      DELTA and DIMENSION, can be used to define uniformly spaced
;      rectilinear grids.
;
;    TENSION (input, numeric scalar)
;      The tension factor, in the range 0 to 1. A value of 0 gives true
;      minimum curvature surface interpolation.
;
;    XOUT, YOUT (output, numeric arrays)
;      Grid vertex positions.
;
; RETURN VALUE:
;    The function returns a 2D array containing the filtered
;    (x,y,z) data.
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2011-07:
;      Written
;    Mark Hadfield, 2012-10:
;      Added MULTIPLE keyword so that ad-hoc adjustment of output
;      dimensions by the caller is no longer needed.
;    Mark Hadfield, 2018-01:
;      The GMT surface command is now invoked as "gmt surface" rather
;      then "surface" as required by recent versions of GMT.
;-
function mgh_gmt_surface, x, y, z, $
     DELTA=delta, DIMENSION=dimension, MULTIPLE=multiple, $
     START=start, TENSION=tension, VERBOSE=verbose, $
     XOUT=xout, YOUT=yout

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n_data = n_elements(x)

   if n_elements(y) ne n_data then $
        message, 'Input vectors do not agree'

   if n_elements(z) ne n_data then $
        message, 'Input vectors do not agree'

   ;; Process keywords

   if n_elements(multiple) eq 0 then multiple = 16

   if n_elements(tension) eq 0 then tension = 0

   if tension lt 0 || tension gt 1 then $
        message, 'Invalid tension value'

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

   ;; ...I think I've got that right!
   my_dimension_pad = 1+multiple*(1+(my_dimension-2)/multiple)

   my_limit = [my_start[0],my_start[0]+my_delta[0]*(my_dimension_pad[0]-1), $
               my_start[1],my_start[1]+my_delta[1]*(my_dimension_pad[1]-1)]

   ;; Base name for temporary files

   base = filepath('mgh_gmt_surface_'+cmunique_id(), /TMP)

   ;; Write data in XYZ format

   openw, lun, base+'.xyz', /GET_LUN
   for i=0,n_elements(x)-1 do $
         printf, FORMAT='(%"%0.10f %0.10f %0.10f")', lun, x[i], y[i], z[i]
   free_lun, lun

   ;; Generate a gridded surface

   cmd = 'gmt surface '
   if keyword_set(verbose) then $
        cmd += '-V '
   fmt = '(%"%s.xyz -T%0.2f -R%0.10f/%0.10f/%0.10f/%0.10f ' + $
         '-I%0.10f/%0.10f -G%s.grd")'
   cmd += string(FORMAT=fmt, base, tension, my_limit, my_delta, base)
   if !version.os_family eq 'Windows' then begin
      spawn, LOG_OUTPUT=1, cmd
   endif else begin
      spawn, cmd
   endelse

   file_delete, base+'.xyz'

   ;; Retrieve the gridded surface data from the netCDF file & return
   ;; the results

   onc = obj_new('MGHncREadFile', base+'.grd')

   if arg_present(xout) then begin
      xout = onc->VarGet('x')
      xout = xout[0:my_dimension[0]-1,0:my_dimension[1]-1]
   endif
   if arg_present(yout) then begin
      yout = onc->VarGet('y')
      yout = yout[0:my_dimension[0]-1,0:my_dimension[1]-1]
   endif

   zout = onc->VarGet('z')
   zout = zout[0:my_dimension[0]-1,0:my_dimension[1]-1]

   obj_destroy, onc

   file_delete, base+'.grd'

   return, zout

end
