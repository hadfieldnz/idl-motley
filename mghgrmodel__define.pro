; svn $Id$
;+
; CLASS NAME:
;   MGHgrModel
;
; PURPOSE:
;   An MGHgrModel is an IDLgrModel that keeps track of axes that have
;   been added to it.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   IDLgrModel.
;
; METHODS:
;   In addition to those inherited from IDLgrModel:
;
;     AddAxis
;       Add an object to the axes container.
;
;     GetAxis
;       Get axis references from the axes container.
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
;     Written
;   Mark Hadfield, 2004-07:
;     Minor updates.
;-

; MGHgrModel::Init

function MGHgrModel::Init, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.axes = obj_new('MGH_Container')

   return, self->IDLgrModel::Init(_STRICT_EXTRA=extra)

end

; MGHgrModel::Cleanup
;
pro MGHgrModel::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.axes

   self->IDLgrModel::Cleanup

end


; MGHgrModel::AddAxis (Procedure)
;
pro MGHgrModel::AddAxis, axis, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.axes->Add, axis, _STRICT_EXTRA=extra

end

; MGHgrModel::GetAxis (Function)
;
;   Return object references to axes in the axes container.
;   They can be selected by DIRECTION and POSITION.
;
function MGHgrModel::GetAxis, $
     ALL=all, COUNT=count, DIRECTION=direction, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   axes =self.axes->Get(/ALL, COUNT=count)

   if count eq 0 then return, -1

   ;; Filter the list of axes by DIRECTION

   if n_elements(direction) eq 1 then begin

      dirs = mgh_reproduce(0,axes)

      for i=0,n_elements(dirs)-1 do begin
         axes[i]->GetProperty, DIRECTION=d
         dirs[i] = d
      endfor

      match = where(dirs eq direction,count)

      if count eq 0 then return, -1

      axes = axes[match]

   endif

   ;; Return a list of axes or a single one, depending on the
   ;; ALL and POSITION keywords.

   if keyword_set(all) then return, axes

   case n_elements(position) gt 0 of

      0: begin
         count = 1
         return, axes[0]
      end

      1: begin
         if max(position) ge count || min(position) lt 0 then $
              message, 'Position value out of range'
         count = n_elements(position)
         return, axes[position]
      end

   endcase

end


; MGHgrModel__Define

pro MGHgrModel__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrModel, inherits IDLgrModel, axes: obj_new()}

end


