; svn $Id$
;+
; NAME:
;   MGH_TV_MAP_PATCH
;
; PURPOSE:
;   This function combines calls to MAP_PATCH & TV to avoid problems
;   with passing information between the two routines in an
;   MGH_DGwindow object.
;
; CALLING SEQUENCE:
;   MGH_TV_MAP_PATCH, image, lon, lat
;
; POSITIONAL PARAMETERS
;   image (input, 1- or 2-dimensional array)
;     Data to be overlaid on a map.
;
;   lon, lat (input, optional, 1- or 2-dimensional array)
;     Longitude and latitude data. See MAP_PATCH documentation.
;
; KEYWORD PARAMETERS
;   TV_KEYWORDS
;     Set this keyword to a structure wrapping any keywords that are
;     to passed to the TV routine.
;
;   All other keywords are passed to MAP_PATCH.
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
;   Mark Hadfield, 2001-11:
;     Written.
;   Mark Hadfield, 2002-12:
;     Upgraded to IDL 5.6.
;-

pro MGH_TV_MAP_PATCH, data, lon, lat, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, MISSING=missing, $
     PALETTE=palette, SCALE=scale, TV_PROPERTIES=tv_properties, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   warped_data = map_patch(data, lon, lat, $
                           XSIZE=xsize, XSTART=xstart, YSIZE=ysize, YSTART=ystart, $
                           _STRICT_EXTRA=extra)

   void = check_math(MASK=128)

   if keyword_set(scale) then begin
      warped_data = mgh_bytscl(warped_data, BYTE_RANGE=byte_range, $
                               DATA_RANGE=data_range, MISSING=missing)
   endif

   mgh_tv, warped_data, xstart, ystart, $
           /DEVICE, XSIZE=xsize, YSIZE=ysize, PALETTE=palette, $
           _STRICT_EXTRA=tv_properties

end
