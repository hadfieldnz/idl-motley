; svn $Id$
;+
; NAME:
;   MGH_PICTURE_IS_FITTABLE
;
; PURPOSE:
;   This function determines whether a picture has properties that
;   allow its size to be determined explicitly. It optionally returns
;   size information via the UNITS and DIMENSIONS keywords.
;
;   "Picture" is my name for an IDL drawable object, ie an IDLgrView,
;   IDLgrScene or IDLgrViewgroup.
;
; CATEGORY:
;   Object graphics
;
; CALLING SEQUENCE:
;   Result = MGH_PICTURE_IS_FITTABLE(picture, UNITS=units, DIMENSIONS=dimensions)
;
; POSITIONAL PARAMETERS:
;   picture (input, scalar object reference)
;     A picture whose properties are to be queried
;
; KEYWORD PARAMETERS:
;   DIMENSIONS (output, 2-element floating)
;     Dimensions for a rectangle enclosing the view(s) in the picture.
;
;   N_VIEWS (output, scalar integer)
;     Number of views contained in the picture.
;
;   UNITS (output, scalar integer)
;     Units for the DIMENSIONS. One of the criteria for a viewgroup to
;     be fittable is that all views have the same units.
;
;   VIEWS (output, object reference)
;     An array of object references to the views contained in the picture
;
; RETURN VALUE:
;   The function returns 1B if the picture is fittable, otherwise
;   0B. The UNITS and DIMENSIONS keywords are given values iff the
;   picture is fittable.
;
; DEPENDENCIES:
;   Runs under IDL 5.1 or greater.
;
; EXAMPLE:
;   To fit window oWindow to view oView
;
;   IDL> fittable = mgh_picture_is_fittable(oView, UNITS=units, DIMENSIONS=dimensions)
;   IDL> if fittable then oWindow->SetProperty, UNITS=units, DIMENSIONS=dimensions
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
;   Mark Hadfield, 1998-09:
;     Written.
;   Mark Hadfield, 2001-01:
;     Added VIEWS keyword.
;   Mark Hadfield, 2002-06:
;     Moved code to get the view objects to a separate function,
;     MGH_PICTURE_GET_VIEWS. I took this opportunity to enchance this code and it
;     now handles IDLgrScene objects correctly.
;-

function MGH_PICTURE_IS_FITTABLE, picture, $
     DIMENSIONS=dimensions, N_VIEWS=n_views, UNITS=units, VIEWS=views

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   views = mgh_picture_get_views(picture, COUNT=n_views)

   if n_views eq 0 then return, 0B

   for i=0,n_views-1 do begin
      views[i]->GetProperty, UNITS=view_units, DIMENSIONS=view_dimensions, $
           LOCATION=view_location
      if (view_units gt 2) then return, 0
      if (view_location[0] lt 0) then return, 0
      if (view_location[1] lt 0) then return, 0
      if (view_dimensions[0]*view_dimensions[1] eq 0) then return, 0
      case i of
         0: begin
            picture_units = view_units
            picture_dimensions = view_dimensions+view_location
         end
         else: begin
            if (view_units ne picture_units) then return, 0B
            picture_dimensions = (view_dimensions+view_location) > picture_dimensions
         endelse
      endcase
   endfor

   ;; If we have got to here, picture is fittable.

   units = picture_units
   dimensions =  picture_dimensions

   return, 1B

end


