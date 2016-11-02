;+
; NAME:
;   MGH_STRUCT_PRINT
;
; PURPOSE:
;   This procedure prints structure tag names and values.
;
; CALLING SEQUENCE:
;   MGH_STRUCT_PRINT, struct
;
; POSITIONAL PARAMETERS:
;   struct (input, structure)
;     The structure to be printed
;
; KEYWORD PARAMETERS:
;   UNIT (input, integer)
;     Logical unit number to which output is to be printed. Default is -1.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-06:
;     Written.
;-
pro mgh_struct_print, struct, UNIT=unit

   compile_opt DEFINT32
   compile_opt STRICTARR

   if size(struct, /TYPE) ne 8 then message, 'Argument is not a structure'

   if n_elements(unit) eq 0 then unit = -1

   tags = tag_names(struct)

   for i=0,n_elements(tags)-1 do $
        printf, unit,'  ',strlowcase(tags[i]),': ', struct.(i)

end
