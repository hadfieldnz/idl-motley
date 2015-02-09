; svn $Id$
;+
; NAME:
;   MGH_NULL
;
; PURPOSE:
;   This function defines a null value for each IDL data type.
;
; CALLING SEQUENCE:
;   result = MGH_NULL(template)
;   result = MGH_NULL(TYPE=type)
;
; POSITIONAL PARAMETERS:
;   template (input, any type & size)
;     If this argument is present, then the null value assumes its type.
;
; KEYWORD PARAMETERS:
;   TYPE (input, numeric scalar)
;     This keyword is used to specify the null value's type via IDL's
;     type specifiers.
;
; RETURN VALUE:
;   The function returns a scalar null value.
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
;   Mark Hadfield, 1997-05:
;     Written.
;   Mark Hadfield, 1999-12:
;     Modified for IDL 5.3 constants.
;-

function MGH_NULL, template, TYPE=ktype

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ttype = size(template, /TYPE)

   if (ttype eq 0) && (n_elements(ktype) gt 0) then ttype = ktype

   case ttype of

      1: return, 255B           ; Byte
      2: return, -32767S        ; 16-bit integer
      3: return, -2147483647L   ; 32-bit integer
      4: return, !values.f_nan  ; Single-precision floating
      5: return, !values.d_nan  ; Double-precision floating
      7: return, ''             ; String
      10: return, ptr_new()     ; Pointer
      11: return, obj_new()     ; Object
      13: return, 4294967295U   ; 32-bit unsigned integer
      14: return, -9223372036854775808LL ; 64-bit integer
      15: return, 18446744073709551615ULL ; 64-bit unsigned integer

      else: message,'A null value has not been defined for this data type'

   endcase

end
