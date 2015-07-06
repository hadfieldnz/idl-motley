;+
; NAME:
;   MGH_OBJ_LIST
;
; PURPOSE:
;   Search the heap for and return a list of all objects matching one
;   or more classes.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2010-10:
;     Written.
;   Mark Hadfield, 2011-06:
;     The matching objects are now collected in an MGH_Vector
;     object. The List object previously used did not seem to support
;     the ToArray method on object references.
;-
function mgh_obj_list, class, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Get an array of object references *before* we create the output
   ;; list.

   obj = obj_valid()

   ;; Create a list object and add all objects of the specified
   ;; class[es] to it.

   olist = mgh_vector()

   foreach c, class do olist.Add, obj[where(obj_isa(obj, c), /NULL)]

   ;; Return reslts

   count = olist.Count()

   return, count gt 0 ? olist.ToArray(/FLATTEN, /NO_COPY) : obj_new()

end


