; svn $Id$
;+
; NAME:
;   MGH_WIDGET_ABS_OFFSET
;
; PURPOSE:
;   Given a widget ID, this function returns the offset of this widget
;   relative to the screen
;
; CALLING SEQUENCE:
;   Result = MGH_WIDGET_ABS_OFFSET(wid)
;
; POSITIONAL PARAMETERS:
;   wid (input, widget ID)
;     The ID of the widget we are searching.
;
; KEYWORD PARAMETERS:
;   UNITS (input, integer scalar)
;     This keyword specifies the units required fo the result. Valid values
;     are 0 (pixels, default), 1 (inches), 2 (centimetres).
;
; RETURN VALUE:
;   The function returns a 2-element vector representing the offset
;   of the current widget relative to the screen.
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
;   Mark Hadfield, 2004-07:
;     Written.
;-
function MGH_WIDGET_ABS_OFFSET, wid, UNITS=units

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = fltarr(2)

   current = wid

   while widget_info(current, /VALID_ID) do begin
      geom = widget_info(current, /GEOMETRY, UNITS=units)
      result += [geom.xoffset,geom.yoffset]
      current = widget_info(current, /PARENT)
   endwhile

   return, result


end

