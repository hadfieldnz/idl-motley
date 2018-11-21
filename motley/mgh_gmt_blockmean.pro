;+
; NAME:
;   MGH_GMT_BLOCKMEAN
;
; DESCRIPTION:
;    Invoke the GMT blockmean utility to generate gridded values from
;    irregularly spaced data, see...
;
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/man/blockmean.html
;
;    The grid is rectilinear and uniformly spaced and is defined
;    by a combination of the conventional DELTA, DIMENSION and START
;    keywords, as used by GRIDDATA.  The default grid registration is
;    gridline, see...
;
;      http://gmt.soest.hawaii.edu/gmt/doc/gmt/html/GMT_Docs/node184.html
;
; CALLING SEQUENCE:
;    result = mgh_gmt_blockmean(x, y, z, w)
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
;      Grid spacing in the X & Y directions.
;
;    DIMENSION (input, 1 or 2-element integer vector)
;      Grid dimensions (number of vertices) in the X & Y
;      directions. This keyword, along with DELTA and START, can be
;      used to define uniformly spaced rectilinear grids.
;
;    PIXEL (input, switch)
;      Set this keyword for pixel registration.
;
;    START (input, 1 or 2-element numeric vector)
;      Grid origin in the X & Y directions. This keyword, along with
;      DELTA and DIMENSION, can be used to define uniformly spaced
;      rectilinear grids.
;
;    VERBOSE (input, switch)
;      Set this keyword for verbose output from the GMT command.
;
; RETURN VALUE:
;    The function returns a [3,n] array containing the filtered
;    (x,y,z) data.
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2011-07:
;      Written
;    Mark Hadfield, 2018-01:
;      The GMT blockmean command is now invoked as "gmt blockmean" rather
;      then "blockmean" as required by recent versions of GMT.
;-
;-
function mgh_gmt_blockmean, x, y, z, w, $
     DELTA=delta, DIMENSION=dimension, START=start, $
     COUNT=count, PIXEL=pixel, VERBOSE=verbose

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

   ;; Generate the grid

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

   ;; Temporary file names

   base = filepath('mgh_gmt_blockmean_'+cmunique_id(), /TMP)

   file_in = base+'.xyz'
   file_out = base+'_filtered.xyz'

   ;; Write data in XYZ[W] format

   openw, lun, file_in, /GET_LUN
   if use_weight then begin
      for i=0,n_elements(x)-1 do $
            printf, FORMAT='(%"%0.8f %0.8f %0.6f %0.6f")', lun, x[i], y[i], z[i], w[i]
   endif else begin
      for i=0,n_elements(x)-1 do $
            printf, FORMAT='(%"%0.8f %0.8f %0.6f")', lun, x[i], y[i], z[i]
   endelse
   free_lun, lun

   ;; Construct and run the GMT command

   cmd = 'gmt blockmean '
   if keyword_set(pixel) then $
        cmd += '-F '
   if keyword_set(verbose) then $
        cmd += '-V '
   if use_weight then $
        cmd += '-Wi '
   fmt = '(%"%s -R%0.10f/%0.10f/%0.10f/%0.10f -I%0.10f/%0.10f > %s")'
   cmd += string(FORMAT=fmt, file_in, my_limit, my_delta, file_out)
;   message, /INFORM, 'Executing command: '+cmd
   if !version.os_family eq 'Windows' then begin
      spawn, LOG_OUTPUT=1, cmd
   endif else begin
      spawn, cmd
   endelse

   file_delete, file_in

   ;; Retrieve the filtered data and return the results

   count = mgh_n_lines(file_out)

   if count eq 0 then return, -1

   result = dblarr(3, count)

   openr, lun, file_out, /GET_LUN
   xyz = dblarr(3)
   for i=0,count-1 do begin
      readf, lun, xyz
      result[*,i] = xyz
   endfor
   free_lun, lun

   file_delete, file_out

   return, result

end
