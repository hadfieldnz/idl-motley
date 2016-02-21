;+
; NAME:
;   MGH_STRUCT_HASH
;
; PURPOSE:
;   For a specified structure, calculate and return an integer hash value:
;
;     http://en.wikipedia.org/wiki/Hash_function
;
; CALLING SEQUENCE:
;   result = mgh_struct_hash(struct)
;
; RETURN VALUE:
;   The structure returns a long-64 integer value that depends on the
;   structure tag names and tag values.
;
; POSITIONAL ARGUMENTS:
;   struct (input, structure)
;     The structure for which the hash value is to be calculated/
;
; DEPENDENCIES:
;   Requires CHECKSUM32 from the IDL Astronomy Library.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2013-06:
;     Written.
;-
function mgh_struct_hash, struct

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt OBSOLETE

   if n_elements(struct) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct'

   if size(struct, /TYPE) ne 8 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct'

   result = long64(mgh_hashcode(tag_names(struct)))

   for i=0,n_tags(struct)-1 do begin
      s = struct.(i)
      result += isa(s, 'STRUCT') ?  mgh_struct_hash(s) : mgh_hashcode(s)
   endfor

   return, result

end
