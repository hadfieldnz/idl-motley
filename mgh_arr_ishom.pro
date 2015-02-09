; svn $Id$
;+
; ROUTINE NAME:
;   MGH_ARR_ISHOM
;
; PURPOSE:
;   Determine whether an array is homogeneous along a specified dimension.
;
; CATEGORY:
;   Array manipulation.
;
; CALLING SEQUENCE:
;   result = MGH_ARR_ISHOM(arr, dim)
;
; POSITIONAL PARAMETERS:
;   a (input, array)
;     The arr to be tested.
;
;   d (input, integer scalar, optional)
;     The 1-based dimension along which homogeneity is to be
;     tested. Default is 1.
;
; KEYWORD PARAMETERS:
;   TOLERANCE (input, numeric scalar)
;     If this parameter is defined, we test for equality to within the
;     specified tolerance; if it is not we test for exact equality.
;
; RETURN VALUE:
;   The function returns a logical value (byte scalar) indicating
;   whether the array is homogeneous along the specified dimension.
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
;   Mark Hadfield, 2006-02:
;     Written.
;-
function MGH_ARR_ISHOM, a, d, TOLERANCE=tolerance

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(a) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'

   if n_elements(d) eq 0 then d = 1

   n_dims = size(a, /N_DIMENSIONS)

   dims = size(a, /DIMENSIONS)

   if dims[d-1] eq 1 then return, 1B

   ;; Calculate product of all dimensions inside the current one
   inner = 1
   for i=0,d-2 do inner *= dims[i]

   ;; Calculate product of all dimensions outside the current one
   outer = 1
   for i=d,n_dims-1 do outer *= dims[i]

   ;; Generate a copy of array a with 3 dimensions, the middle one
   ;; corresponding to the current dimension, indicated by index d.
   r = reform(a, inner, dims[d-1], outer)

   ;; Work along the required dimension (the middle dimension of r)
   ;; extracting slices and comparing them with the 0'th slice. Return
   ;; 0 immediately if an inhomogeneity is found.

   r0 = r[*,0,*]

   if n_elements(tolerance) gt 0 then begin
      for i=1,dims[d-1]-1 do if max(abs(r[*,i,*]-r0)) gt tolerance then return, 0B
   endif else begin
      for i=1,dims[d-1]-1 do if ~ array_equal(r[*,i,*], r0) then return, 0B
   endelse

   ;; No inhomogeneity detected so return "true"

   return, 1B

end
