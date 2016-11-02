; svn $Id$
;+
; CLASS:
;   MGH_GUI_Droplist
;
; PURPOSE:
;   An enhanced droplist widget
;
; CATEGORY:
;       Widgets.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty and
;   SetProperty methods) are supported:
;
;     COLUMN (Init)
;       Set this keyword to put the title above the droplist,
;       otherwise it is put to the left.
;
;     INDEX (Init, Get, Set)
;       Zero-based index of the currently selected droplist
;       item. Default is 0.
;
;     N_VALUES (Get)
;       Number of items in the droplist.
;
;     PARENT (Init(*), Get)
;       Parent widget ID. (*) Passed to Init via parent argument.
;
;     SELECTED_VALUE (Init, Get, Set)
;       Value of the currently selected droplist item. Type is
;       string.
;
;     TITLE (Init, Get)
;       Label adjacent to the widget.
;
;     UNAME (Init, Get, Set)
;       A string that can be used to identify the widget. Default is ''.
;
;     UVALUE (Init, Get, Set)
;       User value. Default is undefined.
;
;     VALUE (Init, Get, Set)
;       The string array displayed in the droplist.
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
;   Mark Hadfield, 2001-06.
;     Written, borrowing freely from ideas in David Fanning's
;     FSC_DROPLIST (http://www.dfanning.com/programs/fsc_droplist.pro).
;     Originally a stand-alone class, now a sub-class of MGH_GUI_Base.
;   Mark Hadfield, 2001-11.
;     - Updated for IDL 5.5
;     - The TITLE property can now be set only on initialisation,
;       whereas previously it could also be set later. This is to avoid
;       having an empty title label when it is not needed.
;   Mark Hadfield, 2003-08.
;     Updated for IDL 6.0. Now that WIDGET_DROPLIST widgets support both
;     GET_VALUE and SET_VALUE keywords to WIDGET_CONTROL, it is no longer
;     necessary to store the VALUE property in a pointer.
;-

; MGH_GUI_Droplist::Init
;
function MGH_GUI_Droplist::Init, $
     COLUMN=column, INDEX=index, SELECTED_VALUE=selected_value, $
     TITLE=title, VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case keyword_set(column) of
      0: begin
         row = 1
         space = 2
      end
      1: begin
         row = 0
         space = 0
      end
   endcase

   ;; Create the base

   ok = self->MGH_GUI_Base::Init(/BASE_ALIGN_CENTER, COLUMN=keyword_set(column), $
                                 ROW=row, SPACE=space, XPAD=0, YPAD=0, $
                                 _STRICT_EXTRA=extra)
   if ~ ok then message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Populate it

   if n_elements(title) gt 0 then $
        self.titleID = widget_label(self.layout, VALUE=title)

   self.droplistID = widget_droplist(self.layout)

   ;; Complete setup & finalise

   self->SetProperty, INDEX=index, SELECTED_VALUE=selected_value, VALUE=value

   self->Finalize, 'MGH_GUI_Droplist'

   return, 1

end


; MGH_GUI_Droplist::Cleanup
;
pro MGH_GUI_Droplist::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_Droplist::GetProperty
;
pro MGH_GUI_Droplist::GetProperty, $
     N_VALUES=n_values, INDEX=index, PARENT=parent, SELECTED_VALUE=selected_value, $
     TITLE=title, VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

   index = widget_info(self.droplistID, /DROPLIST_SELECT)

   if arg_present(n_values) then $
        n_values = widget_info(self.droplistID, /DROPLIST_NUMBER)

   if arg_present(parent) then $
        parent = widget_info(self.base, /PARENT)

   if arg_present(title) then begin
      case widget_info(self.titleID, /VALID_ID) of
         0: title = ''
         1: widget_control, self.titleID, GET_VALUE=title
      endcase
   endif

   if arg_present(value) || arg_present(selected_value) then begin
      widget_control, self.droplistID, GET_VALUE=value
      selected_value = value[index]
   endif

   uname = widget_info(self.base, /UNAME)

   widget_control, self.base, GET_UVALUE=uvalue

end

; MGH_GUI_Droplist::SetProperty
;
pro MGH_GUI_Droplist::SetProperty, $
     INDEX=index, SELECTED_VALUE=selected_value, SENSITIVE=sensitive, $
     VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

   if n_elements(sensitive) gt 0 then $
        widget_control, self.droplistID, SENSITIVE=sensitive

   if n_elements(value) gt 0 then $
        widget_control, self.droplistID, SET_VALUE=value

   ;; Set INDEX or SELECTED_VALUE after VALUE to ensure the selection
   ;; is consistent with the new list of values.

   if n_elements(index) gt 0 then $
        widget_control, self.droplistID, SET_DROPLIST_SELECT=index

   if n_elements(selected_value) gt 0 then begin
      widget_control, self.droplistID, GET_VALUE=value
      match = where(strmatch(strtrim(value,2), strtrim(selected_value,2), /FOLD_CASE), $
                    n_matches)
      if n_matches gt 0 then $
           widget_control, self.droplistID, SET_DROPLIST_SELECT=match[0]
   endif

end

; MGH_GUI_Droplist::Event
;
function MGH_GUI_Droplist::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.id of

      self.droplistID: begin
         self->GetProperty, INDEX=index, SELECTED_VALUE=selected_value
         return, {MGH_GUI_Droplist_EVENT, id: self.base, top: event.top, $
                  handler: 0, index:index, value:selected_value, self:self}
      end

      else: return, self->MGH_GUI_Base::Event(event)

   endcase

end


; MGH_GUI_Droplist__Define
;
pro MGH_GUI_Droplist__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_Droplist, inherits MGH_GUI_Base, $
                 titleID: 0, droplistID: 0}

end
