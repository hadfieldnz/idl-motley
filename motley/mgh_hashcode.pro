;+
; NAME:
;   MGH_HASHCODE
;
; PURPOSE:
;   Returns
;
; CALLING SEQUENCE:
;   result = mgh_hashcode(val)
;
; RETURN VALUE:
;   The function returns the hashcode of the argument using the
;   hashcode static method for variables.
;
; POSITIONAL ARGUMENTS:
;   var (input, of IDL_Variable or STRUCT type)
;     The value for which the hash value is to be calculated.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-02:
;     Written.
;-
function mgh_hashcode, val

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if isa(val, 'IDL_Undefined') then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'val'

   case 1B of
      isa(val, 'STRUCT'): begin
         result = long64(mgh_hashcode(tag_names(val)))
         for i=0,n_tags(val)-1 do begin
            result += mgh_hashcode(val.(i))
         endfor
      end
      isa(val, 'Pointer'): begin
         ;; Pointer variables come under the IDL_Variable type. By
         ;; treating this case first, we can ensure that the hash
         ;; code of the associated heap variable is returned.
         result = long64(mgh_hashcode(*val))
      end
      isa(val, 'IDL_Variable'): begin
         result = long64(val.hashcode())
      end
   endcase

   return, result

end
