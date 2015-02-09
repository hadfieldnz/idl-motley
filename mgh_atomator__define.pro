; svn $Id$
;+
; CLASS:
;   MGH_Atomator
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
;   Mark Hadfield, 2001-07:
;     Written.
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6.
;-

; MGH_Atomator::Init
;
function MGH_Atomator::Init, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self->MGH_Datamator::Init(ANIMATION_CLASS='MGHgrAtomation', $
                                     _STRICT_EXTRA=extra)

end



pro MGH_Atomator__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Atomator, inherits MGH_Datamator}

end


