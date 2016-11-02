;+
; ROUTINE NAME:
;   MGH_CLASS_EXISTS
;
; PURPOSE:
;   Determine whether the given name represents a class in IDL
;   (actually tests whether structures of that name are automatically
;   created or have already been created
;
; CALLING SEQUENCE:
;   result = mgh_class_exists(name)
;
; POSITIONAL PARAMETERS:
;   naem (input, string scalar)
;     The name to be tested.
;
; RETURN VALUE:
;   The function returns a logical value (byte scalar) indicating
;   whether the class exists.
;
;###########################################################################
; Copyright (c) 2011-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2011-05:
;     Written.
;-
function mgh_class_exists, name

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(name) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'name'

  catch, status
  if status ne 0 then goto, caught_err_resolve

  !null = create_struct(NAME=name)

  caught_err_resolve:
    catch, /CANCEL

  return, status eq 0

end
