; svn $Id$
;+
; NAME:
;   MGH_TF_LONGITUDE
;
; PURPOSE:
;   This function is designed for use with the TICKFORMAT property of
;   IDLgrAxis. It adds 'W' and 'E' suffices appropriately.
;
; CATEGORY:
;   Miscellaneous
;   Object graphics
;
; CALLING SEQUENCE:
;   Result = MGH_TF_LONGITUDE(Direction, Index, Value)
;
; POSITIONAL PARAMETERS:
;   Direction
;     Axis direction, required by the TICKFORMAT interface but ignored.
;
;   Index
;     Axis index, required by the TICKFORMAT interface but ignored.
;
;   Value
;     The real value to be formatted.
;
; KEYWORD PARAMETERS:
;   DATA
;     Specify this keyword to control the format. The keyword value
;     should be a structure with tags "format" and/or "round". All
;     other tags are ignored. The default is equivalent to {format:
;     '', round: 0}.
;
; RETURN VALUE:
;   The function returns a scalar string. The format is controlled by
;   data.format. If this is not supplied a default format is generated
;   by FORMAT_AXIS_VALUES.
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
;   Mark Hadfield, 1998-06:
;     Written.
;   Mark Hadfield, 2000-02:
;     Added format control via the DATA keyword.
;   Mark Hadfield, 2001-05:
;     Added rounding via the "round" tag in DATA. I might generalise
;     this some day.
;   Mark Hadfield, 2002-02:
;     Changed the default number-to-string conversion function from
;     FORMAT_AXIS_VALUES to MGH_FORMAT_FLOAT. The former is inappropriate
;     as it is designed for array inputs (where it can use information
;     about the differences between consecutive values). For scalar values
;     with typical longitude values it rounds excessively.
;-

function MGH_TF_LONGITUDE_PRIVATE_STRING, Value, Format

   compile_opt IDL2, HIDDEN

   result = strlen(format) gt 0 $
            ? string(Value, FORMAT=format) $
            : mgh_format_float(Value)

   return, result[0]

end

function MGH_TF_LONGITUDE, Direction, Index, Value, DATA=data

   compile_opt DEFINT32
   compile_opt STRICTARR

   format = ''  &  round = 0

   if size(data, /TYPE) eq 8 then begin
      if n_elements(data) ne 1 then $
           message, 'The DATA structure must have one element'
      if mgh_struct_has_tag(data, 'format') then format = data.format
      if mgh_struct_has_tag(data, 'round') then round = data.round
   endif

   rvalue = round ? round(value) : value

   case 1 of
      rvalue eq -180: $
           return, mgh_tf_longitude_private_string(-rvalue, format)+'!Z(00B0)'
      rvalue gt -180 and rvalue lt 0: $
           return, mgh_tf_longitude_private_string(-rvalue, format)+'!Z(00B0)W'
      rvalue eq 0: $
           return, mgh_tf_longitude_private_string(rvalue, format)+'!Z(00B0)'
      rvalue gt 0 and rvalue lt 180: $
           return, mgh_tf_longitude_private_string(rvalue, format)+'!Z(00B0)E'
      rvalue eq 180: $
           return, mgh_tf_longitude_private_string(rvalue, format)+'!Z(00B0)'
      rvalue gt 180 and rvalue lt 360: $
           return, mgh_tf_longitude_private_string(360-rvalue, format)+'!Z(00B0)W'
      rvalue eq 360: $
           return, mgh_tf_longitude_private_string(360-rvalue, format)+'!Z(00B0)'
      else: $
           return, mgh_tf_longitude_private_string(rvalue, format)+'!Z(00B0)'
   endcase

end

