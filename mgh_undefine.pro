; svn $Id$
;+
; NAME:
;   MGH_UNDEFINE
;
; PURPOSE:
;   This procedure causes any variable specified in its list of
;   positional parameters to become undefined
;
; CALLING SEQUENCE:
;   MGH_UNDEFINE, P1, P2, etc.
;
; POSITIONAL PARAMETERS:
;   P1 etc:
;     Each variable passed as a positional parameter becomes undefined
;     on exit.
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
;   Mark Hadfield, 1999-12:
;     Written based on ideas from David Fanning and Andrew Cool.
;-
pro MGH_UNDEFINE, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if arg_present(P1) then if n_elements(P1) gt 0 then $
        void = size(temporary(P1))
   if arg_present(P2) then if n_elements(P2) gt 0 then $
        void = size(temporary(P2))
   if arg_present(P3) then if n_elements(P3) gt 0 then $
        void = size(temporary(P3))
   if arg_present(P4) then if n_elements(P4) gt 0 then $
        void = size(temporary(P4))
   if arg_present(P5) then if n_elements(P5) gt 0 then $
        void = size(temporary(P5))
   if arg_present(P6) then if n_elements(P6) gt 0 then $
        void = size(temporary(P6))
   if arg_present(P7) then if n_elements(P7) gt 0 then $
        void = size(temporary(P7))
   if arg_present(P8) then if n_elements(P8) gt 0 then $
        void = size(temporary(P8))
   if arg_present(P9) then if n_elements(P9) gt 0 then $
        void = size(temporary(P9))
   if arg_present(P10) then if n_elements(P10) gt 0 then $
        void = size(temporary(P10))

end
