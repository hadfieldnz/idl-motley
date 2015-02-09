;+
; CLASS NAME:
;   MGH_List
;
; PURPOSE:
;   A wrapper for the List object
;-
pro MGH_List__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_List, inherits List}

end

