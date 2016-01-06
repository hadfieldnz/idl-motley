;+
; NAME:
;   MGH_UV_ROTATE
;
; PURPOSE:
;   Given a complex array of 2 or more dimensions representing velocity data
;   (real axis = u, imaginary axis = v)  and a scalar or 2-D array representing an
;   angle, rotate the velocity data through the specified angle.
;
;   This routine has been written to simplify code for handling velocities on the ROMS
;   grid.
;
; CALLING SEQUENCE:
;   mgh_uv_rotate, uv, angle
;
; POSITIONAL PARAMETERS:
;   uv (input/output, complex array)
;     The velocity data, modified on output.
;
;   angle (input, numeric array or scalar)
;     The angle through which the velocity data are to be rotated.
;
;###########################################################################
; Copyright (c) 2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-01:
;     Written
;-
pro mgh_uv_rotate, uv, angle

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(uv) eq 0 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'uv'

  if n_elements(angle) eq 0 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'angle'

   n_dim = size(uv, /N_DIMENSIONS)
   dim = size(uv, /DIMENSIONS)

   n_dim_angle = size(angle, /N_DIMENSIONS)
   dim_angle = size(angle, /DIMENSIONS)

   ;; The angle argument can be a scalar or an array matching uv in its first
   ;; two dimensions.

   if n_dim_angle gt 0 && ~ array_equal(dim[0:1], dim_angle) then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'uv', angle

   ;; OK, that's the hard stuff done so do the rotation

   cj = complex(0,1)

   n = n_elements(uv)/(dim[0]*dim[1])
   if n gt 1 then $
      uv = reform(uv, [dim[0:1],n], /OVERWRITE)
   for i=0,n-1 do $
      uv[*,*,i] *= exp(cj*angle)
   if n gt 1 then $
      uv = reform(uv, dim, /OVERWRITE)

end
