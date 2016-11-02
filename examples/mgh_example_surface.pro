; svn $Id$
 ;+
; NAME:
;   MGH_EXAMPLE_SURFACE
;
; PURPOSE:
;   Surface plot example.
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
;   Mark Hadfield, 2004-07:
;     Removed call to the axes' obsolete SetInPlace method.
;-

pro mgh_example_surface, m, n, $
     STYLE=style, SURFACE_PROPERTIES=surface_properties

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(m) eq 0 then m = 21

   if n_elements(n) eq 0 then n = m

   if n_elements(style) eq 0 then style = 2

   ;; Create data to be displayed

   dataz = mgh_dist(m,n)
   dataz[m/4,n/4] = !values.f_nan

   ;; Set up graph

   ograph = obj_new('MGHgrGraph3D')

   ograph->SetProperty, NAME='3D surface example'

   ograph->NewFont, SIZE=10

   ;; An MGHgrGraph3D has three top-level models. The axes & surface
   ;; are added to the first one. This is the model that is manipulated
   ;; by the mouse in an MGH_Window.

   ;; The MGHgrLegoSurface object will create its own horizontal
   ;; geometry, depending on the value of the STYLE property. So
   ;; create horizontal axes with default RANGE and then adjust them
   ;; afterwards.

   ograph->NewAxis, 0, TITLE='X', /EXACT, /EXTEND, RESULT=xaxis
   ograph->NewAxis, 1, TITLE='Y', /EXACT, /EXTEND, RESULT=yaxis

   ograph->NewAxis, 2, RANGE=mgh_minmax(dataz, /NAN), TITLE='Z', /EXTEND

   ograph->NewAtom, 'MGHgrLegoSurface', dataz, STYLE=style, $
        COLOR=mgh_color('light blue'), BOTTOM=mgh_color('light green'), $
        _STRICT_EXTRA=surface_properties, RESULT=osurf

   ;; Fit horizontal axes around the surface, just for fun.

   osurf->GetProperty, DATAX=datax, DATAY=datay

   xaxis[0]->SetProperty, RANGE=mgh_minmax(datax)
   yaxis[0]->SetProperty, RANGE=mgh_minmax(datay)

   ;; Add a title. The NewTitle method adds a text object to the
   ;; second model.  The default string is the graph name.

   ograph->NewTitle

   ;; The third model is intended for lights.

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', LOCATION=[2,2,2], TYPE=1, INTENSITY=0.7
   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', TYPE=0, INTENSITY=0.5

   ;; Display it all.

   mgh_new, 'MGH_Window', ograph, MOUSE_ACTION=['Rotate','Pick','Context']

end


