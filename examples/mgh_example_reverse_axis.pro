;+
; NAME:
;   MGH_EXAMPLE_REVERSE_AXIS
;
; PURPOSE:
;   Experimenting with the REVERSE_RANGE keyword for MGHgrAxis objects.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;-
pro mgh_example_reverse_axis, REVERSE_RANGE=reverse_range

   ;; Drawing axes in reverse.

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(reverse_range) eq 0 then reverse_range = 0

   ;; Create the graph

   ograph = obj_new('MGHgrGraph')

   ograph->SetProperty, $
        NAME='3D axes (REVERSE_RANGE='+strtrim(reverse_range,2)+')'

   ;; Add axes

   ograph->NewAxis, DIRECTION=0, RANGE=[0,100], LOCATION=[0,-0.6], $
        TITLE='X axis', REVERSE_RANGE=reverse_range
   ograph->NewAxis, DIRECTION=1, RANGE=[0,100], LOCATION=[-0.6,0], $
        TITLE='Y axis', REVERSE_RANGE=reverse_range
   ograph->NewAxis, DIRECTION=2, RANGE=[0,100], LOCATION=[0.4,0.4], $
        TITLE='Z axis', REVERSE_RANGE=reverse_range

   ;; Draw some text to help us keep our bearing--it's orientation
   ;; does NOT depend on the axes.

   ograph->NewText, 'This way up', LOCATIONS=[-0.2,-0.2], $
        XAXIS=0, YAXIS=0, ZAXIS=0

   ;; Rotate the model to a handy angle

   omodel = ograph->Get()

   omodel->Rotate, [0,0,1], 20
   omodel->Rotate, [1,0,0], -40

   ;; Note that reversed Z axes do not appear correctly because of a
   ;; bug in IDL: Z axes do not respond to TEXTUPDIR.  Also note that
   ;; titles are incorrect when axes are reversed: this could be
   ;; addressed by attending to the text object's properties.

   mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph, $
            MOUSE_ACTION=['Rotate','Pick','Context']

end
