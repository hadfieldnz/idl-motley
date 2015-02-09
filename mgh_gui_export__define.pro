; svn $Id$
;+
; CLASS:
;   MGH_GUI_Export
;
; PURPOSE:
;   This class implements a GUI application for exporting data to
;   another level in the IDL call stack.
;
; CATEGORY:
;   Widgets.
;
; CALLING SEQUENCE
;   mgh_new, 'MGH_GUI_Export', values, captions
;
; POSITIONAL PARAMETERS
;   values (input, pointer array)
;     An array of pointers, each holding a data item that the user may
;     want to export. The object destroys all pointers when it is
;     terminated.
;
;   captions (input, string array)
;     A string array with the same number of elements as values. The
;     captions are displayed in the widget application alongside a
;     field into which the user can enter the desired variable name.
;
; PROPERTIES:
;   The following properties are supported:
;
;     LEVEL (Init, Get, Set)
;       The level to which data are to be exported. Default is 1 (main
;       level).
;
;     N_ITEMS (Get)
;       The number of data items available for export. This is
;       determined at initialisation from the number of elements in
;       the values array.
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
;   Mark Hadfield, 2000-12:
;     Written.
;   Mark Hadfield, 2004-05:
;     Now uses SCOPE_VARFETCH (new in IDL 6.1) to export data instead
;     of the undocumented ROUTINE_NAMES functionality.
;-


; MGH_GUI_Export::Init
;
function MGH_GUI_Export::Init, values, captions, LEVEL=level, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ;; Load data

   n_items = n_elements(values)

   if n_items eq 0 then $
        message, 'Number of data items is zero'

   if n_elements(captions) ne n_items then $
        message, 'Number of captions does not match number of items'

   if size(values, /TYPE) ne 10 then $
        message, 'Data are not in pointer form'

   self.n_items = n_items

   self.captions = ptr_new(captions)

   self.values = ptr_new(values)

   self.level = n_elements(level) gt 0 ? level : 1

   ;; Initialise the base widget.

   ok = self->MGH_GUI_Base::Init(/COLUMN, VISIBLE=visible, TLB_SIZE_EVENTS=0, $
                                 TLB_FRAME_ATTR=1+2, TITLE='IDL Data Exporter', $
                                 _STRICT_EXTRA=extra )

   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Build GUI components

   self->BuildMenuBar
   self->BuildEditBar
   self->BuildButtonBar

   ;; Finalise widget appearance

   self->Update

   self->Finalize, 'MGH_GUI_Export'

   return, 1

end


; MGH_GUI_Export::Cleanup
;
pro MGH_GUI_Export::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ptr_free, *self.values

   ptr_free, self.values

   ptr_free, self.captions

   ptr_free, self.field_id

   self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_Export::GetProperty
;
pro MGH_GUI_Export::GetProperty, $
     ALL=all, LEVEL=level, NAMES=names, N_ITEMS=n_items, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::GetProperty, ALL=all, _STRICT_EXTRA=extra

   level = self.level

   n_items = self.n_items

   if arg_present(names) then begin
      names = strarr(n_items)
      field_id = *self.field_id
      for i=0,n_items-1 do $
           if widget_info(field_id[i], /VALID_ID) then begin
         widget_control, field_id[i], GET_VALUE=n
         names[i] = n
      endif
   endif

   if arg_present(all) then $
        all = create_struct(all, 'level', level, 'n_items', n_items)

end

; MGH_GUI_Export::SetProperty
;
pro MGH_GUI_Export::SetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_Export::About
;
pro MGH_GUI_Export::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   printf, lun, FORMAT='(%"%s: I have %d data items available to be exported ' + $
           'to level %d")', mgh_obj_string(self), self.n_items, self.level

end

; MGH_GUI_Export::BuildButtonBar
;
;   Show the button bar
;
pro MGH_GUI_Export::BuildButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if self.button_bar gt 0 then $
        message, 'The button bar can only be created once'

   ;; Add an invisible base above the button bar to enforce a minimum
   ;; width for the widget. This is necessary on Windows because
   ;; otherwise the menu bar wraps around and messes up vertical
   ;; layout.

   void = widget_base(self.base, XSIZE=150, YPAD=0)

   ;; Add button bar base & buttons

   self.button_bar = widget_base(self.layout, UNAME='BUTTON_BAR', /ROW, $
                                 /ALIGN_CENTER, /BASE_ALIGN_CENTER)

   void = widget_button(self.button_bar, VALUE=' OK ', UNAME='BUTTON_OK', $
                        UVALUE=self->Callback('EventButtonBar'))
   void = widget_button(self.button_bar, VALUE='Cancel', UNAME='BUTTON_CANCEL', $
                        UVALUE=self->Callback('EventButtonBar'))

end

; MGH_GUI_Export::BuildEditBar
;
;   Show the edit bar. Save IDs of the editable text widgets with the
;   class structure.
;
pro MGH_GUI_Export::BuildEditBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if self.edit_bar gt 0 then message, 'The edit bar can be created only once'

   self.edit_bar = widget_base(self.layout, ROW=self.n_items, /GRID, $
                               /ALIGN_CENTER, /BASE_ALIGN_CENTER)

   captions = *self.captions

   field_id = lonarr(self.n_items)

   for i=0,self.n_items-1 do begin
      id = widget_label(self.edit_bar, VALUE=captions[i])
      field_id[i] = widget_text(self.edit_bar, XSIZE=15, /EDITABLE, $
                                UVALUE=self->Callback('EventValueWidget'))
   endfor

   self.field_id = ptr_new(field_id)

end

; MGH_GUI_Export::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_GUI_Export::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if not widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   ombar = obj_new('MGH_GUI_PDmenu', ['File','Help'], /MBAR, $
                   BASE=self.menu_bar)

   ombar->NewItem, PARENT='File', ['Close']
   ombar->NewItem, PARENT='Help', ['About']

end

; MGH_GUI_Export::EventButtonBar
;
function MGH_GUI_Export::EventButtonBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   uname = widget_info(event.id, /UNAME)

   case uname of

      'BUTTON_OK': begin
         self->Export
         self->Kill
         return, 0
      end

      'BUTTON_CANCEL': begin
         self->Kill
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_GUI_Export::EventMenuBar
;
function MGH_GUI_Export::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.CLOSE': begin
         self->Kill
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_GUI_Export::EventValueWidget
;
function MGH_GUI_Export::EventValueWidget, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ;; Should implement tabbing here.

   return, 0

end

; MGH_GUI_Export::Export
;
pro MGH_GUI_Export::Export

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->GetProperty, NAMES=names

   for i=0,self.n_items-1 do begin
      if strlen(names[i]) gt 0 then begin
         case mgh_str_isidentifier(names[i]) of
            0: begin
               print, FORMAT='(%"%s: cannot export variable %s - invalid identifier")', $
                      mgh_obj_string(self), names[i]
            end
            1: begin
               if n_elements(values) eq 0 then values = *self.values
               val = *values[i]
               print, FORMAT='(%"%s: exporting %s data to level %d as variable %s")', $
                      mgh_obj_string(self), size(val, /TNAME), self.level, names[i]
               (scope_varfetch(names[i], /ENTER, LEVEL=self.level)) = temporary(val)
            end
         endcase
      endif
   endfor

end

; MGH_GUI_Export__Define
;
pro MGH_GUI_Export__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_Export, inherits MGH_GUI_Base, level: 0L, $
                 captions: ptr_new(), values: ptr_new(), n_items: 0L, $
                 edit_bar: 0L, button_bar: 0L, field_id: ptr_new()}

end


