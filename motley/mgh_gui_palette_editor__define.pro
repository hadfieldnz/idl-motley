; svn $Id$
;+
; CLASS:
;   MGH_GUI_Palette_Editor
;
; PURPOSE:
;   This class implements a widget application incorporating a
;   MGH_CW_PALETTE_EDITOR widget. It is used to edit an Object
;   Graphics palette object. The application can maintain a list of
;   "clients", which are notified when the palette is changed.
;
; CATEGORY:
;       Widgets, Object Graphics.
;
; PROPERTIES:
;     CLIENT (Init)
;       This keyword specifies a list of client objects. Extra clients
;       can be added subsequently with the AddClient method.
;
;     CT_FILE (Init, Get)
;       The colour table file from which the predefined colour tables
;       are drawn. Default is the value of !MGH_CT_FILE or, if this is
;       not available, an empty string which cause the IDL default
;       colour table file to be used.
;
;     FRAME (Init)
;       Width of the frame surrounding the top-level base..
;
;     PALETTE (Init, Get)
;       The palette whose colour table is to be edited.
;
;     YSIZE (Init)
;       Height of the MGH_CW_PALETTE_EDITOR widget.
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
;   Mark Hadfield, 1999-10:
;     Written.
;   Mark Hadfield, 2002-10:
;     Upgraded for IDL 5.6.
;   Mark Hadfield, 2002-11:
;     The embedded palette-editor widget has been changed from
;     CW_PALETTE_EDITOR to MGH_CW_PALETTE_EDITOR. The latter is a
;     modified form of the former, allowing a different colour-table
;     file to be specified.
;-


; MGH_GUI_Palette_Editor::Init
;
function MGH_GUI_Palette_Editor::Init, opalette, $
     CLIENT=client, CT_FILE=ct_file, FRAME=frame, IMMEDIATE=immediate, PALETTE=palette, $
     VISIBLE=visible, YSIZE=ysize, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Keyword defaults

   if n_elements(ct_file) eq 0 then ct_file = mgh_ct_file()

   if n_elements(frame) eq 0 then frame = 2

   if n_elements(palette) gt 0 then $
        self.palette = palette $
   else if n_elements(opalette) gt 0 then $
        self.palette = opalette

   if n_elements(visible) eq 0 then visible = 1

   if n_elements(ysize) eq 0 then ysize=128

   ;; Properties

   self.immediate = n_elements(immediate) gt 0 ? keyword_set(immediate) : 0

   ;; Create a container for clients, to be notified when
   ;; the palette is changed. Add the clients, if any, to it.

   self.clients = obj_new('MGH_Container', DESTROY=0)
   self->AddClient, client

   ;; Initialise the base widget. The base is originally made invisible (unless modal);
   ;; its visibility will be reset when initialisation is completed.

   ok = self->MGH_GUI_Base::Init(MODAL=modal, /BASE_ALIGN_CENTER, /COLUMN, $
                                 TLB_SIZE_EVENTS=0, TLB_FRAME_ATTR=1, $
                                 TITLE='IDL Palette Editor', VISIBLE=0, $
                                 _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Create & add the palette editor widget.

   self->NewChild, 'mgh_cw_palette_editor', RESULT=ochild, $
        FILE=ct_file, FRAME=frame, YSIZE=ysize, $
        UVALUE=self->Callback('EventPaletteEditor')

   self.palette_editor = ochild

   ;; Add other interface elements

   self->BuildMenuBar
   self->BuildButtonBar

   ;; Realise the widgets to ensure that the object window contained
   ;; in the palette editor is created

   self->Realize

   ;; Finalise appearance & return. It seems to be necessary (at least in
   ;; IDL 5.6) tp load data *after* the object is made visible to ensure that
   ;; its display is updated.

   self->SetProperty, VISIBLE=visible

   self->LoadData

   self->Finalize, 'MGH_GUI_Palette_Editor'

   return, 1

end


; MGH_GUI_Palette_Editor::Cleanup
;
pro MGH_GUI_Palette_Editor::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    obj_destroy, self.clients

    self->MGH_GUI_Base::Cleanup

end


; MGH_GUI_Palette_Editor::GetProperty
;
PRO MGH_GUI_Palette_Editor::GetProperty, $
     PALETTE=palette, STATUS=status, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   palette = self.palette

   status = self.status

   self->MGH_GUI_Base::GetProperty, _EXTRA=extra

end

; MGH_GUI_Palette_Editor::About
;
pro MGH_GUI_Palette_Editor::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   self->GetProperty, PALETTE=palette

   if obj_valid(palette) then $
        printf, lun, self, 'The palette is '+mgh_obj_string(palette, /SHOW_NAME)

   clients = self.clients->Get(/ALL, COUNT=n_clients)

   case n_clients gt 0 of
      0: begin
         printf, lun, self, 'There are no clients'
      end
      1: begin
         printf, lun, self, 'The clients are: '+ $
                 strjoin(mgh_obj_string(clients, /SHOW_TITLE))
      end
   endcase

end

; MGH_GUI_Palette_Editor::AddClient

; Purpose:
;   Add one or more client objects to the container
;
pro MGH_GUI_Palette_Editor::AddClient, Client

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(client)-1 do self.clients->Add, client[i]

end

; MGH_GUI_Palette_Editor::BuildButtonBar
;
;   Show the button bar
;
pro MGH_GUI_Palette_Editor::BuildButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.button_bar gt 0 then $
        message, 'The button bar can only be created once'

   obar = self->NewChild('MGH_GUI_Base', /OBJECT, /ROW, /ALIGN_CENTER, $
                         /BASE_ALIGN_CENTER, UVALUE=self->Callback('EventButtonBar'))

   self.button_bar = obar->GetBase()

   ;; Add an invisible base above the button bar to enforce a minimum
   ;; width for the widget. This is necessary on Windows because
   ;; otherwise the menu bar wraps around and messes up vertical
   ;; layout.

   self->NewChild, 'widget_base', XSIZE=200, YPAD=0, YSIZE=0

   case self.immediate of

      0: begin
         obar->NewChild, 'widget_button', VALUE='OK', UNAME='OK'
         obar->NewChild, 'widget_button', VALUE='Cancel', UNAME='Cancel'
         obar->NewChild, 'widget_button', VALUE='Apply', UNAME='Apply'
         obar->NewChild, 'widget_button', VALUE='Reset', UNAME='Reset'
      end

      else: obar->NewChild, 'widget_button', VALUE='Close', UNAME='Close'

   endcase

end

; MGH_GUI_Palette_Editor::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_GUI_Palette_Editor::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   obar = obj_new('MGH_GUI_PDmenu', ['File','Window','Help'], BASE=self.menu_bar, /MBAR)

   obar->NewItem, PARENT='File', ['Close']

   obar->NewItem, PARENT='Window', ['Show Clients']

   obar->NewItem, PARENT='Help', ['About']

end

function MGH_GUI_Palette_Editor::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.CLOSE': begin
         self.status = 0
         self->Kill
         return, 0
      end

      'WINDOW.SHOW CLIENTS': begin
         self->ShowClient, /ALL
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_GUI_Palette_Editor::EventButtonBar
;
function MGH_GUI_Palette_Editor::EventButtonBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.uname of

      'OK': begin
         self.status = 1
         self->StoreData
         self->NotifyClient, /ALL
         self->Kill
         return, 0
      end

      'Cancel': begin
         self.status = 0
         self->Kill
         return, 0
      end

      'Apply': begin
         self->StoreData
         self->Update
         self->NotifyClient, /ALL
         return, 0
      end

      'Reset': begin
         self->LoadData
         self->Update
         return, 0
      end

      'Close': begin
         self.status = 1
         self->Kill
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_GUI_Palette_Editor::EventPaletteEditor
;
function MGH_GUI_Palette_Editor::EventPaletteEditor, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.immediate of

      0: return, 0

      1: begin
         self->StoreData
         self->Update
         self->NotifyClient, /ALL
         return, 0
      end

   endcase

end

; MGH_GUI_Palette_Editor::LoadData
;
pro MGH_GUI_Palette_Editor::LoadData

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.palette) then return

   self.palette->GetProperty, RED=r, GREEN=g, BLUE=b

   nc = n_elements(r) < n_elements(g) < n_elements(b)

   data = bytarr(3,256)
   data[0,0:nc-1] = r
   data[1,0:nc-1] = g
   data[2,0:nc-1] = b

   widget_control, self.palette_editor, SET_VALUE=data

end

pro MGH_GUI_Palette_Editor::NotifyClient, Client, ALL=all

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(all) then client = self.clients->Get(/ALL)

   for i=0,n_elements(client)-1 do if obj_valid(client[i]) then client[i]->Update

end

; MGH_GUI_Palette_Editor::ShowClient
;
;   Show or hide one or more clients
;
pro MGH_GUI_Palette_Editor::ShowClient, Client, ALL=all, FLAG=flag

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


; MGH_GUI_Palette_Editor::StoreData
;
PRO MGH_GUI_Palette_Editor::StoreData

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.palette) then return

   widget_control, self.palette_editor, GET_VALUE=data

   self.palette->GetProperty, RED=r, GREEN=g, BLUE=b

   nc = n_elements(r) < n_elements(g) < n_elements(b)

   self.palette->SetProperty, $
        RED=data[0,0:nc-1], GREEN=data[1,0:nc-1], BLUE=data[2,0:nc-1]

end

; MGH_GUI_Palette_Editor::Update
;
pro MGH_GUI_Palette_Editor::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->UpdateButtonBar

end

; MGH_GUI_Palette_Editor::UpdateButtonBar
;
pro MGH_GUI_Palette_Editor::UpdateButtonBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.button_bar)

   if obj_valid(obar) then begin

      n_clients = self.clients->Count()

      case self.immediate of

         0:

         1: begin
            wid = obar->FindChild('Apply')
            if widget_info(wid, /VALID_ID) then $
                 widget_control, wid, SENSITIVE=(n_clients gt 0)
            wid = obar->FindChild('Reset')
            if widget_info(wid, /VALID_ID) then $
                 widget_control, wid, SENSITIVE=(n_clients gt 0)
         end

      endcase

   end

end


; MGH_GUI_Palette_Editor__Define
;
pro MGH_GUI_Palette_Editor__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_Palette_Editor, inherits MGH_GUI_Base, $
                 palette_editor: 0L, button_bar: 0L, immediate: 0B, $
                 palette: obj_new(), clients: obj_new(), status: 0B}

end


