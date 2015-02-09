; svn $Id$
;+
; CLASS:
;   MGH_GUI_LightEditor
;
; PURPOSE:
;   This class implements a GUI application with a single CW_LIGHT_EDITOR
;   widget.
;
; CATEGORY:
;       Widgets.
;
; PROPERTIES:
;   The following properties are supported:
;
;     CLIENT (Init, Get, Set)
;       A reference to the object with which this object will exchange
;       information. The client must support GetProperty and
;       SetProperty methods which accept 'PROPERTY_NAME' as a
;       keyword. It must also support Update and Show
;       methods. (Subclasses of MGH_GUI_Base inherit Update and Show.)
;
;   Several other properties are inherited unaltered from the superclass, MGHwidgetBase.
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
;       destroyed.) For example a subclass of MGH_GUI_LightEditor
;       might call MGH_GUI_LightEditor::Init with MANAGED=0 then call
;       the Manage method at the end of its own initialisation
;       prcoess.
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
;       Written.
;-


; MGH_GUI_LightEditor::Init
;
function MGH_GUI_LightEditor::Init, $
     CLIENT=client, IMMEDIATE=immediate, LIGHT=light, MODAL=modal, $
     XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.immediate = keyword_set(immediate)

   ;; Create a container for clients, to be notified when
   ;; the palette is changed. Add the clients, if any, to it.

   self.clients = obj_new('MGH_Container', DESTROY=0)
   self->AddClient, client

   ;; Initialise the base widget.

   ok = self->MGH_GUI_Base::Init(/COLUMN, TLB_FRAME_ATTR=1, TITLE='IDL Light Editor', $
                                 _STRICT_EXTRA=extra )
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Populate the menu bar

   self->BuildMenuBar

   ;; Create & add the light editor widget.

   self.light_editor = $
        cw_light_editor(self.layout, LIGHT=light, $
                        XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange)

   ;; Add a button bar

   self->ShowButtonBar

   ;; Finalise widget appearance

   self->Update

   ;; Realise the widget hierarchy after appearance has been finalised.

   self->Finalize, 'MGH_GUI_LightEditor'

   return, 1

end


; MGH_GUI_LightEditor::Cleanup
;
pro MGH_GUI_LightEditor::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    obj_destroy, self.clients

    self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_LightEditor::GetProperty
;
pro MGH_GUI_LightEditor::GetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_LightEditor::SetProperty
;
pro MGH_GUI_LightEditor::SetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_LightEditor::About
;
pro MGH_GUI_LightEditor::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   clients = self.clients->Get(/ALL, COUNT=n_clients)

   if n_clients gt 0 then $
        printf, lun, self, ': The clients are', clients

end

; MGH_GUI_LightEditor::AddClient

; Purpose:
;   Add one or more client objects to the container
;
pro MGH_GUI_LightEditor::AddClient, client

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(client)-1 do self.clients->Add, client[i]

end

; MGH_GUI_LightEditor::Event
;
; Purpose:
;   Handle widget events. Return 1 if the event has been fullyu dealt with, otherwise 0.
;
function MGH_GUI_LightEditor::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.id of

      self.light_editor: begin
         case tag_names(event, /STRUCTURE_NAME) of
            'CW_LIGHT_EDITOR_LS':
            'CW_LIGHT_EDITOR_LM': if self.immediate then self->NotifyClient, /ALL
         endcase
         return, 1
      end

      else:

   endcase

   uname = widget_info(event.id, /UNAME)

   case uname of

      'CLOSE': begin
         self->Kill
         return, 1
      end

      'SHOW_CLIENT': begin
         self->ShowClient, /ALL
         return, 1
      end

      'ABOUT': begin
         self->About
         return, 1
      end

      'BUTTON_CLOSE': begin
         self->NotifyClient, /ALL
         self->Kill
         return, 1
      end

      'BUTTON_APPLY': begin
         self->NotifyClient, /ALL
         return, 1
      end

      else: return, 0

   endcase

end

; MGH_GUI_LightEditor::NotifyClient

; Purpose:
;   Notify the clients of changes in the palette by calling their Update methods
;
pro MGH_GUI_LightEditor::NotifyClient, Client, ALL=all

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


    if keyword_set(all) then client = self.clients->Get(/ALL)

    for i=0,n_elements(client)-1 do if obj_valid(client[i]) then client[i]->Update

end

; MGH_GUI_LightEditor::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_GUI_LightEditor::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   ;; File menu

   menu = widget_button(self.menu_bar, VALUE='File', UNAME='FILE')

   wid = widget_button(menu, VALUE='Close', UNAME='CLOSE')

   ;; Window menu

   menu = widget_button(self.menu_bar, VALUE='Window', UNAME='WINDOW')

   wid = widget_button(menu, VALUE='Show Client', UNAME='SHOW_CLIENT')

   ;; Help menu

   menu = widget_button(self.menu_bar, VALUE='Help', UNAME='HELP')

   wid = widget_button(menu, VALUE='About', UNAME='ABOUT')

end

; MGH_GUI_LightEditor::Update
;
;   Update the sensitivity & appearance of all widgets.
;
pro MGH_GUI_LightEditor::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


    self->MGH_GUI_Base::Update

end

; MGH_GUI_LightEditor::ShowButtonBar
;
;   Show the button bar
;
pro MGH_GUI_LightEditor::ShowButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.button_bar gt 0 then message, 'The button bar can only be created once'

   self.button_bar = widget_base(self.layout, UNAME='BUTTON_BAR', $
                                 /ROW, /ALIGN_CENTER, /BASE_ALIGN_CENTER)

   id = widget_button(self.button_bar, VALUE='Close', UNAME='BUTTON_CLOSE')
   if (~ self.immediate) then $
        id = widget_button(self.button_bar, VALUE='Apply', UNAME='BUTTON_APPLY')

end

; MGH_GUI_LightEditor::ShowClient
;
;   Show or hide one or more clients
;
pro MGH_GUI_LightEditor::ShowClient, Client, ALL=all, FLAG=flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = 1

   if keyword_set(all) then client = self.clients->Get(/ALL)

   for i=0,n_elements(client)-1 do $
        if obj_valid(client[i]) then begin
      client[i]->Update
      client[i]->Show, flag
   endif

end


; MGH_GUI_LightEditor__Define
;
pro MGH_GUI_LightEditor__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_LightEditor, inherits MGH_GUI_Base, $
                 clients: obj_new(), immediate: 0B, $
                 light_editor: 0L, button_bar: 0L}

end


