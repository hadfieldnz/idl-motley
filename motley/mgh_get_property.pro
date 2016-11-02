; svn $Id$
;+
; NAME:
;   MGH_GET_PROPERTY
;
; PURPOSE:
;   A user-friendly wrapper for an object's GetProperty method. This routine
;   has function and procedure forms. It therefore needs to be compiled before
;   use using .COMPILE ... or RESOLVE_ROUTINE, /COMPILE_FULL_FILE, ....
;
; CALLING SEQUENCE:
;   MGH_GET_PROPERTY, object, PROP1=prop1, PROP2=prop2, ...)
;
;   result = MGH_GET_PROPERTY(object, /PROP)
;
; INPUTS:
;   object (input, object reference, scalar)
;      Object to be queried.
;
; KEYWORDS:
;   Both the procedure and the function accept any keywords that are
;   accepted by the object's GetProperty method. The procedure returns
;   the values via the keywords, just like GetProperty. The function
;   requires that only one keyword be set and it returns the
;   corresponding property via the function's return value.
;
; EXAMPLE:
;   IDL> resolve_routine, 'mgh_get_property',  /COMPILE_FULL_FILE
;   IDL> obuff = obj_new('IDLgrBuffer')
;   IDL> mgh_get_property, obuff, DIMENSIONS=dim & print, dim
;      640.000      480.000
;   IDL> print, mgh_get_property(obuff, /DIMENSIONS)
;      640.000      480.000
;   IDL> obj_destroy, obuff
;
; TO DO:
;   Allow multiple keywords to the function form.
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
;   Mark Hadfield, 2001-11:
;     Written
;   Mark Hadfield, 2004-05:
;     This routine now deprecated for 2 reasons: the function form requires
;     EXECUTE, which I am trying to avoid; the procedure form has never been
;     useful.
;-
function MGH_GET_PROPERTY, object, _EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_tags(extra) ne 1 then $
        message, 'This function requires a single keyword to be set'

   if ~ keyword_set(extra.(0)) then $
        message, 'This function requires a single keyword to be set'

   property = (tag_names(extra))[0]

   ;; Don't bother testing EXECUTE's return value, just let errors be
   ;; handled as if GetProperty were called directly

   ok = execute('object->GetProperty, '+property+'=result')

   return, result

end

pro MGH_GET_PROPERTY, object, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   object->GetProperty, _STRICT_EXTRA=extra

end



