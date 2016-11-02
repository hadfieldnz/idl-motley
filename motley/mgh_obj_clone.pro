;+
; NAME:
;   MGH_OBJ_CLONE
;
; PURPOSE:
;   Given a reference to an object heap variable, this function
;   generates a copy and returns a reference to it.
;
; CALLING SEQUENCE:
;   result = MGH_OBJ_CLONE(object)
;
; POSITIONAL PARAMETERS:
;   object (input, scalar object reference):
;     Object to be copied.
;
; KEYWOED PARAMETERS:
;   VERBOSE (input, switch):
;     Control informational output.
;
; RESTRICTIONS:
;   There are situations where cloning objects is unsuccessful because
;   it leads to duplicate objects, dangling references, or
;   inconsistencies between (say) a child's information about its
;   parent and the parent's information about its children.
;
;###########################################################################
; Copyright (c) 1998-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, Feb 1998:
;     Written as OBJ_CLONE.
;   Mark Hadfield, Sep 1998:
;     Renamed MGH_OBJ_CLONE.
;   Mark Hadfield, Aug 2000:
;     Updated for IDL 5.4.
;-
function mgh_obj_clone, Object, VERBOSE=verbose

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(object) then return, obj_new()

   file = filepath(cmunique_id()+'.idl_object', /TMP)

   if keyword_set(verbose) then $
        message, /INFORMATIONAL, 'Saving object to file '+file

   clone = object

   save, clone, FILE=file

   restore, FILE=file

   if keyword_set(verbose) then $
        message, /INFORMATIONAL, 'Deleting file '+file

   file_delete, file

   return, clone

end


