;+
; CLASS:
;   MGH_DGwindow
;
; PURPOSE:
;   This class encapsulates a widget application containing a direct
;   graphics window.  The window displays the results of one or more
;   direct-graphics commands, each stored in an MGH_Command object
;
; CATEGORY:
;       Widgets, Direct Graphics.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported:
;
;     COMMANDS (Init, Get, Set)
;       A list of MGH_Command objects specifying commands to be
;       executed each time the window is drawn.
;
;     DIMENSIONS (Init, Get, Set)
;       A 2-element array specifying the width & height of the
;       graphics window.
;
;     EXPAND_STATUS_BAR (Init, Get, Set)
;       This property determines whether the the "status bar" beneath
;       the draw widget is expanded or collapsed. Default is 1 (expanded).
;
;     MOUSE_ACTION (Get)
;       A 3-element string array specifying the mouse handler object
;       to be associated with each mouse button. Mouse press, release
;       & motion events that originate from the draw widget are sent
;       to "mouse handler" objects, one handler per mouse
;       button. These handlers are created and destroyed by the
;       SetUpMouseHandler method. For an MGH_DGwindow object, the
;       MOUSE_ACTION property is set to ['Pick','None','Context']
;       and cannot be changed.
;
;     RESIZEABLE (Init, Get)
;       Set this value to 1 (the default) to allow the base to be
;       resized and 0 to suppress resizing. The value cannot be
;       changed after initialisation because WIDGET_CONTROL does not
;       support this.
;
;     NAME (Init, Get, Set)
;       A name for the plot, to be used in forming file names.
;
;     RESIZEABLE (Init, Get)
;       This property controls what action is taken in response to
;       resize events. Valid values are:
;         0 - Base resizing does not change the window dimensions.
;         1 - Base resizing changes the window dimensions.
;         2 - Base resizing changes the window dimensions in such a
;             way that the aspect ratio is preserved. This is the
;             default.
;
;     TITLE (Get)
;       The title appears in the base widget's title bar. It is
;       calculated from the picture name.
;
;     TOOLTIP (Get)
;       The tool tip appears when the cursor hovers over the draw
;       widget. It is calculated from the picture name.
;
;     USE_PIXMAP (Init, Get)
;       This property specifies whether graphics commands will be sent
;       straight to the window (0) or rendered first in an off-screen
;       pixmap (1). Default is 0.
;
;###########################################################################
; Copyright (c) 2000-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield 2000-07:
;     Written, based on XWINDOW by David Fanning.
;   Mark Hadfield 2001-06:
;     Modified for the following name change: MGHdgCommand ->
;     MGH_Command. This reflects the fact that command objects are not
;     restricted to a Direct Graphics context.
;   Mark Hadfield 2001-09:
;     The Plot method is now deprecated in favour of NewCommand.
;   Mark Hadfield 2001-1:
;     - Added a DrawToClipboard method and a corresponding Edit.Copy
;       menu item based on David Fanning's CLIPBOARD routine.
;   Mark Hadfield, 2002-09:
;     - Increased maximum number of positional parameters allowed by
;       the NewCommand method to 4.
;   Mark Hadfield, 2002-10:
;     - Updated for IDL 5.6.
;     - Added mouse handling, using mouse-handler objects as in
;       MGH_Window.  Code is adapted from the latter but only two
;       mouse handlers are available (Pick & Context) and they cannot
;       be changed.
;   Mark Hadfield, 2004-03:
;     - Renamed all "DrawTo" methods to "WritePictureTo". This
;       was done for consistency with MGH_Window, MGH_Player and
;       MGH_DGplayer.
;     - Added a "WriteToImageFile" method..
;   Mark Hadfield, 2015-02:
;     - Default DIMENSIONS now 600x600.
;   Mark Hadfield, 2015-05:
;     Removed the facility to launch a clipboard viewer: the viewer is no
;     longer available in Windows.
;-
; MGH_DGwindow::Init
;
function MGH_DGwindow::Init, cmds, $
     BACKGROUND=background, COMMANDS=commands, DIMENSIONS=dimensions, ERASE=erase, $
     EXPAND_STATUS_BAR=expand_status_bar, NAME=name, RESIZEABLE=resizeable, $
     RESIZE_PRESERVE=resize_preserve, $
     RETAIN=retain, USE_PIXMAP=use_pixmap, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   mgh_mouse_handler_library

   ;; Create a container to hold the plotting commands.

   self.commands = obj_new('IDL_Container')

   ;; Load commands into container

   if n_elements(commands) eq 0 && n_elements(cmds) gt 0 then $
        commands = cmds

   for i=0,n_elements(commands)-1 do self.commands->Add, commands[i]

   ;; Defaults

   self.background = n_elements(background) gt 0 ? background : !p.background

   self.erase = keyword_set(erase)

   self.resizeable = keyword_set(resizeable)

   self.resize_preserve = $
        n_elements(resize_preserve) gt 0 ? keyword_set(resize_preserve) : 1B

   if n_elements(dimensions) eq 0 then dimensions = [600,600]

   if n_elements(expand_status_bar) eq 0 then expand_status_bar = 1B

   self.use_pixmap = keyword_set(use_pixmap)

   ;; Check that the current device supports graphics windows and save
   ;; the device name

   if (!d.flags and 256) eq 0 then $
        message, 'Current graphics device must support windows'

   self.display_name = !d.name

   ;; Create base

   ok = self->MGH_GUI_Base::Init(/COLUMN, /BASE_ALIGN_CENTER, /MBAR, /NOTIFY_REALIZE, $
                                 /TLB_SIZE_EVENTS, _STRICT_EXTRA=_extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; The following settings have been tuned for Windows. They may need modifying
   ;; on other platforms.

   expose_events = 0
   if n_elements(retain) eq 0 then retain = 2

   ;; Create a draw widget.

   self.draw_widget = $
        widget_draw(self.layout, UNITS=0, $
                    XSIZE=dimensions[0], YSIZE=dimensions[1], GRAPHICS_LEVEL=1, $
                    RETAIN=retain , EXPOSE_EVENTS=expose_events, BUTTON_EVENTS=1, $
                    UVALUE=self->Callback('EventWindow') )

   ;; Create an off-screen pixmap

   d_window = !d.window
   window, /FREE, /PIXMAP, XSIZE=dimensions[0], YSIZE=dimensions[1]
   self.pixmap = !d.window
   wset, d_window

   ;; Add other interface components

   self->BuildMenuBar

   self->BuildDrawContext

   self->BuildStatusBar, keyword_set(expand_status_bar)

   self->BuildStatusContext

   ;; Specify mouse action (not changeable) and set up mouse handlers.

   self.mouse_action = ['Pick','None','Context']
   for button=0,2 do self->SetUpMouseHandler, button

   ;; Set window ID to an impossible value. Otherwise if we try to draw
   ;; before realising the widget, output goes to window 0.

   self.window = 1000

   ;; Remaining set-up is done in the NotifyRealize method,
   ;; because it requires the index for the window that is
   ;; created when the draw widget is realised.

   ;; Pass other properties to SetProperty method

   self->MGH_DGwindow::SetProperty, NAME=name

   ;; Finalize and return

   self->Finalize, 'MGH_DGWindow'

   return, 1

end


; MGH_DGwindow::Cleanup
;
pro MGH_DGwindow::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.commands

   obj_destroy, self.mouse_handler

   if self.pixmap ge 0 then begin
      d_name = !d.name
      set_plot, self.display_name
      wdelete, self.pixmap
      set_plot, d_name
   endif

   self->MGH_GUI_Base::Cleanup

end


; MGH_DGwindow::GetProperty
;
pro MGH_DGwindow::GetProperty, $
     COMMANDS=commands, DIMENSIONS=dimensions, EXPAND_STATUS_BAR=expand_status_bar, $
     MOUSE_ACTION=mouse_action, N_COMMANDS=n_commands, NAME=name, $
     RESIZEABLE=resizeable, RESIZE_preserve=resize_preserve, $
     UNITS=units, $
     USE_PIXMAP=use_pixmap, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n_commands = self.commands->Count()

   if arg_present(commands) then begin
      case n_commands gt 0 of
         0: commands = -1
         1: begin
            commands = objarr(n_commands)
            for i=0,n_commands-1 do $
                 commands[i] = self.commands->Get(POSITION=i)
         end
      endcase
   endif

   if arg_present(dimensions) then begin
      geom = widget_info(self.draw_widget, /GEOMETRY)
      dimensions = [geom.xsize, geom.ysize]
   endif

   expand_status_bar = self.expand_status_bar

   mouse_action = self.mouse_action

   name = self.name

   resizeable = self.resizeable

   resize_preserve = self.resize_preserve

   units = 0

   use_pixmap = self.use_pixmap

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=_extra

end

; MGH_DGwindow::SetProperty
;
pro MGH_DGwindow::SetProperty, $
     COMMANDS=commands, DIMENSIONS=dimensions, EXPAND_STATUS_BAR=expand_status_bar, $
     NAME=name, RESIZEABLE=resizeable, RESIZE_PRESERVE=resize_preserve, $
     USE_PIXMAP=use_pixmap, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(commands) gt 0 then begin
      self.commands->Remove, /ALL
      for i=0,n_elements(commands)-1 do self.commands->Add, commands[i]
   endif

   if n_elements(name) gt 0 then begin
      self.name = name
      self->MGH_GUI_Base::SetProperty, TITLE='IDL Window - '+name
      l_max = 36
      tooltip= strlen(name) gt l_max ? strmid(name, 0, l_max-3) + '...' : name
      widget_control, self.draw_widget, TOOLTIP=tooltip
   endif

   if n_elements(resizeable) gt 0 then $
        self.resizeable = keyword_set(resizeable)

   if n_elements(resize_preserve) gt 0 then $
        self.resize_preserve = keyword_set(resize_preserve)

   if n_elements(dimensions) eq 2 then begin
      widget_control, self.draw_widget, XSIZE=dimensions[0], YSIZE=dimensions[1]
      if self.pixmap gt 0 then begin
         d_name = !d.name
         set_plot, self.display_name
         wdelete, self.pixmap
         window, /FREE, /PIXMAP, XSIZE=dimensions[0], YSIZE=dimensions[1]
         self.pixmap = !d.window
         set_plot, d_name
      endif
   endif

   if n_elements(expand_status_bar) gt 0 then $
        self->BuildStatusBar, keyword_set(expand_status_bar)

   if n_elements(use_pixmap) gt 0 then $
        self.use_pixmap = keyword_set(use_pixmap)

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=_extra

end

; MGH_DGwindow::About
;
;   Print information about the window and its contents
;
pro MGH_DGwindow::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   printf, lun, self, ': my window & pixmap indices are ', $
           strtrim(self.window,2), ' ', strtrim(self.pixmap,2)

   commands = self.commands->Get(/ALL, COUNT=n_commands)
   if n_commands gt 0 then begin
      printf, lun, self, ': I execute the following commands:'
      for i=0,n_commands-1 do printf, lun, '    ', commands[i]->String()
   endif

end

; MGH_DGwindow::AddCommand
;
;   Add an object to the commands container
;
pro MGH_DGwindow::AddCommand, obj, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.commands->Add, obj, _STRICT_EXTRA=_extra

end

; MGH_DGwindow::BuildDrawContext
;
pro MGH_DGwindow::BuildDrawContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.draw_context gt 0 then return

   items = ['About','Copy Bitmap']

   self->NewChild, /OBJECT, 'MGH_GUI_PDMenu', /CONTEXT, items, $
        UVALUE=self->Callback('EventDrawContext'), RESULT=omenu

   self.draw_context = omenu->GetBase()

end

; MGH_DGwindow::BuildMenuBar
;
pro MGH_DGwindow::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   iswin = strcmp(!version.os_family, 'Windows', /FOLD_CASE)

   ;; Create a pulldown menu object with top-level items.

   obar = obj_new('MGH_GUI_PDmenu', BASE=self.menu_bar, /MBAR, $
                  ['File','Edit','Tools','Window','Help'])

   ;; Populate menus in turn...

   ;; ...File menu

   obar->NewItem, PARENT='File', ['Export','Print...','Close'], MENU=[1,0,0]

   case iswin of
      0B: fmts = ['EPS...','PNG...']
      1B: fmts = ['EPS...','PNG...','WMF...']
   endcase
   obar->NewItem, PARENT='File.Export', temporary(fmts)

   ;; ...Edit menu

   obar->NewItem, PARENT='Edit', ['Copy']

   ;; ...Tools menu

   obar->NewItem, PARENT='Tools', ['Export Data...']

   ;; ...Window menu

   obar->NewItem, PARENT='Window', ['Update','Expand/Collapse'], MENU=[0,1]

   obar->NewItem, PARENT='Window.Expand/Collapse', ['Status Bar ']

   ;; ...Help menu

   obar->NewItem, PARENT='Help', ['About']

end

; MGH_DGWindow::BuildStatusBar
;
pro MGH_DGWindow::BuildStatusBar, expand

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default is to toggle the state of the bar

   if n_elements(expand) eq 0 then expand = (self.expand_status_bar eq 0)

   ;; Check that the base exists. Once created, this will not be
   ;; destroyed, thus ensuring that the order of toolbars will not
   ;; change

   case widget_info(self.status_bar, /VALID_ID) of
      0: begin
         obar = self->NewChild('MGH_GUI_Base', /OBJECT, $
                               UVALUE=self->Callback('EventStatusBar'))
         self.status_bar = obar->GetBase()
         new = 1B
      end
      1: begin
         obar = mgh_widget_self(self.status_bar)
         new = 0B
      end
   endcase

   ;; If bar is already in required state, then no action is necessary

   if (~ new) && (keyword_set(expand) eq self.expand_status_bar) then return

   ;; Clear all children from the base

   obar->Clear

   ;; Now populate the bar

   case keyword_set(expand) of

      0: begin
         obar->NewChild, 'MGH_GUI_Base', /OBJECT, XSIZE=200, YSIZE=5, /FRAME, $
              /CONTEXT_EVENTS, PROCESS_EVENTS=0, UNAME='STATUS_BASE'
      end

      1: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, /ROW, /ALIGN_CENTER, $
              /BASE_ALIGN_CENTER, /CONTEXT_EVENTS, XPAD=10, PROCESS_EVENTS=0, $
              UNAME='STATUS_BASE', RESULT=obase
         obase->NewChild, 'widget_label', VALUE=' ', UNAME='STATUS_INFO', /DYNAMIC_RESIZE
         obase->NewChild, 'widget_label', VALUE='  '
         obase->NewChild, 'widget_base', /NONEXCLUSIVE, /ROW, RESULT=rbase
         obase->NewChild, 'widget_button', PARENT=rbase, UNAME='RESIZEABLE', $
              VALUE='Resize'
         obase->NewChild, 'widget_button', PARENT=rbase, UNAME='RESIZE_PRESERVE', $
              VALUE='Keep Aspect'
      end

   endcase

   self.expand_status_bar = keyword_set(expand)

end

; MGH_DGWindow::BuildStatusContext
;
pro MGH_DGWindow::BuildStatusContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.status_context gt 0 then return

   omenu = self->NewChild(/OBJECT, 'MGH_GUI_PDMenu', /CONTEXT, ['Expand Status Bar'], $
                          UVALUE=self->Callback('EventStatusContext'))

   self.status_context = omenu->GetBase()

end

; MGH_DGwindow::Draw
;
pro MGH_DGwindow::Draw

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   d_name = !d.name

   set_plot, self.display_name

   tvlct, r, g, b, /GET

   d_window = !d.window

   wset, self.use_pixmap ? self.pixmap : self.window

   if self.erase then erase, COLOR=self.background

   for i=0,self.commands->Count()-1 do begin
      command = self.commands->Get(POSITION=i)
      if obj_valid(command) then command->Execute
   endfor

   if self.use_pixmap then begin
      wset, self.window
      self->GetProperty, DIMENSIONS=dimensions
      device, COPY=[0,0,dimensions,0,0,self.pixmap]
   endif

   tvlct, r, g, b

   wset, d_window

   set_plot, d_name

end

; MGH_DGwindow::EventBase
;
function MGH_DGwindow::EventBase, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case tag_names(event, /STRUCTURE_NAME) of

      'WIDGET_BASE': begin
         self->Resize, event.x, event.y
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end


; MGH_DGWindow::EventDrawContext
;
function MGH_DGwindow::EventDrawContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'ABOUT': begin
         self->About
         return, 0
      end

      'COPY BITMAP': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_DGwindow::EventMenuBar
;
function MGH_DGwindow::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.PRINT': begin
         if dialog_printersetup() then begin
            widget_control, HOURGLASS=1
            self->WritePictureToPrinter, /BANNER
         endif
         return, 0
      end

      'FILE.EXPORT.EPS': begin
         self->GetProperty, NAME=name
         ext = '.eps'
         case strlen(name) of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                          mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            widget_control, HOURGLASS=1
            self->WritePictureToPostscriptFile, filename
         endif
         return, 0
      end

      'FILE.EXPORT.PNG': begin
         self->GetProperty, NAME=name
         ext = '.png'
         case strlen(name) of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                          mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            widget_control, HOURGLASS=1
            self->WritePictureToImageFile, filename
         endif
         return, 0
      end

      'FILE.EXPORT.WMF': begin
         self->GetProperty, NAME=name
         ext = '.wmf'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                          mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            widget_control, HOURGLASS=1
            self->WritePictureToMetaFile, filename
         endif
         return, 0
      end

      'FILE.CLOSE': begin
         self->Kill
         return, 0
      end

      'EDIT.COPY': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard
         return, 0
      end

      'TOOLS.EXPORT DATA': begin
         self->ExportData, values, labels
         ogui = obj_new('MGH_GUI_Export', values, labels, /BLOCK, /FLOATING, $
                        GROUP_LEADER=self.base)
         ogui->Manage
         obj_destroy, ogui
         return, 0
      end

      'WINDOW.UPDATE': begin
         self->Update
         return, 0
      end

      'WINDOW.EXPAND/COLLAPSE.STATUS BAR': begin
         self->BuildStatusBar
         self->UpdateStatusBar
         self->UpdateStatusContext
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_DGwindow::EventMouse
;
;   For a specified mouse button, establish whether this event (from the draw widget)
;   is of interest to this button's handler and take appropriate action
;
function MGH_DGwindow::EventMouse, event, button

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Reject the event if this button is inactive

   if self.mouse_action[button] eq 'None' then return, event

   ;; Check event type

   case event.type of
      0: begin
         ;; Pass on press events from other buttons
         if event.press ne (2^button) then return, event
      end
      1: begin
         ;; Pass on release events from other buttons
         if event.release ne (2^button) then return, event
      end
      2:                        ; Accept motion events
      else: return, event       ; Reject all non-mouse events
   endcase

   ;; Pass the event to this button's mouse-handler object's Event method.

   if obj_valid(self.mouse_handler[button]) then $
        self.mouse_handler[button]->Event, event

   ;; Return 0 for press and release events, to indicate that these
   ;; have been completely handled. For motion events (which are not
   ;; associated with any particular button) we pass the event on
   ;; because a handler associated with another mouse button may be
   ;; interested in them.

   case event.type gt 1 of
      0: return, 0
      1: return, event
   endcase

end

; MGH_DGwindow::EventStatusBar
;
function MGH_DGwindow::EventStatusBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.uname of

      'STATUS_BASE': begin
         widget_displaycontextmenu, event.event.id , event.event.x, $
                                    event.event.y, self.status_context
         return, 0
      end

      'RESIZEABLE': begin
         self->SetProperty, RESIZEABLE=event.event.select
         self->UpdateStatusBar
         return, 0
      end

      'RESIZE_PRESERVE': begin
         self->SetProperty, RESIZE_PRESERVE=event.event.select
         self->UpdateStatusBar
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_DGWindow::EventStatusContext
;
function MGH_DGWindow::EventStatusContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'EXPAND STATUS BAR': begin
         self->BuildStatusBar
         self->UpdateStatusBar
         self->UpdateStatusContext
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_DGwindow::EventWindow
;
;   Handle events from the graphics window (draw widget)
;
function MGH_DGwindow::EventWindow, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1 of

      event.type le 2: begin    ; Mouse event

         event = self->EventMouse(event,0)
         if ~ mgh_is_event(event) then return, 0
         event = self->EventMouse(event,1)
         if ~ mgh_is_event(event) then return, 0
         event = self->EventMouse(event,2)
         if ~ mgh_is_event(event) then return, 0

         ;; Many mouse events are left unhandled by the above methods.
         ;; We ignore them--this could be modified to allow mouse events to
         ;; be passed on to subclasses.

         return, 0

      end

      event.type eq 4: begin    ; Expose event

         self->Draw
         return, 0

      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_DGwindow::ExportData
;
pro MGH_DGwindow::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   labels = ['Self', 'Window Index', 'Pixmap Index']
   values = [ptr_new(self), ptr_new(self.window), ptr_new(self.pixmap)]

end

; MGH_DGwindow::NewCommand
;
;   Construct a command object & store it in the commands container
;
function MGH_DGwindow::NewCommand, command, p1, p2, p3, p4, p5, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = obj_new('MGH_Command', command, p1, p2, p3, p4, p5, _STRICT_EXTRA=_extra)

   self->AddCommand, result

   return, result

end

pro MGH_DGwindow::NewCommand, command, p1, p2, p3, p4, p5, $
     RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      1: result = self->NewCommand( command, _STRICT_EXTRA=_extra )
      2: result = self->NewCommand( command, p1, _STRICT_EXTRA=_extra )
      3: result = self->NewCommand( command, p1, p2, _STRICT_EXTRA=_extra )
      4: result = self->NewCommand( command, p1, p2, p3, _STRICT_EXTRA=_extra )
      5: result = self->NewCommand( command, p1, p2, p3, p4, _STRICT_EXTRA=_extra )
      6: result = self->NewCommand( command, p1, p2, p3, p4, p5, _STRICT_EXTRA=_extra )
   endcase

end

; MGH_DGwindow::NotifyRealize
;
pro MGH_DGwindow::NotifyRealize

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; The base widget has now been realized. This creates an
   ;; direct-graphics window; we store the reference in the object
   ;; structure.

   widget_control, self.draw_widget, GET_VALUE=thewindow
   self.window = thewindow

   self->GetProperty, DIMENSIONS=dimensions
   window, /FREE, /PIXMAP, XSIZE=dimensions[0], YSIZE=dimensions[1]

   self->Update

end

; MGH_DGwindow::PickReport
;
pro MGH_DGwindow::PickReport, pos, LUN=lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(lun) eq 0 then lun = -1

   if n_elements(pos) ne 2 then $
        message, 'Parameter POS must be a 2-element vector'

   printf, lun, FORMAT='(%"%s: pick at %d %d (device) %f %f %f (data)")', $
           mgh_obj_string(self), pos, convert_coord(pos, /DEVICE, /TO_DATA)

end

; MGH_DGwindow::Resize
;
pro MGH_DGwindow::Resize, x, y

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, DIMENSIONS=dimensions

   ;; If the RESIZEABLE property is 0, then just reset the
   ;; window's DIMENSIONS property to force the base to resize itself
   ;; around the window

   if self.resizeable eq 0 then begin
      self->SetProperty, DIMENSIONS=dimensions
      return
   endif

   ;; If the RESIZEABLE property is set, then resize the window
   ;; to the new size

   ;; Widget geometry calculations are worked out via a combination of
   ;; reading the documentation and trial & error. I'm not sure if
   ;; they are robust but they seem to work in the situations tested.

   ;; Why do we subtract 3*ypad below and only 2*xpad? I don't know
   ;; but it seems that column bases have extra padding in the Y
   ;; direction and row bases have extra padding in the X direction.

   self->GetProperty, GEOMETRY=geom_base
   xx = x - 2*geom_base.margin - 2*geom_base.xpad
   yy = y - 2*geom_base.margin - 3*geom_base.ypad

   obar = mgh_widget_self(self.status_bar)
   if obj_valid(obar) then begin
      obar->GetProperty, GEOMETRY=geom_bar
      yy = yy - geom_bar.scr_ysize - geom_base.space
   endif

   ;; Calculate & apply new dimensions

   new_dimensions = [xx > 200, yy > 150]

   if self.resize_preserve then $
        new_dimensions = sqrt(product(new_dimensions/dimensions))*dimensions

   self->SetProperty, DIMENSIONS=new_dimensions

   self->Update

end

; MGH_DGWindow::SetUpMouseHandler
;
pro MGH_DGwindow::SetUpMouseHandler, b

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.mouse_handler[b]

   case self.mouse_action[b] of
      'None':
      'Pick': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Pick', self)
      end
      'Context': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Context', self.draw_context)
      end
   endcase

end

; MGH_DGwindow::Update
;
; Purpose:
;   This is the method that should normally be called to redisplay the
;   window and its contents when anything has changed.
;
pro MGH_DGwindow::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->Draw

   self->UpdateMenuBar

   self->UpdateStatusBar
   self->UpdateStatusContext

end

; MGH_DGwindow::UpdateMenuBar
;
pro MGH_DGwindow::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin
      self->GetProperty, N_COMMANDS=n_commands
      obar->SetItem, 'File.Export', SENSITIVE=(n_commands gt 0)
   endif

end

; MGH_DGwindow::UpdateStatusBar
;
; Reset the sensitivity & value of various menu items & buttons.
;
pro MGH_DGwindow::UpdateStatusBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.status_bar)

   if obj_valid(obar) then begin

      wid = obar->FindChild('STATUS_INFO')
      if widget_info(wid, /VALID_ID) then begin
         self->GetProperty, DIMENSIONS=dimensions
         dim_text = strjoin(strtrim(string(round(dimensions)),2),' x ')
         status_text = 'Dim: '+dim_text
         widget_control, wid, SET_VALUE=status_text
      endif

      wid = obar->FindChild('RESIZEABLE')
      if widget_info(wid, /VALID_ID) then $
           widget_control, wid, SET_BUTTON=self.resizeable

      wid = obar->FindChild('RESIZE_PRESERVE')
      if widget_info(wid, /VALID_ID) then begin
         widget_control, wid, SET_BUTTON=self.resize_preserve
         widget_control, wid, SENSITIVE=self.resizeable
      endif

   endif

end

; MGH_DGWindow::UpdateStatusContext
;
pro MGH_DGWindow::UpdateStatusContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.status_context)

   if obj_valid(omenu) then begin

      self->GetProperty, EXPAND_STATUS_BAR=expand_status_bar

      omenu->SetItem, 'Expand Status Bar', $
           VALUE=(expand_status_bar ? 'Collapse' : 'Expand')+' Status Bar'

   endif

end

; MGH_DGwindow::WritePictureToClipboard
;
pro MGH_DGwindow::WritePictureToClipboard

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Save the Direct Graphics state

   d_name = !d.name

   set_plot, self.display_name

   tvlct, r, g, b, /GET

   d_window = !d.window

   ;; Render the commands to the pixmap and take a snapshot

   wset, self.pixmap

   if self.erase then erase, COLOR=self.background

   for i=0,self.commands->Count()-1 do begin
      command = self.commands->Get(POSITION=i)
      if obj_valid(command) then command->Execute
   endfor

   snapshot = tvrd(/TRUE)

   ;; Restore the direct graphics state

   tvlct, r, g, b

   wset, d_window

   set_plot, d_name

   ;; Load the snapshot into a view & render it to clipboard object
   ;; then destroy all temporary objects.

   dims = (size(snapshot, /DIMENSIONS))[1:2]

   mgh_new, 'IDLgrImage', snapshot, LOCATION=[-0.5,-0.5], DIMENSIONS=[1,1], RESULT=oimage

   mgh_new, 'IDLgrModel', RESULT=omodel
   omodel->Add, oimage

   mgh_new, 'IDLgrView', VIEWPLANE_RECT=[-0.5,-0.5,1,1], RESULT=oview
   oview->Add, omodel

   mgh_new, 'IDLgrClipboard', UNITS=0, DIMENSIONS=dims, RESULT=oclip

   oclip->Draw, oview

   obj_destroy, [oview,oclip]

end

; MGH_DGwindow::WritePictureToImageFile
;
pro MGH_DGwindow::WritePictureToImageFile, file, JPEG=jpeg, PNG=png, PPM=ppm

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(file) eq 0 then $
        message, 'A file name must be supplied'

   case 1B of
      keyword_set(jpeg): filetype = 'JPEG'
      keyword_set(ppm): filetype = 'PPM'
      else: filetype = 'PNG'
   endcase

   ;; Save the Direct Graphics state

   d_name = !d.name

   set_plot, self.display_name

   tvlct, r, g, b, /GET

   d_window = !d.window

   ;; Render the commands to the pixmap and take a snapshot

   wset, self.pixmap

   if self.erase then erase, COLOR=self.background

   for i=0,self.commands->Count()-1 do begin
      command = self.commands->Get(POSITION=i)
      if obj_valid(command) then command->Execute
   endfor

   snapshot = tvrd(/TRUE)

   ;; Restore the direct graphics state

   tvlct, r, g, b

   wset, d_window

   set_plot, d_name

   ;; Write the (true-colour) image into the file

   dim = size(snapshot, /DIMENSIONS)

   fmt = '(%"%s: Writing %d x %d image to %s file %s")'
   print, FORMAT=fmt, mgh_obj_string(self), dim[1:2], filetype, file

   case filetype OF

      'JPEG': begin
         write_image, File, 'JPEG', snapshot
      end

      'PNG': begin
         write_image, File, 'PNG', snapshot
      end

      'PPM': begin
         write_image, File, 'PPM', reverse(snapshot, 3)
      end

   endcase

end

; MGH_DGwindow::WritePictureToMetaFile
;
pro MGH_DGwindow::WritePictureToMetaFile, file

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(file) eq 0 then $
        message, 'A file name must be supplied'

   self->GetProperty, DIMENSIONS=dimensions

   d_name = !d.name

   set_plot, 'METAFILE'

   device, XSIZE=dimensions[0]/30, YSIZE=dimensions[1]/30, FILE=file

   for i=0,self.commands->Count()-1 do begin
      command = self.commands->Get(POSITION=i)
      if obj_valid(command) then command->Execute
   endfor

   device, /CLOSE

   set_plot, d_name

end

; MGH_DGwindow::WritePictureToPostscriptFile
;
pro MGH_DGwindow::WritePictureToPostscriptFile, file

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(file) eq 0 then $
        message, 'A file name must be supplied'

   self->GetProperty, DIMENSIONS=dimensions

   d_name = !d.name

   set_plot, 'PS'

   device, XSIZE=dimensions[0]/30, YSIZE=dimensions[1]/30, XOFFSET=0, YOFFSET=0, $
           BITS_PER_PIXEL=8, /COLOR, ENCAPSULATED=1, PREVIEW=0, FILE=file

   for i=0,self.commands->Count()-1 do begin
      command = self.commands->Get(POSITION=i)
      if obj_valid(command) then command->Execute
   endfor

   device, /CLOSE

   set_plot, d_name

end

; MGH_DGwindow::WritePictureToPrinter
;
pro MGH_DGwindow::WritePictureToPrinter, BANNER=banner

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   d_name = !d.name

   set_plot, 'PRINTER'

   ;; We are trying to make the figure size on the printed page equal
   ;; the on-screen size. Assume a screen resolution of 96 dpi =
   ;; 0.0265 cm.

   self->GetProperty, DIMENSIONS=dimensions, NAME=name

   device, GET_PAGE_SIZE=psize

   fsize = 0.0265*dimensions
   psize = psize/[!d.x_px_cm,!d.y_px_cm]

   xsize = fsize[0]
   ysize = fsize[1]
   xoffset = 0.5*(psize[0]-fsize[0]) > 0
   yoffset = 0.5*(psize[1]-fsize[1]) > 0

   device, XSIZE=xsize, YSIZE=ysize, XOFFSET=xoffset, YOFFSET=yoffset

   for i=0,self.commands->Count()-1 do begin
      command = self.commands->Get(POSITION=i)
      if obj_valid(command) then command->Execute
   endfor

   if keyword_set(banner) then begin

      ;; I'm not sure if it's permitted to resize the device without
      ;; closing a document like this, but give it a go!

      device, XSIZE=psize[0], YSIZE=psize[1], XOFFSET=0, YOFFSET=0

      if strlen(name) eq 0 then name = 'IDL plot'

      banner_text = $
           string(FORMAT='(%"%s printed at %s")', $
                  name, mgh_dt_string(mgh_dt_now(), ZONE=mgh_dt_zone()))

      xyouts, 0.05, 0.05, banner_text, /NORMAL

   endif

   device, /CLOSE_DOCUMENT

   set_plot, d_name

end

; MGH_DGwindow__Define
;
pro MGH_DGwindow__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_DGwindow, inherits MGH_GUI_Base, $
                 commands: obj_new(), display_name: '', $
                 draw_context: 0L, draw_widget: 0L, $
                 expand_status_bar: 0B, status_bar: 0L, status_context: 0L, $
                 window: 0L, pixmap: 0L, resizeable: 0B, resize_preserve: 0B, erase: 0B, $
                 mouse_action: strarr(3), mouse_handler: objarr(3), $
                 background: 0B, name: '', use_pixmap: 0B}

end


