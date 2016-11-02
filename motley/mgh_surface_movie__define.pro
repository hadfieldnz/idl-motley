; svn $Id$
;+
; CLASS NAME:
;   MGH_Surface_Movie
;
; PURPOSE:
;
;   This class displays a 3-D numeric array as a sequence of surface
;   plots in a window with axes and a colour scale. The class inherits
;   from MGH_Player.
;
; OBJECT CREATION CALLING SEQUENCE
;
;   mgh_new, 'MGH_Surface_Movie', Values
;
; POSITIONAL PARAMETERS:
;
;   values (input, 3D numeric array)
;     Data to be plotted
;
;   x, y (input, 1D or 2D numeric array, optional)
;     X & Y positions of the data points.
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
;   Mark Hadfield, May 1999:
;     Written.
;   Mark Hadfield, Dec 2000:
;     Miscellaneous enhancements. DIMENSION now zero-based.
;   Mark Hadfield, Jul 2001:
;     Now based on MGH_Player.
;   Mark Hadfield, 2003-07:
;     SLICE_DIMENSION now 1-based..
;-

; MGH_Surface_Movie::Init

function MGH_Surface_Movie::Init, values, x, y, $
     DATA_RANGE=data_range, $
     EXAMPLE=example, $
     GRAPH_PROPERTIES=graph_properties, $
     SLICE_DIMENSION=slice_dimension, $
     SLICE_RANGE=slice_range, $
     SLICE_STRIDE=slice_stride, $
     STYLE=style, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, $
     ZAXIS_PROPERTIES=zaxis_properties, $
     _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(example) then begin
      if n_elements(values) eq 0 then values = transpose(mgh_flow(), [1,2,0])
   endif

   if n_elements(data_values) eq 0 && n_elements(values) gt 0 then data_values = values

   n_dim = size(data_values, /N_DIMENSIONS)
   dim = size(data_values, /DIMENSIONS)

   if n_dim eq 2 then begin
      n_dim = 3
      dim = [dim, 1]
   endif

   if n_dim ne 3 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_values'

   if n_elements(slice_dimension) eq 0 then slice_dimension = 3
   if n_elements(slice_stride) eq 0 then slice_stride = 1

   self.style = n_elements(style) gt 0 ? style : 2

   self.data_range = $
        n_elements(data_range) gt 0 ? data_range : mgh_minmax(values, /NAN)

   if n_elements(slice_stride) eq 0 then slice_stride = 1

   nums = dim[slice_dimension-1]

   case slice_dimension of
      1: begin
         numx = dim[1]
         numy = dim[2]
      end
      2: begin
         numx = dim[0]
         numy = dim[2]
      end
      3: begin
         numx = dim[0]
         numy = dim[1]
      end
   endcase

   if n_elements(slice_range) eq 0 then slice_range = [0,nums-1]

   case (self.style eq 2) or (self.style eq 6) of
      1: begin
         surface_color = mgh_color('light blue')
         surface_bottom = mgh_color('light green')
      end
      0: begin
         surface_color = mgh_color('black')
         surface_bottom = mgh_color('black')
      end
   endcase

   ;; Set up X and Y position arrays

   if n_elements(x) eq 0 then x = findgen(numx)
   if n_elements(y) eq 0 then y = findgen(numy)

   vertx = mgh_stagger(x, DELTA=(self.style ge 5))
   verty = mgh_stagger(y, DELTA=(self.style ge 5))

   ;; Create the base graph

   mgh_new, RESULT=ograph, 'MGHgrGraph3D', COLOR=replicate(225B,3), $
            NAME='3D array animation', $
            _STRICT_EXTRA=graph_properties

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   xrange = mgh_minmax(mgh_stagger(x, DELTA=1))
   yrange = mgh_minmax(mgh_stagger(y, DELTA=1))

   ograph->NewAxis, 0, RANGE=xrange, /EXACT, _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, 1, RANGE=yrange, /EXACT, _STRICT_EXTRA=yaxis_properties
   ograph->NewAxis, 2, RANGE=self.data_range, /EXACT, _STRICT_EXTRA=zaxis_properties

   ;; Add some lights. This is necessary only for a filled surface,
   ;; but seems to have no disadvantages in other cases, so do it
   ;; always.

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, 'IDLgrLight', MODEL=olmodel, LOCATION=[0.5,0.5,0.8], $
        TYPE=1, INTENSITY=0.7, NAME='Positional'
   ograph->NewAtom, 'IDLgrLight', MODEL=olmodel, $
        TYPE=0, INTENSITY=0.5, NAME='Ambient'

   ;; Create an empty surface object, add it to the graphics tree &
   ;; keep a reference to it.

   ograph->NewAtom, 'MGHgrLegoSurface', STYLE=self.style, $
        DATAZ=replicate(!values.f_nan,numx,numy), $
        DATAX=vertx, DATAY=verty, BOTTOM=surface_bottom, COLOR=surface_color, $
        RESULT=osurf

   self.surface = osurf

   ;; Create an MGH_Datamation object and load the frames into it

   oanimation = obj_new('MGHgrDatamation', GRAPHICS_TREE=ograph)

   for s=slice_range[0],slice_range[1],slice_stride do begin

      case slice_dimension of
         1: fdata = reform(values[s,*,*])
         2: fdata = reform(values[*,s,*])
         3: fdata = reform(values[*,*,s])
      endcase

      oframe = obj_new('MGH_Command', OBJECT=self.surface, $
                       'SetProperty', DATAZ=fdata)


      oanimation->AddFrame, oframe

   endfor

   ;; Set up the player and return

   ok = self->MGH_Player::Init(ANIMATION=oanimation, CHANGEABLE=0, $
                               MOUSE_ACTION=['Rotate','Pick','Context'], $
                               _STRICT_EXTRA=_extra)

   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Player'

   self->Finalize, 'MGH_Surface_Movie'

   return, 1

end

; MGH_Surface_Movie::Cleanup
;
pro MGH_Surface_Movie::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::Cleanup

end

; MGH_Surface_Movie::GetProperty
;
pro MGH_Surface_Movie::GetProperty, $
     DATA_RANGE=data_range, STYLE=style, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   data_range = self.data_range

   style = self.style

   self->MGH_Player::GetProperty, _STRICT_EXTRA=_extra

end

; MGH_Surface_Movie::SetProperty
;
pro MGH_Surface_Movie::SetProperty, $
     DATA_RANGE=data_range, STYLE=style, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(data_range) gt 0 then begin
      self.data_range = data_range
      self->GetProperty, GRAPHICS_TREE=ograph
      zaxis = ograph->GetAxis(DIRECTION=2, /ALL, COUNT=n_zaxes)
      if n_zaxes gt 0 then zaxis[0]->SetProperty, RANGE=self.data_range
   endif

   if n_elements(style) gt 0 then begin

      self.style = style

      ;; Following code could be moved to a separate method.

      case (self.style eq 2) or (self.style eq 6) of
         1: begin
            surface_color = mgh_color('light blue')
            surface_bottom = mgh_color('light green')
         end
         0: begin
            surface_color = mgh_color('black')
            surface_bottom = mgh_color('black')
         end
      endcase

      self.surface->SetProperty, $
           STYLE=self.style, COLOR=surface_color, BOTTOM=surface_bottom

   endif

   self->MGH_Player::SetProperty, _STRICT_EXTRA=_extra

end

; MGH_Surface_Movie::About
;
;   Print information about the window and its contents
;
pro MGH_Surface_Movie::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::About, lun

end

; MGH_Surface_Movie::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Surface_Movie::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->MGH_Player::BuildMenuBar

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      obar->NewItem, PARENT='Tools', SEPARATOR=[1,0,0,1], MENU=[1,0,0,0], $
           ['Data Range','Set Style...','Arrange Lights...', 'View Data Values...']

      obar->NewItem, PARENT='Tools.Data Range', ['Set...','Fit this Frame']

   endif

end


; MGH_Surface_Movie::EventMenuBar
;
function MGH_Surface_Movie::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   case event.value of

      'TOOLS.DATA RANGE.SET': begin
         mgh_new, 'MGH_GUI_SetArray', CAPTION='Range', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, IMMEDIATE=0, $
                  N_ELEMENTS=2, PROPERTY_NAME='DATA_RANGE'
         return, 0
      end

      'TOOLS.DATA RANGE.FIT THIS FRAME': begin
         self->GetProperty, POSITION=position
         oframe = self.animation->GetFrame(POSITION=position)
         oframe[0]->GetProperty, KEYWORDS=keywords
         data_range = mgh_minmax(keywords.dataz, /NAN)
         if data_range[0] eq data_range[1] then data_range += [-1,1]
         self->SetProperty, DATA_RANGE=data_range
         self->Update
         return, 0
      end

      'TOOLS.SET STYLE': begin
         mgh_new, 'MGH_GUI_SetList', CAPTION='Style', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, IMMEDIATE=0, $
                  ITEM_STRING=['Points','Mesh','Filled','Ruled XZ', $
                               'Ruled YZ','Lego','Lego Filled'], $
                  PROPERTY_NAME='STYLE'
         return, 0
      end

      'TOOLS.ARRANGE LIGHTS': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         olights = graphics_tree->Get(POSITION=2)
         mgh_new, 'MGH_GUI_LightEditor', CLIENT=self, $
                  LIGHT=olights->Get(/ALL), /FLOATING, $
                  GROUP_LEADER=self.base, /IMMEDIATE
         return, 0
      end

      'TOOLS.VIEW DATA VALUES': begin
         self->GetProperty, POSITION=position
         oframe = self.animation->GetFrame(POSITION=position)
         oframe->GetProperty, KEYWORDS=keywords
         data_dims = size(keywords.dataz, /DIMENSIONS)
         xvaredit, keywords.dataz, GROUP=self.base, $
                   X_SCROLL_SIZE=(data_dims[0] < 12), $
                   Y_SCROLL_SIZE=(data_dims[1] < 30)
         return, 1
      end

      else: return, self->MGH_Player::EventMenuBar(event)

   endcase

end

; MGH_Surface_Movie::ExportData
;
pro MGH_Surface_Movie::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::ExportData, values, labels

   self->GetProperty, ANIMATION=animation, POSITION=position

   oframe = animation->GetFrame(POSITION=position)
   oframe[0]->GetProperty, KEYWORDS=keywords

   labels = [labels, 'Surface Data']
   values = [values, ptr_new(keywords.dataz)]

end

; MGH_Surface_Movie__Define

pro MGH_Surface_Movie__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Surface_Movie, inherits MGH_Player, $
                 surface: obj_new(), data_range: fltarr(2), style: 0B}

end
