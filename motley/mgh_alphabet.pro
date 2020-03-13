;+
; NAME:
;   MGH_ALPHABET
;
; DESCRIPTION:
;    Return the 26 letters of the ISO basic Latin alphabet (which is a fancy
;    name for the English alphabet
;
; CALLING SEQUENCE:
;    result = mgh_alphabet(UPPERCASE=uppercase)
;
; POSITiONAL PARAMETERS:
;   None
;
; KEYWORD PARAMETERS:
;    UPPERCASE (input, switch)
;      Return upper case letters instead of the default lowr case.
;
; RETURN VALUE:
;    A 26-element string vector
;
;###########################################################################
; Copyright (c) 2020 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2020-03:
;      Written.
;-
function mgh_alphabet, UPPERCASE=uppercase

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Retain generality so this could potentially be adapted for
   ;; other sequences of ASCII characters.

   n_result = 26

   result = strarr(n_result)

   start = byte(keyword_set(uppercase) ? 'A' : 'a')

   ;; This could be vectorised, but it is surprisingly awkward
   ;; to do so. Note that the loop counter must be a byte integer.

   for b=0B,n_result-1 do result[b] = string(start[0]+b)

   return, result

end
