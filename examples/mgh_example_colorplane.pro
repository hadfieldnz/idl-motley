 ;+
; NAME:
;   MGH_EXAMPLE_COLORPLANE
;
; PURPOSE:
;   Colour plane example.
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
pro mgh_example_colorplane, $
     STYLE=style, PLANE_CLASS=plane_class, TRUE=true

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(style) eq 0 then style = 0

   if n_elements(plane_class) eq 0 then plane_class = 'MGHgrColorPlane'

   ograph = obj_new('MGHgrGraph2D', NAME='Colour plane example')

   ograph->NewMask

   ograph->NewFont, SIZE=10

   numx = 20  &  numy = 20

   missing = bytarr(numx,numy)
   missing[  numx/3,  numy/6] = 1B
   missing[2*numx/3,2*numy/3] = 1B

   case keyword_set(true) of
      0: begin
         colors = mgh_bytscl(mgh_dist(numx,numy))
         ograph->NewPalette, mgh_get_ct('Prism', /SYSTEM), RESULT=opal
      end
      1: begin
         colors = bytarr(3,numx,numy)
         colors[0,*,*] = mgh_bytscl(mgh_dist(numx,numy))
         colors[1,*,*] = 255-mgh_bytscl(mgh_dist(numx,numy))
      end
   endcase

   ;; We will create the surface first, fit the axes to it, then add
   ;; the surface to the graph with AddAtom. This departs from the usual way
   ;; of doing such things, which is to create the axes first then
   ;; create the atom with NewAtom. I did it this way just for fun.

   ;; Set up arrays defining the location of the data values

   xx = mgh_range(-50,50,N_ELEMENTS=numx)
   yy = mgh_range(0,100,N_ELEMENTS=numy)

   ;; The surface requires the location of the vertices. With STYLE=0
   ;; we need one more vertex location in each direction than the
   ;; number of data values. The MGH_STAGGER function was written to
   ;; do this.

   if style eq 0 then begin
      xx = mgh_stagger(xx, DELTA=1)
      yy = mgh_stagger(yy, DELTA=1)
   endif

   ;; Create the surface

   oplane = obj_new(plane_class, NAME='Color plane', COLOR_VALUES=colors, $
                    MISSING_POINTS=missing, /REGISTER_PROPERTIES, $
                    STYLE=style, DATAX=xx, DATAY=yy, PALETTE=opal)

   oplane->GetProperty, XRANGE=xrange, YRANGE=yrange

   ograph->NewAxis, 0, RANGE=xrange, /EXACT, /EXTEND, NAME='X axis'
   ograph->NewAxis, 1, RANGE=yrange, /EXACT, /EXTEND, NAME='Y axis'

   ograph->AddAtom, oplane

   mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph

end

