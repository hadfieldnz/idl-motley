;+
; NAME:
;   MGH_ELLIPSE
;
; PURPOSE:
;   Return the (x,y) vertex positions of a polyline approximating
;   an ellipse, given the semi-major axis, eccentricity and inclination
;   (mathematical convention)
;
; CALLING SEQUENCE:
;   result = MGH_ELLIPSE(sma, ecc, inc, N_VERTEX=n_vertex)
;
; RETURN VALUE
;   The function returns the vertex positions in an array dimensioned
;   [2,n_vertex,n_ellipse]
;
; POSITIONAL ARGUMENTS
;   sma (input, numeric scalar or vector)
;   ecc (input, numeric scalar or vector)
;   inc (input, numeric scalar or vector)
;     Ellipse parameters: semi-major axis, eccentricity and inclination.
;
; KEYWORD PARAMETERS
;   N_VERTEX (input, integer)
;     The number of vertices defining each ellipse. The default is 49, with
;     the first and last vertices coinciding.
;
; PROCEDURE:
;   Simple trigonometry.
;
;###########################################################################
; Copyright (c) 2001-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-01:
;     Written, based on JD Smith's POLYClIP.
;-
function mgh_ellipse, sma, ecc, inc, N_VERTEX=n_vertex

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(sma) eq 0 then sma = 1
   if n_elements(ecc) eq 0 then ecc = 1
   if n_elements(inc) eq 0 then inc = 0

   if n_elements(vertex) eq 0 then n_vertex = 49

   n_ellipse = n_elements(sma)

   if n_elements(ecc) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'ecc'
   if n_elements(inc) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'inc'

   result = dblarr(2, n_vertex, n_ellipse)

   cj = dcomplex(0, 1)

   ang = mgh_range(0, 2*!const.pi, N_ELEMENTS=n_vertex)

   for i_ellipse=0,n_ellipse-1 do begin

      ;; Lay out an ellipse on the complex plane, with the specified eccentricity
      ;; and with the semi-major axis along the x axis. Note that tidal ellipses have
      ;; an implied direction of rotation, determined by the sign of the eccentricity.
      ;; I think that a positive eccentricity implies counter-clockwise rotation,
      ;; which is consistent with the following.
      xy = complex(sma[i_ellipse]*cos(ang), sma[i_ellipse]*ecc[i_ellipse]*sin(ang))

      ;; Rotate it so that the semi-major axis has the specified inclination
      xy *= exp(cj*inc[i_ellipse])

      ;; Load xy data into the result
      result[0,*,i_ellipse] = real_part(xy)
      result[1,*,i_ellipse] = imaginary(xy)

      mgh_undefine, xy

   endfor

   return, result

end

