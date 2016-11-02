;+
; NAME:
;   MGH_STRUCT_MERGE
;
; PURPOSE:
;   This function merges two anonymous structures.
;
; CALLING SEQUENCE:
;   result = mgh_struct_merge(struct0, struct1)
;
; POSITIONAL PARAMETERS:
;   struct0 (input, scalar structure)
;     First structure
;
;   struct1 (input, scalar structure, optional)
;     Second structure. Tags in this structure are appended to or
;     replace those in the first structure.
;
;###########################################################################
; Copyright (c) 2002-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-06:
;     Written.
;-
function mgh_struct_merge, struct0, struct1

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Check arguments

   if n_elements(struct0) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct0'

   if size(struct0, /TYPE) ne 8 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct0'

   if size(struct1, /TYPE) ne 8 then $
        return, struct0

   ;; Represent the merged structures as a pair of arrays, a string
   ;; array holding tag names and a pointer array holding values. The
   ;; arrays will be rebuilt into a structure below using MGH_STRUCT_BUILD.
   ;; I suspect this operation could be done much more simply these days
   ;; using dictionary objects.

   n0 = n_tags(struct0)
   n1 = n_tags(struct1)

   tags = [tag_names(struct0), tag_names(struct1)]

   values = ptrarr(n0+n1, /NOZERO)
   for i=0,n0-1 do values[i] = ptr_new(struct0.(i))
   for i=0,n1-1 do values[i+n0] = ptr_new(struct1.(i))

   ;; Duplicate tags must be omitted from the result. Tags in struct1
   ;; take precedence over those in struct0. A tag is omitted by
   ;; setting the corresponding string in the tags array to the empty
   ;; string; it is then skipped by MGH_STRUCT_BUILD.

   for i=0,n0-1 do begin
      if max(strmatch(tags[n0:n0+n1-1], tags[i], /FOLD_CASE)) gt 0 then tags[i] = ''
   endfor

   ;; Build result then clean up

   result = mgh_struct_build(tags, values)

   ptr_free, values

   return, result

end
