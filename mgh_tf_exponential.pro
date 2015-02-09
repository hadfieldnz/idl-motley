; svn $Id$
;+
; NAME:
;   MGH_TF_EXPONENTIAL
;
; PURPOSE:
;   This function is designed for use with the TICKFORMAT property of IDLgrAxis.
;   It returns a formatted representation of exp(Value)
;
; CATEGORY:
;   Miscellaneous
;   Object graphics
;
; CALLING SEQUENCE:
;   Result = FUNCTION_NAME(Direction, Index, Value)
;
; INPUTS:
;   Direction:  Axis direction, required by the TICKFORMAT interface but ignored.
;
;   Index:      Axis index, required by the TICKFORMAT interface but ignored.
;
;   Value:      The real value to be formatted.
;
; OUTPUTS:
;   The function returns a scalar string.
;
; TO DO:
;   Allow format control via the DATA keyword.
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
;   Mark Hadfield, Jun 1998:
;       Written.
;-

function MGH_TF_EXPONENTIAL, direction, index, value, level, DATA=data

   compile_opt DEFINT32
   compile_opt STRICTARR

   base = exp(1)
   format = ''

   if size(data, /TYPE) eq 8 then begin
      if n_elements(data) ne 1 then $
           message, 'The DATA structure must have one element'
      if mgh_struct_has_tag(data, 'base') then base = data.base
      if mgh_struct_has_tag(data, 'format') then format = data.format
   endif

   if n_elements(level) gt 0 then format = format[level]

   rvalue = base^value

   result = strlen(format) gt 0 $
            ? string(rvalue, FORMAT=format) $
            : mgh_format_float(rvalue)

   return, result[0]

end

