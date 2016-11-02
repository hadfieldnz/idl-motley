; svn $Id$
;+
; NAME:
;   MGH_TOC
;
; PURPOSE:
;   MGH_TIC and MGH_TOC operate a global stopwatch. Call MGH_TIC to
;   start the stopwatch and MGH_TOC to stop it and print the elapsed
;   time.
;
; CALLING SEQUENCE:
;   MGH_TIC
;   <Do stuff to be timed here>
;   MGH_TOC
;
; OUTPUTS:
;   MGH_TOC optionally returns the elapsed time as its first
;   argument.
;
; COMMON BLOCKS:
;   MGH_TICTOC_COMMON
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
;   Mark Hadfield, 2000-09:
;     Written.
;   Mark Hadfield, 2000-11:
;     MGH_TIC and MGH_TOC now use an MGH_Stopwatch object.
;   Mark Hadfield, 2005-07:
;     Now reports stopwatch name if applicable.
;-
pro mgh_toc, elapsed

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   common mgh_tictoc_common, owatch

   if ~ obj_valid(owatch) then begin
      message, /INFORM, 'There is no stopwatch object'
      return
   endif

   owatch->GetProperty, ELAPSED=elapsed, NAME=name

   obj_destroy, owatch

   case strlen(name) gt 0 of
      0: msg = 'Elapsed time is '+mgh_format_float(elapsed)
      1: msg = name+': elapsed time is '+mgh_format_float(elapsed)
   endcase

   message, /INFORM, msg

END


