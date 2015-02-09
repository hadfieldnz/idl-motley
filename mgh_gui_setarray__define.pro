; svn $Id$
;+
; CLASS:
;   MGH_GUI_SetArray
;
; PURPOSE:
;   This class implements a GUI application for changing a property of
;   a client application. The property value must be a
;   one-dimensional, numeric array with a fixed number of elements.
;
; CATEGORY:
;       Widgets.
;
; CALLING SEQUENCE
;   MGH_GUI_SetArray supports two modes of operation. In the first,
;   a client object is specified and the dialogue exchanges information
;   with the client by calling the client's methods. An example of the
;   calling sequence is (within a client object's method):
;
;     mgh_new, 'MGH_GUI_SetArray', CLIENT=self, CAPTION='Data Range' $
;       , /FLOATING, GROUP_LEADER=self.base $
;       , N_ELEMENTS=2, PROPERTY_NAME='DATA_RANGE'
;
;   If this mode of operation is employed the object can be blocking/modal
;   or non-blocking.
;
;   In the second mode, there is no client & information is extracted
;   from the object after the widget is destroyed--this only works if
;   the object is blocking or modal. Thus
;
;       odlg = obj_new('MGH_GUI_SetArray', /BLOCK, CAPTION='Style', $
;                      N_ELEMENTS=2)
;       odlg->GetProperty, STATUS=status, VALUE=value
;       obj_destroy, odlg
;       case status of
;           0: print, 'Cancelled'
;           1: print, 'Data range is ',value
;       endcase
;
; PROPERTIES:
;   The following properties are supported:
;
;     CAPTION (Init)
;       The caption that appears to the left of the text entry fields.
;       The default is the property name in lower case.
;
;     CLIENT (Init, Get, Set)
;       A reference to the object whose property is to be modified.
;       The client must support GetProperty and SetProperty methods
;       which accept the property in question as a keyword. It must
;       also support a Update method.
;
;     INTEGER (Init, Get, Set)
;       Set this property to 1 to ensure that property values are displayed
;       & processed as integers..
;
;     N_ELEMENTS (Init, Get)
;       The number of elements in the property value array. This is fixed
;       at initialisation.
;
;     PROPERTY_NAME (Init, Get)
;       The name of the property to be managed by this application..
;
;     VALUE (Get, Set)
;       This application's own copy of the property value. (These values
;       are copied to & from the client application via the LoadData
;       and StoreData methods.
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
;   Mark Hadfield, Jan 2000:
;     Written originally as MGHgrDataRangeEditor (which managed a
;     2-element property called DATA_RANGE) then generalised for n
;     elements and renamed MGH_GUI_SetArray.
;   Mark Hadfield, Jun 2001:
;     Updated for recent changes in MGH_GUI_Base event-handling conventions.
;-


; MGH_GUI_SetArray::Init
;
function MGH_GUI_SetArray::Init, $
     CAPTION=caption, CLIENT=client, IMMEDIATE=immediate, INTEGER=integer, $
     N_ELEMENTS=n_elements, PROPERTY_NAME=property_name, VALUE=value, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Keyword defaults

   if n_elements(client) gt 0 then self.client = client

   ;; Object properties

   self.immediate = $
        n_elements(immediate) gt 0 ? keyword_set(immediate) : 0

   self.property_name = $
        n_elements(property_name) gt 0 ? property_name : 'DATA_RANGE'

   self.caption = $
        n_elements(caption) gt 0 ? caption : strlowcase(self.property_name)

   self.integer = n_elements(integer) gt 0 ? integer : 0B

   self.n_elements = n_elements(n_elements) gt 0 ? n_elements : 2

   self->SetProperty, VALUE=value

   ;; Initialise the base widget.

   ok = self->MGH_GUI_Base::Init(/COLUMN, TLB_FRAME_ATTR=1+2, $
                                 TITLE='IDL Property Editor', $
                                 _STRICT_EXTRA=extra )
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Build interface components

   self->BuildMenuBar
   self->BuildEditBar
   self->BuildButtonBar

   ;; Load data from the client

   self->LoadData

   ;; Finalise the widget

   self->Update

   self->Finalize, 'MGH_GUI_SetArray'

   return, 1

end


; MGH_GUI_SetArray::Cleanup
;
pro MGH_GUI_SetArray::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.value
   ptr_free, self.field_id

   self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_SetArray::GetProperty
;
pro MGH_GUI_SetArray::GetProperty, $
     CLIENT=client, INTEGER=integer, N_ELEMENTS=n_elements, $
     PROPERTY_NAME=property_name, STATUS=status, VALUE=value, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   client = self.client

   integer = self.integer

   n_elements = self.n_elements

   property_name = self.property_name

   status = self.status

   if arg_present(value) && ptr_valid(self.value) then $
        value = *(self.value)

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_SetArray::SetProperty
;
pro MGH_GUI_SetArray::SetProperty, $
     CLIENT=client, INTEGER=integer, VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(client) gt 0 then self.client = client

   if n_elements(integer) gt 0 then self.integer = integer

   if n_elements(value) eq self.n_elements then begin
      ptr_free, self.value
      self.value = ptr_new(float(value))
   endif

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_SetArray::About
;
pro MGH_GUI_SetArray::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   self->GetProperty, CLIENT=client, PROPERTY_NAME=property_name

   printf, lun, self, ': I edit the ', property_name, ' property'

   if obj_valid(client) then $
        printf, lun, self, ': My client is ', client

end

; MGH_GUI_SetArray::BuildButtonBar
;
;   Show the button bar
;
pro MGH_GUI_SetArray::BuildButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.button_bar gt 0 then message, 'The button bar can only be created once'

   obar = self->NewChild('MGH_GUI_Base', /OBJECT, /ROW, /ALIGN_CENTER, $
                         /BASE_ALIGN_CENTER, UVALUE=self->Callback('EventButtonBar'))

   self.button_bar = obar->GetBase()

   ;; Add an invisible base above the button bar to enforce a minimum width
   ;; for the widget. This is necessary on Windows because otherwise the menu bar
   ;; wraps around and messes up vertical layout.

   self->NewChild, 'widget_base', XSIZE=200, YPAD=0, YSIZE=0

   case self.immediate of

      0: begin
         obar->NewChild, 'widget_button', VALUE='OK', UNAME='OK'
         obar->NewChild, 'widget_button', VALUE='Cancel', UNAME='Cancel'
         obar->NewChild, 'widget_button', VALUE='Apply', UNAME='Apply'
      end

      else: obar->NewChild, 'widget_button', VALUE='Close', UNAME='Close'

   endcase

end

; MGH_GUI_SetArray::BuildEditBar
;
;   Show the edit bar. Save IDs of the editable text widgets with the class structure.
;
pro MGH_GUI_SetArray::BuildEditBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.edit_bar gt 0 then message, 'The edit bar can be created only once'

   obar = self->NewChild('MGH_GUI_Base', /OBJECT, /ROW, /ALIGN_CENTER, $
                         /BASE_ALIGN_CENTER, UVALUE=self->Callback('EventEditBar'), $
                         XPAD=3)

   self.edit_bar = obar->GetBase()

   field_id = lonarr(self.n_elements)

   obar->NewChild, 'widget_label', VALUE=self.caption

   for i=0,self.n_elements-1 do $
        field_id[i] = obar->NewChild('widget_text', XSIZE=8, /EDITABLE, $
                                     /ALL_EVENTS, /KBRD_FOCUS_EVENTS)

   self.field_id = ptr_new(field_id)

end

; MGH_GUI_SetArray::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_GUI_SetArray::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    if ~ widget_info(self.menu_bar, /VALID_ID) then return

    if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

    ombar = obj_new('MGH_GUI_PDmenu', /MBAR, BASE=self.menu_bar, ['File','Window','Help'])

    ombar->NewItem, PARENT='File', 'Close'
    ombar->NewItem, PARENT='Window', 'Show Client'
    ombar->NewItem, PARENT='Help', 'About'

end

; MGH_GUI_SetArray::EventButtonBar
;
function MGH_GUI_SetArray::EventButtonBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.uname of

      'Close': begin
         self.status = 1
         self->Kill
         return, 0
      end

      'OK': begin
         self->StoreData
         self->NotifyClient
         self.status = 1
         self->Kill
         return, 0
      end

      'Apply': begin
         self->StoreData
         self->NotifyClient
         return, 0
      end

      'Cancel': begin
         self.status = 0
         self->Kill
         return, 0
      end

      else: return, self->EventUnexpected(event)

   end

end

; MGH_GUI_SetArray::EventEditBar
;
function MGH_GUI_SetArray::EventEditBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Text-field events have been intercepted & wrapped by the edit bar
   ;; using its EventGeneric function. The original event is available
   ;; as event.event

   field_id = *self.field_id

   ifield = where(event.event.id eq field_id, n_match)

   if n_match ne 1 then return, self->EventUnexpected(event)

   ifield = ifield[0]

   ;; There are four events of interest

   struct_name = tag_names(event.event, /STRUCTURE_NAME)

   ;; ...widget has gained focus
   event_enter = struct_name eq 'WIDGET_KBRD_FOCUS' ? (event.event.enter eq 1) : 0

   ;; ...widget has lost focus
   event_leave = struct_name eq 'WIDGET_KBRD_FOCUS' ? (event.event.enter eq 0) : 0

   ;; ...widget has received EOL
   event_eol = struct_name eq 'WIDGET_TEXT_CH' ? (event.event.ch eq 10) : 0

   ;; ...widget has received TAB
   event_tab = struct_name eq 'WIDGET_TEXT_CH' ? (event.event.ch eq 9) : 0

   switch 1 of

      event_enter: begin

         ;; Select field contents

         widget_Control, event.event.id, GET_VALUE=text
         text = text[0]
         widget_Control, event.event.id, SET_TEXT_SELECT=[0,strlen(text)]

         return, 0

      end

      event_tab: begin

         ;; "Tab" to next field. This will trigger a pair of input focus events
         ;;  that ensure the old field contents are processed and the new field
         ;; is selected

         widget_control, field_id[(ifield + 1) mod self.n_elements], /INPUT_FOCUS

         return, 0

      end

      event_leave or event_eol: begin

         ;; Read field contents and store in the current widget's VALUE property.
         ;; Update all widgets to ensure validity of data etc.
         ;; If IMMEDIATE, communicate with client.

         ;; We know that the index number of the text widget
         ;; will be in the right range. However we do need to check for
         ;; the possibility that GetProperty will return an
         ;; undefined value

         widget_control, event.event.id, GET_VALUE=field_value
         self->GetProperty, VALUE=value
         if n_elements(value) gt 0 then begin
            value[ifield] = self.integer ? long(field_value[0]) : float(field_value[0])
            self->SetProperty, VALUE=value
         endif

         self->Update

         if self.immediate then begin
            self->StoreData
            self->NotifyClient
         endif

         return, 0

      end

      else: return, 0

   endswitch

end

; MGH_GUI_SetArray::EventMenuBar
;
function MGH_GUI_SetArray::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.CLOSE': begin
         self.status = 1
         self->Kill
         return, 0
      end

      'WINDOW.SHOW CLIENT': begin
         self->ShowClient
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_GUI_SetArray::LoadData
;
pro MGH_GUI_SetArray::LoadData

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.client) then return

   self->GetProperty, PROPERTY_NAME=property_name

   ;; Don't bother testing return value, just let errors be handled
   ;; as if GetProperty were called directly

   void = execute('self.client->GetProperty, '+property_name+'=value')

   self->SetProperty, VALUE=value

end

; MGH_GUI_SetArray::NotifyClient

; Purpose:
;   Notify the client of changes by calling its Update method
;
pro MGH_GUI_SetArray::NotifyClient

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if obj_valid(self.client) then self.client->Update

end

; MGH_GUI_SetArray::ShowClient
;
;   Show or hide the client
;
pro MGH_GUI_SetArray::ShowClient, FLAG=flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = 1

   if obj_valid(self.client) then begin
      self.client->Update
      self.client->Show, flag
   endif

end


; MGH_GUI_SetArray::StoreData
;
PRO MGH_GUI_SetArray::StoreData

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.client) then return

   self->GetProperty, PROPERTY_NAME=property_name, VALUE=value

   self.client->SetProperty, _EXTRA=create_struct(property_name, value)

end


; MGH_GUI_SetArray::Update
;
pro MGH_GUI_SetArray::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    self->UpdateButtonBar
    self->UpdateEditBar
    self->UpdateMenuBar

end

; MGH_GUI_SetArray::UpdateButtonBar
;
pro MGH_GUI_SetArray::UpdateButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    obar = mgh_widget_self(self.button_bar)

    if obj_valid(obar) then begin
        id = obar->FindChild('Apply')
        if widget_info(id, /VALID_ID) then $
            widget_control, id, SENSITIVE=obj_valid(self.client)
    endif

end

; MGH_GUI_SetArray::UpdateEditBar
;
pro MGH_GUI_SetArray::UpdateEditBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, VALUE=value

   field_id = *self.field_id

   for i=0,self.n_elements-1 do begin
      case n_elements(value) eq self.n_elements of
         0: begin
            widget_control, field_id[i], SET_VALUE=''
         end
         1: begin
            widget_control, field_id[i], SET_VALUE=' ' + $
                 (self.integer ? strtrim(round(value[i]),2) : mgh_format_float(value[i]) )
         end
      endcase
   endfor

end

; MGH_GUI_SetArray::UpdateMenuBar
;
pro MGH_GUI_SetArray::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if widget_info(self.menu_bar, /VALID_ID) then begin

      obar = mgh_widget_self(self.menu_bar)
      obar->SetItem, 'Window.Show Client', SENSITIVE=obj_valid(self.client)

   endif

end

; MGH_GUI_SetArray__Define
;
pro MGH_GUI_SetArray__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGH_GUI_SetArray, inherits MGH_GUI_Base, $
         property_name: '', value: ptr_new(), immediate: 0B, $
         integer: 0B, n_elements: 0, caption: '', client: obj_new(), $
         status: 0B, edit_bar: 0L, button_bar: 0L, field_id: ptr_new()}

end


