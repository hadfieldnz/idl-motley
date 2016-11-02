;+
; NAME:
;   MGH_STRUCT_EVAL
;
; PURPOSE:
;   Return data for a named tag in a structure
;
; CALLING SEQUENCE:
;   result = mgh_struct_eval(struct, tag)
;
; POSITIONAL PARAMETERS:
;   struct (input, structure scalar)
;     The input structure.
;
;   tag (input, string scalar)
;     The name of a tag in the input structure. An error is raised if
;     the tag is not found.
;
; RETURN VALUE:
;   The function returns the data associated with the tag. So
;
;     result = mgh_eval(my_struct, 'foo')
;
;   is equivalent to
;
;     result = my_struct.foo
;
;###########################################################################
; Copyright (c) 2010 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2010-05:
;     Written.
;-
function mgh_struct_eval, struct, tag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Check arguments

   if n_elements(struct) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct'

   if size(struct, /TYPE) ne 8 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct'

   if n_elements(tag) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'tag'

   if n_elements(tag) gt 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'tag'

   loc = mgh_struct_find_tag(struct, tag)

   if loc lt 0 then message, 'Tag not found: '+tag

   return, struct.(loc)

end
