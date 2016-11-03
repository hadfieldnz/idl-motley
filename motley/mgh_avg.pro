;+
; NAME:
;   MGH_AVG
;
; PURPOSE:
;   This function returns the average value of an array over the specified
;   dimension, optionally ignoring missing data.
;
;###########################################################################
; Copyright (c) 2009 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; CALLING SEQUENCE:
;   result = mgh_avg(array[, dimension ])
;
; POSITIONAL ARGUMENTS:
;   array (input)
;     Input array.  May be any numeric type.
;
;   dimension (input)
;     Dimension over which to average (same definition as TOTAL).
;     Must be scalar. Dimensions are numbered from 1.
;
; KEYWORD PARAMETERS:
;   DOUBLE (input, switch)
;     If set, return a double-precision result. Default is to return a
;     double-precision result for double-precision data and a
;     single-precision result for other data types.
;
;   NAN (input, switch)
;      Set this keyword to specify that NaN values should be treated
;      as missing.
;
;   NEEDED (input, integer)
;      Number of good values required to form an average. Default is 1.
;
; RETURN VALUE:
;   The function returns an array or scalar containing the averages.
;
; RESTRICTIONS:
;   The dimension specified must be valid for the array passed.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1993-12:
;     Created, inspired by IDL Astronomy Library routine AVG.
;   Mark Hadfield, 1995-07:
;     Modified for IDL 4.0: missing data may now be indicated by IEEE
;     NaN or Infinity values. MISSING keyword has been deleted and NAN
;     keyword added.
;   Mark Hadfield, 2005-09:
;     Modified code that calculates the number of elements in the
;     specified dimension to reduce memory requirement.
;   Mark Hadfield, 2009-10:
;     Fix bug: was not returning a double-precision result for
;     double-precision data.
;-
function MGH_AVG, Arr, Dimension, NAN=nan, NEEDED=needed, DOUBLE=double

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   if n_elements(arr) eq 0 then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_UNDEFVAR', 'ARR'

   ndim = size(arr, /N_DIMENSIONS)

   ;; If the dimension argument exceeds the number of dimensions in the
   ;; input, then return the input unaltered. This allowed to handle
   ;; IDL's mania for stripping trailing dimensions

   if n_elements(dimension) gt 0 && dimension gt ndim then return, Arr

   if n_elements(nan) eq 0 then nan = !false

   if n_elements(needed) eq 0 then needed = 1

   if n_elements(double) eq 0 then $
        double = size(0D, /TYPE) eq 5 || size(0D, /TYPE) eq 9

   ;; Calculate number of elements (n) and sum of elements (s) over
   ;; specified dimension.

   case n_elements(dimension) gt 0 of

      0: begin
         n = keyword_set(nan) ? total(finite(Arr)) : n_elements(Arr)
         s  = total(Arr, DOUBLE=double, NAN=nan)
      end

      1: begin
         n = keyword_set(nan) $
             ? total(finite(Arr), Dimension) $
             : (size(arr, /DIMENSIONS))[dimension-1]
         s  = total(Arr, Dimension, DOUBLE=double, NAN=nan)
      end
   endcase

   ;; Clear "illegal operation" error messages.
   if keyword_set(nan) then void = check_math()

   ;; Construct an array for output (with the same data type as sums)
   ;; and fill with missing values. Then, where sufficient good values
   ;; exist, evaluate the average.

   if keyword_set(nan) then begin
      result = s
      result[*] = !values.f_nan
      enuf = where (n ge needed, n_enuf)
      if n_enuf gt 0 then result[enuf] = s[enuf]/n[enuf]
      return, result
   endif else begin
      return, s/n
   endelse

end
