; svn $Id$
;+
; NAME:
;   Class MGH_Debug
;
; PURPOSE:
;   This class provides the ability to examine the fields in
;   an object's class structure
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
;   Mark Hadfield, 2003-10:
;     Written.
;   Mark Hadfield, 2004-05:
;     Call to EXECUTE function removed from Method DebugList; now using
;     CREATE_sTRUCT's NAME keyword instead.
;-

function MGH_Debug::DebugList

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   void = create_struct(NAME=obj_class(self))

   return, tag_names(void)

end

function MGH_Debug::DebugGet, field

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   tags = self->DebugList()

   index = where(strmatch(tags, field, /FOLD_CASE), count)

   if count eq 0 then message, 'Field not found'

   return, self.(index)

end

pro MGH_Debug__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Debug, mgh_debug_dummy_tag: 0B}

end

