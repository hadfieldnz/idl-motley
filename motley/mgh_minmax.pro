;+
; NAME:
;   MGH_MINMAX
;
; PURPOSE:
;   This function returns a 2 element vector containing both the
;   minimum and maximum of an array.
;
; CALLING SEQUENCE:
;   result = mgh_minmax(array)
;
; POSITIONAL PARAMETERS:
;   array (input, numeric, scalar or array)
;     Data for which max & min are required.
;
; RETURN VALUE:
;   The function returns a two-element vector equal to
;   [min(arr),max(arr)]
;
; KEYWORD PARAMETERS:
;   ABSOLUTE (input, switch)
;     Set this keyword to cause the routine to use the absolute value
;     of each element in determining the minimum and maximum
;     values.This keyword has no effect for arrays of type byte or
;     unsigned integer.
;
;   NAN (input, switch)
;     Set this keyword to cause the routine to check for occurrences
;     of the IEEE floating-point value NaN in the input data.
;     Elements with the value NaN are treated as missing data.
;
;   SUBSCRIPT (output, 2-element integer)
;     This keyword returns the one-dimensional subscripts of the minimum
;     and maximum elements, bundled as a 2-element integer vector.
;
; PROCEDURE:
;   The MIN function is used with the MAX keyword
;
; EXPLANATION:
;   The function is defined for convenience and performance. A single
;   call to MGH_MINMAX is faster than separate calls to MAX and MIN.
;
;###########################################################################
; Copyright (c) 1999-2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-11:
;     Written based on the MINMAX routine in the IDL Astronomy Library.
;   Mark Hadfield, 2003-06:
;     Added SUBSCRIPT keyword
;   Mark Hadfield, 2007-02:
;     Added ABSOLUTE keyword, to support the MIN/MAX keyword of the
;     same name introduced in IDL 6.1.
;-
function mgh_minmax, array, $
     ABSOLUTE=absolute, NAN=nan, SUBSCRIPT=subscript

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   amin = min(array, subscript_min, ABSOLUTE=absolute, MAX=amax, NAN=nan, $
              SUBSCRIPT_MAX=subscript_max)

   subscript = [subscript_min, subscript_max]

   return, [amin, amax]

end

