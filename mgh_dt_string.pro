;+
; NAME:
;   MGH_DT_STRING
;
; PURPOSE:
;   Given a date-time in Julian-date (numeric) form return a string
;   in ISO 8601 format.
;
; CATEGORY:
;   Date and time.
;
; CALLING SEQUENCE:
;   Result = MGH_DT_STRING(dtval[, zone, /DATE_ONLY])
;
; POSITIONAL PARAMETERS:
;   dtval (input, numeric scalar or array)
;     A Julian-date number
;
;   zone (input, integer)
;     Time zone relative to UTC, in hours. If this is omitted, then
;     the output string's time zone field is omitted. If it is
;     supplied, then dtval (which is assumed to be in UTC) is
;     converted to the specified zone and a time-zone field is
;     included in the output.
;
; KEYWORD PARAMETERS:
;   DATE_ONLY (input, switch)
;     If DATE_ONLY is set, then the default format generates an ISO
;     8601 date (e.g. 2000-08-03) otherwise it generates an ISO 8601
;     date-time (e.g. 2000-08-03T11:03:13)
;
;   DATE_ONLY (input, string)
;     Pass a valid calendar format to this keyword to override the default
;     format.
;
; RETURN VALUE:
;   The function returns a string scalar or array. Since formatted
;   input is used, arrays are reformed to one dimension and truncated
;   at 1024 elements.
;
; TO DO:
;   Allow for fractional time zones. Work around limitations of
;   formatted input?
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
;   Mark Hadfield, 2000-08:
;     Written.
;   Mark Hadfield, 2001-05:
;     Added the time-zone argument and the handling for it. Removed
;     some of the generality in handling formats because this
;     conflicts with handling time zones.
;-
function mgh_dt_string, dtval, $
     DATE_ONLY=date_only, FORMAT=format, ZONE=zone

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(format) eq 0 then begin
      format = '(C(CYI4.4,"-",CMOI2.2,"-",CDI2.2'
      if ~ keyword_set(date_only) then $
           format += ',"T",CHI2.2,":",CMI2.2,":",CSI2.2'
      format += '))'
   endif

   if n_elements(zone) gt 0 then begin
      return, string(dtval+zone/24.D0, FORMAT=format) + $
              mgh_str_subst(string(zone, FORMAT='("Z",I3.2)'),' ','+')
   endif else begin
      return, string(dtval, FORMAT=format)
   endelse

end
