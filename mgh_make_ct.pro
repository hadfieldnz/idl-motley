;+
; NAME:
;   MGH_MAKE_CT
;
; PURPOSE:
;   This function constructs a colour table by linear interpolation between
;   a set of specified control points
;
; CATEGORY:
;   Graphics
;   Color Specification.
;
; CALLING SEQUENCE:
;   Result = MGH_MAKE_CT(Indices, Colors)
;
; POSITIONAL PARAMETERS:
;   indices (input, numeric vector)
;     A vector, dimensioned [n[ where n >= 2, containing a list of
;     control point indices. Elements must be monotonically increasing
;     and in the range [0,255].
;
;   colors (input, numeric array or string vector)
;     A list of control-point colors. If numeric, it must be
;     dimensioned [3,n]. If of string type, it must be dimensioned [n]
;     and is converted to numeric rgb form by the MGH_COLORS function.
;
; KEYWORD PARAMETERS:
;   NAME (input, scalar string)
;     A string to be used as the name of the color table. Default ''.
;
; RETURN VALUE:
;   The function returns a colour table in the form of an anonymous
;   structure with tags NAME (string), N_COLORS (integer), RED (byte
;   array), GREEN (ditto) and BLUE (ditto). N_COLORS is equal to one
;   plus the final value in the list of indices.
;
;###########################################################################
; Copyright (c) 1999-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-08:
;     Written.
;   Mark Hadfield, 2001-10:
;     Updated to IDL2 syntax.
;   Mark Hadfield, 2012-12:
;     Surther updates.
;-
function mgh_make_ct, indices, colors, NAME=name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(name) eq 0 then name = ''

   ncp = n_elements(indices)

   if ncp lt 2 then $
        message, 'The number of control point indices must >=2'

   if ceil(indices[0]) ne 0 then $
        message, 'The first control point index must be zero'

   case size(colors, /TYPE) of

      7: begin
         if n_elements(colors) ne ncp then $
              message, 'The colors array, if a string, must be dimensioned [n]'
         col = mgh_color(colors)
      end

      else: begin
         cdims = size(Colors, /DIMENSIONS)
         if n_elements(cdims) ne 2 then $
              message, 'The colors array, if numeric, must be dimensioned [3,n]'
         if cdims[0] ne 3 or cdims[1] ne ncp then $
              message, 'The colors array, if numeric, must be dimensioned [3,n]'
         col = colors
      endelse

   endcase


   ncol = fix(indices[ncp-1]) + 1S

   result = {name: name, n_colors:ncol, $
             red: bytarr(ncol), green: bytarr(ncol), blue: bytarr(ncol) }

   for j=0,ncp-2 do begin

      ;; Position of control points; enforce floating point to allow
      ;; floating arithmetic on colours
      r0 = float(indices[j])
      r1 = float(indices[j+1])

      ;; Colors at control points; ditto
      c0 = float(col[*,j])
      c1 = float(col[*,j+1])

      ;; Identify indices between the control points
      i0 = ceil(indices[j])
      i1 = floor(indices[j+1])
      ii = i0 + indgen(i1-i0+1)

      ;; Interpolate with floating arithmetic then convert to byte
      result.red[ii]   = 0 > round(c0[0]+(ii-r0)*(c1[0]-c0[0])/(r1-r0)) < 255
      result.green[ii] = 0 > round(c0[1]+(ii-r0)*(c1[1]-c0[1])/(r1-r0)) < 255
      result.blue[ii]  = 0 > round(c0[2]+(ii-r0)*(c1[2]-c0[2])/(r1-r0)) < 255

   endfor

   return, result

end

