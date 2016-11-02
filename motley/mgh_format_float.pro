;+
; NAME:
;   MGH_FORMAT_FLOAT
;
; PURPOSE:
;   This function returns a string representation of a floating-point
;   numeric value. It is designed for use in widget applications,
;   where one wants an editable value, with no extraneous digits, that
;   can be converted easily back to numeric form.
;
; CALLING SEQUENCE:
;   Result = MGH_FORMAT_FLOAT(Value)
;
; POSITIONAL PARAMETERS:
;   Value (input, numeric, scalar or array)
;     The value to be formatted.
;
; RETURN VALUE:
;   The function returns a string with the same shape as the input.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-05:
;       Written.
;   Mark Hadfield, 2013-08:
;       Minor updates.
;-
function mgh_format_float, value, FORMAT=format

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default formats for free format output are listed in the IDL 6.0
   ;; documentation under "Programming in IDL: Basics of IDL
   ;; Programming: Files and Input/Output: Using Free Format
   ;; Input/Output"

   if n_elements(format) eq 0 then $
        format = size(value, /TYPE) eq 5 ? '(G16.8)' : '(G13.6)'

   ;; Start with the default representation, with leading & trailing blanks
   ;; removed.

   result = strtrim(string(value, FORMAT=format),2)

   ;; We may encounter tricky platform-dependent differences in case
   ;; etc, so let's take a general approach, i.e. use STRSPLIT, with
   ;; its REGEX capabilities, in a loop.

   for i=0,n_elements(result)-1 do begin

      ;; Split at exponent identifier, if any.

      s = strsplit(result[i], '[de]', /EXTRACT, /REGEX, /FOLD_CASE)

      ;; The first part is assumed to be of the form nnnn.nnnn

      s0 = strsplit(s[0], '.', /EXTRACT)

      case n_elements(s0) of
         1:
         2: begin
            ss = s0[1]
            ;; Look for trailing "0"s. Strip them off, leaving
            ;; one if it is the first character to the right of
            ;; the decimal place.
            pp = stregex(ss, '0+$')
            if pp ge 0 then ss = strmid(ss, 0, (pp > 1))
            s0[1] = ss
         end
         else: message, 'Too many substrings in numeric portion'
      endcase

      s[0] = strjoin(s0, '.')

      ;; Reassemble the numeric and exponent parts

      result[i] = strjoin(s, 'E')

   endfor

   return, result

end

