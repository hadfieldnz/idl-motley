; svn $Id$
;+
; NAME:
;   MGH_DT_ZONE
;
; PURPOSE:
;   This function returns the local machine's time zone.
;
; CATEGORY:
;   Date-time.
;
; CALLING SEQUENCE:
;   Result = MGH_DT_ZONE()
;
; RETURN VALUE:
;   The function returns a scalar double-precision value representing
;   the difference between local time and UTC in hours
;
; PROCEDURE:
;   Compare results of systime(/JULIAN) and systime(/JULIAN, /UTC)
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
;   Mark Hadfield, 2001-05:
;     Written.
;-

function MGH_DT_ZONE

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, 24.D0*(systime(/JULIAN) - systime(/JULIAN, /UTC))

end
