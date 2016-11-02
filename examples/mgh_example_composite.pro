 ;+
; NAME:
;   MGH_EXAMPLE_COMPOSITE
;
; PURPOSE:
;   An example of a composite graphics element to confirm that positons are
;   calculated correctly.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2004-03:
;     Updated for IDL 6.0.
;-
pro mgh_example_composite

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ograph = obj_new('MGHgrGraph2D', NAME='Composite graphics object example' )

   ograph->NewFont, SIZE=10

   ograph->NewAxis, DIRECTION=0, RANGE=[-1,2]
   ograph->NewAxis, DIRECTION=1, RANGE=[-1,2]

   print, 'Click on the grey rectangles & check that positions are reported ' + $
          'correctly in data units.'

   ograph->NewAtom, 'MGHgrCompositeExample', $
        DIMENSIONS=[1,0.69], LOCATION=[-0.5,-0.4,200], $
        ZCOORD_CONV=[0,0.001], NAME='Composite Object 0', RESULT=oc0

   ograph->NewAtom, 'MGHgrCompositeExample', $
        DIMENSIONS=[1,0.69], LOCATION=[0.1,0.1,500], $
        ZCOORD_CONV=[0,0.001], NAME='Composite Object 1', RESULT=oc1

   mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph, $
            MOUSE_ACTION=['Pick','Prop Sheet','Context']

   print, 'X, Y & Z range after drawing:'

   oc0->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
   print, [xrange, yrange, zrange]

   oc1->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
   print, [xrange, yrange, zrange]

end

