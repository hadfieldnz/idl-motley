; svn $Id$
;+
; CLASS:
;   MGH_GUI_PickObj
;
; PURPOSE:
;   This class implements a widget that allows the user to select from a list of objects.
;
; CATEGORY:
;       Widgets.
;
; WARNING:
;   The MGH_OBJ_STRING function is called to generate the string
;   values for the list widget.  This can be very slow if the
;   SHOW_NAME or SHOW_TITLE keyword is set and the list of candidates
;   includes objects that do not support a GetProperty method. It is
;   unwise to set SHOW_NAME or SHOW_TITLE without filtering the list
;   of candidates, or otherwise ensuring that they all support the
;   required property.
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
;   Mark Hadfield, Jul 2000
;       Written.
;-


; MGH_GUI_PickObj::Init
;
function MGH_GUI_PickObj::Init, candidates, $
     ISA=isa, MAX_LIST=max_list, MANAGED=managed, MODAL=modal, $
     MULTIPLE=multiple, SHOW_NAME=show_name, SHOW_TITLE=show_title, $
     TITLE=title, VISIBLE=visible, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; This dialog always blocks

   if n_elements(managed) eq 0 then managed = 1

   if n_elements(modal) eq 0 then modal = 0

   if n_elements(visible) eq 0 then visible = 1

   if n_elements(title) eq 0 then title = 'Select object(s)'

   if n_elements(max_list) eq 0 then max_list = 100

   ;; Check and store the list of candidates

   n_list = n_elements(candidates)

   if size(candidates, /TYPE) ne 11 then n_list = 0

   if n_list gt max_list then $
        message, 'The number of objects to be submitted to the list widget' + $
                 ' exceeds the maximum. Please reduce the number or reset the ' + $
                 'MAX_LIST keyword.'

   if n_list gt 0 then self.candidates = ptr_new(candidates)

   ;; Initialise the base.

   ok = self->MGH_GUI_Base::Init(BLOCK=1, MODAL=modal, /COLUMN, TITLE=title, $
                                 VISIBLE=visible, TLB_FRAME_ATTR=1, $
                                 _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'


   ;; Populate the base

   wlist = widget_list(self.layout, MULTIPLE=multiple, XSIZE=30, YSIZE=8, UNAME='LIST')
   if n_list gt 0 then begin
      list_value = mgh_obj_string(candidates, SHOW_NAME=show_name, SHOW_TITLE=show_title)
      xsize = ((1.1*max(strlen(list_value)) > 30) < 100)
      ysize = ((n_elements(list_value) > 8) < 50)
      widget_control, wlist, SET_VALUE=list_value, XSIZE=xsize, YSIZE=ysize
   endif

   wbbar = widget_base(self.layout, /ROW, /ALIGN_CENTER)

   widget_control, self.base, $
        DEFAULT_BUTTON=widget_button(wbbar, VALUE='OK', UNAME='OK', SENSITIVE=0)
   widget_control, self.base, $
        CANCEL_BUTTON=widget_button(wbbar, VALUE='Cancel', UNAME='CANCEL')

   ;; Complete initialisation

   self->Realize

   if keyword_set(managed) then self->Manage

   return, 1

end


; MGH_GUI_PickObj::Cleanup
;
pro MGH_GUI_PickObj::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.candidates
   ptr_free, self.selected

   self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_PickObj::GetProperty
;
pro MGH_GUI_PickObj::GetProperty, STATUS=status, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   status = self.status

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_PickObj::Event
;
function MGH_GUI_PickObj::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   uname = widget_info(event.id, /UNAME)

   case uname of

      'CANCEL': begin
         self.status = 0
         self->Kill
         return, 0
      end

      'OK': begin
         self.status = 1
         self->Kill
         return, 0
      end

      'LIST': begin
         ptr_free, self.selected
         selected = widget_info(event.id, /LIST_SELECT)
         case selected[0] ge 0 of
            0: begin
               widget_control, widget_info(event.handler, FIND_BY_UNAME='OK'), $
                    SENSITIVE=0
            end
            1: begin
               widget_control, widget_info(event.handler, FIND_BY_UNAME='OK'), $
                    SENSITIVE=1
               self.selected = ptr_new(selected)
            end
         endcase
         return, 0
      end

      else: return, self->MGH_GUI_Base::Event(event)

   endcase

end

; MGH_GUI_PickObj::Selected
;
function MGH_GUI_PickObj::Selected, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    case ptr_valid(self.selected) of

        0: begin
            count = 0
            return, -1
        end

        1: begin
            selected = *self.selected
            count = n_elements(selected)
            return, (*self.candidates)[selected]
        end

    endcase

end

; MGH_GUI_PickObj__Define
;
pro MGH_GUI_PickObj__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_PickObj, inherits MGH_GUI_Base, $
                 candidates: ptr_new(), selected: ptr_new(), status: 0B}

end


