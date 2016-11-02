;+
; NAME:
;   MGH_UV_ROTATE
;
; PURPOSE:
;   Given a complex array representing velocity data (real axis = u, imaginary
;   axis = v) and a scalar or array of lower dimensionality representing an
;   angle, where the dimensions of the angle correspond to the inner dimensions
;   of the velocity, rotate the velocity data through the specified angle.
;
;   This routine has been written to simplify code for handling velocities on the ROMS
;   grid.
;
; CALLING SEQUENCE:
;   mgh_uv_rotate, uv, angle
;
; POSITIONAL PARAMETERS:
;   uv (input/output, complex array)
;     The velocity data, modified on output. Must be complex.
;
;   angle (input, numeric array or scalar, optional)
;     The angle through which the velocity data are to be rotated. Default
;     is 0. The number of dimensions must currently be nor more than 2, but
;     this limitation could be relaxed with some simple additions to the code.
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

   ;; Because the rotation is done in situ, we cannot rely on promotion
   ;; of real data.
   if ~ (isa(uv, 'COMPLEX') || isa(uv, 'DCOMPLEX')) then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgtype', 'uv'

   if n_elements(angle) eq 0 then angle = 0

   dim = size(uv, /DIMENSIONS)

   n_dim_angle = size(angle, /N_DIMENSIONS)
   dim_angle = size(angle, /DIMENSIONS)

   cj = complex(0, 1)

   case n_dim_angle of

      0: uv *= exp(cj*angle)

      1: begin

         if ~ array_equal(dim[0], dim_angle) then $
            message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'uv', angle

         n = n_elements(uv)/(dim[0])
         if n gt 1 then $
            uv = reform(uv, [dim[0],n], /OVERWRITE)
         for i=0,n-1 do $
            uv[*,*,i] *= exp(cj*angle)
         if n gt 1 then $
            uv = reform(uv, dim, /OVERWRITE)

      end

      2: begin

         if ~ array_equal(dim[0:1], dim_angle) then $
            message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'uv', angle

         n = n_elements(uv)/(dim[0]*dim[1])
         if n gt 1 then $
            uv = reform(uv, [dim[0:1],n], /OVERWRITE)
         for i=0,n-1 do $
            uv[*,*,i] *= exp(cj*angle)
         if n gt 1 then $
            uv = reform(uv, dim, /OVERWRITE)

      end

   endcase

end
