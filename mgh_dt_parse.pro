;+
; NAME:
;   MGH_DT_PARSE
;
; PURPOSE:
;   This procedure extracts date & time information from a string in
;   extended ISO 8601 format.
;
; CALLING SEQUENCE:
;   Result = mgh_dt_parse(Iso)
;
; POSITIONAL PARAMETERS:
;   Iso (input)
;     A string scalar in ISO 8601 format
;
; OUTPUTS:
;   The function returns a structure with one or more of the following
;   tags:
;
;     YEAR (integer)
;       Year number
;
;     MONTH (byte)
;       Month number
;
;     DAY (byte)
;       Day of month
;
;     HOUR (byte)
;       Hour of day
;
;     MINUTE (byte)
;       Minute
;
;     SECOND (float)
;       Second
;
;     ZONE (float)
;      Time zone in hours
;
; RESTRICTIONS:
;   - Years before 0 AD are not allowed (because minus signs are
;     interpreted as date separators).
;
;###########################################################################
; Copyright (c) 1999-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-08:
;     Written as MGHDT_PARSE_ISO, based on routine STR2UTC in the CDS
;     library (http://sohowww.nascom.nasa.gov/solarsoft/gen/idl/).
;   Mark Hadfield, 2000-08:
;     Copied (with no substantive changes in the code) into my new
;     date-time library as MGH_DT_PARSE.
;   Mark Hadfield, 2001-05:
;     Converted from a procedure returning data via keyword
;     arguments to a function returning a structure. Moved the
;     source file into my Motley library.
;   Mark Hadfield, 2001-10:
;     The result, which is a structure, no longer has the dummy tag
;     (name "dummy") which was included to simplify the
;     structure-building code.
;   Mark Hadfield, 2011-07:
;     The output if no date-time strings are found
;     is now an empty structure and the code has been simplified somewhat to take
;     advantage of this.
;-
function mgh_dt_parse, iso_string

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(iso_string) ne 1 || size(iso_string, /TYPE) ne 7 then $
    message, 'Date-time argument must be a scalar string in ISO format'

  ;; Separate the input string into date and time parts. Accept
  ;; either "T" or " " as separators--they may not appear elsewhere
  ;; in the string.

  iso_trim = strtrim(iso_string, 2)

  pSep = strpos(iso_trim,'T')
  if pSep lt 0 then pSep = strpos(iso_trim,' ')

  if pSep ge 0 then begin
    ;; Separator found
    sDate = strtrim(strmid(iso_trim,0,pSep),2)
    sTime = strmid(strmid(iso_trim,pSep-1),2)
  endif else begin
    ;; Separator not found. This could be a date or a time
    pTimeSep = strpos(iso_trim,':')
    if pTimeSep ge 0 then begin
      ;; It's a time
      sDate = ''
      sTime = iso_trim
    endif else begin
      ;; It's a date
      sDate = iso_trim
      sTime = ''
    endelse
  endelse

  ;; Default output, if no date-time elements are found, is an
  ;; empty structure

  result = {}

  ;; Parse date string

  if strlen(sDate) gt 0 then begin

    sDate = strsplit(sDate, '-', /EXTRACT)

    if strlen(sDate[0]) gt 0 then $
      result = create_struct(result, 'year', fix(sDate[0]))
    if n_elements(sDate) ge 2 && strlen(sDate[1]) gt 0 then $
      result = create_struct(result, 'month', fix(sDate[1]))
    if n_elements(sDate) ge 3 && strlen(sDate[2]) gt 0 then $
      result = create_struct(result, 'day', fix(sDate[2]))

  endif

  ;; Parse time &/or time-zone string

  if strlen(sTime) gt 0 then begin

    ;; Split at time-zone separator, if any

    pZone = strpos(sTime,'Z')
    if pZone lt 0 then $
      pZone = strpos(sTime,'+')
    if pZone lt 0 then $
      pZone = strpos(sTime,'-')

    if pZone ge 0 then begin
      sTmp = strtrim(strmid(sTime,0,pZone),2)
      sZone = strtrim(strmid(sTime,pZone),2)
      sTime = sTmp
    endif

    ;; Parse time string

    sTime = strsplit(sTime, ':', /EXTRACT)

    if strlen(sTime[0]) gt 0 then $
      result = create_struct(result, 'hour', fix(sTime[0]))
    if n_elements(sTime) ge 2 && strlen(sTime[1]) gt 0 then $
      result = create_struct(result, 'minute', fix(sTime[1]))
    if n_elements(sTime) ge 3 && strlen(sTime[2]) gt 0 then $
      result = create_struct(result, 'second', float(sTime[2]))

    ;; Parse time-zone string

    if n_elements(sZone) gt 0 then begin
      if strmid(sZone,0,1) eq 'Z' then $
        sZone = strmid(sZone,1)
      if strlen(sZone) gt 0 then $
        result = create_struct(result, 'zone', fix(sZone))
    endif

  endif

  return, result

end
