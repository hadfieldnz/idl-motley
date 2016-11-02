;+
; NAME:
;   MGH_Stopwatch
;
; PURPOSE:
;   An MGH_Stopwatch object can be used for keeping track of elapsed time
;   in a lengthy calculation.
;
; CATEGORY:
;   Utilities.
;
; EXPLANATORY NOTE:
;   The resolution of the time recorded by an MGH_Stopwatch object
;   depends on the granularity of the system clock. On my Windows 2000
;   PC with IDL 5.5 this is approximately 0.015 s.
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
;   Mark Hadfield, 2000-11:
;     Written.
;   Mark Hadfield, 2011-08:
;     Now inherits IDL_Object.
;-
function MGH_Stopwatch::Init, NAME=name

   compile_opt DEFINT32
   compile_opt STRICTARR

   self.start = !values.d_nan

   if n_elements(name) gt 0 then self.name = name

   return, 1B

end

pro MGH_Stopwatch::GetProperty, ELAPSED=elapsed, NAME=name, START=start

   compile_opt DEFINT32
   compile_opt STRICTARR

   elapsed = systime(1)-self.start

   name = self.name

   start = self.start

end

pro MGH_Stopwatch::Start

   compile_opt DEFINT32
   compile_opt STRICTARR

   self.start = systime(1)

end

pro MGH_Stopwatch__define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGH_Stopwatch, inherits IDL_Object, start: 0D, name: ''}

end
