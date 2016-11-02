;+
; NAME:
;   MGH_DT_NOW
;
; PURPOSE:
;   This function returns the current date-time.
;
; CATEGORY:
;   Date-time.
;
; CALLING SEQUENCE:
;   Result = MGH_DT_NOW()
;
; PROCEDURE:
;   Just return systime(/JULIAN, /UTC)
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
;   Mark Hadfield, May 2001:
;       Written.
;-
function MGH_DT_NOW

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, systime(/JULIAN, /UTC)

end
