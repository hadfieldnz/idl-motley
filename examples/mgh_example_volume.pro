;+
; NAME:
;   MGH_EXAMPLE_VOLUME
;
; PURPOSE:
;   Volume visualisation example.
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
;-
pro mgh_example_volume

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ograph = obj_new('MGHgrGraph3D')

   ograph->SetProperty, NAME='3D volume example'

   ograph->NewFont, SIZE=10

   ;; An MGHgrGraph3D has three top-level models. The volume is added
   ;; to the first one. This is the model that is manipulated by the
   ;; mouse in an MGH_Window.

   ;; Axes

   ograph->NewAxis, 0, RANGE=[0,1], TITLE='X', /EXTEND
   ograph->NewAxis, 1, RANGE=[0,1], TITLE='Y', /EXTEND
   ograph->NewAxis, 2, RANGE=[0,1], TITLE='Z', /EXTEND

   ;; Get data

   file = filepath(SUBDIR=['examples', 'data'], 'head.dat')
   data = BYTARR(80, 100, 57)
   openr, lun, file, /GET_LUN
   readu, lun, data
   free_lun, lun

   ;; Volume object

   ograph->NewAtom, 'MGHgrVolume', data, NAME='Data volume', $
        /ZERO_OPACITY_SKIP, /ZBUFFER, LOCATION=[0,0,0], DIMENSIONS=[1,1,1]

   ;; Add a title. The NewTitle method adds a text object to the
   ;; second model.  The default string is the graph name.

   ograph->NewTitle

   ;; The third model is intended for lights.

   light_model = ograph->Get(POSITION=2)

   ograph->NewAtom, MODEL=light_model, 'IDLgrLight', LOCATION=[2,2,2], TYPE=1, INTENSITY=0.7

   ograph->NewAtom, MODEL=light_model, 'IDLgrLight', TYPE=0, INTENSITY=0.5

   ;; Display it all.

   mgh_new, 'MGH_Window', ograph, MOUSE_ACTION=['Rotate','Pick','Context']

end


