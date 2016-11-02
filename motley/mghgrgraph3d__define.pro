; svn $Id$
;+
; CLASS NAME:
;   MGHgrGraph3D
;
; PURPOSE:
;   This class implements a 3D graph with a plot volume and space for axes & annotations.
;   It includes several methods for adding axes, plots, and other graphics atoms & models.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   MGHgrGraph.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty & SetProperty
;   methods) are supported in addition to those inherited from MGHgrGraph:
;
;     PLOT_BOX (Init,Get,Set)
;       This is a 6-element vector specifying
;       the location and dimensions in normalised coordinates of the "plot volume".
;       By default axes and plots are drawn around, and plots in, the plot volume.
;
; METHODS:
;   ...Methods documentation under construction...
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
;   Mark Hadfield, 2000-08:
;     - Replaced existing classes MGHgrView, MGHgrGraph, MGHgrFixedGraph & MGHgrGraph3D
;       with MGHgrGraph (similar to the old MGHgrView), MGHgrGraph2D (merges the old
;       MGHgrGraph & MGHgrFixedGraph) and MGHgrGraph3D (similar to the old class of the
;       same name but much of the logic has been moved to the superclass MGHgrGraph).
;     - Removed the NewText method from this class (which therefore now inherits
;       MGHgrGraph::NewText unchanged). The functionality previously provided
;       by the TITLE keyword to NewText is now in a separate method called NewTitle.
;       The NewTitle method requires its "text class" to have an interface very
;       similar to IDLgrText, whereas the NewText method can be used with any
;       graphics atom class that supports a FONT property and takes up to 1 positional
;       parameter in its Init method.
;   Mark Hadfield, 2004-09:
;     Changed default projection of the view from 2 (perspective) to 1 (orthogonal, default)
;     to work around a vector-output bug in IDL 6.1.
;-

; MGHgrGraph3D::Init

function MGHgrGraph3D::Init, $
     PLOT_BOX=plot_box, VIEWPLANE_RECT=viewplane_rect, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Create a view with three models

;  ok = self->MGHgrGraph::Init(N_MODELS=3, PROJECTION=2, _STRICT_EXTRA=extra)
   ok = self->MGHgrGraph::Init(N_MODELS=3, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGHgrGraph'

   ;; The first model will hold graphics--rotate it for convenenient viewing

   omodel = self->Get(POSITION=0)
   omodel->SetProperty, TRANSFORM=[[ 0.824735,-0.565539,-0.002397, 0.000000], $
                                   [ 0.315446, 0.456494, 0.831945, 0.000000], $
                                   [-0.469396,-0.686882, 0.554876, 0.000000], $
                                   [ 0.000000, 0.000000, 0.000000, 1.000000]]

   ;; The second model is to hold unrotated graphics (eg title) and
   ;; the third model is to hold lights

   ;; Defaults for PLOT_BOX and VIEWPLANE_RECT:

   if n_elements(plot_box) eq 0 then plot_box = [-0.5,-0.5,-0.5,1.0,1.0,1.0]
   if n_elements(viewplane_rect) eq 0 then $
        viewplane_rect = plot_box[[0,1,3,4]] + [-0.5,-0.5,1.0,1.0]

   self.plot_box = plot_box
   self->MGHgrGraph::SetProperty, VIEWPLANE_RECT=viewplane_rect

   return, 1

end

; MGHgrGraph3D::Cleanup
;
pro MGHgrGraph3D::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGHgrGraph::Cleanup

end

; MGHgrGraph3D::GetProperty
;
PRO MGHgrGraph3D::GetProperty, $
     PLOT_BOX=plot_box, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   plot_box = self.plot_box

   self->MGHgrGraph::GetProperty, _STRICT_EXTRA=extra

END

; MGHgrGraph3D::SetProperty
;
PRO MGHgrGraph3D::SetProperty, $
     PLOT_BOX=plot_box, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(plot_box) gt 0 then self.plot_box = plot_box

   self->MGHgrGraph::SetProperty, _STRICT_EXTRA=extra

end

; MGHgrGraph3D::NewAxis
;
;   Create an axis with the appropriate scaling, add it to the plot
;   and return the object reference.
;
function MGHgrGraph3D::NewAxis, dir, $
     BOX=box, DIRECTION=direction, LOCATION=location, NORM_RANGE=norm_range, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(direction) eq 0 then $
        direction = n_elements(dir) gt 0 ? dir : 0

   if n_elements(box) eq 0 then self->GetProperty, PLOT_BOX=box

   if n_elements(location) eq 0 then begin
      case direction of
         0: location = [0.,box[1],box[2]]
         1: location = [box[0],0.,box[2]]
         2: location = [box[0],box[1]+box[3],0.]
      endcase
   endif

   if n_elements(norm_range) eq 0 then $
        norm_range = [box[direction],box[direction]+box[direction+3]]

   return, self->MGHgrGraph::NewAxis(DIRECTION=direction, LOCATION=location, $
                                     NORM_RANGE=norm_range, _STRICT_EXTRA=extra)

end

; MGHgrGraph3D::NewTitle
;
function MGHgrGraph3D::NewTitle, P1, $
     ALIGNMENT=alignment, LOCATIONS=locations, STRINGS=strings, $
     VERTICAL_ALIGNMENT=vertical_alignment, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, VIEWPLANE_RECT=viewplane_rect

   if n_elements(alignment) eq 0 then alignment = 0.5

   if n_elements(locations) eq 0 then $
        locations = [viewplane_rect[0]+0.5*viewplane_rect[2], $
                     viewplane_rect[1]+1.0*viewplane_rect[3]-0.1, $
                     0]

   model = self->Get(POSITION=1)

   if n_elements(strings) eq 0 then begin
      case n_elements(p1) gt 0 of
         0B: self->GetProperty, NAME=strings
         1B: strings = p1
      endcase
   endif


   if n_elements(vertical_alignment) eq 0 then vertical_alignment = 0.5

   return, self->NewText(MODEL=model, XAXIS=0, YAXIS=0, ZAXIS=0, $
                         ALIGNMENT=alignment, LOCATIONS=locations, STRINGS=strings, $
                         VERTICAL_ALIGNMENT=vertical_alignment, _STRICT_EXTRA=extra )

end

; Procedure forms for the "New..." functions. We only need to include the ones
; not inherited from MGHgrGraph

pro MGHgrGraph3D::NewTitle, P1, RESULT=result, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewTitle( _STRICT_EXTRA=extra )
      1: result = self->NewTitle(P1, _STRICT_EXTRA=extra )
   endcase

end


; MGHgrGraph3D__Define

pro MGHgrGraph3D__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrGraph3D, inherits MGHgrGraph, plot_box: fltarr(6)}

end


