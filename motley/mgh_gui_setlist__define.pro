; svn $Id$
;+
; CLASS:
;   MGH_GUI_SetList
;
; PURPOSE:
;   This class implements a GUI application for selecting an integer value
;   from an enumerated list.
;
; CALLING SEQUENCE
;   MGH_GUI_SetList supports two modes of operation. In the first,
;   a client object is specified and the dialogue exchanges information
;   with the client by calling the client's methods. An example of the
;   calling sequence is (within a method of the client object):
;
;       mgh_new, 'MGH_GUI_SetList', CLIENT=self, CAPTION='Style',
;            /FLOATING, GROUP_LEADER=self.base, $
;            ITEM_STRING=['Points','Mesh','Filled','Ruled XZ','Ruled YZ'], $
;            PROPERTY_NAME='STYLE'
;
;   The dialogue gets the value of the client's STYLE property during
;   initialisation and then sets the value of the same property when
;   the user presses the Apply or OK buttons (or, in IMMEDIATE mode, whenever
;   the droplist value is changed). This mode of operation
;   can be used with or without blocking in the dialogue.
;
;   In the second mode, there is no client & information is extracted
;   from the object after the widget is destroyed--this only works if the object
;   is blocking or modal. Thus
;
;       odlg = obj_new('MGH_GUI_SetList', /BLOCK, CAPTION='Style' $
;               , ITEM_STRING=['Points','Mesh','Filled','Ruled XZ','Ruled YZ'])
;       odlg->GetProperty, STATUS=status, VALUE=value
;       obj_destroy, odlg
;       if status then print, 'Style is ',value else print, 'Cancelled'
;
;   There is no need to specify PROPERTY_NAME in this call because there is
;   no interaction with any client objects.
;
; PROPERTIES:
;   The following properties are supported:
;
;       CAPTION (Init)
;           The caption that appears to the left of the text entry fields.
;           The default is the property name in lower case.
;
;       CLIENT (Init, Get, Set)
;           A reference to the object with which this object will exchange
;           information. The client must support GetProperty and SetProperty
;           methods which accept 'PROPERTY_NAME' as a keyword. It must
;           also support Update and Show methods. (Subclasses of
;           MGH_GUI_Base inherit Update and Show.)
;
;       IMMEDIATE (Init, Get)
;           Set this property to 1 to cause the client to be updated every time the
;           droplist value is changed. The default (IMMEDIATE=0) is for the client
;           to be updated only when the OK or APPLY button is pressed.
;
;       ITEM_NUMBER (Init, Get)
;           An array of numbers, dimensioned (N_ITEMS), specifying the
;           acceptable values for the property. Default is indgen(N_ITEMS)
;
;       ITEM_STRING (Init, Get)
;           An array of strings, dimensioned (N_ITEMS), specifying the
;           text to appear in the droplist. Default is strarr(N_ITEMS)
;
;       N_ITEMS (Init, Get)
;           The number of droplist items, each representing an acceptable
;           integer value. N_ITEMS need not be specified explicitly
;           if it can be deduced from ITEM_STRING or ITEM_NUMBER.
;
;       PROPERTY_NAME (Init, Get)
;           The name of the client property to be managed by this dialogue.
;
;       STATUS (Get)
;           Equal to 1 if the OK button has been pressed, otherwise 0. This
;           property is of interest only in blocking or modal operation.
;
;       VALUE (Get, Set)
;           This is the dialogue's copy of the property value.
;
;   Several other properties are inherited unaltered from the superclass, MGH_GUI_Base.
;   The following property is inherited with additional functionality:
;
;     MANAGED (Init, Get)
;       This keyword can still be retrieved via GetProperty, but in
;       addition it is accepted by the Init method, where it specifies
;       whether Init should call the Manage method.  The default (1 =
;       manage the object immediately) allows a simpler creation
;       sequence and will normally be satisfactory *except* when the
;       widget application is (or could be) blocking and there is some
;       reason to interact with it programmatically--in a way that
;       requires its widgets to be intact--after initialisation.
;       (Recall that the Manage method of a blocking widget object
;       does not return until the widget hierarchy has been
;       destroyed.) For example a subclass of MGH_GUI_SetList might
;       call MGH_GUI_SetList::Init with MANAGED=0 then call the Manage
;       method at the end of its own initialisation prcoess.
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
;   Mark Hadfield, 2000-01:
;     Written.
;   Mark Hadfield, 2001-01:
;     Added the IMMEDIATE keyword.
;   Mark Hadfield, 2004-06:
;     - Now uses IDL 6.0 logical handling.
;     - Code for constructing GUI updated to use the facilities of MGH_GUI_Base
;       and MGH_GUI_PDmenu as much as possible.
;-


; MGH_GUI_SetList::Init
;
function MGH_GUI_SetList::Init, $
     CAPTION=caption, CLIENT=client, IMMEDIATE=immediate, $
     ITEM_NUMBER=item_number, ITEM_STRING=item_string, N_ITEMS=n_items, $
     PROPERTY_NAME=property_name, VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Keyword defaults

   if n_elements(client) gt 0 then self.client = client

   ;; Get the list of items (acceptable values) and their associated
   ;; names If N_ITEMS not specified, then try to determine it from
   ;; other arguments.

   if n_elements(n_items) eq 0 then begin
      n_items = n_elements(item_number) gt 0 $
                ? n_elements(item_number) : n_elements(item_string)
   endif

   if n_elements(n_items) gt 0 then self.n_items = n_items

   if n_elements(item_number) gt 0 then self.item_number = ptr_new(item_number)

   if n_elements(item_string) gt 0 then self.item_string = ptr_new(item_string)

   ;; Load property name and initial value, if supplied

   if n_elements(property_name) gt 0 then self.property_name = property_name

   if n_elements(value) gt 0 then self.value = value

   ;; Set other object properties

   self.immediate = keyword_set(immediate)

   case n_elements(caption) gt 0 of
      0: begin
         self.caption = strlen(self.property_name) gt 0 $
              ? strlowcase(self.property_name) : 'Value'
      end
      1: self.caption = caption
   endcase

   ;; Initialise the base widget.

   ok = self->MGH_GUI_Base::Init(/COLUMN, TLB_FRAME_ATTR=1+2, $
                                 TITLE='IDL List Dialogue', _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Setlist'

   ;; Add interface components

   self->BuildMenuBar
   self->BuiltEditBar
   self->BuildButtonBar

   ;; Load data from the client

   self->LoadData

   ;; Finalise widget appearance

   self->Update

   self->Finalize, 'MGH_GUI_SetList'

   return, 1

end


; MGH_GUI_SetList::Cleanup
;
pro MGH_GUI_SetList::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.item_number
   ptr_free, self.item_string

   self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_SetList::GetProperty
;
pro MGH_GUI_SetList::GetProperty, $
     CLIENT=client, IMMEDIATE=immediate, ITEM_NUMBER=item_number, $
     ITEM_STRING=item_string, N_ITEMS=n_items, PROPERTY_NAME=property_name, $
     STATUS=status, VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   client = self.client

   immediate = self.immediate

   n_items = self.n_items

   property_name = self.property_name

   value = self.value

   status = self.status

   if arg_present(item_number) then begin
      item_number = ptr_valid(self.item_number) $
                    ? *(self.item_number) : lindgen(self.n_items)
   endif

   if arg_present(item_string) then begin
      item_string = ptr_valid(self.item_string) $
                    ? *(self.item_string) : strarr(self.n_items)
   endif

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_SetList::SetProperty
;
pro MGH_GUI_SetList::SetProperty, $
     CLIENT=client, VALUE=value, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(client) gt 0 then self.client = client

   if n_elements(value) gt 0 then self.value = value

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_SetList::About
;
pro MGH_GUI_SetList::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   self->GetProperty, CLIENT=client, PROPERTY_NAME=property_name

   printf, lun, FORMAT='(%"%s: I edit the %s property")', $
           mgh_obj_string(self), strupcase(property_name)

   if obj_valid(client) then $
        printf, lun, FORMAT='(%"%s: my client is %s")', $
                mgh_obj_string(self), mgh_obj_string(client)

end

function MGH_GUI_SetList::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   uname = widget_info(event.id, /UNAME)

   case uname of

      'BUTTON_OK': begin
         self.status = 1
         self->StoreData
         self->NotifyClient
         self->Kill
         return, 0
      end

      'BUTTON_CANCEL': begin
         self.status = 0
         self->Kill
         return, 0
      end

      'BUTTON_APPLY': begin
         self->StoreData
         self->NotifyClient
         return, 1
      end

      'BUTTON_CLOSE': begin
         self.status = 1
         self->Kill
         return, 0
      end

      'SET_VALUE': begin
         self->GetProperty, ITEM_NUMBER=item_number
         self->SetProperty, value=item_number[event.index]
         self->Update
         if self.immediate then begin
            self->StoreData
            self->NotifyClient
         endif
         return, 0
      end

      else: return, self->MGH_GUI_Base::Event(event)

   endcase

end

function MGH_GUI_SetList::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   uname = widget_info(event.id, /UNAME)

   case event.value of

      'FILE.CLOSE': begin
         self.status = 0
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

      else: return, self->MGH_GUI_Base::EventMenuBar(event)

   endcase

end

; MGH_GUI_SetList::LoadData
;
pro MGH_GUI_SetList::LoadData

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.client) then return

   self->GetProperty, PROPERTY_NAME=property_name

   ;; Don't bother testing return value, just let errors be handled as if
   ;; GetProperty were called directly

   void = execute('self.client->GetProperty, '+property_name+'=value')

   self->SetProperty, VALUE=value

end

; MGH_GUI_SetList::NotifyClient

; Purpose:
;   Notify the client of changes by calling its Update method
;
pro MGH_GUI_SetList::NotifyClient

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if obj_valid(self.client) then self.client->Update

end

; MGH_GUI_SetList::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_GUI_SetList::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   mgh_new, 'MGH_GUI_PDmenu', ['File','Window','Help'], $
            BASE=self.menu_bar, /MBAR, RESULT=obar

   obar->NewItem, PARENT='File', ['Close'], ACCELERATOR=['Ctrl+F4']

   obar->NewItem, PARENT='Window', ['Show Client']

   obar->NewItem, PARENT='Help', ['About']

end

; MGH_GUI_SetList::BuildButtonBar
;
;   Show the button bar
;
pro MGH_GUI_SetList::BuildButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.button_bar gt 0 then message, 'The button bar can only be created once'

   ;; Add an invisible base above the button bar to enforce a minimum
   ;; width for the widget. This is necessary on Windows because
   ;; otherwise the menu bar wraps around and messes up vertical
   ;; layout.

   self->NewChild, 'widget_base', XSIZE=200, YPAD=0

   self.button_bar = self->NewChild('widget_base', UNAME='BUTTON_BAR', $
                                    /ROW, /ALIGN_CENTER, /BASE_ALIGN_CENTER)

   case self.immediate of

      0: begin
         self->NewChild, PARENT=self.button_bar, 'widget_button', $
              VALUE=' OK ', UNAME='BUTTON_OK'
         self->NewChild, PARENT=self.button_bar, 'widget_button', $
              VALUE='Cancel', UNAME='BUTTON_CANCEL'
         self->NewChild, PARENT=self.button_bar, 'widget_button', $
              VALUE='Apply', UNAME='BUTTON_APPLY'
      end

      1: begin
         self->NewChild, PARENT=self.button_bar, 'widget_button', $
              VALUE='Close', UNAME='BUTTON_CLOSE'
      end

   endcase

end

; MGH_GUI_SetList::BuiltEditBar
;
;   Show the edit bar
;
pro MGH_GUI_SetList::BuiltEditBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.edit_bar gt 0 then $
        message, 'The edit bar can be created only once'

   self->GetProperty, ITEM_NUMBER=item_number, ITEM_STRING=item_string

   self.edit_bar = $
        self->NewChild('widget_base', UNAME='EDIT_BAR', /ROW, $
                       /ALIGN_CENTER, /BASE_ALIGN_CENTER)

   self->NewChild, PARENT=self.edit_bar, 'widget_label', VALUE=self.caption
   self->NewChild, PARENT=self.edit_bar, 'widget_label', VALUE=' '
   self->NewChild, PARENT=self.edit_bar, 'widget_droplist', UNAME='SET_VALUE', $
        VALUE=strtrim(item_number,2)+': '+item_string

end

; MGH_GUI_SetList::ShowClient
;
;   Show or hide the client
;
pro MGH_GUI_SetList::ShowClient, FLAG=flag

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


; MGH_GUI_SetList::StoreData
;
PRO MGH_GUI_SetList::StoreData

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.client) then return

   self->GetProperty, PROPERTY_NAME=property_name, VALUE=value

   self.client->SetProperty, _STRICT_EXTRA=create_struct(property_name, value)

end


; MGH_GUI_SetList::Update
;
pro MGH_GUI_SetList::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, ITEM_NUMBER=item_number, VALUE=value

   ;; Set edit bar values

   index = where(item_number eq value, count)
   if count gt 0 then begin
      wid = widget_info(self.edit_bar, FIND_BY_UNAME='SET_VALUE')
      if wid gt 0 then $
           widget_control, wid, SET_DROPLIST_SELECT=index[0]
   endif

   ;; Set button bar values

   wid = widget_info(self.button_bar, FIND_BY_UNAME='BUTTON_APPLY')
   if wid gt 0 then $
        widget_control, wid, SENSITIVE=obj_valid(self.client)

end

; MGH_GUI_SetList__Define
;
pro MGH_GUI_SetList__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGH_GUI_SetList, inherits MGH_GUI_Base, $
         property_name: '', value: 0L, n_items: 0L, $
         item_number: ptr_new(), item_string: ptr_new(), $
         caption: '', edit_bar: 0L, button_bar: 0L, $
         client: obj_new(), status: 0B, immediate: 0B}

end


