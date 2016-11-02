; svn $Id$
;+
; NAME:
;   MGH_N_BYTES
;
; PURPOSE:
;   Return the total number of bytes in data element
;
; CALLING SEQUENCE:
;       result = mgh_mgh_n_bytes(a)
;
; POSITIONAL PARAMETERS:
;   a (input, numeric or string, scalar or array)
;     Data element whose size in bytes is to be returned.
;
; KEYWORD PARAMETERS:
;   LONG64 (input, switch)
;     If set, return result as 64-bit integer. Default is long integer.
;
; RETURN VALUE:
;   The total number of bytes in a is returned as an integer scalar.
;
; NOTES:
;   - For a string array, the number of bytes is computed after conversion
;     with the BYTE() function, i.e. each element has the same length,
;     equal to the maximum individual string length.
;
; MODIFICATION HISTORY:
;   Written, based on N_BYTES in the IDL Astronomy Library. The
;   motivation was that the return type was changed from a 32-bit
;   integer to a 64-bit integer, breaking most of the code i used it
;   in.
;-
function mgh_n_bytes, a

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   dtype = size(a,/type)                  ;;; data type

   if dtype EQ 0 then return, 0           ;;; undefined

   nel = n_elements(a)

   if keyword_set(long64) then nel = long64(nel)
   case dtype of
      1: nb = 1                            ;;; Byte
      2: nb = 2                            ;;; Integer*2
      3: nb = 4                            ;;; Integer*4
      4: nb = 4                            ;;; Real*4
      5: nb = 8                            ;;; Real*8
      6: nb = 8                            ;;; Complex
      7: nb = max(strlen(a))               ;;; String
      8: nb = n_tags(a, /LENGTH)           ;;; Structure
      9: nb = 16                           ;;; Double Complex
      12: nb = 2                           ;;; Unsigned Integer*2
      13: nb = 4                           ;;; Unsigned Integer*4
      14: nb = 8                           ;;; 64 bit integer
      15: nb = 8                           ;;; Unsigned 64 bit integer
      else: message,'ERROR - Object or Pointer data types not valid'
   endcase

   return, nel*nb

end
