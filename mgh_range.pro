; svn $Id$
;+
; FUNCTION NAME:
;   MGH_RANGE
;
; PURPOSE:
;   This function generates a 1-D array of values between specified limits.
;
; CATEGORY:
;   Array processing.
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
;   Mark Hadfield, 1998-10:
;     Written.
;   Mark Hadfield, 1999-09:
;     Changed STEP keyword to STRIDE
;   Mark Hadfield, 2000-11:
;     Added N_ELEMENTS keyword.
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6.
;   Mark Hadfield, 2004-06:
;     Updated for IDL 6.0.
;   Mark Hadfield, 2006-11:
;     Now accepts a single two-element vector as input.
;-
function mgh_range, start, finish, $
     N_ELEMENTS=n_elements, STRIDE=stride

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(finish) eq 0 && n_elements(start) eq 2 then begin
      s = start[0]
      f = start[1]
   endif else begin
      s = start
      f = finish
   endelse

   if n_elements(stride) eq 0 then begin
      if n_elements(n_elements) eq 1 then begin
         stride = (f-s)/double(n_elements-1)
      endif else begin
         stride = 1
      endelse
   end

   if n_elements(n_elements) eq 0 then $
        n_elements = round((f-s)/stride+1)

   return, s + stride * lindgen(n_elements)

end
