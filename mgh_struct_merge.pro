;+
; NAME:
;   MGH_STRUCT_MERGE
;
; PURPOSE:
;   This function merges two anonymous structures.
;
; CALLING SEQUENCE:
;   Result = MGH_STRUCT_MERGE(struct0, struct0)
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
;   Mark Hadfield, 2002-06:
;     Written.
;-
function mgh_struct_merge, struct0, struct1

   compile_opt DEFINT32
   compile_opt STRICTARR

   ;; Check arguments

   if n_elements(struct0) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct0'

   if size(struct0, /TYPE) ne 8 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct0'

   if size(struct1, /TYPE) ne 8 then $
        return, struct0

   ;; Represent the merged structures as a pair of arrays, a string
   ;; array holding tag names and a pointer array holding values. This
   ;; will be rebuilt into a structure below using MGH_STRUCT_BUILD.

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
