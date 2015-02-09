;+
; NAME:
;   MGH_EXAMPLE_ANIMATE
;
; PURPOSE:
;   Object graphics animation example.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2009-10:
;     Hello from idlde70 on Thotter.
;-
pro mgh_example_animate, option, $
     PLAYER=player, N_GRID=n_grid

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   ;; Create a 3D dataset. This will be animated as a series of
   ;; surfaces representing slices along the first dimension

   data_values = mgh_flow(N_GRID=n_grid)

   data_dims = size(data_values, /DIMENSIONS)

   ;; Create & populate a graphics tree

   ograph = obj_new('MGHgrGraph3D', NAME='Example animation')

   ograph->NewFont, SIZE=12

   ;; Add axes

   ograph->NewAxis, 0, RANGE=[0,data_dims[1]-1], /EXACT
   ograph->NewAxis, 1, RANGE=[0,data_dims[2]-1], /EXACT
   ograph->NewAxis, 2, RANGE=mgh_minmax(data_values)

   ;; Add some lights

   olmodel = ograph->Get(POSITION=2)

   ograph->NewAtom, 'IDLgrLight', MODEL=olmodel, LOCATION=[0.5,0.5,0.8], TYPE=1, $
        INTENSITY=0.7, NAME='Positional'
   ograph->NewAtom, 'IDLgrLight', MODEL=olmodel, TYPE=0, INTENSITY=0.5, NAME='Ambient'

   case option of

      0: begin

         ;; Create an MGHgrDatamation object and display it wih an MGH_Player

         ;; Create an empty surface object to be animated

         ograph->NewAtom, 'IDLgrSurface', STYLE=2, NAME='Data surface', $
              BOTTOM=mgh_color('light green'), COLOR=mgh_color('light blue'), $
              RESULT=osurf

         ;; Create the animation.

         mgh_new, 'MGHgrDatamation', GRAPHICS_TREE=ograph, RESULT=oanimation

         ;; Load data into the animation

         for slice=0,data_dims[0]-1 do begin
            oanimation->AddFrame, obj_new('MGH_Command', OBJECT=osurf, 'SetProperty', $
                                          DATAZ=reform(data_values[slice,*,*]))
         endfor

         mgh_new, 'MGH_Player', ANIMATION=oanimation, $
                  MOUSE_ACTION=['Rotate','Pick','Context'], RESULT=player

      end

      1: begin

         ;; Create an MGHgrAtomation object and display it wih an MGH_Player

         oanimation = obj_new('MGHgrAtomation', GRAPHICS_TREE=ograph)

         ;; Create frames and add to animation via the player's
         ;; AddItem method.

         for slice=0,data_dims[0]-1 do begin

            ;; Create the atom and add it to the player. The "ADD=0"
            ;; keyword means it is not added to the graph--the
            ;; player will be responsible for adding and removing it
            ;; during playback.

            osurf = ograph->NewAtom('IDLgrSurface', NAME='Data surface', $
                                    DATAZ=reform(data_values[slice,*,*]), STYLE=2, $
                                    BOTTOM=mgh_color('light green'), $
                                    COLOR=mgh_color('light blue'), ADD=0)

            oanimation->AddFrame, osurf

         endfor

         mgh_new, 'MGH_Player', ANIMATION=oanimation, $
                  MOUSE_ACTION=['Rotate','Pick','Context'], RESULT=player

      end

      2: begin

         ;; Load and display an MGHgrDatamation object using an MGH_Datamator

         ;; Create an empty surface object to be animated

         ograph->NewAtom, 'IDLgrSurface', STYLE=2, NAME='Data surface', $
              BOTTOM=mgh_color('light green'), $
              COLOR=mgh_color('light blue'), RESULT=osurf

         ;; Create the player window & animation.

         mgh_new, 'MGH_Datamator', GRAPHICS_TREE=ograph, $
                  MOUSE_ACTION=['Rotate','Pick','Context'], RESULT=player

         ;; Load data into the animation

         for slice=0,data_dims[0]-1 do begin

            ;; Check to see if the user has selected the "Finish
            ;; Loading" menu item

            if player->Finished() then break

            ;; Create a command to generate this frame and add it to
            ;; the player

            player->AddFrame, obj_new('MGH_Command', OBJECT=osurf, 'SetProperty', $
                                      DATAZ=reform(data_values[slice,*,*]))

         endfor

         player->Finish

      end

      3: begin

         ;; Load and display an MGHgrAtomation object using an MGH_Atomator

         mgh_new, 'MGH_Atomator', GRAPHICS_TREE=ograph, $
                  MOUSE_ACTION=['Rotate','Pick','Context'], RESULT=player

         ;; Create frames and add to animation via the player's
         ;; AddItem method.

         for slice=0,data_dims[0]-1 do begin

            ;; Check to see if the user has selected the "Finish
            ;; Loading" menu item

            if player->Finished() then break

            ;; Create the atom and add it to the player. The "ADD=0"
            ;; keyword means it is not added to the graph--the
            ;; player will be responsible for adding and removing it
            ;; during playback.

            ograph->NewAtom, 'IDLgrSurface', NAME='Data surface', $
                 DATAZ=reform(data_values[slice,*,*]), $
                 STYLE=2, BOTTOM=mgh_color('light green'), $
                 COLOR=mgh_color('light blue'), ADD=0, RESULT=osurf

            player->AddFrame, osurf

         endfor

         player->Finish

      end

   endcase

end
