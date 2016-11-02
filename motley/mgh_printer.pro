; svn $Id$
;+
; NAME:
;   MGH_PRINTER
;
; PURPOSE:
;   Support a session-wide Object Graphics printer.
;
; CATEGORY:
;   Widgets.
;
; CALLING SEQUENCE:
;   There are 2 modes of operation:
;
;   1: Return a reference to the session-wide printer object, after
;   creating it if necessary:
;
;       obj = MGH_PRINTER()
;
;   2: Set up the printer
;
;       int = MGH_PRINTER(/SETUP)
;
; POSITIONAL PARAMETERS:
;   None
;
; KEYWORD PARAMETERS:
;   SETUP
;     If this keyword is set, run DIALOG_PRINTERSETUP and return the
;     result.
;
; RETURN VALUE:
;   The function returns an object reference, or if SETUP is set, an
;   integer representing the completion status of DIALOG_PRINTERSETUP.
;
; SIDE EFFECTS:
;   A new system variable, !mgh_printer, is created and an
;   IDLgrPrinter object reference is stored in it.
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
;     Updated.
;-
function MGH_PRINTER, SETUP=setup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   defsysv, '!mgh_printer', EXISTS=exists

   if ~ exists then $
        defsysv, '!mgh_printer', obj_new('IDLgrPrinter')

   if ~ obj_valid(!mgh_printer) then $
        !mgh_printer = obj_new('IDLgrPrinter')

   return, keyword_set(setup) $
           ? dialog_printersetup(!mgh_printer) : !mgh_printer

end
