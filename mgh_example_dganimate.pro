; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_DGANIMATE
;
; PURPOSE:
;   Example illustrating different methods of animating direct graphics
;   commands.
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
;-

pro mgh_example_dganimate, option, N_GRID=n_grid

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   ;; Create a 3D dataset. This will be animated as a series of surfaces representing
   ;; slices along the first dimension

   data_values = mgh_flow(N_GRID=n_grid)

   data_dims = size(data_values, /DIMENSIONS)

   case option of

      0: begin

         ;; Store DG commands in an MGHdgAnimation & display in an MGH_DGplayer

         mgh_new, 'MGHdgAnimation', RESULT=oanimation

         zrange = mgh_minmax(data_values)

         for slice=0,data_dims[0]-1 do begin
            oanimation->AddFrame, $
                 obj_new('MGH_Command', 'surface', reform(data_values[slice,*,*]), $
                         ZRANGE=zrange)
         endfor

         mgh_new, 'MGH_DGplayer', ANIMATION=oanimation, NAME='Example animation'

      end

      1: begin

         ;; Render DG commands to images & display in an MGH_Imagator

         animator = obj_new('MGH_Imagator', DIMENSIONS=[500,500], $
                            GRAPHICS_TREE_PROPERTIES={name: 'Example animation'})


         zrange = mgh_minmax(data_values)

         for slice=0,data_dims[0]-1 do begin

            if animator->Finished() then break

            animator->SetPlot

            surface, reform(data_values[slice,*,*]), ZRANGE=zrange

            animator->AddPlot

         endfor

         animator->Finish

      end

      2: begin

         ;; Render DG commands to images & display in an XINTERANIMATE widget
         ;; See D. Fanning's "IDL Programming Techniques", 2nd edition, p105.

         xinteranimate, SET=[500,500,data_dims[0]], /SHOWLOAD

         window, /FREE, /PIXMAP, XSIZE=500, YSIZE=500

         mypix = !d.window

         wset, mypix

         zrange = mgh_minmax(data_values)

         for slice=0,data_dims[0]-1 do begin
            surface, reform(data_values[slice,*,*]), ZRANGE=zrange
            xinteranimate, FRAME=slice, WINDOW=mypix
         endfor

         xinteranimate, 70

         wdelete, mypix

      end

   endcase

end

