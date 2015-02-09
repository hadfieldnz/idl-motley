; svn $Id$
;+
; NAME:
;   MGH_IS_EVENT
;
; PURPOSE:
;   This function determines whether a variable represents a widget
;   event. It carries out a simple test (see below) on the size and
;   type of the variable. The function has been created and given its
;   name to allow clearer event-handling code.
;
; CALLING SEQUENCE:
;   result = MGH_IS_EVENT(var)
;
; POSITIONAL PARAMETERS:
;   var (input)
;     The variable to be examined.
;
; RETURN VALUE:
;   This function returns 1 if the variable is a single-element
;   structure, otherwise 0.
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
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2004-06:
;     Now uses short-circuiting logical operator.
;-

function MGH_IS_EVENT, value

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, size(value, /TYPE) eq 8 && n_elements(value) eq 1

end

