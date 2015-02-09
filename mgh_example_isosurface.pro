; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_ISOSURFACE
;
; PURPOSE:
;   Isosurface example
;
;   You might also like to try the command:
;
;     mgh_new, 'mgh_isosurface', /EXAMPLE
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
;   Mark Hadfield, 2001-02:
;     Written.
;-

pro mgh_example_isosurface, $
     N_GRID=n_grid, PERCENT_POLYGON=percent_polygon, THRESHOLD=threshold

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(threshold) eq 0 then threshold = -3.5

   data_values = reverse(mgh_flow(N_GRID=n_grid),1)

   isosurface, -data_values, -threshold, vert, conn

   msg = ['ISOSURFACE created a mesh with', $
          strtrim(mesh_numtriangles(conn),2), $
          'triangles']
   message, /INFORM, strjoin(temporary(msg), ' ')

   ;; Scale vertex positions here if necessary

   ;; Decimate the mesh

   if n_elements(percent_polygon) gt 0 then begin

      numt = mesh_decimate(vert, conn, conn2, $
                           PERCENT_POLYGON=percent_polygon)
      conn = temporary(conn2)

      if numt eq 0 then message, 'No vertices returned by MESH_DECIMATE'

      message, /INFORM, 'MESH_DECIMATE returned a mesh with '+ $
               strtrim(numt,2)+' triangles'

   endif

   ;; Create a graph

   ograph = obj_new('MGHgrGraph3D')

   ograph->SetProperty, NAME='Isosurface example'

   ograph->NewFont, SIZE=10

   ograph->NewAxis, 0, RANGE=[0,2*n_grid-1], TITLE='X', /EXTEND, /EXACT
   ograph->NewAxis, 1, RANGE=[0,n_grid-1], TITLE='Y', /EXTEND, /EXACT
   ograph->NewAxis, 2, RANGE=[0,n_grid-1], TITLE='Z', /EXTEND, /EXACT

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', LOCATION=[2,2,2], $
        TYPE=1, INTENSITY=0.7
   ograph->NewAtom, MODEL=olmodel, 'IDLgrLight', TYPE=0, INTENSITY=0.5

   ;; Create the polygon and display in a window

   ograph->NewAtom, 'IDLgrPolygon', $
        DATA=vert, POLYGONS=conn, $
        COLOR=mgh_color('light blue'), $
        BOTTOM=mgh_color('light green')

   mgh_new, 'MGH_Window', ograph

end
