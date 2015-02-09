; svn $Id$
;+
; CLASS NAME:
;   MGH_Bprofile_Movie
;
; PURPOSE:
;   This class displays a pair of 2-D numeric arrays as a sequence of
;   current-barb profiles. The class inherits from MGH_Datamator.
;
;   Note that the MGHgrBarb object automagically changes its SCALE
;   property when its [X,Y,Z]COORD_CONV properties are changed, and this
;   can cause problems for the current plot. Perhaps a property should be
;   added to MGHgrBarb to suppress re-scaling in selected directions.

; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'mgh_bprofile_movie', u, v
;
; INPUTS:
;   u, v
;     2D numeric arrays containing u and v components of velocity
;
; KEYWORD PARAMETERS:
;   SPEED_MAX (input, numeric scalar)
;     This keyword specifies the range of the speed axes. Default
;     is taken from data.
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
;   Mark Hadfield, 2001-03:
;     Written.
;   Mark Hadfield, 2001-06:
;     - Now inherits from MGH_Datamator instead of MGH_Atomator.
;-

; MGH_Bprofile_Movie::Init

function MGH_Bprofile_Movie::Init, u, v, z, $
     EXAMPLE=example, $
     GRAPH_PROPERTIES=graph_properties, $
     SLICE_DIMENSION=slice_dimension, $
     SLICE_RANGE=slice_range, $
     SLICE_STRIDE=slice_stride, $
     SPEED_MAX=speed_max, $
     TITLE=title, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, $
     ZAXIS_PROPERTIES=zaxis_properties, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(example) then begin
      nz = 31  &  nt = 101
      z = findgen(nz)/(nz-1.)
      zz = z#replicate(1,nt)
      t = replicate(1,nz)# findgen(nt)/(nt-1.)
      s = sin(!pi*zz^2)*(0.1+sqrt(t))
      p = 3*!pi*t+0.5*!pi*zz*t
      u = s*cos(p)  &  v = s*sin(p)
      mgh_undefine, nz, nt, t, s, p, zz
   endif

   if n_elements(slice_dimension) eq 0 then slice_dimension = 1

   if size(u, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'U'
   if size(v, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'V'

   self.speed_max = n_elements(speed_max) gt 0 $
        ? speed_max : max(sqrt(u^2+v^2), /NAN)

   if n_elements(slice_stride) eq 0 then slice_stride = 1

   dim = size(u, /DIMENSIONS)

   case slice_dimension of
      0: begin
         numz = dim[1]  &  nums = dim[0]
      end
      1: begin
         numz = dim[0]  &  nums = dim[1]
      end
   endcase

   if n_elements(slice_range) eq 0 then slice_range = [0,nums-1]

   if n_elements(z) eq 0 then z = findgen(numz)

   ;; Create the base graph.

   ograph = obj_new('MGHgrGraph3D', COLOR=replicate(225B ,3), $
                    NAME='Velocity profile animation', _STRICT_EXTRA=graph_properties)

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   ograph->NewAxis, 0, RANGE=[-1,1]*self.speed_max, /EXACT, $
        _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, 1, RANGE=[-1,1]*self.speed_max, /EXACT, $
        _STRICT_EXTRA=yaxis_properties
   ograph->NewAxis, 2, RANGE=mgh_minmax(z), /EXACT, $
        _STRICT_EXTRA=zaxis_properties

   ;; Barb plot object to be animated

   self.barb = ograph->NewAtom('MGHgrBarb', DATAZ=z, COLOR=mgh_color('red'))

   ;; Create an animator window to display and manage the movie.

   ok = self->MGH_Datamator::Init(CHANGEABLE=0, GRAPHICS_TREE=ograph, $
                                  MOUSE_ACTION=['Rotate','Pick','Context'], $
                                  _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Datamator'

   ;; Step through the array generating new frames & plotting data

   for s=slice_range[0],slice_range[1],slice_stride do begin

      if self->Finished() then break

      case slice_dimension of
         0: begin
            uu = reform(u[s,*])
            vv = reform(v[s,*])
         end
         1: begin
            uu = reform(u[*,s])
            vv = reform(v[*,s])
         end
      endcase

      self->AddFrame, obj_new('MGH_Command', OBJECT=self.barb, $
                              'SetProperty', DATAU=temporary(uu), DATAV=temporary(vv))

   endfor

   self->Finish

   return, 1

end

; MGH_Bprofile_Movie::Cleanup
;
pro MGH_Bprofile_Movie::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Datamator::Cleanup

end

; MGH_Bprofile_Movie::GetProperty
;
pro MGH_Bprofile_Movie::GetProperty, $
     SPEED_MAX=speed_max, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   speed_max = self.speed_max

   self->MGH_Datamator::GetProperty, _STRICT_EXTRA=extra

end

; MGH_Bprofile_Movie::SetProperty
;
pro MGH_Bprofile_Movie::SetProperty, $
     SPEED_MAX=speed_max, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GRAPHICS_TREE=graph

   if n_elements(speed_max) gt 0 then begin
      self.speed_max = speed_max
      if obj_valid(graph) then begin
         xaxis = graph->GetAxis(DIRECTION=0)
         xaxis->SetProperty, RANGE=self.speed_max*[-1,1]
         yaxis = graph->GetAxis(DIRECTION=1)
         yaxis->SetProperty, RANGE=self.speed_max*[-1,1]
;        graph->GetScaling, XCOORD_CONV=xcoord, YCOORD_CONV=ycoord
;        self.barb->SetProperty, SCALE=[xcoord[1],ycoord[1],1]
      endif
   endif

   self->MGH_Datamator::SetProperty, _STRICT_EXTRA=extra

end

; MGH_Bprofile_Movie::About
;
;   Print information about the window and its contents
;
pro MGH_Bprofile_Movie::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Datamator::About, lun

end

; MGH_Bprofile_Movie::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Bprofile_Movie::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Datamator::BuildMenuBar

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then $
        obar->NewItem, PARENT='Tools', ['Set Max Speed...']

end


; MGH_Bprofile_Movie::EventMenuBar
;
function MGH_Bprofile_Movie::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'TOOLS.SET MAX SPEED': begin
         mgh_new, 'MGH_GUI_SetArray', CAPTION='Max speed', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, IMMEDIATE=1, N_ELEMENTS=1, $
                  PROPERTY_NAME='SPEED_MAX'
         return, 1
      end

      else: return, self->MGH_Datamator::EventMenuBar(event)

   endcase

end

; MGH_Bprofile_Movie::ExportData
;
pro MGH_Bprofile_Movie::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Datamator::ExportData, values, labels

   self->GetProperty, ANIMATION=animation, POSITION=position

   oframe = animation->GetFrame(POSITION=position)
   oframe[0]->GetProperty, KEYWORDS=keywords

   labels = [labels,'U,V Profile']
   values = [values,ptr_new(complex(keywords.datau,keywords.datav))]

end

; MGH_Bprofile_Movie__Define

pro MGH_Bprofile_Movie__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGH_Bprofile_Movie, inherits MGH_Datamator, $
         barb: obj_new(), speed_max: 0.D}

end
