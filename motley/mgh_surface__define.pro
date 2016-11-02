;+
; CLASS NAME:
;   MGH_Surface
;
; PURPOSE:
;   This class displays a 2-D numeric array as a surface plot in a window,
;   with axes and a colour scale.
;
; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'MGH_Surface', values[, x, y]
;
; INPUTS:
;   values (input, numeric 2-D)
;     Data to be plotted
;
;   x, y (input, optional, numeric 1-D or 2-D)
;     Surface X & Y data
;
; PROPERTIES:
;   The following properties are supported (amongst others):
;
;     DATA_RANGE (Init,Get,*Set)
;       The range of data values to be mapped onto the indexed color
;       range for the density surface and the colour bar. Data values
;       outside the range are mapped to the nearest end of the
;       range. If not specified, DATA_RANGE is calculated when the
;       density surface is created.
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
;   Mark Hadfield, 2000-12
;     Written.
;-

; MGH_Surface::Init

function MGH_Surface::Init, $
     values, X, Y, $
     BYTE_RANGE=byte_range, DATA_VALUES=data_values, $
     DATAX=datax, DATAY=datay, $
     DATA_RANGE=data_range, EXAMPLE=example, $
     GRAPH_PROPERTIES=graph_properties, $
     PALETTE=palette, $
     STYLE=style, TITLE=title, $
     SURFACE_PROPERTIES=surface_properties, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, $
     ZAXIS_PROPERTIES=zaxis_properties, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Defaults

   if n_elements(style) eq 0 then style = 2

   ;; Sort out data

   if keyword_set(example) then $
        data_values = beselj(0.5*shift(mgh_dist(40),20,20),0)

   if n_elements(datax) eq 0 then if n_elements(X) gt 0 then datax = X
   if n_elements(datay) eq 0 then if n_elements(Y) gt 0 then datay = Y
   if n_elements(data_values) eq 0 then $
        if n_elements(values) gt 0 then data_values = values

   if size(data_values, /N_DIMENSIONS) ne 2 then $
        message, 'DATA_VALUES array must have 2 dimensions)'

   dims = size(data_values, /DIMENSIONS)

   if n_elements(datax) eq 0 then $
        datax = mgh_stagger(findgen(dims[0]), DELTA=style ge 5)
   if n_elements(datay) eq 0 then $
        datay = mgh_stagger(findgen(dims[1]), DELTA=style ge 5)

   surface_color = [100,100,255]
   surface_bottom = [100,255,100]

   ;; Calculate data range

   case n_elements(data_range) gt 0 of
      0: self.data_range = mgh_minmax(data_values, /NAN)
      1: self.data_range = data_range
   endcase

   ;; Create graph & axes. If surface is non-lego allow

   ograph = obj_new('MGHgrGraph3D', COLOR=replicate(225B,3), $
                    NAME='Surface Plot', /REGISTER_PROPERTIES, $
                    _STRICT_EXTRA=graph_properties)

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   xrange = mgh_minmax(mgh_stagger(datax, DELTA=style lt 5))
   yrange = mgh_minmax(mgh_stagger(datay, DELTA=style lt 5))

   ograph->NewAxis, DIRECTION=0, RANGE=xrange, /EXACT, $
        _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, DIRECTION=1, RANGE=yrange, /EXACT, $
        _STRICT_EXTRA=yaxis_properties
   ograph->NewAxis, DIRECTION=2, RANGE=self.data_range, /EXACT, $
        _STRICT_EXTRA=zaxis_properties

   ;; Add a model containing some lights
   ;; This is necessary only for a filled surface, but seems to have
   ;; no disadvantages in other cases, so do it always.

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, 'IDLgrLight', MODEL=olmodel, LOCATION=[0.5,0.5,0.8], $
        TYPE=1, INTENSITY=0.7, NAME='Positional'
   ograph->NewAtom, 'IDLgrLight', MODEL=olmodel, TYPE=0, INTENSITY=0.5, $
        NAME='Ambient'

   ograph->NewTitle, title

   ograph->NewAtom, 'MGHgrLegoSurface', STYLE=style, COLOR=surface_color, $
        BOTTOM=surface_bottom, DATAZ=data_values, DATAX=datax, $
        DATAY=datay, /HIDDEN_LINES, NAME='Surface', /REGISTER_PROPERTIES, $
        _STRICT_EXTRA=surface_properties, RESULT=osurf
   self.surface = osurf

   ok = self->MGH_Window::Init(ograph, CHANGEABLE=0, $
                               MOUSE_ACTION=['Rotate','Pick','Context'], $
                               _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Window'

;   self->RegisterProperty, 'Style', $
;        ENUMLIST=['Points','Mesh','Filled','Ruled XZ','Ruled YZ','Lego','Lego Filled']

   self->Finalize, 'MGH_Surface'

   return, 1

end

; MGH_Surface::Cleanup
;
pro MGH_Surface::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::Cleanup

end

; MGH_Surface::GetProperty
;
pro MGH_Surface::GetProperty, $
     ALL=all, DATA_RANGE=data_range, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::GetProperty, ALL=all, _STRICT_EXTRA=extra

   self.surface->GetProperty, STYLE=style

   data_range = self.data_range

   if arg_present(all) then $
        all = create_struct(all, 'data_range', data_range, 'style', style)

END

; MGH_Surface::SetProperty
;
pro MGH_Surface::SetProperty, $
     DATA_RANGE=data_range, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::SetProperty, _STRICT_EXTRA=extra

   self.surface->SetProperty, STYLE=style

   if n_elements(data_range) gt 0 then begin

      self.data_range = data_range

      self->GetProperty, GRAPHICS_TREE=ograph

      zaxis = ograph->GetAxis(DIRECTION=2, /ALL, COUNT=n_zaxes)
      zaxis[0]->SetProperty, RANGE=self.data_range

   endif

END

; MGH_Surface::About
;
;   Print information about the window and its contents
;
pro MGH_Surface::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::About, lun

   if obj_valid(self.surface) then begin
      printf, lun, self, ': the surface is ' + $
              mgh_obj_string(self.surface, /SHOW_NAME)
  endif

end

; MGH_Surface::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Surface::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::BuildMenuBar

   ombar = mgh_widget_self(self.menu_bar)

   ombar->NewItem, PARENT='Tools', SEPARATOR=[1,0,0,1,0,0], $
        ['Set Data Range...','Arrange Lights...', $
         'Edit Data Values...','Graph Properties...','Surface Properties...']

end

; MGH_Surface::EventMenuBar
;
function MGH_Surface::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'TOOLS.SET DATA RANGE': begin
         mgh_new, 'MGH_GUI_SetArray', /FLOATING, MBAR=0, $
                  GROUP_LEADER=self.base, N_ELEMENTS=2, CAPTION='Range', $
                  CLIENT=self, PROPERTY_NAME='DATA_RANGE'
         return, 0
      end

;      'TOOLS.SET STYLE': begin
;         mgh_new, 'MGH_GUI_SetList', CAPTION='Style', CLIENT=self, $
;                  /FLOATING, GROUP_LEADER=self.base, /IMMEDIATE, $
;                  ITEM_STRING=['Points','Mesh','Filled','Ruled XZ', $
;                               'Ruled YZ','Lego','Lego Filled'], $
;                  PROPERTY_NAME='STYLE', /MBAR
;         return, 0
;      end

      'TOOLS.ARRANGE LIGHTS': begin
         self->GetProperty, GRAPHICS_TREE=graph
         olights = graph->Get(POSITION=2)
         mgh_new, 'MGH_GUI_LightEditor', CLIENT=self, $
                  LIGHT=olights->Get(/ALL), /IMMEDIATE, /FLOATING, $
                  GROUP_LEADER=self.base
         return, 0
      end

      'TOOLS.EDIT DATA VALUES': begin
         self.surface->GetProperty, DATAZ=dataz
         data_dims = size(dataz, /DIMENSIONS)
         xvaredit, dataz, GROUP_LEADER=self.base, $
                   X_SCROLL_SIZE=(data_dims[0] < 8), $
                   Y_SCROLL_SIZE=(data_dims[1] < 30)
         self.surface->SetProperty, DATAZ=dataz
         self->Update
         return, 0
      end

      'TOOLS.GRAPH PROPERTIES': begin
         self->GetProperty, GRAPHICS_TREE=ograph
         mgh_new, 'MGH_GUI_PropertySheet', /FLOATING, GROUP_LEADER=self.base, $
              CLIENT=ograph, SPECTATOR=self
         return, 0
      end

      'TOOLS.SURFACE PROPERTIES': begin
         mgh_new, 'MGH_GUI_PropertySheet', /FLOATING, GROUP_LEADER=self.base, $
              CLIENT=self.surface, SPECTATOR=self
         return, 0
      end

      else: return, self->MGH_Window::EventMenuBar(event)

   endcase

end

; MGH_Surface::ExportData
;
pro MGH_Surface::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::ExportData, values, labels

   self.surface->GetProperty, DATAX=datax, DATAY=datay, DATAZ=dataz

   labels = [labels,'Data Z','Vertex X','Vertex Y']
   values = [values,ptr_new(dataz),ptr_new(datax),ptr_new(datay)]

end

; MGH_Surface::NewAtom
;
pro MGH_Surface::NewAtom, class, P1, P2, P3, UPDATE=update, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(update) eq 0 then update = 1B

   self->GetProperty, GRAPHICS_TREE=ograph

   case n_params() of
      1: ograph->NewAtom, class, _STRICT_EXTRA=extra
      2: ograph->NewAtom, class, P1, _STRICT_EXTRA=extra
      3: ograph->NewAtom, class, P1, P2, _STRICT_EXTRA=extra
      4: ograph->NewAtom, class, P1, P2, P3, _STRICT_EXTRA=extra
   endcase

   if keyword_set(update) then self->Update

end

; MGH_Surface::NewSymbol
;
pro MGH_Surface::NewSymbol, P1, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=ograph

   case n_params() of
      0: ograph->NewSymbol, _STRICT_EXTRA=extra
      1: ograph->NewSymbol, P1, _STRICT_EXTRA=extra
   endcase

end

; MGH_Surface__Define

pro MGH_Surface__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Surface, inherits MGH_Window, surface: obj_new(), $
                 data_range: dblarr(2)}

end
