;+
; NAME:
;   MGH_DT_UNITS
;
; PURPOSE:
;   This function parses "units" descriptors for date-time data, see
;
;     http://my.unidata.ucar.edu/content/software/udunits/man.php?udunits+3
;
; CATEGORY:
;   Date-time.
;
; CALLING SEQUENCE:
;   Result = MGH_DT_UNITS(ustring)
;
; RETURN VALUE:
;   The function returns a structure containing tags "scale" and "offset"
;   that can be used to convert data-time data into a Julian Date.
;
;###########################################################################
; Copyright (c) 2004-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2004-10:
;     Written.
;-
function mgh_dt_units, ustring

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(ustring, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'ustring'

   if size(ustring, /N_ELEMENTS) gt 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'ustring'

   if size(ustring, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'ustring'

   result = {scale: 0.D, offset: 0.D}

   ;; Split the string at "since"

   p = strpos(ustring, 'since')

   if p ge 0 then begin
      s0 = strmid(ustring, 0, p+1)
      s1 = strmid(ustring, p+5)
   endif else begin
      s0 = ustring
   endelse

   ;; Handle the units component

   case 1B of
      strmatch(s0, 'day*', /FOLD_CASE): begin
         result.scale = 1
      end
      strmatch(s0, 'hour*', /FOLD_CASE): begin
         result.scale = 1/24.D
      end
      strmatch(s0, 'second*', /FOLD_CASE): begin
         result.scale = 1/(24.D*3600.D)
      end
      else: begin
         result.scale = 1
      end
   endcase

   ;; Handle the base-date component. Special handling for year zero.

   if n_elements(s1) gt 0 then begin
      dts = mgh_dt_parse(strtrim(s1, 2))
      if dts.year eq 0 then begin
        dts.year = 1
        result.offset = mgh_dt_julday(dts) - mgh_dt_julday(YEAR=dts.year)
      endif else begin
        result.offset = mgh_dt_julday(dts)
      endelse
   endif

   return, result

end
