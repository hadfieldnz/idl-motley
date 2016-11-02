; svn $Id$
;+
; CLASS:
;   MGH_GUI_PropertySheet
;
; PURPOSE:
;   This class implements a GUI application for setting the properties
;   of an object, using the IDL property-sheet widget
;
; CALLING SEQUENCE
;   An example of the
;   calling sequence is (within a method of the client object):
;
;       mgh_new, 'MGH_GUI_PropertySheet', CLIENT=self, SPECTATOR=self
;
;   The dialogue gets the value of the client's STYLE property during
;   initialisation and then sets the value of the same property when
;   the user presses the Apply or OK buttons (or, in IMMEDIATE mode, whenever
;   the droplist value is changed). This mode of operation
;   can be used with or without blocking in the dialogue.
;
; PROPERTIES:
;   The following properties are supported, in addition to those inherited
;   from the superclass, MGH_GUI_Base
;
;       CLIENT (Init, Get, Set)
;         A reference to the object(s) whose properties are to be set
;
;       SPECTATOR (Init, Get, Set)
;         A reference to object(s) that are to be informed when the
;         properties have been changed
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
;   Mark Hadfield, 2004-06:
;     Written.
;-


; MGH_GUI_PropertySheet::Init
;
function MGH_GUI_PropertySheet::Init, $
     CLIENT=client, SPECTATOR=spectator, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = obj_new('MGH_Container', DESTROY=0)
   self.spectator = obj_new('MGH_Container', DESTROY=0)

   ;; Keyword defaults

   for i=0,n_elements(client)-1 do self.client->Add, client[i]

   for i=0,n_elements(spectator)-1 do self.spectator->Add, spectator[i]

   ;; Initialise the base widget.

   ok = self->MGH_GUI_Base::Init(/COLUMN, TLB_FRAME_ATTR=1+2, $
                                 TITLE='IDL Property Sheet Dialogue', _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_PropertySheet'

   ;; Add interface components

   self->BuildMenuBar
   self->BuildPropertySheet
   self->BuildButtonBar

   ;; Finalise widget appearance

   self->Update

   self->Finalize, 'MGH_GUI_PropertySheet'

   return, 1

end


; MGH_GUI_PropertySheet::Cleanup
;
pro MGH_GUI_PropertySheet::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.client
   obj_destroy, self.spectator

   self->MGH_GUI_Base::Cleanup

end

; MGH_GUI_PropertySheet::GetProperty
;
pro MGH_GUI_PropertySheet::GetProperty, $
     CLIENT=client, IMMEDIATE=immediate, SPECTATOR=spectator, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if arg_present(client) then client = self.client->Get(/ALL)

   if arg_present(spectator) then spectator = self.spectator->Get(/ALL)

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_PropertySheet::SetProperty
;
pro MGH_GUI_PropertySheet::SetProperty, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_GUI_PropertySheet::About
;
pro MGH_GUI_PropertySheet::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

end

pro MGH_GUI_PropertySheet::BuildMenuBar

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

   obar->NewItem, PARENT='Window', ['Show Spectator']

   obar->NewItem, PARENT='Help', ['About']

end

pro MGH_GUI_PropertySheet::BuildButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.button_bar gt 0 then $
        message, 'The button bar can only be created once'

   ;; Add an invisible base above the button bar to enforce a minimum
   ;; width for the widget. This is necessary on Windows because
   ;; otherwise the menu bar wraps around and messes up vertical
   ;; layout.

   self->NewChild, 'widget_base', XSIZE=200, YPAD=0

   self->NewChild, 'widget_base', UNAME='BUTTON_BAR', /ROW, $
        /ALIGN_CENTER, /BASE_ALIGN_CENTER, RESULT=btn
   self.button_bar = temporary(btn)

   self->NewChild, PARENT=self.button_bar, 'widget_button', $
        VALUE='Close', UNAME='BUTTON_CLOSE'

   self->NewChild, PARENT=self.button_bar, 'widget_button', $
        VALUE='Update', UNAME='BUTTON_UPDATE'

end

pro MGH_GUI_PropertySheet::BuildPropertySheet

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.property_sheet gt 0 then $
        message, 'The property sheet widget can be created only once'

   client = self.client->Get(/ALL, COUNT=n_client)

   if n_client gt 0 then begin
      self->NewChild, 'widget_propertysheet', UNAME='PROPERTY_SHEET', $
          VALUE=client, RESULT=ps
      self.property_sheet = temporary(ps)
   endif

end

function MGH_GUI_PropertySheet::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   uname = widget_info(event.id, /UNAME)

   case uname of

      'PROPERTY_SHEET': begin
         if event.type eq 0 then begin
            value = widget_info(event.id, COMPONENT=event.component, $
                                PROPERTY_VALUE=event.identifier)
            event.component->SetPropertyByIdentifier, event.identifier, value
         endif
         self->NotifySpectator
         return, 0
      end

      'BUTTON_CLOSE': begin
         self->Kill
         return, 0
      end

      'BUTTON_UPDATE': begin
         self->Update
         return, 0
      end

      else: return, self->MGH_GUI_Base::Event(event)

   endcase

end

function MGH_GUI_PropertySheet::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   uname = widget_info(event.id, /UNAME)

   case event.value of

      'FILE.CLOSE': begin
         self->Kill
         return, 0
      end

      'WINDOW.SHOW SPECTATOR': begin
         self->ShowSpectator
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->MGH_GUI_Base::EventMenuBar(event)

   endcase

end

pro MGH_GUI_PropertySheet::NotifySpectator

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   spectator = self.spectator->Get(/ALL, COUNT=n_spectator)

   for i=0,n_spectator-1 do $
        if obj_valid(spectator[i]) then spectator[i]->Update

end

; MGH_GUI_PropertySheet::ShowSpectator
;
;   Show or hide the client
;
pro MGH_GUI_PropertySheet::ShowSpectator, FLAG=flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = 1

   spectator = self.spectator->Get(/ALL, COUNT=n_spectator)

   for i=0,n_spectator-1 do begin
      if obj_valid(spectator[i]) then begin
         spectator[i]->Update
         spectator[i]->Show, flag
      endif
   endfor

end


; MGH_GUI_PropertySheet::Update
;
pro MGH_GUI_PropertySheet::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if widget_info(self.property_sheet, /VALID_ID) then $
        widget_control, self.property_sheet, /REFRESH_PROPERTY

end

; MGH_GUI_PropertySheet__Define
;
pro MGH_GUI_PropertySheet__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGH_GUI_PropertySheet, inherits MGH_GUI_Base, $
         edit_bar: 0L, button_bar: 0L, property_sheet: 0L, $
         client: obj_new(), spectator: obj_new()}

end


