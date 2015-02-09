; svn $Id$
;+
; NAME:
;   MGH_STRUCT_HAS_TAG
;
; PURPOSE:
;   Determines whether a variable is a structure containing the
;   specified tag.
;
; CATEGORY:
;   Structures.
;
; CALLING SEQUENCE:
;   Result = MGH_STRUCT_HAS_TAG(var,tagname)
;
; POSITIONAL PARAMETERS:
;   var (input, scalar)
;     The variable to be searched.
;
;   tagname (input, scalar string)
;     Name of the tag to search for. (The function is
;     case-insensitive.)
;
; KEYWORD PARAMETERS:
;   COUNT (output, scalar integer)
;     This keyword returns the total number of occurrences of the
;     tag. (Its value can be more than 1 in some circumstances.)
;
; RETURN VALUE:
;   This function returns 1 if the variable is a structure containing
;   the tag, otherwise 0.
;
; PROCEDURE:
;   Use TAG_NAMES to produce a list of tag names and search for the
;   one we want.
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
;   Mark Hadfield, 1993-10:
;     Written.
;   Mark Hadfield, 1998-05:
;     Added COUNT keyword.
;-

function MGH_STRUCT_HAS_TAG, Var, Tagname, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR

   if size(Var, /TYPE) ne 8 then begin
      count = 0
      return, 0B
   endif

   void = where(strmatch('.'+tag_names(Var)+'.', '.'+Tagname+'.', /FOLD_CASE), count)

   return, count gt 0

end

