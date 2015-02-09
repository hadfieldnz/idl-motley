;+
; NAME:
;   MGH_MOUSE_HANDLER_LIBRARY
;
; PURPOSE:
;   Define classes for mouse-handler objects used to control user
;   interaction with object graphics window objects like MGH_Window.
;
;   The file mgh_mouse_handler_library.pro is just a handy place to
;   collect class definitions for mouse-handler objects.
;
; CATEGORY:
;  Object Graphics
;
; CALLING SEQUENCE:
;   mgh_mouse_handler_library
;
; OUTPUTS:
;   None.
;
; SIDE EFFECTS:
;   The first time this routine is executed in a session, definitions
;   are compiled for the following mouse-handler classes:
;
;       MGH_Mouse_Handler_Context
;       MGH_Mouse_Handler_Debug
;       MGH_Mouse_Handler_Magnify
;       MGH_Mouse_Handler_Pick
;       MGH_Mouse_Handler_PropertySheet
;       MGH_Mouse_Handler_Rotate
;       MGH_Mouse_Handler_Scale
;       MGH_Mouse_Handler_Translate
;       MGH_Mouse_Handler_Zoom
;
;   The classes are documented separately below. Mouse handler objects
;   support only three methods, Init, Event and Cleanup.
;
;     Init
;       The Init method associates the mouse-handler with an OG window
;       object (the client) and may accept extra keywords to further
;       influence the mouse-handler's action, the _Rotate object
;       accepts keywords to constrain rotation.
;
;      Event
;        This method is called by the the OG window's  event-handling
;        code and accepts a structure. Note that the mouse-handler's
;        Event methods is a procedure, unlike the widget-object event
;        methods which are all functions. A procedure is used because
;        mouse handlers never "swallow" events.
;
;      Cleanup
;        Object destruction is intiated by the client.
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
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2001-10:
;     Added MGH_Mouse_Handler_Context class.
;   Mark Hadfield, 2002-06:
;     Added MGH_Mouse_Handler_Zoom class based on code that was
;     originally associated with the MGH_Plot class.
;   Mark Hadfield, 2002-07:
;     Moved most of the data-picking code from MGH_Mouse_Handler_Pick
;     to a new method, MGH_Window::PickReport. This makes it easier
;     to adapt data-picking behaviour for subclasses of MGH_Window.
;   Mark Hadfield, 2004-07:
;     - Added MGH_Mouse_Handler_PropertySheet class.
;     - Modified MGH_Mouse_Handler_Zoom for new axis class behaviour:
;       axis ranges are now modified using SetProperty rather than
;       SetInPlace.
;-

; ***** MGH_Mouse_Handler_Context class *****

function MGH_Mouse_Handler_Context::Init, menu

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.menu = menu

   return, 1

end

pro MGH_Mouse_Handler_Context::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_Context::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if event.type eq 0 then $
        widget_displaycontextmenu, event.id, event.x, event.y, self.menu

end

pro MGH_Mouse_Handler_Context__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Context, inherits IDL_Object, $
                 menu: 0}

end

; ***** MGH_Mouse_Handler_Debug class *****

function MGH_Mouse_Handler_Debug::Init, client

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   return, 1

end

pro MGH_Mouse_Handler_Debug::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_Debug::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   help, self.client
   help, /STRUCT, event

end

pro MGH_Mouse_Handler_Debug__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Debug, inherits IDL_Object, $
                 client: obj_new()}

end

; ***** MGH_Mouse_Handler_Magnify class *****

function MGH_Mouse_Handler_Magnify::Init, client, THREE_DIMENSIONAL=three_dimensional

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   self.three_dimensional = keyword_set(three_dimensional)

   return, 1

end

pro MGH_Mouse_Handler_Magnify::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_Magnify::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client->GetProperty, GRAPHICS_TREE=graphics_tree

   if event.type eq 0 then begin

      if ~ obj_valid(graphics_tree) then begin
         message, /INFORM, 'There is no graphics tree'
         return
      endif

      ;; Determine which view and model this object will act on. If
      ;; there are multiple views in the graphics tree, choose the
      ;; first one selected.
      
      if obj_isa(graphics_tree,'IDLgrView') then begin
         view = graphics_tree
      endif else begin
         views = self.client->Select(graphics_tree, [event.x,event.y])
         if ~ obj_valid(views[0]) then return
         view = views[0]
      endelse

      model = view->Get()
      if ~ obj_valid(model) then return

      ;; Save commands in the client's undo stack to restore the
      ;; model's TRANSFORM property

      model->GetProperty, TRANSFORM=transform
      self.client->UndoSave, $
           obj_new('MGH_Command', OBJECT=model, 'SetProperty', TRANSFORM=transform)

      ;; Calculate window dimensions in device units

      self.client->GetProperty, DIMENSIONS=dimensions, RESOLUTION=resolution, $
           SCREEN_DIMENSIONS=screen_dimensions, UNITS=units
      case units of
         0: dim = dimensions
         1: dim = 2.54*dimensions/resolution
         2: dim = dimensions/resolution
         3: dim = dimensions*screen_dimensions
      endcase

      ;; Scaling factor depends on whether a modifier key has been
      ;; pressed

      scale = event.modifiers gt 0 ? 0.5D0 : 2.0D0

      ;; Scale the model then translate it so that the point
      ;; under the mouse remains under the mouse.  (The other
      ;; obvious possibility is to have the point under the
      ;; mouse move to the centre of the window.)

      origin = mgh_dest_position([0,0], view, self.client)
      norm = mgh_dest_position([1,1], view, self.client) - origin

      case self.three_dimensional of
         0: model->Scale, scale, scale, 1
         1: model->Scale, scale, scale, scale
      endcase

      model->Translate, $
           (1-scale)*(event.x-origin[0])/norm[0], $
           (1-scale)*(event.y-origin[1])/norm[1], $
           0

      self.client->Update

   endif

end

pro MGH_Mouse_Handler_Magnify__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Magnify, inherits IDL_Object, $
                 client: obj_new(), three_dimensional: 0B}

end

; ***** MGH_Mouse_Handler_Pick class *****

function MGH_Mouse_Handler_Pick::Init, client

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   return, 1

end

pro MGH_Mouse_Handler_Pick::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_Pick::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if event.type ne 0 then return

   self.client->PickReport, [event.x,event.y]

end

pro MGH_Mouse_Handler_Pick__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Pick, inherits IDL_Object, $
                 client: obj_new()}

end

; ***** MGH_Mouse_Handler_Properties class *****

function MGH_Mouse_Handler_PropertySheet::Init, client

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   return, 1

end

pro MGH_Mouse_Handler_PropertySheet::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_PropertySheet::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if event.type ne 0 then return

   self.client->PropertySheet, [event.x,event.y], MODIFIERS=event.modifiers

end

pro MGH_Mouse_Handler_PropertySheet__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_PropertySheet, inherits IDL_Object, $
                 client: obj_new()}

end

; ***** MGH_Mouse_Handler_Rotate class *****

function MGH_Mouse_Handler_Rotate::Init, client, $
     AXIS=axis, BUTTON=button, CONSTRAIN=constrain

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   self.active = 0

   self.button = n_elements(button) gt 0 ? button : 0

   self.constrain = n_elements(constrain) gt 0 ? constrain : 0

   self.axis = n_elements(axis) gt 0 ? axis : 0

   return, 1

end

pro MGH_Mouse_Handler_Rotate::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.trackball

end

pro MGH_Mouse_Handler_Rotate::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client->GetProperty, GRAPHICS_TREE=graphics_tree

   case event.type of

      0: begin    ;;; Mouse button press

         if ~ obj_valid(graphics_tree) then begin
            message, /INFORM, 'There is no graphics tree'
            return
         endif

         ;; Determine which view and model this object will act on. If
         ;; there are multiple views in the graphics tree, choose the
         ;; first one selected.

         if obj_isa(graphics_tree,'IDLgrView') then begin
            self.view = graphics_tree
         endif else begin
            views = self.client->Select(graphics_tree, [event.x,event.y])
            if ~ obj_valid(views[0]) then return
            self.view = views[0]
         endelse

         model = self.view->Get()
         if ~ obj_valid(model) then return
         self.model = model

         ;; Calculate window dimensions in device units

         self.client->GetProperty, DIMENSIONS=dimensions, RESOLUTION=resolution, $
              SCREEN_DIMENSIONS=screen_dimensions, UNITS=units
         case units of
            0: dim = dimensions
            1: dim = 2.54*dimensions/resolution
            2: dim = dimensions/resolution
            3: dim = dimensions*screen_dimensions
         endcase

         ;; Set up trackball

         case obj_valid(self.trackball) of
            0: begin
               mgh_new, 'Trackball', 0.5*dim, sqrt(dim[0]*dim[1]), $
                        AXIS=self.axis, CONSTRAIN=self.constrain, $
                        MOUSE=2^self.button, RESULT=otrack
               self.trackball = otrack
            end
            1: begin
               self.trackball->Reset, 0.5*dim, sqrt(dim[0]*dim[1]), $
                    AXIS=self.axis, CONSTRAIN=self.constrain, $
                    MOUSE=2^self.button
            end
         endcase

         ;; Set window quality for faster redraws

         self.client->SetWindowQuality, DRAG=1
         self.client->Draw

         ;; Save commands in the client's undo stack to restore the
         ;; model's TRANSFORM property

         self.model->GetProperty, TRANSFORM=transform
         self.client->UndoSave, $
              obj_new('MGH_Command', OBJECT=self.model, $
                      'SetProperty', TRANSFORM=transform)

         ;; Set the active flag so we know to pass events to the trackball

         self.active = 1B

      end

      1: begin                  ;;; Mouse button release

         self.active = 0B
         self.client->Update

      end

      2:

   endcase

   ;; If rotation is active for this button then pass all events to
   ;; the trackball

   if self.active then begin

      if self.trackball->Update(event, TRANSFORM=qmat) ne 0 then begin
         self.model->GetProperty, TRANSFORM=transform
         self.model->SetProperty, TRANSFORM=transform#qmat
         self.client->Draw
      endif

   endif

end

pro MGH_Mouse_Handler_Rotate__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Rotate, inherits IDL_Object, $
                 client:obj_new(), button:0S, active:0B, $
                 trackball:obj_new(), axis:0S, constrain:0B, view: obj_new(), $
                 model: obj_new()}

end

; ***** MGH_Mouse_Handler_Scale class *****

function MGH_Mouse_Handler_Scale::Init, client

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   self.origin = -1

   return, 1

end

pro MGH_Mouse_Handler_Scale::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_Scale::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client->GetProperty, GRAPHICS_TREE=graphics_tree

   case event.type of

      0: begin                  ; Mouse button press

         if ~ obj_valid(graphics_tree) then begin
            message, /INFORM, 'There is no graphics tree'
            return
         endif

         ;; Determine which view and model this object will act on. If
         ;; there are multiple views in the graphics tree, choose the
         ;; first one selected.

         if obj_isa(graphics_tree,'IDLgrView') then begin
            self.view = graphics_tree
         endif else begin
            views = self.client->Select(graphics_tree, [event.x,event.y])
            if ~ obj_valid(views[0]) then return
            self.view = views[0]
         endelse

         model = self.view->Get()
         if ~ obj_valid(model) then return
         self.model = model

         ;; Set the origin for scaling events to be the
         ;; centre of the window
         self.client->GetProperty, DIMENSIONS=dimensions, $
              RESOLUTION=resolution, SCREEN_DIMENSIONS=screen_dimensions, $
              UNITS=units
         case units of
            0: dim = dimensions
            1: dim = 2.54*dimensions/resolution
            2: dim = dimensions/resolution
            3: dim = dimensions*screen_dimensions
         endcase

         ;; Store the origin and the distance of this event from it
         ;; for later use.
         self.origin = dim/2
         self.radius = sqrt(total(float([event.x,event.y]-self.origin)^2)) > 20

         ;; Reduce window quality for faster redraw
         self.client->SetWindowQuality, DRAG=1
         self.client->Draw

         ;; Save a command in the client's undo stack to restore the
         ;; model's TRANSFORM property

         self.model->GetProperty, TRANSFORM=transform
         self.client->UndoSave, $
              obj_new('MGH_Command', OBJECT=self.model, $
                      'SetProperty', TRANSFORM=transform)

      end

      1: begin                  ; Button release

         self.origin = -1

         self.view = obj_new()
         self.model = obj_new()

         self.client->Update

      end

      2: begin                  ; Mouse motion

         if max(self.origin) ge 0 then begin

            radius = sqrt(total(([event.x,event.y]-self.origin)^2)) > 20
            scale = radius / self.radius

            case event.modifiers gt 0 of
               0: self.model->Scale, scale, scale, 1
               1: self.model->Scale, scale, scale, scale
            endcase

            self.radius = radius

         endif

         self.client->Draw

      end

   endcase

end

pro MGH_Mouse_Handler_Scale__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Scale, inherits IDL_Object, $
                 client:obj_new(), origin: intarr(2), radius: 0., $
                 view: obj_new(), model: obj_new()}

end

; ***** MGH_Mouse_Handler_Translate class *****

function MGH_Mouse_Handler_Translate::Init, client, VERTICAL=vertical

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   self.x = -1
   self.y = -1

   self.vertical = n_elements(vertical) gt 0 ? vertical : 0

   return, 1

end

pro MGH_Mouse_Handler_Translate::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

pro MGH_Mouse_Handler_Translate::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client->GetProperty, GRAPHICS_TREE=graphics_tree

   case event.type of

      0: begin                  ; Press

         if ~ obj_valid(graphics_tree) then begin
            message, /INFORM, 'There is no graphics tree'
            return
         endif

         ;; Determine which view and model this object will act on. If
         ;; there are multiple views in the graphics tree, choose the
         ;; first one selected.

         if obj_isa(graphics_tree,'IDLgrView') then begin
            self.view = graphics_tree
         endif else begin
            views = self.client->Select(graphics_tree, [event.x,event.y])
            if ~ obj_valid(views[0]) then return
            self.view = views[0]
         endelse

         model = self.view->Get()
         if ~ obj_valid(model) then return
         self.model = model

         ;; Save cursor positin

         self.x = event.x
         self.y = event.y

         ;; Set window quality for faster redraws

         self.client->SetWindowQuality, DRAG=1
         self.client->Draw

         ;; Save commands in the client's undo stack to restore the
         ;; model's TRANSFORM property

         self.model->GetProperty, TRANSFORM=transform
         self.client->UndoSave, $
              obj_new('MGH_Command', OBJECT=self.model, $
                      'SetProperty', TRANSFORM=transform)

      end

      1: begin                  ; Release

         self.x = -1
         self.y = -1

         self.view = obj_new()
         self.model = obj_new()

         self.client->Update

      end

      2: begin                  ; Motion

         if (self.x < self.y) lt 0 then return

         ;; Calculate dimensions on the destination device (in pixels)
         ;; of a unit square on the viewplane

         norm = mgh_dest_usquare(self.view, self.client)

         case self.vertical of
            0: begin
               self.model->Translate, $
                    (event.x-self.x)/norm[0], $
                    (event.y-self.y)/norm[1], $
                    0
            end
            1: begin
               self.model->Translate, $
                    0 , $
                    0, $
                    (event.y-self.y)/sqrt(norm[0]*norm[1])
            end
         endcase

         self.x = event.x
         self.y = event.y

         self.client->Draw

      end

   endcase

end

pro MGH_Mouse_Handler_Translate__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Translate, inherits IDL_Object, $
                 client:obj_new(), x:0S, y:0S, vertical:0B, view: obj_new(), $
                 model: obj_new()}

end

; ***** MGH_Mouse_Handler_Zoom class *****

function MGH_Mouse_Handler_Zoom::Init, client, $
     NORMAL=normal, USE_INSTANCE=use_instance

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = client

   self.normal = n_elements(normal) gt 0 ? normal : 2B

   self.use_instance = keyword_set(use_instance)

   return, 1

end

pro MGH_Mouse_Handler_Zoom::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Some just-in-case cleanup. Normally all graphical elements
   ;; created by this object will be destroyed when the mouse button
   ;; is released.

   obj_destroy, [self.iview, self.imodel, self.box, self.target]

end

pro MGH_Mouse_Handler_Zoom::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client->GetProperty, GRAPHICS_TREE=graphics_tree

   case event.type of

      0: begin   ;;; Mouse button press

         if ~ obj_valid(graphics_tree) then begin
            message, /INFORM, 'There is no graphics tree'
            return
         endif

         ;; Determine which view this object will act on. If there are
         ;; multiple views in the graphics tree, choose the first one
         ;; selected. The view must be of class MGHgrGraph

         if obj_isa(graphics_tree,'IDLgrView') then begin
            view = graphics_tree
         endif else begin
            views = self.client->Select(graphics_tree, [event.x,event.y])
            if ~ obj_valid(views[0]) then return
            view = views[0]
         endelse

         if ~ obj_isa(view, 'MGHgrGraph') then begin
            message, /INFORM, 'View is not of class MGHgrGraph'
            return
         endif

         self.view = view

         ;; Find the default model and axes. The GetScaling method
         ;; provides a convenient way to do this

         self.view->GetScaling, MODEL=model, XAXIS=xaxis, YAXIS=yaxis, ZAXIS=zaxis

         ;; A valid model object is required

         if ~ obj_valid(model) then begin
            message, /INFORM, 'Model is not valid'
            return
         endif

         self.model = model

         ;; The axes in the plane of the zoom box are required.
         ;; The normal axis is optional

         case obj_valid(xaxis) of
            0: begin
               if self.normal ne 0 then begin
                  message, /INFORM, 'X axis is missing'
                  return
               endif
            end
            1: self.xaxis = xaxis
         endcase

         case obj_valid(yaxis) of
            0: begin
               if self.normal ne 1 then begin
                  message, /INFORM, 'Y axis is missing'
                  return
               endif
            end
            1: self.yaxis = yaxis
         endcase

         case obj_valid(zaxis) of
            0: begin
               if self.normal ne 2 then begin
                  message, /INFORM, 'Z axis is missing'
                  return
               endif
            end
            1: self.zaxis = zaxis
         endcase

         ;; If instancing is to be used, create a second graphics tree
         ;; in which to put the target polygon and zoom box.

         ;; It would also be possible to put the mouse handler's
         ;; graphics atoms in the original graphics tree, then hiding
         ;; and unhide atoms and/or models as necessary before each
         ;; draw. But the code to do this in a generally satisfactory
         ;; way would be too complicated, I think.

         if self.use_instance then begin
            self.view->GetProperty, DIMENSIONS=dimensions, DOUBLE=double, $
                 LOCATION=location, UNITS=units, $
                 VIEWPLANE_RECT=vrect
            self.iview = obj_new('IDLgrView', /TRANSPARENT, $
                                 DIMENSIONS=dimensions, DOUBLE=double, $
                                 LOCATION=location, UNITS=units, VIEWPLANE_RECT=vrect)
            self.model->GetProperty, TRANSFORM=transform
            self.imodel = obj_new('IDLgrModel', TRANSFORM=transform)
            self.iview->Add, self.imodel
         endif

         ;; Get some geometric info used in creating the selection
         ;; target and zoombox

         self.view->GetProperty, DELTAZ=deltaz

         if obj_valid(self.xaxis) then $
              self.xaxis->GetProperty, CRANGE=xcrange
         if obj_valid(self.yaxis) then $
              self.yaxis->GetProperty, CRANGE=ycrange
         if obj_valid(self.zaxis) then $
              self.zaxis->GetProperty, CRANGE=zcrange

         ;; Create a selection target

         data = dblarr(3,4)

         case self.normal of

            0: begin
               data[0,*] = n_elements(xcrange) gt 0 ? xcrange[0] : 0
               data[1,*] = ycrange[[0,1,1,0]]
               data[2,*] = zcrange[[0,0,1,1]]
            end

            1: begin
               data[0,*] = ycrange[[0,0,1,1]]
               data[1,*] = (n_elements(ycrange) gt 0) ? ycrange[1] : 0
               data[2,*] = zcrange[[0,1,1,0]]
            end

            2: begin
               data[0,*] = xcrange[[0,1,1,0]]
               data[1,*] = ycrange[[0,0,1,1]]
               data[2,*] = (n_elements(zcrange) gt 0) ? zcrange[0] : -10*deltaz
            end

         endcase

         ;; Tried setting DEPTH_WRITE_DISABLE to 0--this causes all pickdata
         ;; events to return 0, though they seem to return good data.

         self.view->NewAtom, 'MGHgrBackground', DATA=data, $
              COLOR=mgh_color('grey'), DEPTH_OFFSET=1, DEPTH_WRITE_DISABLE=0, $
              MODEL=self.model, XAXIS=self.xaxis, YAXIS=self.yaxis, ZAXIS=self.zaxis, $
              ADD=(~ self.use_instance), RESULT=target

         self.target = target

         if self.use_instance then self.imodel->Add, self.target

         ;; Redraw the view so that PickData will find it.

         case self.use_instance of
            0: self.client->Draw, self.view
            1: begin
               self.client->Draw, CREATE_INSTANCE=2
               self.client->Draw, self.iview, /DRAW_INSTANCE
            end
         endcase

         ;; Pick the target at the mouse-event position

         ok = self.client->PickData(self.view, self.target, [event.x,event.y], pos)
         if ok lt 1 then message, /INFORM, 'Selection missed target'

         ;; Create the the zoom box polyline. If instancing is not
         ;; used then add it to the client's graph. If it is then we
         ;; will add it to a second, transparent view

         data = dblarr(3,4)

         case self.normal of

            0: begin
               data[0,*] = n_elements(xcrange) gt 0 ? xcrange[0] : 0
               data[1,*] = pos[1]
               data[2,*] = pos[2]
            end

            1: begin
               data[0,*] = pos[0]
               data[1,*] = n_elements(ycrange) gt 0 ? ycrange[1] : 0
               data[2,*] = pos[2]
            end

            2: begin
               data[0,*] = pos[0]
               data[1,*] = pos[1]
               data[2,*] = n_elements(zcrange) gt 0 ? zcrange[0] : 10*deltaz
            end

         endcase

         self.view->NewAtom, 'IDLgrPolygon', DATA=data, $
              COLOR=mgh_color('green'), THICK=2, STYLE=1, $
              /DEPTH_TEST_DISABLE, ADD=(~ self.use_instance), RESULT=box
         self.box = box

         if self.use_instance then self.imodel->Add, self.box

         ;; The changed switch will be set to 1 when the first mouse motion
         ;; event has been received and processed successfully

         self.changed = 0B

      end

      1: begin   ;;; Mouse button release

         if self.changed then begin

            ;; Save a pair of commands in client's undo stack to restore the
            ;; range of the normal axes.

            case self.normal of
               0: begin
                  axis0 = self.yaxis
                  axis1 = self.zaxis
               end
               1: begin
                  axis0 = self.xaxis
                  axis1 = self.zaxis
               end
               2: begin
                  axis0 = self.xaxis
                  axis1 = self.yaxis
               end
            endcase
            axis0->GetProperty, RANGE=range0
            axis1->GetProperty, RANGE=range1
            cmd = [obj_new('MGH_Command', OBJECT=axis0, 'SetProperty', RANGE=range0), $
                   obj_new('MGH_Command', OBJECT=axis1, 'SetProperty', RANGE=range1)]
            self.client->UndoSave, cmd

            ;; Get data from the zoom box and resize axes accordingly

            self.box->GetProperty, DATA=data
            case self.normal of
               0: begin
                  yrange = [data[1,0],data[1,1]]
                  if yrange[0] ne yrange[1] then $
                       self.yaxis->SetProperty, RANGE=yrange
                  zrange = [data[2,0],data[2,3]]
                  if zrange[0] ne zrange[1] then $
                       self.zaxis->SetProperty, RANGE=zrange
               end
               1: begin
                  xrange = [data[0,0],data[0,1]]
                  if xrange[0] ne xrange[1] then $
                       self.xaxis->SetProperty, RANGE=xrange
                  zrange = [data[2,0],data[2,3]]
                  if zrange[0] ne zrange[1] then $
                       self.zaxis->SetProperty, RANGE=zrange
               end
               2: begin
                  xrange = [data[0,0],data[0,1]]
                  if xrange[0] ne xrange[1] then $
                       self.xaxis->SetProperty, RANGE=xrange
                  yrange = [data[1,0],data[1,3]]
                  if yrange[0] ne yrange[1] then $
                       self.yaxis->SetProperty, RANGE=yrange
               end
            endcase

            self.changed = 0B

         endif

         ;; Clean up temporary graphics atoms then update client. This
         ;; code has to be a little more careful than you might think
         ;; because on Windows it is possible, using the Ctrl key, to
         ;; generate a release event without a preceding press event.

         case self.use_instance of
            0: begin
               if obj_valid(self.box) then self.model->Remove, self.box
               if obj_valid(self.target) then self.model->Remove, self.target
               obj_destroy, [self.box,self.target]
            end
            1: obj_destroy, self.iview
         endcase

         self.client->Update

      end

      2: begin   ;;; Mouse motion

         if obj_valid(self.box) then begin

            ;; Pick the target

            ok = self.client->PickData(self.view, self.target, $
                                       [event.x,event.y], pos)
            if ok lt 1 then message, /INFORM, 'Selection missed target'

            ;; Resize zoom box and redraw. Modifier keys can be used
            ;; to constrain the handler to resize the box vertically
            ;; or horizontally only. The respective modifier keys are
            ;; specified in an OS-specific way because the Ctrl key in
            ;; Windows simulates the middle mouse button.

            self.box->GetProperty, DATA=data

            case !version.os_family of
               'Windows': begin
                  mod0 = 1      ; Shift
                  mod1 = 8      ; Alt
               end
               else: begin
                  mod0 = 1      ; Shift
                  mod1 = 2      ; Ctrl
               endelse
            endcase

            case self.normal of
               0: begin
                  if (event.modifiers && mod0) eq 0 then data[1,1:2] = pos[1]
                  if (event.modifiers && mod1) eq 0 then data[2,2:3] = pos[2]
               end
               1: begin
                  if (event.modifiers && mod0) eq 0 then data[0,1:2] = pos[0]
                  if (event.modifiers && mod1) eq 0 then data[2,2:3] = pos[2]
               end
               2: begin
                  if (event.modifiers && mod0) eq 0 then data[0,1:2] = pos[0]
                  if (event.modifiers && mod1) eq 0 then data[1,2:3] = pos[1]
               end
            endcase

            self.box->SetProperty, DATA=data

            case self.use_instance of
               0: self.client->Draw, self.view
               1: self.client->Draw, self.iview, /DRAW_INSTANCE
            endcase

            ;; Set the changed switch to indicate that the zoom box has
            ;; been resized

            self.changed = 1B

         endif
      end

   endcase

end

pro MGH_Mouse_Handler_Zoom__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Mouse_Handler_Zoom, inherits IDL_Object, $
                 client: obj_new(), changed: 0B, normal: 0S, $
                 view: obj_new(), model: obj_new(), $
                 xaxis: obj_new(), yaxis: obj_new(), zaxis: obj_new(), $
                 box: obj_new(), target: obj_new(), $
                 use_instance: 0B, iview: obj_new(), imodel: obj_new()}

end

pro MGH_Mouse_Handler_Library

end
