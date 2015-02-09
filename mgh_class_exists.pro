; svn $Id$
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
