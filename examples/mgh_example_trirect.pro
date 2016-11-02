;+
; NAME:
;   MGH_EXAMPLE_TRIRECT
;
; PURPOSE:
;   Show output from MGH_TRIANGULATE_RECTANGLE function
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-11:
;     Written.
;-
pro mgh_example_trirect, dim

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(dim) eq 0 then dim = [5,6]

   x = mgh_range(-0.5, 0.5, N_ELEMENTS=dim[0]) # replicate(1, dim[1])
   y = replicate(1, dim[0]) # mgh_range(-0.5, 0.5, N_ELEMENTS=dim[1])

   ograph = obj_new('MGHgrGraph')

   ograph->NewAtom, 'IDLgrPolygon', x, y, NAME='Polygon', $
        POLYGONS=mgh_triangulate_rectangle(dim, /POLYGONS), STYLE=1

   mgh_new, 'mgh_window', ograph

end
