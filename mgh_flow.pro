; svn $Id$
;+
; NAME:
;   MGH_FLOW
;
; PURPOSE:
;   This is an IDL implementation of the Matlab "flow" function. It is
;   useful as a test dataset for 3D interpolation and visualisation
;   code.
;
;   The result of the function is alleged to represent "the speed
;   profile of a submerged jet within a infinite tank (Fluid
;   Mechanics, Landau & Lifshitz)", but it is not clear to me what
;   physical situation it represents. The return value of the function
;   is in fact the logarithm of a velocity. The field is radially
;   symmetric about the x axis there is a cone of low values
;   (near-zero speed hence large negative logarithm) with half-angle
;   about the x axis of 15^deg or so. This tends not to be
;   well-sampled on a rectangular grid.
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
;   Mark Hadfield, Dec 2000:
;     Written, based on the Matlab flow function..
;-

function MGH_FLOW, X, Y, Z, N_GRID=n_grid

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; If any position arrays are missing then provide defaults

   if n_elements(x)*n_elements(y)*n_elements(z) eq 0 then begin

      if n_elements(n_grid) eq 0 then n_grid = 25

      ;; 1-D position arrays

      x1 = mgh_range(0.1,10,n_elements=2*n_grid)
      y1 = mgh_range(-3,3,n_elements=n_grid)
      z1 = mgh_range(-3,3,n_elements=n_grid)

      ;; 3-D position arrays

      x = rebin(x1, 2*n_grid, n_grid, n_grid)
      y = rebin(reform(y1,1,n_grid), 2*n_grid, n_grid, n_grid)
      z = rebin(reform(z1,1,1,n_grid), 2*n_grid, n_grid, n_grid)

   endif

   ;; Dimensions of result. For now assume these are the same as dimensions
   ;; of one of the position arrays.

   n_dims = size(x, /N_DIMENSIONS)
   dims = size(x, /DIMENSIONS)

   ;; Convert from rectangular to spherical coordinates, with
   ;; North Pole (phi = pi/2) along the x axis.

   scoord = cv_coord(FROM_RECT=transpose([[y[*]],[z[*]],[x[*]]]), /TO_SPHERE)

   th = scoord[0,*]             ; Longitude
   phi = scoord[1,*]            ; Latitude
   r = scoord[2,*]              ; Radius

   ;; These look like velocity components in spherical coordinates

   a = 2.  &  nu = 1.

   vth = mgh_reproduce(0.,x)
   vphi = -2.*nu*sin(phi)/((a-cos(phi))*r)
   vr = 2.*(nu/r)*((a^2-1.)/(a-cos(phi))^2-1.)

   ;; Transform back to rectangular coordinates. Does this make sense?

   rcoord = cv_coord(FROM_SPHERE=transpose([[vth[*]],[vphi[*]],[vr[*]]]), $
                     /TO_RECT)

   ;; Return log of speed.

   result = alog(sqrt(rcoord[0,*]^2 + rcoord[1,*]^2 + rcoord[2,*]^2))

   if n_dims gt 0 then result = reform(result, dims)

   return, result

end
