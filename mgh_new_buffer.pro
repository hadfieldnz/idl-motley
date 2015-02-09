; svn $Id$
;+
; NAME:
;   MGH_NEW_BUFFER
;
; PURPOSE:
;   This function creates and returns a new IDLgrBuffer, or similar
;   destination object. It checks to see whether the buffer dimensions
;   (in device units) are going to exceed the screen dimensions and if
;   necessary adjusts the value of DIMENSIONS or RESOLUTION
;   accordingly to keep it in bounds.
;
; CATEGORY:
;   Object graphics
;
; CALLING SEQUENCE:
;   Result = MGH_NEW_BUFFER(Class, DIMENSIONS=dimensions, $
;                           RESOLUTION=resolution, UNITS=units)
;
; POSITIONAL PARAMETERS:
;   class (input, string scalar, optional)
;     The object class name (default 'IDLgrBuffer').
;
; KEYWORD PARAMETERS:
;   DIMENSIONS (input, numeric 2-element vector)
;     The requested dimensions of the new buffer. The actual
;     dimensions may differ from this to keep the buffer size (in
;     device units) within the limits set by the screen dimensions.
;
;   MULTIPLE (input, 1 or 2-element integer)
;     Buffer dimensions in pixels are forced to be an integer
;     multiple of this value.
;
;   RESOLUTION (input, numeric two-element vector or scalar)
;     The requested resolution of the new buffer. The actual
;     resolution may differ from this to keep the buffer size (in
;     device units) within the limits set by the screen
;     dimensions.
;
;   UNITS (input, integer scalar)
;     Units for the DIMENSIONS.
;
; RETURN VALUE:
;   The function returns an object reference.
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
;       Written.
;   Mark Hadfield, 2004-05:
;       Added MULTIPLE keyword.
;-
function mgh_new_buffer, class, $
     DIMENSIONS=dimensions, MULTIPLE=multiple, RESOLUTION=resolution, $
     UNITS=units, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(class) eq 0 then class = 'IDLgrBuffer'

   ;; Create a temporary instance of the buffer class to establish
   ;; default properties & screen dimensions

   o = obj_new(class)
   o->GetProperty, DIMENSIONS=default_dimensions, $
        RESOLUTION=default_resolution, SCREEN_DIMENSIONS=sdim, $
        UNITS=default_units
   obj_destroy, o

   ;; Supply defaults

   if n_elements(dimensions) eq 0 then dimensions = default_dimensions

   if n_elements(resolution) eq 0 then resolution = default_resolution

   if n_elements(units) eq 0 then units = default_units

   ;; Dimensions & resolution may be changed, so make a copy to
   ;; protect keyword variables We also take this opportunity to allow
   ;; scalar resolutions.

   dim = float(dimensions)

   mul = round(n_elements(multiple) gt 0 ? multiple : 1) * [1,1]

   res = float(resolution > 1.E-4) * [1,1]

   ;; Adjust resolution or dimensions to fit within screen dimensions

   case units of
      0: begin
         dim = dim / (max(dim/sdim) > 1)
      end
      1: begin
         pdim = 2.54*dim/res
         res = res * (max(pdim/sdim) > 1)
      end
      2: begin
         pdim = dim/res
         res = res * (max(pdim/sdim) > 1)
      end
   endcase

   ;; If applicable, adjust number of pixels to be a multiple of
   ;; specified value

   if max(mul) gt 1 then begin

      case units of
         0: begin
            dim = mul * floor(dim/mul)
         end
         1: begin
            pdim = 2.54*dim/res
            pdim = mul * floor(pdim/mul)
            dim = (pdim*res) / 2.54
         end
         2: begin
            pdim = dim/res
            pdim = mul * floor(pdim/mul)
            dim = pdim*res
         end
      endcase

   endif

   ;; Create and return the object.

   return, obj_new(class, UNITS=units, DIMENSIONS=dim, RESOLUTION=res, $
                   _STRICT_EXTRA=extra)

end
