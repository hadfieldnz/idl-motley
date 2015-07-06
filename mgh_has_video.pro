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
;   This function returns 1 if the specified funtionality is supported, 0 otherwise.
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
;-
function mgh_has_video, FORMaT=format, CODEC=codec

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if ~ mgh_class_exists('IDLffVideoWrite') then return, 0B

  file = filepath(cmunique_id()+'.avi', /TMP)

  ovid = obj_new('IDLffVideoWrite', file)

  if n_elements(format) gt 0 then begin
    f = ovid->GetFormats()
    if max(strmatch(f, format, /FOLD_CASE)) eq 0 then return, 0B
  endif

  if n_elements(codec) gt 0 then begin
    c = ovid->GetCodecs()
    if max(strmatch(c, codec, /FOLD_CASE)) eq 0 then return, 0B
  endif

  return, 1B

end


