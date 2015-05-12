;+
; CLASS:
;   MGH_Window
;
; PURPOSE:
;   This class encapsulates a widget application containing an object
;   graphics window. The window displays a single picture (ie a
;   IDLgrView, IDLgrViewGroup or IDLgrScene).
;
; CATEGORY:
;   Widgets, Object Graphics.
;
; POSITIONAL PARAMETERS FOR INIT METHOD:
;   picture
;     A synonym for the GRAPHICS_TREE property.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported:
;
;     BACKGROUND_COLOR (Init, Get, Set)
;       A 3-element byte array specifying the RGB colour to which the
;       window will be erased before every draw. The default is
;       [127,127,127].
;
;     COLOR_MODEL (Init, Get)
;       This property is inherited from the embedded IDLgrWindow. The
;       default is 0 (RGB) and the code has never been tested and
;       probably will not work with a value of 1 (indexed).
;
;     BACKGROUND_COLOR (Init, Get, Set)
;       A 3-element byte array specifying the RGB colour to which the
;       window will be erased before every draw. The default is
;       [127,127,127]. NB: for a window with COLOR_MODEL=1 the use of
;       an RGB colour will probably fail. But I have never used 
;
;     DIMENSIONS (Init, Get, Set)
;       A 2-element array specifying the width & height of the
;       graphics window. If the picture and the window are both
;       "fittable"  (see FITTABLE keyword) then UNITS & DIMENSIONS are
;       taken from the picture.
;
;     CHANGEABLE (Init, Get)
;       This property determines whether the GRAPHICS_TREE property
;       can be changed once it has been first set. It is 1 (on) by
;       default but should be set to 0 if the MGH_Window is to be used
;       in a composite application which needs to ensure that the
;       GRAPHICS_TREE is not changed behind its back.
;
;     EXPAND_STATUS_BAR (Init, Get, Set)
;       This property determines whether the the "status bar" beneath
;       the draw widget is expanded or collapsed. Default is 1
;       (expanded).
;
;     FITTABLE (Init, Get)
;       This property determines whether the window will try to resize
;       itself to fit the GRAPHICS_TREE picture. Default is 1 (try to
;       fit) by default. For a fit to occur, the picture must also be
;       fittable, as determined by the MGH_PICTURE_IS_FITTABLE
;       function.
;
;     GRAPHICS_TREE (Init, Get, Set)
;       This property is passed to the embedded draw widget. Setting
;       the GRAPHICS_TREE triggers other changes including resetting
;       the window title and creating an "undo" stack. The
;       CHANGEABLE property determines whether the GRAPHICS_TREE
;       property can be changed once it has been first set.
;
;     MOUSE_ACTION (Init, Get, Set)
;       A 3-element string array specifying the mouse handler object
;       to be associated with each mouse button. Mouse press, release
;       & motion events that originate from the draw widget are sent
;       to "mouse handler" objects, one handler per mouse
;       button. These handlers are created and destroyed by the
;       SetUpMouseHandler method, which is called by SetProperty. Each
;       time MOUSE_ACTION is changed this method destroys all existing
;       mouse handlers then creates a new set according to rules
;       hard-wired into the code.
;
;     MOUSE_LIST (Init, Get)
;       This property is a string array that defines the set of values
;       available from the "mouse action" droplists on the status
;       bar. Note that this property affects the user interface
;       only. It does not affect the range of permissible values for
;       the elements of MOUSE_ACTION--these values are determined
;       implicitly by the code in the SetUpMouseHandler method.
;
;     RESIZEABLE (Init, Get, Set)
;       This property detrmines whether the window or picture
;       dimensions are changed in response to base resize events.  The
;       resizing of the window interacts with the automatic fitting of
;       the window to the picture, in a way that depends on whether
;       the picture is fittable (i.e. function MGH_PICTURE_IS_FITTABLE
;       returns 1) and whether the window is fittable (FITTABLE
;       property is 1).
;
;     RESIZE_PRESERVE (Init, Get, Set)
;       This property determines whether the aspect ratio of the
;       window or picture is preserved when the window or picture
;       is resized. It is ignored if RESIZEABLE is 0.
;
;     RESOLUTION (Get)
;       Taken from the graphics window.
;
;     TITLE (Get)
;       The title, which appears in the base widget's title bar, is
;       calculated from the picture name.
;
;     TOOLTIP (Get)
;       The tooltip which appears when the cursor hovers over the draw
;       widget, is calculated from the picture name.
;
;     UNITS (Init, Get, Set)
;       Units for the DIMENSIONS. Default is 2 (cm).
;
;     HIGH_RESOLUTION (Init, Get, Set)
;       Default resolution for PNG and TIFF files produced by the
;       "high-res" menu items. The default is 2.54/240.
;
;     VECTOR_RESOLUTION (Init, Get, Set)
;       Default resolution for off-screen vector buffers, used by
;       methods WritePictureToClipboard, WritePictureToClipboard
;       (vector formats) and WritePictureToVRML. By default, this
;       property is set to a non-finite value, which means that the
;       resolution of the IDLgrWindow object is used.
;
;     VISIBLE (Init, Get, Set)
;       Set this property to 1 to make the window visible, 0 to make
;       it invisible.
;
;   ... and many more.
;
; KNOWN PROBLEMS:
;   - On Windows, if the RESIZEABLE property is set, then flashing
;     occurs when a top-level MGH_Window object is created because the
;     Draw method is called twice. The first draw occurs when the
;     object is realised (which causes the NotifyRealize method to be
;     called, which calls Update, which calls Draw.) The second draw
;     occurs when the OS sends a resize event to the newly created
;     base (which calls Resize, which calls Draw) as mentioned
;     somewhere in the IDL documentation. I have considered various
;     ways to suppress this, but decided it is simpler to set the
;     default value of RESIZEABLE to 0.
;
; TO DO:
;   Have repertoire of mouse handlers (MOUSE_LIST) depend on the type
;   of graphics tree? Query the graphics tree for the mouse actions it
;   supports?? (No, probably not a good idea.)
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2001-10:
;     Added support for a context menu associated with the draw
;     widget.
;   Mark Hadfield, 2002-01:
;     Changed default RETAIN setting from 2 to 1. This has no effect
;     on Windows but leads to a dramatic improvement in speed and
;     appearance on Linux.
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6. Added tool tips and check-box menus.
;   Mark Hadfield, 2002-12:
;     Further changes to default RETAIN & EXPOSE_EVENTS settings on
;     Unix, for better results on Rangi, a DEC Alpha machine.
;   Mark Hadfield, 2004-05:
;     - Added code to export graphics using new formats & facilities
;       in IDL 6.1: EPS with CMYK colour space and JPEG 2000.
;     - Limited the draw widget's tooltip length to work around IDL
;       bug.
;   Mark Hadfield, 2004-07:
;     - Moved code that sets window title from the SetupGraphicsTree
;       method to the Update method, to allow for the possibility that
;       the graph name has been changed by the user. Remainder of
;   Mark Hadfield, 2005-08:
;     - Changed resolution for "hi-res" PNGs from 0.005 to 0.01. The
;       former was, as I recall, intended as a very low value that would
;       not normally be reached because of IDL's limits on buffer sizes.
;       However these limits have been relaxed (in version 6.2?) meaning
;       it can now generate really big images.
;   Mark Hadfield, 2008-09:
;     - Resolution for "hi-res" PNGs is now 0.0075.
;   Mark Hadfield, 2009-09:
;     - Fixed cosmetic bug in EventMenuBar messages.
;   Mark Hadfield, 2009-10:
;     The RENDERER, RETAIN & EXPOSE_EVENTS settings for non-Windows
;     platforms were changed again to work on Thotter. It all remains a
;     bit of a mystery, however.
;   Mark Hadfield, 2009-11:
;     I added a new property, BACKGROUND_COLOR, that's used when the
;     Draw method is called without a valid picture and also when drawing
;     to buffers. (I still haven't sorted this out fully.) The Draw method
;     used to pass inherited keywords to the IDLgrWindow--the only valid
;     ones being CREATE_INSTANCE and DRAW_INSTANCE. This functionality
;     has been disabled for the time being. 
;   Mark Hadfield, 2011-05:
;     Default RENDERER now determined with PREF_GET. 
;   Mark Hadfield, 2011-08:
;     - Fixed a very long-standing and major bug in PickReport(!): wrong index
;       supplied to the vector of targets. 
;     - Further adjustment to the resolution for "hi-res" images. To limit
;       image size the RESOLUTION was increased from 2.54/360 to 2.54/240. The
;       image now produced from the window displayed by MGH_EXAMPLE_PLOT on
;       Windows is now 1912x1912.
;   Mark Hadfield, 2013-04:
;     - The extension for Windows metafiles has been changed from WMF to EMF.
;   Mark Hadfield, 2013-06:
;     - Bitmap PDFs are now at high resolution (2.54/600, or 600 dpi).
;   Mark Hadfield, 2014-09:
;     - The resolution for "hi-res" images is now set by a keyword/property
;       called HIGH_RESOLUTION (clever eh?). The default value is unchanged
;       at 2.54/240. The image now produced from the window displayed by
;       MGH_EXAMPLE_PLOT on Windows is now 2102x2102.
;   Mark Hadfield, 2015-05:
;     Removed the facility to launch a clipboard viewer: the viewer is no
;     longer available in Windows.
;-

; MGH_Window::Init
;
function MGH_Window::Init, picture, $
     BACKGROUND_COLOR=background_color, $
     CHANGEABLE=changeable, $
     COLOR_MODEL=color_model, $
     DIMENSIONS=dimensions, $
     DRAG_QUALITY=drag_quality, $
     EXPAND_STATUS_BAR=expand_status_bar, $
     EXPOSE_EVENTS=expose_events, FITTABLE=fittable, $
     GRAPHICS_TREE=graphics_tree, $
     MOUSE_ACTION=mouse_action, MOUSE_LIST=mouse_list, $
     QUALITY=quality, REALIZED=realized, $
     RENDERER=renderer, RESIZEABLE=resizeable, $
     RESIZE_PRESERVE=resize_preserve, $
     RETAIN=retain, UNITS=units, $
     BITMAP_RESOLUTION=bitmap_resolution, $
     HIGH_RESOLUTION=high_resolution, $
     VECTOR_RESOLUTION=vector_resolution, $
     VISIBLE=visible, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Executing the following routine causes all class definitions in
   ;; the corresponding .pro file to be compiled. Objects of these
   ;; classes are used to handle mouse events

   mgh_mouse_handler_library

   ;; Process picture argument

   if obj_valid(picture) then graphics_tree = picture

   ;; Keywords

   if n_elements(expand_status_bar) eq 0 then expand_status_bar = 1

   ;; Property defaults

   self.background_color = $
        n_elements(background_color) gt 0 ? background_color : [127B,127B,127B]

   self.changeable = n_elements(changeable) gt 0 ? keyword_set(changeable) : 1B

   self.fittable = n_elements(fittable) gt 0 ? keyword_set(fittable) : 1B

   self.graphics_tree = $
        n_elements(graphics_tree) gt 0 ? graphics_tree : obj_new()

   self.quality = n_elements(quality) gt 0 ? quality : 2B

   self.drag_quality = n_elements(drag_quality) gt 0 ? drag_quality : 0B

   self.mouse_action = n_elements(mouse_action) gt 0 $
        ? mouse_action : ['Magnify','Translate','Context']

   self.resizeable = keyword_set(resizeable)

   self.resize_preserve = $
        n_elements(resize_preserve) gt 0 ? keyword_set(resize_preserve) : 1B

   case n_elements(mouse_list) gt 0 of
      0: begin
         ml = ['None', 'Magnify', 'Magnify 3D', 'Pick','Prop Sheet', $
               'Rotate', 'Rotate X', 'Rotate Y', 'Rotate Z', $
               'Scale', 'Translate', 'Trans Z', $
               'Zoom XY', 'Zoom XZ', 'Zoom YZ', $
               'Debug', 'Context']
         self.mouse_list = ptr_new(ml, /NO_COPY)
      end
      1: self.mouse_list = ptr_new(mouse_list)
   endcase

   self.bitmap_resolution = $
     n_elements(bitmap_resolution) gt 0 ? bitmap_resolution : !values.f_nan
   self.high_resolution = $
     n_elements(high_resolution) gt 0 ? high_resolution : 2.54/240
   self.vector_resolution = $
     n_elements(vector_resolution) gt 0 ? vector_resolution : !values.f_nan

   ;; Set up DIMENSIONS after UNITS

   self.units = n_elements(units) gt 0 ? units : 2

   case n_elements(dimensions) of
      0: begin
         case self.units of
            0: self.dimensions = [400,400]
            1: self.dimensions = [4.,4.]
            2: self.dimensions = [10.,10.]
            3: self.dimensions = [0.25,0.25]
         endcase
      end
      else: self.dimensions = dimensions
   endcase

   ;; For cosmetic reasons, the VISIBLE keyword is not
   ;; initially passed to the base (which is created invisible) but is
   ;; stored in a tag in the class structure. The first time the Update
   ;; method is called it sets the visibility to this tag's value.

   self._visible = n_elements(visible) gt 0 ? keyword_set(visible) : 1

   ;; Create the widget base. The Init method is smart enough to ignore
   ;; irrelevant keywords. Base is created invisible if possible
   ;; to avoid visible resizing.

   ok = self->MGH_GUI_Base::Init(/COLUMN, /BASE_ALIGN_CENTER, /MBAR, $
                                 /NOTIFY_REALIZE, /TLB_SIZE_EVENTS, $
                                 VISIBLE=0, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; The following settings specify the Object Graphics renderer
   ;; (hardware or software) and whether the draw widget is to retain
   ;; its contents in backing store or be redrawn on expose events.

   ;; The optimum settings depend on the platform, the video hardware,
   ;; and even on the version of the video driver. The defaults below
   ;; should work on most systems. If you have *good* OpenGL
   ;; acceleration on your system you may get best results using
   ;; RENDERER=0, RETAIN=0 and EXPOSE_EVENTS=1.

   ;; NB: RETAIN=2 seems to work pretty well on Windows but is dreadfully
   ;; slow over X Windows.
   
   case !version.os_family of
      'Windows': begin
         if n_elements(renderer) eq 0 then renderer = pref_get('IDL_GR_WIN_RENDERER')
         if n_elements(retain) eq 0 then retain = 2
         if n_elements(expose_events) eq 0 then expose_events = (retain lt 2)
      end
      else: begin
         if n_elements(renderer) eq 0 then renderer = pref_get('IDL_GR_X_RENDERER')
         if n_elements(retain) eq 0 then retain = 0
         if n_elements(expose_events) eq 0 then expose_events = (retain lt 2)
      end
   endcase

   ;; Set up the undo stack

   self.undo_stack = obj_new('MGH_Stack')

   ;; Create a draw widget.

   self->NewChild, 'widget_draw', $
        COLOR_MODEL=color_model, GRAPHICS_LEVEL=2, $
        RENDERER=renderer, RETAIN=retain, $
        EXPOSE_EVENTS=expose_events, BUTTON_EVENTS=1, MOTION_EVENTS=1, $
        XSIZE=400, YSIZE=400, $
        UVALUE=self->Callback('EventWindow'), $
        RESULT=odraw
   self.draw_widget = odraw

   ;; Build other UI components

   self->BuildMenuBar

   self->BuildDrawContext

   self->BuildStatusBar, keyword_set(expand_status_bar)

   self->BuildStatusContext

   ;; Remaining set-up is done in the NotifyRealize method, because it requires
   ;; a reference to the window object that is created when the draw widget
   ;; is realised.

   ;; Finalize and return

   self->Finalize, 'MGH_Window'

   return, 1

end


; MGH_Window::Cleanup
;
pro MGH_Window::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.mouse_list

   obj_destroy, self.graphics_tree

   obj_destroy, self.mouse_handler

   obj_destroy, self.window

   if obj_valid(self.undo_stack) then begin
      while self.undo_stack->Count() gt 0 do obj_destroy, self.undo_stack->Get()
      obj_destroy, self.undo_stack
   endif

   self->MGH_GUI_Base::Cleanup

end


; MGH_Window::GetProperty
;
pro MGH_Window::GetProperty, $
     ALL=all, $
     BACKGROUND_COLOR=background_color, $
     CHANGEABLE=changeable, $
     COLOR_MODEL=color_model, $
     DIMENSIONS=dimensions, $
     DRAG_QUALITY=drag_quality, $
     EXPAND_STATUS_BAR=expand_status_bar, $
     FITTABLE=fittable, GRAPHICS_TREE=graphics_tree, $
     MOUSE_ACTION=mouse_action, $
     MOUSE_LIST=mouse_list, $
     QUALITY=quality, RENDERER=renderer, $
     RESIZEABLE=resizeable, RESIZE_preserve=resize_preserve, $
     RETAIN=retain, $
     SCREEN_DIMENSIONS=screen_dimensions, $
     TOOLTIP=tooltip, UNDO_COUNT=undo_count, UNITS=units, $
     RESOLUTION=resolution, $
     BITMAP_RESOLUTION=bitmap_resolution, $
     HIGH_RESOLUTION=high_resolution, $
     VECTOR_RESOLUTION=vector_resolution, $
     WINDOW=window, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::GetProperty, ALL=all, _STRICT_EXTRA=extra

   background_color = self.background_color

   changeable = self.changeable

   dimensions = self.dimensions

   drag_quality = self.drag_quality

   expand_status_bar = self.expand_status_bar

   fittable = self.fittable

   graphics_tree = self.graphics_tree

   mouse_action = self.mouse_action

   mouse_list = *(self.mouse_list)

   quality = self.quality

   resizeable = self.resizeable

   resize_preserve = self.resize_preserve

   tooltip = widget_info(self.draw_widget, /TOOLTIP)

   bitmap_resolution = self.bitmap_resolution
   high_resolution = self.high_resolution
   vector_resolution = self.vector_resolution

   units = self.units

   window = self.window

   case obj_valid(self.window) of
      0: begin
         color_model = 0
         renderer = -1
         resolution = [0.,0.]
         retain = -1
         screen_dimensions = [0,0]
      end
      1: begin
         self.window->GetProperty, $
              COLOR_MODEL=color_model, RENDERER=renderer, $
              RESOLUTION=resolution, RETAIN=retain, $
              SCREEN_DIMENSIONS=screen_dimensions
      end
   endcase

   case obj_valid(self.undo_stack) of
      0: undo_count = 0
      1: undo_count = self.undo_stack->Count()
   endcase

   if arg_present(all) then $
        all = create_struct(all, $
                            'background_color', background_color, $
                            'changeable', changeable, $
                            'color_model', color_model, $
                            'dimensions', dimensions, $
                            'drag_quality', drag_quality, $
                            'expand_status_bar', expand_status_bar, $
                            'fittable', fittable, $
                            'graphics_tree', graphics_tree, $
                            'mouse_action', mouse_action, $
                            'mouse_list', mouse_list, $
                            'quality', quality, $
                            'renderer', renderer, $
                            'resizeable', resizeable, $
                            'resize_preserve', resize_preserve, $
                            'resolution', resolution, $
                            'screen_dimensions', screen_dimensions, $
                            'undo_count', undo_count, $
                            'units', units, $
                            'bitmap_resolution', bitmap_resolution, $
                            'high_resolution', high_resolution, $
                            'vector_resolution', vector_resolution, $
                            'window', window)

end

; MGH_Window::SetProperty
;
pro MGH_Window::SetProperty, $
     BACKGROUND_COLOR=background_color, $
     DIMENSIONS=dimensions, $
     DRAG_QUALITY=drag_quality, $
     EXPAND_STATUS_BAR=expand_status_bar, $
     GRAPHICS_TREE=graphics_tree, $
     MOUSE_ACTION=mouse_action, QUALITY=quality, $
     RESIZEABLE=resizeable, RESIZE_PRESERVE=resize_preserve, UNITS=units, $
     BITMAP_RESOLUTION=bitmap_resolution, $
     HIGH_RESOLUTION=high_resolution, $
     VECTOR_RESOLUTION=vector_resolution, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(background_color) gt 0 then $
        self.background_color = background_color

   if n_elements(drag_quality) gt 0 then $
        self.drag_quality = drag_quality

   if n_elements(expand_status_bar) gt 0 then $
        self->BuildStatusBar, keyword_set(expand_status_bar)

   if n_elements(graphics_tree) gt 0 then begin
      if ~ self.changeable then begin
         message, 'The GRAPHICS_TREE property cannot be changed ' + $
                  'once set for a non-CHANGEABLE window'
      endif
      self.graphics_tree = graphics_tree
      self->SetupGraphicsTree
   endif

   if n_elements(mouse_action) gt 0 then begin
      self.mouse_action = mouse_action
      for button=0,2 do self->SetUpMouseHandler, button
   endif

   if n_elements(quality) gt 0 then $
        self.quality = quality

   if n_elements(resizeable) gt 0 then $
        self.resizeable = keyword_set(resizeable)

   if n_elements(resize_preserve) gt 0 then $
        self.resize_preserve = keyword_set(resize_preserve)

   if n_elements(bitmap_resolution) gt 0 then $
     self.bitmap_resolution = bitmap_resolution
   if n_elements(high_resolution) gt 0 then $
     self.high_resolution = high_resolution
   if n_elements(vector_resolution) gt 0 then $
     self.vector_resolution = vector_resolution

   if n_elements(dimensions) gt 0 then $
        self.dimensions = dimensions

   if n_elements(units) gt 0 then $
        self.units = units

   if n_elements(dimensions) gt 0 or n_elements(units) gt 0 then $
        self->SetUpWindow

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_Window::About
;
pro MGH_Window::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   self->GetProperty, GRAPHICS_TREE=graphics_tree, RENDERER=renderer, RETAIN=retain

   printf, lun, FORMAT='(%"%s: My RENDERER & RETAIN properties are %d %d")', $
           mgh_obj_string(self), renderer, retain

   printf, lun, FORMAT='(%"%s: My graphics tree is %s")', $
           mgh_obj_string(self), mgh_obj_string(graphics_tree, /SHOW_NAME)

   self->GetProperty, UNITS=units, DIMENSIONS=dimensions
   case units of
      0: begin
         printf, lun, FORMAT='(%"%s: My dimensions are %d x %d pix")', $
                 mgh_obj_string(self), dimensions
      end
      1: begin
         printf, lun, FORMAT='(%"%s: My dimensions are %0.1f x %0.1f in")', $
                 mgh_obj_string(self), dimensions
      end
      2: begin
         self->GetProperty, RESOLUTION=resolution
         printf, lun, FORMAT='(%"%s: My dimensions are %0.1f x %0.1f cm ' + $
                 '(%d x %d pix)")', mgh_obj_string(self), dimensions, $
                 round(dimensions/resolution)
      end
      3: begin
         printf, lun, FORMAT='(%"%s: My dimensions are %d x %d %%")', $
                 mgh_obj_string(self), round(100*dimensions)
      end

   endcase

end

; MGH_Window::BuildDrawContext
;
pro MGH_Window::BuildDrawContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.draw_context gt 0 then return

   items = ['About','Copy Bitmap','Copy Vector','Undo','Undo All']

   self->NewChild, /OBJECT, 'MGH_GUI_PDMenu', /CONTEXT, items, $
        UVALUE=self->Callback('EventDrawContext'), RESULT=omenu

   self.draw_context = omenu->GetBase()

end

; MGH_Window::BuildMenuBar
;
pro MGH_Window::BuildMenuBar

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

   case self.changeable of
      0: begin
         obar->NewItem, ['Save...','Export','Print','Close'], $
              PARENT='File', MENU=[0,1,1,0], SEPARATOR=[0,1,1,1], $
              ACCELERATOR=['Ctrl+S','','','Ctrl+F4']
      end
      1: begin
         obar->NewItem, ['Open...','Save...','Clear','Export','Print','Close'], $
              PARENT='File', MENU=[0,0,0,1,1,0], SEPARATOR=[0,0,0,1,1,1], $
              ACCELERATOR=['Ctrl+O','Ctrl+S','','','','Ctrl+F4']
      end
   endcase
   
   fmts = ['EPS...','EPS (CMYK)...','PDF...','PDF (bitmap)...', $
           'PNG...','PNG (hi-res)...','JPEG...','JPEG 2000...', $
           'TIFF...','TIFF (hi-res)...','VRML..']
   if iswin then fmts = ['EMF...',fmts]
   obar->NewItem, PARENT='File.Export', temporary(fmts)

   obar->NewItem, PARENT='File.Print', ['Bitmap...','Vector...']

   ;; ...Edit menu

   obar->NewItem, PARENT='Edit', ['Copy','Undo'], MENU=[1,1], SEPARATOR=[0,1]

   obar->NewItem, PARENT='Edit.Copy', ['Bitmap','Vector']

   obar->NewItem, PARENT='Edit.Undo', ['Previous','All'], ACCELERATOR=['Ctrl+Z','']

   ;; ...Tools menu

   obar->NewItem, PARENT='Tools', ['Export Data...']

   ;; ...Window menu

   obar->NewItem, PARENT='Window', ['Update','Toolbars'], MENU=[0,1]

   obar->NewItem, PARENT='Window.Toolbars', ['Status Bar'], /CHECKED_MENU

   ;; ...Help menu

   obar->NewItem, PARENT='Help', ['About']

end

; MGH_Window::BuildStatusBar
;
pro MGH_Window::BuildStatusBar, expand

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default is to toggle the state of the bar

   if n_elements(expand) eq 0 then expand = ~ self.expand_status_bar

   ;; Check that the status-bar base exists. Once created, this will
   ;; not be destroyed, thus ensuring that the order of toolbars will
   ;; not change

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
         obar->NewChild, 'MGH_GUI_Base', $
              /OBJECT, XSIZE=200, YSIZE=5, /FRAME , /CONTEXT_EVENTS, $
              PROCESS_EVENTS=0, UNAME='STATUS_BASE', RESULT=ocont
      end

      1: begin
         obar->NewChild, 'MGH_GUI_Base', /OBJECT, /ROW, /ALIGN_CENTER, $
              /BASE_ALIGN_CENTER, /CONTEXT_EVENTS, XPAD=10, PROCESS_EVENTS=0, $
              UNAME='STATUS_BASE', RESULT=ocont
         ocont->NewChild, 'MGH_GUI_Droplist', /OBJECT, $
              UNAME='MOUSE_ACTION_LEFT', VALUE=*self.mouse_list, TITLE='L:'
         ocont->NewChild, 'MGH_GUI_Droplist', /OBJECT, $
              UNAME='MOUSE_ACTION_MIDDLE', VALUE=*self.mouse_list, TITLE='M:'
         ocont->NewChild, 'widget_label', VALUE='  '
         ocont->NewChild, 'widget_base', /NONEXCLUSIVE, /ROW, RESULT=rbase
         ocont->NewChild, 'widget_button', PARENT=rbase, UNAME='RESIZEABLE', $
              VALUE='Resize'
         ocont->NewChild, 'widget_button', PARENT=rbase, UNAME='RESIZE_PRESERVE', $
              VALUE='Keep Aspect'
      end

   endcase

   self.expand_status_bar = keyword_set(expand)

end

; MGH_Window::BuildStatusContext
;
pro MGH_Window::BuildStatusContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.status_context gt 0 then return

   self->NewChild, /OBJECT, 'MGH_GUI_PDMenu', /CONTEXT, RESULT=omenu, $
     ['Status Bar'], CHECKED_MENU=1, UVALUE=self->Callback('EventStatusContext')

   self.status_context = omenu->GetBase()

end

; MGH_Window::Draw
;
pro MGH_Window::Draw, picture, $
     CREATE_INSTANCE=create_instance, DRAW_INSTANCE=draw_instance

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.window) then return

   if n_elements(picture) eq 0 then $
        self->GetProperty, GRAPHICS_TREE=picture

   if obj_valid(picture) then begin
      self.window->Draw, picture, $
           CREATE_INSTANCE=create_instance, DRAW_INSTANCE=draw_instance
   endif else begin
      self.window->Erase, COLOR=self.background_color
   endelse

end

; MGH_Window::EventBase
;
function MGH_Window::EventBase, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case tag_names(event, /STRUCTURE_NAME) of

      'WIDGET_BASE': begin
         ;; This is a TLB-resize event
         self->Resize, event.x, event.y
         return, 0
      end

      'MGH_WINDOW_UPDATE': begin
         ;; MGH_WINDOW_UPDATE events are generated by the Update
         ;; method for child MGH_WINDOW objects to tell the parent
         ;; that the object has changed in some way.
         case self.parent gt 0 of
            0: return, self->EventUnexpected(event)
            1: return, event
         endcase
      end

   endcase

end


; MGH_Window::EventDrawContext
;
function MGH_Window::EventDrawContext, event

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

      'COPY VECTOR': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard, /VECTOR
         return, 0
      end

      'UNDO': begin
         self->Undo
         return, 0
      end

      'UNDO ALL': begin
         self->Undo, /ALL
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Window::EventMenuBar
;
function MGH_Window::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.OPEN': begin
         filename = dialog_pickfile(/READ, FILTER='*.idl_picture')
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            obj_destroy, self.graphics_tree
            self->SetProperty, GRAPHICS_TREE=mgh_var_restore(filename, /RELAX)
            self->Update
         endif
         return, 0
      end

      'FILE.SAVE': begin
         self.graphics_tree->GetProperty, NAME=name
         default_file = strlen(name) gt 0 ? name+'.idl_picture' : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*.idl_picture')
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_var_save, graphics_tree, filename
         endif
         return, 0
      end

      'FILE.CLEAR': begin
         obj_destroy, self.graphics_tree
         self->SetProperty, GRAPHICS_TREE=obj_new()
         self->Update
         return, 0
      end

      'FILE.EXPORT.EMF': begin
        ;; This option provides for output in system-native vector format.
        ;; It is applicable only on Windows.
        self.graphics_tree->GetProperty, NAME=name
        ext = '.emf'
        default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
        filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
        if strlen(filename) gt 0 then begin
          widget_control, HOURGLASS=1
          mgh_cd_sticky, file_dirname(filename)
          self->WritePictureToGraphicsFile, filename, /VECTOR
        endif
        return, 0
      end
      
      'FILE.EXPORT.EPS': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.eps'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToGraphicsFile, filename, /POSTSCRIPT, /VECTOR
         endif
         return, 0
      end

      'FILE.EXPORT.EPS (CMYK)': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.eps'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToGraphicsFile, filename, /POSTSCRIPT, /VECTOR, /CMYK
         endif
         return, 0
      end

      'FILE.EXPORT.PDF': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.pdf'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToPDF, filename, VECTOR=1
         endif
         return, 0
      end

      'FILE.EXPORT.PDF (BITMAP)': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.pdf'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToPDF, filename, VECTOR=0, RESOLUTION=2.54D0/600
         endif
         return, 0
      end

      'FILE.EXPORT.JPEG': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.jpg'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, /JPEG, filename
         endif
         return, 0
      end

      'FILE.EXPORT.JPEG 2000': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.jp2'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, /JP2, filename
         endif
         return, 0
      end

      'FILE.EXPORT.PNG': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.png'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, /PNG, filename
         endif
         return, 0
      end

      'FILE.EXPORT.PNG (HI-RES)': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.png'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, /PNG, filename, RESOLUTION=self.high_resolution
         endif
         return, 0
      end

      'FILE.EXPORT.TIFF': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.tif'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, /TIFF, filename
         endif
         return, 0
      end

      'FILE.EXPORT.TIFF (HI-RES)': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.tif'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, /TIFF, filename, RESOLUTION=self.high_resolution
         endif
         return, 0
      end

      'FILE.EXPORT.VRML': begin
         self.graphics_tree->GetProperty, NAME=name
         ext = '.wrl'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : '' 
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToVRML, filename
         endif
         return, 0
      end

      'FILE.PRINT.BITMAP': begin
         if mgh_printer(/SETUP) then begin
            widget_control, HOURGLASS=1
            self->WritePictureToPrinter, /BANNER, PRINTER=mgh_printer()
         endif
         return, 0
      end

      'FILE.PRINT.VECTOR': begin
         if mgh_printer(/SETUP) then begin
            widget_control, HOURGLASS=1
            self->WritePictureToPrinter, /BANNER, PRINTER=mgh_printer(), /VECTOR
         endif
         return, 0
      end

      'FILE.CLOSE': begin
         self->Kill
         return, 0
      end


      'EDIT.UNDO.PREVIOUS': begin
         self->Undo
         return, 0
      end

      'EDIT.UNDO.ALL': begin
         self->Undo, /ALL
         return, 0
      end

      'EDIT.COPY.BITMAP': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard
         return, 0
      end

      'EDIT.COPY.VECTOR': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard, /VECTOR
         return, 0
      end

      'TOOLS.EXPORT DATA': begin
         self->ExportData, values, labels
         ogui = obj_new('MGH_GUI_Export', values, labels, $
                         /BLOCK, /FLOATING, GROUP_LEADER=self.base)
         ogui->Manage
         obj_destroy, ogui
         return, 0
      end

      'WINDOW.UPDATE': begin
         self->Update
         return, 0
      end

      'WINDOW.TOOLBARS.STATUS BAR': begin
         self->BuildStatusBar
         self->UpdateStatusBar
         self->UpdateMenuBar
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

; MGH_Window::EventMouse
;
;   For a specified mouse button, establish whether this event (from the draw widget)
;   is of interest to this button's handler and take appropriate action
;
function MGH_Window::EventMouse, event, button

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Reject the event if this button is inactive

   if self.mouse_action[button] eq 'None' then return, event

   ;; Reject the event if there is no graphics tree.  (It's possible
   ;; that in future there might be a mouse-event handler that does
   ;; something useful in this situation but right now there isn't.)

   if ~ obj_valid(self.graphics_tree) then return, event

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

; MGH_Window::EventStatusBar
;
function MGH_Window::EventStatusBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.uname of

      'STATUS_BASE': begin
         widget_displaycontextmenu, event.event.id, event.event.x, event.event.y, $
              self.status_context
         return, 0
      end

      'MOUSE_ACTION_LEFT': begin
         self->GetProperty, MOUSE_ACTION=mouse_action
         mouse_action[0] = event.event.value
         self->SetProperty, MOUSE_ACTION=mouse_action
         self->Update
         return, 0
      end

      'MOUSE_ACTION_MIDDLE': begin
         self->GetProperty, MOUSE_ACTION=mouse_action
         mouse_action[1] = event.event.value
         self->SetProperty, MOUSE_ACTION=mouse_action
         self->Update
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

; MGH_Window::EventStatusContext
;
function MGH_Window::EventStatusContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'STATUS BAR': begin
         self->BuildStatusBar
         self->UpdateStatusBar
         self->UpdateMenuBar
         self->UpdateStatusContext
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Window::EventWindow
;
;   Handle events from the graphics window (draw widget)
;
function MGH_Window::EventWindow, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1B of

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


; MGH_Window::ExportData
;
pro MGH_Window::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=graphics_tree

   labels = ['Self', 'Graphics Tree']
   values = [ptr_new(self), ptr_new(graphics_tree)]

end

; MGH_Window::Fit
;
; Purpose:
;   Fit the window to the picture. The FITTED output keyword
;   indicates whether fitting has taken place.
;
pro MGH_Window::Fit, FITTED=fitted

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   fitted = 0B

   if ~ self.fittable then return

   if mgh_picture_is_fittable(self.graphics_tree, UNITS=units, DIMENSIONS=dimensions) then begin
      self->SetProperty, UNITS=units, DIMENSIONS=dimensions
      fitted = 1B
   endif

end

; MGH_Window::NotifyRealize
;
pro MGH_Window::NotifyRealize

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; The base widget has now been realized. This creates an
   ;; object-graphics window; we store the reference in the object
   ;; structure and add it to the disposal container.

   widget_control, self.draw_widget, GET_VALUE=thewindow
   self.window = thewindow

   ;; Set up window object

   self->SetUpWindow

   ;; Set up graphics tree

   self->SetUpGraphicsTree

   ;; Set up mouse button handlers

   for button=0,2 do self->SetUpMouseHandler, button

   case !version.os_family of
      'Windows': $
           if ~ self.resizeable then self->Draw
      else:
   endcase

end


; MGH_Window::PickData
;
; (Needed by some mouse-handler objects)
;
function MGH_Window::PickData, p1, p2, p3, p4, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.window->PickData(p1, p2, p3, p4, _STRICT_EXTRA=extra)

end

; MGH_Window::PropertySheet
;
pro MGH_Window::PropertySheet, pos, MODIFIERS=modifiers

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(pos) ne 2 then $
        message, 'Parameter POS must be a 2-element vector'

   case obj_isa(self.graphics_tree,'IDLgrView') of
      0: views = self.window->Select(self.graphics_tree, pos)
      1: views = [self.graphics_tree]
   endcase

   if size(views, /TYPE) ne 11 then begin
      printf, lun, FORMAT='(%"%s: No views selected")', mgh_obj_string(self)
      return
   endif

   origin = mgh_widget_abs_offset(self.base)

   case keyword_set(modifiers) of

      0B: begin

         xoff = origin[0] + 30
         yoff = origin[1] + 30
         for i=n_elements(views)-1,0,-1 do begin
            targets = self.window->Select(views[i], pos, DIMENSIONS=[6,6])
            for i=n_elements(targets)-1,0,-1 do begin
               if obj_valid(targets[i]) then begin
                  mgh_new, 'MGH_GUI_PropertySheet', GROUP_LEADER=self.base, $
                           /FLOATING, XOFFSET=xoff, YOFFSET=yoff, $
                           CLIENT=targets[i], SPECTATOR=self
                  xoff += 20
                  yoff += 20
               endif
            endfor
         endfor
      end
      1B: begin
         xoff = origin[0] + 30
         yoff = origin[1] + 30
         for i=n_elements(views)-1,0,-1 do begin
            mgh_new, 'MGH_GUI_PropertySheet', GROUP_LEADER=self.base, $
                     /FLOATING, XOFFSET=xoff, YOFFSET=yoff, $
                     CLIENT=views[i], SPECTATOR=self
            xoff += 20
            yoff += 20
         endfor
      end
   endcase


end

; MGH_Window::PickReport
;
pro MGH_Window::PickReport, pos, LUN=lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(lun) eq 0 then lun = -1

   if n_elements(pos) ne 2 then $
        message, 'Parameter POS must be a 2-element vector'

   case obj_isa(self.graphics_tree,'IDLgrView') of
      0: views = self.window->Select(self.graphics_tree, pos)
      1: views = [self.graphics_tree]
   endcase

   if size(views, /TYPE) ne 11 then begin
      printf, lun, FORMAT='(%"%s: no views selected")', mgh_obj_string(self)
      return
   endif

   for i=0,n_elements(views)-1 do begin
      view = views[i]
      printf, lun, FORMAT='(%"%s: selected view %s")', $
              mgh_obj_string(self), mgh_obj_string(view, /SHOW_NAME)
      targets = self.window->Select(view, pos)
      valid = where(obj_valid(targets), n_targets)
      case n_targets gt 0 of
         0: begin
            printf, lun, FORMAT='(%"%s: no targets selected")', mgh_obj_string(self)
         end
         1: begin
            targets = targets[valid]
            for j=0,n_targets-1 do begin
               atom = targets[j]
               status = self.window->PickData(view, atom, pos, data)
               ;; There are situations where an atom is caught by the
               ;; Select method, but the PickData method returns 0
               ;; (failure). In this case data may be more or less
               ;; valid (usually the Z value will be the rear clipping
               ;; plane). So print it in any case.
               printf, lun, FORMAT='(%"%s: atom %s, success: %d, value: %f %f %f")', $
                       mgh_obj_string(self), mgh_obj_string(atom, /SHOW_NAME), $
                       status, double(data)
            endfor
         end
      endcase
   endfor

end

; MGH_Window::Resize
;
pro MGH_Window::Resize, x, y

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.resizeable of

      0B: begin

         ;; Get & set the window's DIMENSIONS property to allow the
         ;; base to resize itself around the window

         self->GetProperty, DIMENSIONS=dimensions
         self->SetProperty, DIMENSIONS=dimensions

      end

      1B: begin

         ;; Resize the window (and maybe the picture) to the new size

         ;; Widget geometry calculations, worked out via a combination
         ;; of reading the documentation and trial & error. I'm not
         ;; sure if they are robust but they seem to work in the
         ;; situations tested.

         ;; Why do we subtract 3*ypad below and only 2*xpad? I don't
         ;; know but it seems that column bases have extra padding in
         ;; the Y direction and row bases have extra padding in the X
         ;; direction.

         self->GetProperty, GEOMETRY=geom_base
         xx = x - 2*geom_base.margin - 2*geom_base.xpad
         yy = y - 2*geom_base.margin - 3*geom_base.ypad

         obar = mgh_widget_self(self.status_bar)
         if obj_valid(obar) then begin
            obar->GetProperty, GEOMETRY=geom_bar
            yy = yy - geom_bar.scr_ysize - geom_base.space
         endif

         ;; The action taken depends on whether the picture has
         ;; explicit dimensions

         case mgh_picture_is_fittable(self.graphics_tree, DIMENSIONS=dimensions, $
                                      N_VIEWS=n_views, UNITS=units, VIEWS=views) of

            0: begin

               self->GetProperty, UNITS=units, DIMENSIONS=dimensions, $
                    RESOLUTION=resolution, SCREEN_DIMENSIONS=screen_dimensions

               case units of
                  0:  new_dimensions = [xx > 200, yy > 150]
                  1:  new_dimensions = [xx > 200, yy > 150]*resolution/2.54
                  2:  new_dimensions = [xx > 200, yy > 150]*resolution
                  3:  new_dimensions = [xx > 200, yy > 150]/screen_dimensions
               endcase

               if self.resize_preserve then $
                    new_dimensions = sqrt(product(new_dimensions/dimensions))*dimensions

               self->SetProperty, DIMENSIONS=new_dimensions

            end

            1: begin

               self->GetProperty, RESOLUTION=resolution

               case units of
                  0:  new_dimensions = [xx, yy]
                  1:  new_dimensions = [xx, yy]*resolution/2.54
                  2:  new_dimensions = [xx, yy]*resolution
               endcase

               s = ((new_dimensions/dimensions) > 0.2) < 5.0

               if self.resize_preserve then s = sqrt(product(s))

               for i=0,n_views-1 do begin
                  views[i]->GetProperty, DIMENSIONS=view_dimensions, $
                       LOCATION=view_location
                  views[i]->SetProperty, DIMENSIONS=s*view_dimensions, $
                       LOCATION=s*view_location
               endfor

            end

         endcase

         self->Fit

         self->Draw

         self->UpdateDrawToolTip

      end

   endcase

end

; MGH_Window::Select
;
; (Needed by some mouse-handler objects)
;
function MGH_Window::Select, p1, p2, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.window->Select(p1, p2, _STRICT_EXTRA=extra)

end

; MGH_Window::SetUpGraphicsTree
;
;   Called when GRAPHICS_TREE property has changed. Clear the
;   undo stack and set the window title
;
pro MGH_Window::SetUpGraphicsTree

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   while self.undo_stack->Count() gt 0 do $
        obj_destroy, self.undo_stack->Get()

   self.window->SetProperty, GRAPHICS_TREE=self.graphics_tree

end

; MGH_Window::SetUpMouseHandler
;
;   Called when MOUSE_ACTION property has changed. Sets up a mouse
;   handler on the specified button
;
pro MGH_Window::SetUpMouseHandler, b

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.mouse_handler[b]

   case self.mouse_action[b] of
      'None':
      'Magnify': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Magnify', self)
      end
      'Magnify 3D': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Magnify', self, /THREE_DIMENSIONAL)
      end
      'Pick': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Pick', self)
      end
      'Prop Sheet': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_PropertySheet', self)
      end
      'Rotate': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Rotate', self, BUTTON=b)
      end
      'Rotate X': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Rotate', self, AXIS=0, $
                      BUTTON=b, /CONSTRAIN)
      end
      'Rotate Y': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Rotate', self, AXIS=1, $
                      BUTTON=b, /CONSTRAIN)
      end
      'Rotate Z': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Rotate', self, AXIS=2, $
                      BUTTON=b, /CONSTRAIN)
      end
      'Scale': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Scale', self)
      end
      'Translate': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Translate', self)
      end
      'Trans Z': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Translate', self, /VERTICAL)
      end
      'Zoom XY': begin
         self->GetProperty, RENDERER=renderer
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Zoom', self, NORMAL=2, $
                      USE_INSTANCE=(renderer eq 1))
      end
      'Zoom XZ': begin
         self->GetProperty, RENDERER=renderer
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Zoom', self, NORMAL=1, $
                      USE_INSTANCE=(renderer eq 1))
      end
      'Zoom YZ': begin
         self->GetProperty, RENDERER=renderer
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Zoom', self, NORMAL=0, $
                      USE_INSTANCE=(renderer eq 1))
      end
      'Debug': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Debug', self)
      end
      'Context': begin
         self.mouse_handler[b] = $
              obj_new('MGH_Mouse_Handler_Context', self.draw_context)
      end
   endcase

end

; MGH_Window::SetUpWindow
;
;   Called when UNITS or DIMENSIONS properties have changed.
;
pro MGH_Window::SetUpWindow

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.window->SetProperty, UNITS=self.units, DIMENSIONS=self.dimensions

end

; MGH_Window::SetWindowQuality
;
;   Set the window quality for dragging/non-dragging
;
pro MGH_Window::SetWindowQuality, DRAG=drag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.window->SetProperty, $
        QUALITY=keyword_set(drag) ? self.drag_quality : self.quality

end

; MGH_Window::Undo
;
;   Undo changes by executing commands in the Undo stack.
;
pro MGH_Window::Undo, ALL=all

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.undo_stack) then return

   if self.undo_stack->Count() eq 0 then return

   case keyword_set(all) of
      0: begin
         cmd = self.undo_stack->Get()
         for c=0,n_elements(cmd)-1 do begin
            if obj_valid(cmd[c]) then begin
               cmd[c]->Execute
               obj_destroy, cmd[c]
            endif
         endfor
      end
      1: begin
         while self.undo_stack->Count() gt 0 do begin
            cmd = self.undo_stack->Get()
            for c=0,n_elements(cmd)-1 do begin
               if obj_valid(cmd[c]) then begin
                  cmd[c]->Execute
                  obj_destroy, cmd[c]
               endif
            endfor
         endwhile
      end
   endcase

   self->Update

end

; MGH_Window::UndoSave
;
;   Save a command (or array thereof) in the undo stack
;
pro MGH_Window::UndoSave, cmd

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(self.undo_stack) then return

   self.undo_stack->Add, cmd

end

; MGH_Window::Update
;
pro MGH_Window::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Recalculate window dimensions (which are displayed on the status
   ;; bar) first.

   self->Fit

   ;; Update GUI components

   self->UpdateMenuBar

   self->UpdateDrawContext
   self->UpdateDrawToolTip

   self->UpdateStatusBar

   self->UpdateStatusContext

   ;; Update graphics window. This involves some version-specific
   ;; cosmetic hackery. The visibility of the base is determined from
   ;; the class structure _visible tag. Once this has been done, this
   ;; tag is set to a large value so that it will be ignored
   ;; thereafter.

   self->SetWindowQuality, DRAG=0

   case !version.os_family of

      'Windows': begin
         self->Draw
         if self._visible le 1 then begin
            self->MGH_GUI_Base::SetProperty, VISIBLE=self._visible
            self._visible = 255
         endif
      end

      else: begin
         if self._visible le 1 then begin
            self->MGH_GUI_Base::SetProperty, VISIBLE=self._visible
            self._visible = 255
         endif
         self->Draw
      end

   end

   ;; If this is a top-level base, set the window title
   ;; based on the name of the graphics tree

   if self->IsTLB() then begin
      case obj_valid(self.graphics_tree) of
         0: name = '(no picture)'
         1: begin
            self.graphics_tree->GetProperty, NAME=name
            if strlen(name) eq 0 then name = '(no name)'
         end
      endcase
      self->MGH_GUI_Base::SetProperty, TITLE='IDL - ' + name
   endif

   ;; If this is a child, send an event up the widget tree to advise
   ;; that the widget has changed. To create the appearance that the
   ;; event comes from us we have to specify our own self.base as the
   ;; argument. The event is intercepted by our EventBase method,
   ;; which has instructions to pass on events of this type.

   if ~ self->IsTLB() then begin
      widget_control, self.base, $
           SEND_EVENT={MGH_Window_UPDATE, id:0L, top:0L, handler:0L}
   endif

end

; MGH_Window::UpdateDrawContext
;
pro MGH_Window::UpdateDrawContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.draw_context)

   if obj_valid(omenu) then begin

      self->GetProperty, UNDO_COUNT=undo_count

      omenu->SetItem, 'Undo', SENSITIVE=(undo_count gt 0)
      omenu->SetItem, 'Undo All', SENSITIVE=(undo_count gt 0)

   endif

end

; MGH_Window::UpdateDrawToolTip
;
pro MGH_Window::UpdateDrawToolTip

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=graphics_tree, UNITS=units, DIMENSIONS=dimensions

   case obj_valid(graphics_tree) of
      0: name = '(no picture)'
      1: begin
         graphics_tree->GetProperty, NAME=name
         if strlen(name) eq 0 then name = '(no name)'
      end
   endcase

   case units of
      0: dim_text = string(dimensions, FORMAT='(I0," x ",I0)')
      1: dim_text = string(dimensions, FORMAT='(F0.2," x ",F0.2," in")')
      2: dim_text = string(dimensions, FORMAT='(F0.1," x ",F0.1," cm")')
      3: dim_text = string(round(100*dimensions), FORMAT='(I0," x ",I0,"%")')
   endcase

   ;; Limit tooltip length to avoid triggering IDL bug.
   l_max = 36 - strlen(dim_text)
   if strlen(name) gt l_max then name = strmid(name, 0, l_max-3) + '...'

   widget_control, self.draw_widget, TOOLTIP = name + ' - ' +dim_text

end

; MGH_Window::UpdateMenuBar
;
pro MGH_Window::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      ;; Get relevant properties

      self->GetProperty, $
           EXPAND_STATUS_BAR=expand_status_bar, GRAPHICS_TREE=graphics_tree, $
           UNDO_COUNT=undo_count

      ;; Set menu state

      obar->SetItem, 'File.Save', SENSITIVE=obj_valid(graphics_tree)
      obar->SetItem, 'File.Clear', SENSITIVE=obj_valid(graphics_tree)
      obar->SetItem, 'File.Print', SENSITIVE=obj_valid(graphics_tree)
      obar->SetItem, 'File.Export', SENSITIVE=obj_valid(graphics_tree)

      obar->SetItem, 'Edit.Copy', SENSITIVE=obj_valid(graphics_tree)
      obar->SetItem, 'Edit.Undo', SENSITIVE=(undo_count gt 0)

      obar->SetItem, 'Window.Toolbars.Status Bar', SET_BUTTON=(expand_status_bar)

   endif

end

; MGH_Window::UpdateStatusBar
;
pro MGH_Window::UpdateStatusBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.expand_status_bar of

      0:

      else: begin

         obar = mgh_widget_self(self.status_bar)

         ;; The "mouse action" droplists are implemented as
         ;; MGH_GUI_Droplist objects.  To set the appearance of each
         ;; one we retrieve its object reference from its widget tree
         ;; using MGH_WIDGET_SELF

         odrop = mgh_widget_self(obar->FindChild('MOUSE_ACTION_LEFT'))
         odrop->SetProperty, SELECTED_VALUE=self.mouse_action[0]

         odrop = mgh_widget_self(obar->FindChild('MOUSE_ACTION_MIDDLE'))
         odrop->SetProperty, SELECTED_VALUE=self.mouse_action[1]

         wid = obar->FindChild('RESIZEABLE')
         widget_control, wid, SET_BUTTON=self.resizeable

         wid = obar->FindChild('RESIZE_PRESERVE')
         widget_control, wid, SET_BUTTON=self.resize_preserve
         widget_control, wid, SENSITIVE=self.resizeable

      end

   endcase

end

; MGH_Window::UpdateStatusContext
;
pro MGH_Window::UpdateStatusContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.status_context)

   if obj_valid(omenu) then begin

      self->GetProperty, EXPAND_STATUS_BAR=expand_status_bar
      omenu->SetItem, 'Status Bar', SET_BUTTON=(expand_status_bar)

   endif

end

; MGH_Window::UpdateWindow
;
pro MGH_Window::UpdateWindow

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->Fit

   self->SetWindowQuality, DRAG=0

   self->Draw

end

; MGH_Window::WritePictureToClipboard
;
;   Render the picture to an IDLgrClipboard.
;
pro MGH_Window::WritePictureToClipboard, $
     RESOLUTION=resolution, VECTOR=vector

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   
   if n_elements(vector) eq 0 then vector = 1B

   self->GetProperty, GRAPHICS_TREE=graphics_tree

   ;; Determine the units & dimensions of the clipboard object from the window,
   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      case keyword_set(vector) of
         0: self->GetProperty, BITMAP_RESOLUTION=resolution
         1: self->GetProperty, VECTOR_RESOLUTION=resolution
      endcase
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   oclip = mgh_new_buffer('IDLgrClipboard', UNITS=units, $
                          DIMENSIONS=dimensions, RESOLUTION=resolution, $
                          QUALITY=self.quality)

   oclip->GetProperty, $
        UNITS=actual_units, DIMENSIONS=actual_dimensions, RESOLUTION=actual_resolution

   fmt = '(%"%s: drawing picture to clipboard with dimensions %f x %f ' + $
         '(units %d & resolution %f x %f)")'
   print, FORMAT=temporary(fmt), $
          mgh_obj_string(self), actual_dimensions, actual_units, actual_resolution

   oclip->Draw, graphics_tree, VECTOR=vector

   obj_destroy, oclip

end


; MGH_Window::WritePictureToImageFile
;
;   Render the picture to an IDLgrBuffer, then write image to a
;   raster-file format.
;
pro MGH_Window::WritePictureToImageFile, File, RESOLUTION=resolution, $
     GIF=gif, JP2=jp2, JPEG=jpeg, PNG=png, PPM=ppm, TIFF=tiff

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=picture

   case 1B of
      keyword_set(jp2): filetype = 'JP2'
      keyword_set(jpeg): filetype = 'JPEG'
      keyword_set(gif): filetype = 'GIF'
      keyword_set(ppm): filetype = 'PPM'
      keyword_set(tiff): filetype = 'TIFF'
      else: filetype = 'PNG'
   endcase

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      self->GetProperty, BITMAP_RESOLUTION=resolution
      if ~finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   ;; Make buffer size a multiple of 2 to avoid an annoying grey stripe
   ;; at the right-hand edge.

   obuff = mgh_new_buffer('IDLgrBuffer', UNITS=units, MULTIPLE=2, $
                          DIMENSIONS=dimensions, RESOLUTION=resolution, $
                          QUALITY=self.quality)
   obuff->Erase, COLOR=self.background_color
   obuff->Draw, picture
   obuff->GetProperty, IMAGE_DATA=snapshot
   obj_destroy, obuff

   dim = size(snapshot, /DIMENSIONS)
   n_dim = size(snapshot, /N_DIMENSIONS)

   fmt = '(%"Writing %d x %d image to %s file %s")'
   message, /INFORM, string(dim[n_dim-2:n_dim-1], filetype, file, FORMAT=fmt)

   case filetype OF

      'GIF': begin
         ;; Because we are using a window set up for RGB color,
         ;; snapshot contains a [3,m,n] array. Use COLOR_QUAN to
         ;; create a 2D image and appropriate color tables for
         ;; the GIF file.
         image2D = color_quan(snapshot, 1, r, g, b, COLORS=256)
         write_image, File, 'GIF', image2d, r, g, b
      end

      'JP2': begin
         write_jpeg2000, File, snapshot
      end

      'JPEG': begin
         write_image, File, 'JPEG', snapshot
      end

      'PNG': begin
         write_image, File, 'PNG', snapshot
      end

      'PPM': begin
         write_image, File, 'PPM', reverse(snapshot, 3)
      end

      'TIFF': begin
         write_image, File, 'TIFF', reverse(snapshot, 3)
      end

   endcase

end


; MGH_Window::WritePictureToGraphicsFile
;
;   Render the picture to a vector-graphics file using an
;   ILgrClipboard object
;
pro MGH_Window::WritePictureToGraphicsFile, File, $
     CMYK=cmyk, RESOLUTION=resolution, POSTSCRIPT=postscript, VECTOR=vector

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(vector) eq 0 then vector = 1B

   self->GetProperty, GRAPHICS_TREE=picture

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      if keyword_set(vector) then begin
         self->GetProperty, VECTOR_RESOLUTION=resolution
      endif else begin
         self->GetProperty, BITMAP_RESOLUTION=resolution
      endelse
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   oclip = mgh_new_buffer('IDLgrClipboard', UNITS=units, $
                          DIMENSIONS=dimensions, RESOLUTION=resolution, $
                          QUALITY=self.quality)

   oclip->GetProperty, $
        UNITS=actual_units, DIMENSIONS=actual_dimensions, RESOLUTION=actual_resolution

   fmt = '(%"Drawing picture (dim %f x %f, units %d, res %f x %f) to output file %s")'
   message, /INFORM, string(actual_dimensions, actual_units, actual_resolution, $
                            file, FORMAT=fmt)

   oclip->Draw, picture, $
                CMYK=cmyk, FILE=File, POSTSCRIPT=postscript, VECTOR=vector

   obj_destroy, oclip

end

; MGH_Window::WritePictureToPDF
;
;   Render the picture to a PDF file using an
;   ILgrPDF object
;
pro MGH_Window::WritePictureToPDF, file, $
     RESOLUTION=resolution, VECTOR=vector

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   
   if n_elements(vector) eq 0 then vector = 1B

   self->GetProperty, GRAPHICS_TREE=picture

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      if keyword_set(vector) then begin
         self->GetProperty, VECTOR_RESOLUTION=resolution
      endif else begin
         self->GetProperty, BITMAP_RESOLUTION=resolution
      endelse
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif
   
   my_resolution = n_elements(resolution) eq 1 ? replicate(resolution, 2) : resolution 
   
   opdf = obj_new('IDLgrPDF', UNITS=units, LOCATION=[0,0], $
                  DIMENSIONS=dimensions, RESOLUTION=my_resolution)

   opdf->GetProperty, $
        UNITS=actual_units, DIMENSIONS=actual_dimensions, RESOLUTION=actual_resolution

   fmt = '(%"Drawing picture (dim %f x %f, units %d, res %f x %f) ' + $
         'as %s graphics to output file %s")'
   message, /INFORM, string(actual_dimensions, actual_units, actual_resolution, $
                            (keyword_set(vector) ? 'vector' : 'bitmap'), file, $
                            FORMAT=fmt)

   opdf->AddPage, DIMENSIONS=dimensions

   opdf->Draw, picture, VECTOR=vector

   opdf->Save, file

   obj_destroy, opdf

end


; MGH_Window::WritePictureToPrinter
;
pro MGH_Window::WritePictureToPrinter, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=graphics_tree

   if obj_valid(graphics_tree) then begin
      message, /INFORM, "Printing picture..."
      mgh_print_picture, graphics_tree, _STRICT_EXTRA=extra
   endif else begin
      message, /INFORM, "No picture to print"
   endelse

end

; MGH_Window::WritePictureToVRML
;
;   Render the picture to an IDLgrVRML
;
PRO MGH_Window::WritePictureToVRML, File, RESOLUTION=resolution

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=picture

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      self->GetProperty, VECTOR_RESOLUTION=resolution
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   ovrml = mgh_new_buffer('IDLgrVRML', FILENAME=file, UNITS=units, $
                          DIMENSIONS=dimensions, RESOLUTION=resolution)

   ovrml->Draw, picture

   obj_destroy, ovrml

end

pro MGH_Window__Define

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  struct_hide, {MGH_Window, inherits MGH_GUI_Base, $
                background_color: bytarr(3), $
                changeable: 0B, $
                dimensions: fltarr(2), drag_quality: 0B, $
                draw_context: 0L, draw_widget: 0L, $
                expand_status_bar: 0B, fittable: 0B, $
                graphics_tree: obj_new(), $
                mouse_action: strarr(3), mouse_handler: objarr(3), $
                mouse_list: ptr_new(), quality: 0B, resizeable: 0B, $
                resize_preserve: 0B, status_bar: 0L, status_context: 0L, $
                undo_stack: obj_new(), units: 0S, $
                bitmap_resolution: 0.E0, $
                high_resolution: 0.E0, $
                vector_resolution: 0.E0, $
                _visible: 0B, window: obj_new()}

end
