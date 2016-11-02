;+
; NAME:
;   MGH_INTERPOLATE
;
; PURPOSE:
;   This function is a wrapper for the standard IDL INTERPOLATE
;   function. It corrects for the anomalous way INTERPOLATE
;   handles locations near the upper end of the input array, described
;   by the IDL documentation as follows:
;
;     Note - INTERPOLATE considers location points with values between
;     zero and n, where n is the number of values in the input array
;     P, to be valid. Location points outside this range are
;     considered missing data. Location points x in the range
;     n-1 <= x < n return the last data value in the array P.
;
;   Note the final sentence. It is much more logical to treat points
;   in the range  n-1 < x < n as missing, and this is what
;   MGH_INTERPOLATE does. Note also that the anomalous behaviour
;   described in the paragraph above is actually done only in the case
;   of linear interpolation, whereas bilinear interpolation acts in
;   the way I consider logical.
;
; CALLING SEQUENCE:
;   result = MGH_INTERPOLATE(p, x)
;   result = MGH_INTERPOLATE(p, x, y)
;   result = MGH_INTERPOLATE(p, x, y, z)
;
; PARAMETERS:
;   See documentation for INTERPOLATE.
;
; RETURN VALUE:
;   The function returns a single or double precision floating point
;   array with size & shape determined by the x, y & z parameters and
;   the GRID keyword.
;
;###########################################################################
; Copyright (c) 2002 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-06:
;     Written.
;-
function mgh_interpolate, p, x, y, z, $
     MISSING=missing, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of

      2: begin

         if n_elements(missing) gt 0 then begin

            outer = (size(p,/DIMENSIONS))[size(p,/N_DIMENSIONS)-1]
            xx = x
            ii = where(xx gt outer-1, n)
            if n gt 0 then xx[ii] = -1

            return, interpolate(p, xx, _STRICT_EXTRA=extra, MISSING=missing)

         endif else begin

            return, interpolate(p, x, _STRICT_EXTRA=extra)

         endelse

      end

      3: return, interpolate(p, x, y, _STRICT_EXTRA=extra, MISSING=missing)

      4: return, interpolate(p, x, y, z, _STRICT_EXTRA=extra, MISSING=missing)

   endcase

end


