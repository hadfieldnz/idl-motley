;+
; NAME:
;   MGH_STR_SHORTEN
;
; PURPOSE:
;   Shorten a string, by selecting the geinning and end parts, joined by '...'
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   result = mgh_str_vanilla(instr)
;
; POSITIONAL PARAMETERS:
;   instr (input, string scalar or array)
;     Input string(s).
;
; RETURN VALUE:
;   The function returns a string variable with the same shape as the
;   original, with all unsafe characters replaced with safe ones.
;
;###########################################################################
; Copyright (c) 2005-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-12:
;     Written.
;-
function mgh_str_shorten, str, max_length

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(str) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'instr'

   if size(str, /TYPE) ne 7 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'instr'

   if n_elements(max_length) eq 0 then max_length = 50

   result = str

   if strlen(str) gt max_length then begin
      result = result.Substring(0, max_length/2-2)+'...'+result.Substring(-(max_length/2-2))
   endif




   return, result

end
