; svn $Id$
;+
; NAME:
;   MGH_DEST_USQUARE
;
; PURPOSE:
;   For a specified view & destination object, return the physical
;   dimensions of a square on the view plane measuring 1 x 1
;   normalised coordinates
;
; CATEGORY:
;   Object Graphics.
;
; POSITIONAL PARAMETERS:
;   oview (input, scalar object reference)
;     Reference to an Object Graphics view object. This object will be
;     queried for its UNITS, DIMENSIONS, LOCATION and VIEWPLANE_RECT
;     properties.
;
;   odest (input, scalar object reference)
;     Reference to an Object Graphics destination object. This object
;     may be queried for its UNITS, DIMENSIONS, RESOLUTION and
;     SCREEN_DIMENSIONS properties. If the view has non-zero
;     DIMENSIONS and UNITS equal to 0, 1 or 2, and the view units
;     match the units required for the result, then the destination
;     object reference is not required.
;
; KEYWORDS:
;    UNITS (input, scalar integer)
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
;   Mark Hadfield, 1998-05:
;     Written as MGH_NORM_DIMENSIONS.
;   Mark Hadfield, 1999-10:
;     I finally found a use for this, viz. code for manipulating
;     objects with the mouse. I added a UNITS keyword and
;     generalised the code accordingly.
;   Mark Hadfield, 2001-07:
;     Renamed MGH_DEST_USQUARE. Logic made simpler and more robust (I
;     hope). This function shares a lot of its code with the new
;     MGH_DEST_POSITION and I may merge them in future.
;-

function MGH_DEST_USQUARE, oview, odest, UNITS=units

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(units) eq 0 then units = 0

   oview->GetProperty, $
        UNITS=view_units, DIMENSIONS=view_dimensions, $
        LOCATION=view_location, VIEWPLANE_RECT=view_rect

   ;; A view with zero dimensions takes its dimensions from the
   ;; destination device.

   if product(view_dimensions) eq 0 then begin
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
               0: view_dimensions = $
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

   ;; Calculate a scale factor between view units and destination units.

   case units of

      0: begin

         case view_units of
            0: begin
               scale = 1.D0
            end
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

   ;; Result is dimensions of a viewplane unit square on the
   ;; destination device

   return, scale * view_dimensions / view_rect[2:3]

end
