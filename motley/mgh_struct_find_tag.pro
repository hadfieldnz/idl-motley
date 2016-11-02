;+
; NAME:
;   MGH_STRUCT_FIND_TAG
;
; PURPOSE:
;   This function finds tags in a structure by name
;
; CALLING SEQUENCE:
;   Result = MGH_STRUCT_FIND_TAG(struct, tags)
;
; POSITIONAL PARAMETERS:
;   struct (input, scalar structure)
;     Structure in which tags are to be located.
;
;   tags (input, string)
;     A list of tag names
;
; RETURN VALUE:
;   The function returns an integer of the same shape as the "tags"
;   input parameter giving the location of each tag in the
;   structure. Unmatched tags are indicated by the value -1.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2003-04:
;     Written.
;   Mark Hadfield, 2005-11:
;     Updated.
;-
function mgh_struct_find_tag, struct, tags

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Check arguments

   if n_elements(struct) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct'

   if size(struct, /TYPE) ne 8 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct'

   if n_elements(tags) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'tags'

   ;; Result has same shape as tags argument

   result = mgh_reproduce(-1, tags)

   ;; Get list of tag names

   names = tag_names(struct)

   for f=0,n_elements(tags)-1 do begin

      index = where(strmatch(names, tags[f], /FOLD_CASE), n_index)

      if n_index gt 0 then result[f] = index[0]

   endfor

   return, result

end
