; svn $Id$
;+
; CLASS NAME:
;   MGH_IsoSurface
;
; PURPOSE:
;   This class displays a 3-D numeric array as an iso-surface with an
;   adjustable threshols.
;
; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'MGH_IsoSurface', values
;
; INPUTS:
;   values  A 3D array of numeric data
;
; PROPERTIES:
;   The following properties are supported (amongst others):
;
;     BYTE_RANGE (Init,Get)
;       The range of byte values to which the data range is to be mapped.
;
;     DATA_RANGE (Init,Get,*Set)
;       The range of data values to be mapped onto the indexed color range for the
;       density surface and the colour bar. Data values outside the range are mapped
;       to the nearest end of the range. If not specified, DATA_RANGE is calculated
;       when the density surface is created, The DATA_RANGE property can be changed
;       after object initialisation only if the STORE_DATA property has been set.
;
;     PALETTE (Init,Get,Set)
;       A reference to the palette defining the byte-color mapping.
;
;     STORE_DATA (Init,Get):
;       This property is passed to the density surface. It determines whether
;       data values are stored with the surface.
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
;   Mark Hadfield, 1999-05:
;       Written.
;   Mark Hadfield, 2003-10:
;       Updated
;-

; MGH_IsoSurface::Init

function MGH_IsoSurface::Init, values, $
     DATA_VALUES=data_values, EXAMPLE=example, $
     GRAPH_PROPERTIES=graph_properties, $
     THRESHOLD=threshold, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ;; Sort out data

   if keyword_set(example) then data_values = reverse(mgh_flow(),1)

   if n_elements(data_values) eq 0 && n_elements(values) gt 0 then data_values = values

   if size(data_values, /N_DIMENSIONS) ne 3 then $
        message, 'DATA_VALUES array must have 3 dimensions'

   data_dims = size(data_values, /DIMENSIONS)

   self.data_values = ptr_new(data_values)

   ;; Set threshold

   if n_elements(threshold) eq 0 then $
        threshold = mgh_avg(mgh_minmax(data_values, /NAN))

   ;; Create graph

   ograph = obj_new('MGHgrGraph3D')

   ograph->SetProperty, NAME='Isosurface example'

   ograph->NewFont, SIZE=10

   ograph->NewAxis, 0, RANGE=[0,data_dims[0]-1], TITLE='X', /EXTEND, /EXACT
   ograph->NewAxis, 1, RANGE=[0,data_dims[1]-1], TITLE='Y', /EXTEND, /EXACT
   ograph->NewAxis, 2, RANGE=[0,data_dims[2]-1], TITLE='Z', /EXTEND, /EXACT

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', LOCATION=[2,2,2], TYPE=1, INTENSITY=0.7
   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', TYPE=0, INTENSITY=0.5

   ;; Create the polygon

   self.polygon = ograph->NewAtom('IDLgrPolygon', $
                                  COLOR=mgh_color('light blue'), $
                                  BOTTOM=mgh_color('light green'))

   ;; Set up the window and return

   ok = self->MGH_Window::Init(ograph, CHANGEABLE=0, $
                               MOUSE_aCTION=['Rotate','Pick','Context'], $
                               _STRICT_EXTRA=extra)

   if ~ ok then message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Window'

   ;; Add the control bar

   self->BuildControlBar

   ;; Set the treshold. This causes the iso-surface to be calculated.

   self->MGH_IsoSurface::SetProperty, THRESHOLD=threshold

   ;; Finalise & return

   self->Finalize, 'MGH_IsoSurface'

   return, 1

end

; MGH_IsoSurface::Cleanup
;
pro MGH_IsoSurface::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ptr_free, self.data_values

   self->MGH_Window::Cleanup

end


; MGH_IsoSurface::GetProperty
;
PRO MGH_IsoSurface::GetProperty, $
     DATA_VALUES=data_values, THRESHOLD=threshold, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if arg_present(data_values) then $
        data_values = *self.data_values

   threshold = self.threshold

   self->MGH_Window::GetProperty, _STRICT_EXTRA=extra

END

; MGH_IsoSurface::SetProperty
;
pro MGH_IsoSurface::SetProperty, $
     THRESHOLD=threshold, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(threshold) gt 0 then begin
      self.threshold = threshold
      isosurface, *self.data_values, self.threshold, vert, conn
      self.polygon->SetProperty, DATA=vert, POLYGONS=conn
   endif

   self->MGH_Window::SetProperty, _STRICT_EXTRA=extra

END

; MGH_IsoSurface::About
;
;   Print information about the window and its contents
;
pro MGH_IsoSurface::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::About, lun

end

; MGH_Window::BuildControlBar
;
pro MGH_Window::BuildControlBar, flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = (self.control_bar eq 0)

   case flag of

      0: if self.control_bar gt 0 then begin
         widget_control, self.control_bar, /DESTROY
         self.status_bar = 0
      end

      1: if self.control_bar eq 0 then begin

         octl = self->NewChild('MGH_GUI_Base', /OBJECT, /ROW, $
                               /ALIGN_CENTER, /BASE_ALIGN_CENTER, $
                               UVALUE=self->Callback('EventControlBar'))

         self.control_bar = octl->GetBase()

         range = mgh_minmax(*self.data_values, /NAN)

         octl->NewChild, 'cw_fslider', $
              /EDIT, MINIMUM=range[0], MAXIMUM=range[1], UNAME='SLIDER'

      endif

   endcase

end

; MGH_IsoSurface::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_IsoSurface::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::BuildMenuBar

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      ;; Nothing to add right now

   endif

end

; MGH_IsoSurface::EventControlBar
;
function MGH_IsoSurface::EventControlBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   case event.uname of

      'SLIDER': begin
         self->SetProperty, THRESHOLD=event.event.value
         self->Update
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_IsoSurface::EventMenuBar
;
function MGH_IsoSurface::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   case event.value of

      else: return, self->MGH_Window::EventMenubar(event)

   endcase

end

; MGH_IsoSurface::Update
;
pro MGH_IsoSurface::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

    self->UpdateControlBar

    self->MGH_Window::Update

end

; MGH_IsoSurface::UpdateControlBar
;
pro MGH_IsoSurface::UpdateControlBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.control_bar)

   if obj_valid(obar) then begin

      wid = obar->FindChild('SLIDER')
      if wid gt 0 then begin
         self->GetProperty, THRESHOLD=threshold
         widget_control, wid, SET_VALUE=threshold
      endif

   endif

end


; MGH_IsoSurface__Define

pro MGH_IsoSurface__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        { MGH_IsoSurface, inherits MGH_Window, $
          control_bar: 0L, data_values: ptr_new(), $
          polygon: obj_new(), threshold: 0.D}

end
