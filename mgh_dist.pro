; svn $Id$
;+
; NAME:
;   MGH_DIST
;
; PURPOSE:
;   I use the IDL DIST function a lot for testing 2-D plotting
;   routines, but it irritates me severely that it is not
;   symmetrical. Here's a similar function that is.
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
;   Mark Hadfield, Sep 1999:
;       Written.
;-
function MGH_DIST, N, M

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      1: orig = dist(N-1)
      2: orig = dist(N-1, M-1)
   endcase

   dim = size(orig, /DIMENSIONS)

   result = fltarr(dim[0]+1,dim[1]+1)

   result[0,0] = orig

   result[dim[0],0] = result[0,*]
   result[0,dim[1]] = result[*,0]

   return, result

end


