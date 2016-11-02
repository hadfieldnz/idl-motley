; svn $Id$
;+
; CLASS NAME:
;   Mgh_Barb_Movie
;
; PURPOSE:
;
;   This class displays a 3-D numeric array as a sequence of surface
;   plots in a window with axes and a colour scale. The class inherits
;   from MGH_Player.
;
; OBJECT CREATION CALLING SEQUENCE
;
;   mgh_new, 'Mgh_Barb_Movie', Values
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
;   Mark Hadfield, 2003-07:
;     Written.
;-

; Mgh_Barb_Movie::Init

function Mgh_Barb_Movie::Init, u, v, x, y, $
     BARB_SCALE=barb_scale, $
     GRAPH_PROPERTIES=graph_properties, $
     SLICE_DIMENSION=slice_dimension, $
     SLICE_RANGE=slice_range, $
     SLICE_STRIDE=slice_stride, $
     STYLE=style, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, $
     ZAXIS_PROPERTIES=zaxis_properties, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.barb_scale = n_elements(barb_scale) gt 0 ? barb_scale : 0.1

   if ~ array_equal(size(u, /DIMENSIONS), size(v, /DIMENSIONS)) then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'u', 'v'

   ;; Check dimensions. If n_dim is 2 we will pretend the array has a
   ;; trailing unit dimension. This can be displayed if
   ;; SLICE_DIMENSIOn is 2 (the default)

   n_dim = size(u, /N_DIMENSIONS)
   dim = size(u, /DIMENSIONS)

   if n_dim eq 2 then begin
      n_dim = 3
      dim = [dim, 1]
   endif

   if n_dim ne 3 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'u & v'

   if n_elements(slice_dimension) eq 0 then slice_dimension = 2
   if n_elements(slice_stride) eq 0 then slice_stride = 1

   case slice_dimension of
      0: begin
         numx = dim[1]
         numy = dim[2]
         nums = dim[0]
      end
      1: begin
         numx = dim[0]
         numy = dim[2]
         nums = dim[1]
      end
      2: begin
         numx = dim[0]
         numy = dim[1]
         nums = dim[2]
      end
   endcase

   if n_elements(slice_range) eq 0 then slice_range = [0,nums-1]

   mgh_undefine, n_dim, dim

   ;; Set up X and Y position arrays

   if n_elements(x) eq 0 then x = findgen(numx)
   if n_elements(y) eq 0 then y = findgen(numy)

   case size(x, /N_DIMENSIONS) of
      1: begin
         datax = x # replicate(1, numy)
         datay = replicate(1, numx) # y
      end
      2: begin
         datax = x
         datay = y
      end
   endcase

   ;; Create the base graph

   ograph = obj_new('MGHgrGraph2D', NAME='Barb animation', _STRICT_EXTRA=graph_properties)

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   ograph->NewAxis, 0, RANGE=mgh_minmax(x), /EXACT, /EXTEND, $
        _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, 1, RANGE=mgh_minmax(y), /EXACT, /EXTEND, $
        _STRICT_EXTRA=yaxis_properties

   ;; Create an empty barb object, add it to the graphics tree &
   ;; keep a reference to it.

   ograph->NewAtom, 'MGHgrBarb', $
        DATAX=datax, DATAY=datay, SCALE=self.barb_scale, $
        COLOR=mgh_color('red'), RESULT=obarb
   self.barb = obarb

   ;; Create an MGH_Datamation object and load the frames into it

   oanimation = obj_new('MGHgrDatamation', GRAPHICS_TREE=ograph)

   for s=slice_range[0],slice_range[1],slice_stride do begin

      case slice_dimension of
         0: begin
            datau = reform(u[s,*,*])
            datav = reform(v[s,*,*])
         end
         1: begin
            datau = reform(u[*,s,*])
            datav = reform(v[*,s,*])
         end
         2: begin
            datau = reform(u[*,*,s])
            datav = reform(v[*,*,s])
         end
      endcase

      oframe = obj_new('MGH_Command', OBJECT=self.barb, $
                       'SetProperty', DATAU=temporary(datau), DATAV=temporary(datav))


      oanimation->AddFrame, oframe

   endfor

   ;; Set up the player and return

   ok = self->MGH_Player::Init(ANIMATION=oanimation, CHANGEABLE=0, FITTABLE=1, $
                               _STRICT_EXTRA=extra)

   if ~ ok then message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Player'

   self->Finalize, 'Mgh_Barb_Movie'

   return, 1

end

; Mgh_Barb_Movie::Cleanup
;
pro Mgh_Barb_Movie::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::Cleanup

end

; Mgh_Barb_Movie::GetProperty
;
pro Mgh_Barb_Movie::GetProperty, $
     BARB_SCALE=barb_scale, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   barb_scale = self.barb_scale

   self->MGH_Player::GetProperty, _STRICT_EXTRA=extra

end

; Mgh_Barb_Movie::SetProperty
;
pro Mgh_Barb_Movie::SetProperty, $
     BARB_SCALE=barb_scale, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(barb_scale) gt 0 then begin
      self.barb_scale = barb_scale
      self.barb->SetProperty, SCALE=self.barb_scale
   endif

   self->MGH_Player::SetProperty, _STRICT_EXTRA=extra

end

; Mgh_Barb_Movie::About
;
;   Print information about the window and its contents
;
pro Mgh_Barb_Movie::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::About, lun

end

; Mgh_Barb_Movie::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro Mgh_Barb_Movie::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::BuildMenuBar

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      obar->NewItem, PARENT='Tools', SEPARATOR=[1,0], $
        ['Set Barb Scale...','View Data Values...']

   endif

end


; Mgh_Barb_Movie::EventMenuBar
;
function Mgh_Barb_Movie::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'TOOLS.SET BARB SCALE': begin
         mgh_new, 'MGH_GUI_SetArray', CAPTION='Barb Scale', CLIENT=self, $
                  N_ELEMENTS=1, /FLOATING, GROUP_LEADER=self.base, $
                  PROPERTY_NAME='BARB_SCALE'
         return, 1
      end

      else: return, self->MGH_Player::EventMenuBar(event)

   endcase

end

; Mgh_Barb_Movie::ExportData
;
pro Mgh_Barb_Movie::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::ExportData, values, labels

   self->GetProperty, ANIMATION=animation, POSITION=position

   oframe = animation->GetFrame(POSITION=position)
   oframe[0]->GetProperty, KEYWORDS=keywords

   labels = [labels, 'U Data', 'V Data']
   values = [values, ptr_new(keywords.datau), ptr_new(keywords.datav)]

end

; Mgh_Barb_Movie__Define

pro Mgh_Barb_Movie__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Barb_Movie, inherits MGH_Player, $
                 barb: obj_new(), barb_scale: 0.}

end
