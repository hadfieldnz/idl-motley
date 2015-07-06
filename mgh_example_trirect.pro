; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_TRIRECT
;
; PURPOSE:
;   Show output from MGH_TRIANGULATE_RECTANGLE function
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
