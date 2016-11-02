;+
; NAME:
;   MGH_EXAMPLE_WHERE3D
;
; PURPOSE:
;   Object graphics example: graphically illustrate non-missing points in a
;   3D gridded dataset.
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
;   Mark Hadfield, 2002-01:
;     Written.
;-
pro mgh_example_where3D

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Create a 3D data array populated by 0s and 1s

   l = 12  &  m = 14  &  n = 6

   a = randomu(seed,l,m,n) gt 0.5

   ;; Create a graph & set up axes etc.

   ograph = obj_new('MGHgrGraph3D', NAME='Non-missing data in 3D array')

   ograph->NewTitle

   ograph->NewAxis, DIRECTION=0, RANGE=[0,l-1], /EXACT, /EXTEND
   ograph->NewAxis, DIRECTION=1, RANGE=[0,m-1], /EXACT, /EXTEND
   ograph->NewAxis, DIRECTION=2, RANGE=[0,n-1], /EXACT, /EXTEND

   ;; Add some lights

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', LOCATION=[2,2,2], TYPE=1, INTENSITY=0.7
   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', TYPE=0, INTENSITY=0.5

   ;; Draw a grid through the data points. To cut down the clutter
   ;; (and to take advantage of the MESH_OBJ routine) draw only the
   ;; horizontal planes of the grid.

   for k=0,n-1 do begin
      mesh_obj, 1, vert, conn, replicate(k,l,m)
      ograph->NewAtom, 'IDLgrPolygon', $
           COLOR=mgh_color('blue'), DATA=vert, POLY=conn, STYLE=1
   endfor

   ;; Create a symbol to be drawn at the non-missing points.

   ograph->NewSymbol, STYLE=3, $
        /FILL, COLOR=mgh_color('red'), RESULT=osym

   ;; Create arrays holding x, y and z locations of indices

   x = rebin(findgen(l),l,m,n)
   y = rebin(findgen(1,m),l,m,n)
   z = rebin(findgen(1,1,n),l,m,n)

   ;; Strip out the 0s

   ones = where(a, count)

   if count eq 0 then message, 'No non-missing values'

   x = x[ones]
   y = y[ones]
   z = z[ones]

   ;; The symbols are displayed at the vertices of an invisible
   ;; IDLgrPolyline

   ograph->NewAtom, 'IDLgrPolyline', x, y, z, LINE=6, SYMBOL=osym

   mgh_new, 'MGH_Window', ograph, MOUSE_aCTION=['Rotate','Pick','Context']

end


