;+
; NAME:
;   MGH_STRUCT_EQUYAL
;
; PURPOSE:
;   Test whether two structure are equal
;
; CALLING SEQUENCE:
;   result = mgh_struct_equal(struct0, struct1)
;
; RETURN VALUE:
;   The structure returns a logical value.
;
; POSITIONAL ARGUMENTS:
;   struct0 (input, structure)
;     First structure for comparison
;
;   struct1 (input, structure)
;     Second structure for comparison
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
function mgh_struct_equal, struct0, struct1

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(struct0) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct0'
    
  if size(struct0, /TYPE) ne 8 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct0'
     
   if n_elements(struct1) eq 0 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'struct1'
     
   if size(struct1, /TYPE) ne 8 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'struct1'
     
   ;; For now, just form a hash from each structure and test equality
   
   return, mgh_struct_hash(struct0) eq mgh_struct_hash(struct1) 
     
end
