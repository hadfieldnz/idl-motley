;+
; NAME:
;   MGH_STRUCT_HAS_TAG
;
; PURPOSE:
;   Determines whether a variable is a structure OR a dictionary containing the
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
;   This function returns !true if the variable is a structure or a
;   dictionary containing the tag, otherwise !false.
;   
;   Dictionary support was added to support migration from the structure
;   to the dictionary data type.
;
;###########################################################################
; Copyright (c) 1993-2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1993-10:
;     Written.
;   Mark Hadfield, 1998-05:
;     Added COUNT keyword.
;   Mark Hadfield, 2016-03:
;     - Updated.
;     - Added support for dictionaries.
;-
function mgh_struct_has_tag, var, tagname, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   
   case !true of
      isa(var, 'struct'): begin
         !null = where(strmatch('.'+tag_names(Var)+'.', '.'+Tagname+'.', /FOLD_CASE), count)
         return, boolean(count gt 0)
      end
      isa(var, 'dictionary'): begin
         result = var.HasKey(tagname)
         count = result ? 1 : 0
         return, boolean(result)
      end
      else: begin
         count = 0
         return, !false
      end
   endcase

end

