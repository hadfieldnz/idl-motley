; svn $Id$
;+
; NAME:
;   MGH_DEST_POSITION
;
; PURPOSE:
;   Convert from viewplane to destination-object coordinates.
;
;   For a specified view & destination object, given a position on the
;   viewplane, calculate & return the corresponding position on the
;   destination device.
;
; CATEGORY:
;   Object Graphics.
;
; POSITIONAL PARAMETERS:
;   position (input, 2-element vector)
;     A position on the viewplane.
;
;   oview (input, scalar object reference)
;     View object
;
;   odest (input, scalar object reference)
;     Destination object
;
; KEYWORD PARAMETERS:
;    UNITS (input, integer)
;      This keyword specified the units of the result (0 = pixels, 1 =
;      inches, 2 = cm). Default is 0.
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
;   Mark Hadfield, 2001-07:
;     Written as a generalisation of MGH_NORM_DIMENSIONS.
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6.
;-

function MGH_DEST_POSITION, position, oview, odest, UNITS=units

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(position) ne 2 then $
        message, 'First argument must be a position on the view plane'

   if n_elements(units) eq 0 then units = 0

   oview->GetProperty, $
        UNITS=view_units, DIMENSIONS=view_dimensions, $
        LOCATION=view_location, VIEWPLANE_RECT=view_rect

   ;; A view with zero dimensions takes its dimensions from the
   ;; destination device.

   if view_dimensions[0]*view_dimensions[1] eq 0 then begin
      odest->GetProperty, $
           UNITS=dest_units, DIMENSIONS=dest_dimensions, RESOLUTION=dest_resolution
      case view_units of
         0: begin
            case dest_units of
               0: view_dimensions = dest_dimensions
               1: view_dimensions = dest_dimensions/dest_resolution/2.54
               2: view_dimensions = dest_dimensions/dest_resolution
               3: view_dimensions = dest_dimensions*screen_dimensions
            endcase
         end
         1: begin
            case dest_units of
               0: view_dimensions = dest_dimensions*dest_resolution*2.54
               1: view_dimensions = dest_dimensions
               2: view_dimensions = dest_dimensions*2.54
               3: view_dimensions = $
                    dest_dimensions*screen_dimensions*dest_resolution*2.54
            endcase
         end
         2: begin
            case dest_units of
               0: view_dimensions = dest_dimensions*dest_resolution
               1: view_dimensions = dest_dimensions/2.54
               2: view_dimensions = dest_dimensions
               3: view_dimensions = $
                    dest_dimensions*screen_dimensions*dest_resolution
            endcase
         end
         3: view_dimensions = [1,1]
      end
   endif

   ;; Calculate a scale factor between view units and destination
   ;; units.

   case units of

      0: begin

         case view_units of
            0: scale = 1.D0
            1: begin
               odest->GetProperty, RESOLUTION=dest_resolution
               scale = 2.54D0/dest_resolution
            end
            2: begin
               odest->GetProperty, RESOLUTION=dest_resolution
               scale = 1.D0/dest_resolution
            end
            3: begin
               odest->GetProperty, $
                    UNITS=dest_units, DIMENSIONS=dest_dimensions, $
                    RESOLUTION=dest_resolution, SCREEN_DIMENSIONS=screen_dimensions
               case dest_units of
                  0: scale = dest_dimensions
                  1: scale = (2.54D0*dest_dimensions)/dest_resolution
                  2: scale = dest_dimensions/dest_resolution
                  3: scale = dest_dimensions*screen_dimensions
               endcase
            end
         endcase

      end

      1: begin

         case view_units of
            0: begin
               odest->GetProperty, RESOLUTION=dest_resolution
               scale = dest_resolution/2.54D0
            end
            1: scale = 1.D0
            2: scale = 1.D0/2.54D0
            3: begin
               odest->GetProperty, $
                    UNITS=dest_units, DIMENSIONS=dest_dimensions, $
                    RESOLUTION=dest_resolution, SCREEN_DIMENSIONS=screen_dimensions
               case dest_units of
                  0: scale = (dest_resolution*dest_dimensions)/2.54D0
                  1: scale = dest_dimensions
                  2: scale = dest_dimensions/2.54D0
                  3: scale = (dest_resolution*dest_dimensions*screen_dimensions)/2.54D0
               endcase
            end
         endcase

      end

      2: begin

         case view_units of
            0: begin
               odest->GetProperty, RESOLUTION=dest_resolution
               scale = dest_resolution
            end
            1: scale = 2.54D0
            2: scale = 1.D0
            3: begin
               odest->GetProperty, $
                    UNITS=dest_units, DIMENSIONS=dest_dimensions, $
                    RESOLUTION=dest_resolution, SCREEN_DIMENSIONS=screen_dimensions
               case dest_units of
                  0: scale = dest_resolution*dest_dimensions
                  1: scale = 2.54D0*dest_dimensions
                  2: scale = dest_dimensions
                  3: scale = dest_resolution*dest_dimensions*screen_dimensions
               endcase
            end
         endcase

      end

   endcase

   ;; Return result. This seems to work!

   return, scale * (view_location + $
                    view_dimensions*(position-view_rect[0:1])/view_rect[2:3])

end
