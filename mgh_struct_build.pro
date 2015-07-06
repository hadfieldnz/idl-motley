;+
; NAME:
;   MGH_STRUCT_BUILD
;
; PURPOSE:
;   This function builds an anonymous structure, given a list of tag names
;   and a list of pointers to data values.
;
; CALLING SEQUENCE:
;   result = MGH_STRUCT_BUILD(tags, values, POINTER=pointer)
;
; POSITIONAL PARAMETERS:
;   tags (input, string array)
;     List of tag names
;
;   values (input, pointer array)
;     A list of values wrapped in pointers. Must have the same number
;     of elements as the tags array.
;
; KEYWORD PARAMETERS:
;   POINTER (input, switch)
;     Determines whether the output structure includes the data values
;     or pointers to them.
;
; PROCEDURE:
;   A command to create the structure is constructed and processed by
;   EXECUTE. To avoid "Program code area full" failures a limit is
;   placed on the number of tags created at one time; if this limit is
;   exceeded the structure is built up in a series of steps.
;
;###########################################################################
; Copyright (c) 2000-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-11:
;     Written.
;   Mark Hadfield, 2005-09:
;     Added POINTER keyword.
;   Mark Hadfield, 2010-10:
;     The result is now initialised with a !NULL, allowing simplification
;     of the code.
;   Mark Hadfield, 2013-05:
;     Tags now processed with MGH_STR_VANILLA before building structure. If a
;     tag is not a valid identifier, then an error is raised.
;-
function mgh_struct_build, tags, values, POINTER=pointer

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Specify the maximum number of tags to be concatenated at one
   ;; time.  On my system (x86 Win32 Windows 5.4 Sep 25 2000) n_max
   ;; can be as large as 306.  Performance will be affected if n_max
   ;; is made too small but above 200 or so it makes little
   ;; difference.

   n_max = 200

   n_tags = n_elements(tags)

   if n_tags eq 0 then $
        message, 'Number of tags is zero'

   if n_elements(values) ne n_tags then $
        message, 'Number of values does not match number of tags'

   n0 = 0

   result = !null

   while n0 lt n_tags do begin

      n1 = (n0 + n_max - 1) < (n_tags - 1)

      cmd = 'result=create_struct(result,{'

      m = 0B
      for i=n0,n1 do begin
         tag = mgh_str_vanilla(tags[i])
         if strlen(tag) eq 0 then continue
         if ~ mgh_str_isidentifier(tag) then $
              message, 'Invalid identifier'
         if ~ ptr_valid(values[i]) then $
              message, 'Invalid pointer'
         if m then cmd += ','
         cmd += tag+':'
         if ~ keyword_set(pointer) then cmd += '*'
         cmd += 'values['+strtrim(i,2)+']'
         m = 1B
      endfor

      cmd = cmd+'})'

      if ~ execute(cmd) then message, 'Command failed'

      n0 = n1 + 1

   endwhile

   return, result

end
