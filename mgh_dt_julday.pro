;+
; NAME:
;   MGH_DT_JULDAY
;
; PURPOSE:
;   Given date & time expressed in calendar form (year, month, day,
;   hour, minute, second, time zone), this function returns the Julian
;   date
;
; CALLING SEQUENCE:
;   Result = MGH_DT_JULDAY(YEAR=year, MONTH=month, DAY=day, HOUR=hour,
;                          MINUTE=minute, SECOND=second, ZONE=zone)
;
;   Result = MGH_DT_JULDAY(param)
;
; PARAMETERS:
;   The function accepts values for year, month, day, hour, minute,
;   second and time zone. These can be passed as keyword parameters
;   or combined into a single positional parameter in one of two forms:
;     * As tags in a single structure
;     * As fields in a string in ISO format
;
; RETURN VALUE:
;   The function returns a double-precision floating point number.
;
; EXPLANATION:
;   I just don't like JULDAY. The order of arguments is wrong and
;   JULDAY(1,1,2000) doesn't equal JULDAY(1,1,2000,0,0,0). This
;   function replaces JULDAY and addresses these objections
;
; EXAMPLE:
;   print, mgh_dt_julday(YEAR=2000, MONTH=1, DAY=1, $
;                        HOUR=0, MINUTE=0, SECOND=0)
;       2451544.5
;   print, mgh_dt_julday(YEAR=2000)
;       2451544.5
;   print, mgh_dt_julday('2000-01-01 00:00:00')
;       2451544.5
;
;###########################################################################
; Copyright (c) 2000-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-08:
;     Written.
;   Mark Hadfield, 2000-09:
;     Added ZONE argument.
;   Mark Hadfield, 2001-05:
;     New keyword/structure argument passing.
;   Mark Hadfield, 2001-08:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2002-09:
;     Added support for ISO strings.
;   Mark Hadfield, 2004-06:
;     Added support for array positional parameters.
;   Mark Hadfield, 2004-07:
;     Fixed a bug introduced with array parameters: when a scalar
;     positional parameter was passed, the result was a single-element array.
;-
function mgh_dt_julday_calc, $
     YEAR=year, MONTH=month, DAY=day, HOUR=hour, MINUTE=minute, SECOND=second, ZONE=zone

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt HIDDEN

   if n_elements(year) eq 0 then message, 'Year argument is missing'

   if n_elements(month) eq 0 then month = 1

   if n_elements(day) eq 0 then day = 1

   if n_elements(hour) eq 0 then hour = 0

   if n_elements(minute) eq 0 then minute = 0

   if n_elements(second) eq 0 then second = 0

   if n_elements(zone) eq 0 then zone = 0

   return, julday(month, day, year, hour, minute, second) - zone/24.D0

end

function mgh_dt_julday, param, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n_param = size(param, /N_ELEMENTS)

   case n_param gt 0 of

      0B: begin
         return, mgh_dt_julday_calc(_STRICT_EXTRA=extra)
      end

      1B: begin
         result = mgh_reproduce(0.D0, param)
         case size(param, /TNAME) of
            'STRUCT': begin
               for i=0,n_param-1 do $
                     result[i] = mgh_dt_julday_calc(_STRICT_EXTRA=param[i])
            end
            'STRING': begin
               for i=0,n_param-1 do $
                     result[i] = mgh_dt_julday_calc(_STRICT_EXTRA=mgh_dt_parse(param[i]))
            end
            else: begin
               message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'param'
            endelse
         endcase
         return, result
      end

   endcase

end
