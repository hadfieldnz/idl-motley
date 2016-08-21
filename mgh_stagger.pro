;+
; NAME:
;   MGH_STAGGER
;
; PURPOSE:
;   This function is designed to be used for calculations on staggered
;   rectangular grids of arbitrary dimension. It interpolates or
;   extrapolates scalar values between cell centres, faces and vertices.
;
; CATEGORY:
;   Finite-differnce grids.
;
; CALLING SEQUENCE:
;   Result = MGH_STAGGER(X, DELTA=delta])
;
; POSITIONAL PARAMETERS:
;   X (input, numeric array)
;     An array representing values on the grid.
;
; KEYWORD PARAMETERS:
;   DELTA (input, integer scalar or vector)
;     An integer specifying the amount by which each dimension is to
;     be contracted or expanded. If DELTA is scalar, the same
;     expansion/contraction is applied to every dimension. If DELTA is
;     a vector, the number of elements must be greater than or equal to the
;     number of dimensions in the input (greater being permitted to allow
;     for omitted trailing unit dimensions).
;
; RETURN VALUE:
;   The function returns a numeric array of floating, double or
;   complex type, with each dimension in the input unchanged or
;   expanded/contracted according to the corresponding element in
;   DELTA.
;
; PROCEDURE:
;   Linear interpolation & extrapolation.
;
; PERFORMANCE:
;   Time is propertional to number of elements and number of dimensions.
;   On my Pentium 3 800 MHz machine, MGH_STAGGER times for a 2D 1-million
;   element array are:
;
;       DELTA       Time (s)
;         -2         0.19
;         -1         0.61
;          0         0.06
;          1         0.88
;          2         0.29
;
; TO DO:
;   Generalise so that DELTA can take any integer value?
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
;   Mark Hadfield, 1998-09:
;     Written for a single dimension only.
;   Mark Hadfield, 2000-12:
;     Extended to multiple dimensions.
;   Mark Hadfield, 2002-02:
;     Fixed bug: expanding a dimension of size 2 gives wrong
;     answers.
;   Mark Hadfield, 2002-06:
;     * DELTA can now take values in the range [-2,2].
;     * Now allowing scalar DELTA to apply to all dimensions
;   Mark Hadfield, 2002-07:
;     Speeded code up by removing [*] subscripts from
;     LHS of assignments. This improves speed by 25-50 % where
;     applicable but readability suffers a bit.
;   Mark Hadfield, 2002-08:
;     DELTA now allowed to have more elements than the number of
;     dimensions in the input.
;   Mark Hadfield, 2007-02:
;     Computations are now in double precision. I should really do
;     this in a more flexible way!
;-
function mgh_stagger, a, DELTA=delta

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(a) eq 0 then message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'

   n_dims = size(a, /N_DIMENSIONS)
   dims = size(a, /DIMENSIONS)

   ;; Process DELTA parameter--local variable name is del.

   del = n_elements(delta) gt 0 ? delta : 0

   if size(del, /N_DIMENSIONS) eq 0 then del = replicate(del, n_dims)

   if size(del, /N_ELEMENTS) lt n_dims then $
      message, 'The DELTA keyword must have one element for each dimension in the input array'

   ;; Array r will (after some resizing and reshaping) be returned as
   ;; the result. Initially copy the input values into it. Multiply by
   ;; 1. to promote it to (at least) floating point.

   r = 1.*a

   ;; Go through dimensions in turn

   for d=0,n_dims-1 do begin

      if del[d] ne 0 then begin

         if dims[d] eq 1 then $
              message, 'Cannot expand or contract a unit dimension'

         ;; Calculate product of all dimensions inside the current one
         inner = 1
         for i=0,d-1 do inner *= (dims[i]+del[i])

         ;; Calculate product of all dimensions outside the current one
         outer = 1
         for i=d+1,n_dims-1 do outer *= dims[i]

         ;; Reform r so that it has three dimensions, with the middle one
         ;; corresponding to the current dimension, indicated by index d.
         r = reform(r, inner, dims[d], outer, /OVERWRITE)

         case del[d] of

            -2: begin
               ;; Contract dimension by 2
               r = r[*,1:dims[d]-2,*]
            end

            -1: begin
               ;; Contract dimension by 1 with linear interpolation
               r = 0.5D0*r[*,0:dims[d]-2,*] + 0.5D0*r[*,1:dims[d]-1,*]
            end

            1: begin
               ;; Create a temporary array with the current dimension
               ;; increased by 1
               rnew = replicate(r[0], inner, dims[d]+1, outer)
               ;; Set interior values of output with linear interpolation
               rnew[0,1,0] = 0.5D0*r[*,0:dims[d]-2,*] + 0.5D0*r[*,1:dims[d]-1,*]
               ;; Extrapolate end points
               rnew[0,0,0] = 1.5D0*r[*,0,*] - 0.5D0*r[*,1,*]
               rnew[0,dims[d],0] = 1.5D0*r[*,dims[d]-1,*] - 0.5D0*r[*,dims[d]-2,*]
               ;; Replace r with the temporary array.
               r = temporary(rnew)
            end

            2: begin
               ;; Create a temporary array with the current dimension
               ;; increased by 2
               rnew = replicate(r[0], inner, dims[d]+2, outer)
               ;; Set interior values of output
               rnew[0,1,0] = r
               ;; Extrapolate end points
               rnew[0,0,0] = 2*r[*,0,*] - r[*,1,*]
               rnew[0,dims[d]+1,0] = 2*r[*,dims[d]-1,*] - r[*,dims[d]-2,*]
               ;; Replace r with the temporary array.
               r = temporary(rnew)
            end

         endcase

      endif

   endfor

   ;; Reform & return r

   return, reform(r, dims+del, /OVERWRITE)

end
