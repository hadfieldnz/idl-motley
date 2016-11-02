;+
; FUNCTION:
;   MGH_HAS_VIDEO
;
; PURPOSE:
;   Determine whether the current IDL environment supports the IDLffVideoWrite
;   class and (optionally) the specified format and codec
;
; CALLING SEQUENCE:
;   result = mgh_has_video(FORMAT=format, CODEC=codec)
;
; RETURN VALUE:
;   This function returns !true if the specified funtionality is supported,
;   !false otherwise.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001=06:
;       Written.
;   Mark Hadfield, 2001=06:
;       Updated to use:
;       - Static methods of the IDLffVideoWrite class, introduced in IDL 8.3;
;       - Boolean variables, introduced in IDL 8.4.
;-
function mgh_has_video, FORMaT=format, CODEC=codec

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ mgh_class_exists('IDLffVideoWrite') then return, !false

   if n_elements(format) gt 0 then begin
      f = IDLffVideoWrite.GetFormats()
      if max(strmatch(f, format, /FOLD_CASE)) eq 0 then return, !false
   endif

   if n_elements(codec) gt 0 then begin
      c = IDLffVideoWrite.GetCodecs()
      if max(strmatch(c, codec, /FOLD_CASE)) eq 0 then return, !false
   endif

   return, !true

end
