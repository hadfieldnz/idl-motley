; svn $Id$
;+
; CLASS NAME:
;   MGH_Container
;
; PURPOSE:
;   An MGH_Container is a slightly enhanced version of an
;   IDL_Container. It can be set up so that the contained objects are
;   not destroyed with it.
;
; PROPERTIES:
;   DESTROY (Init, Get, Set):
;     Set this keyword to 0 to cause contained objects *not* to be destroyed
;     when container is destroyed.
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
;   Mark Hadfield, 1999-05:
;     Written.
;-

; MGH_Container::Init
;
; Purpose:
;   Initializes an MGH_Container object
;
function MGH_Container::Init, DESTROY=destroy

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDL_Container::Init()
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDL_Container'

   self.destroy = 1B
   if n_elements(destroy) gt 0 then self.destroy = keyword_set(destroy)

   return, 1

end

; MGH_Container::GetProperty
;
pro MGH_Container::GetProperty, DESTROY=destroy

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   destroy = self.destroy

end

; MGH_Container::Cleanup
;
pro MGH_Container::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ self.destroy then begin
      child = self->Get(/ALL, COUNT=n_child)
      for i=0,n_child-1 do $
           if obj_valid(child[i]) then self->Remove, child[i]
   endif

   self->IDL_Container::Cleanup

end

; MGH_Container__Define
;
pro MGH_Container__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Container, inherits IDL_Container, destroy: 0B}

end

