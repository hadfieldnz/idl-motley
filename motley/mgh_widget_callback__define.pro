; svn $Id$
;+
; NAME:
;   MGH_WIDGET_CALLBACK__DEFINE
;
; PURPOSE:
;   Define MGH_WIDGET_CALLBACK, a named structure used for callbacks in object
;   widgets.
;
; CATEGORY:
;   Widgets.
;
; CALLING SEQUENCE:
;   This procedure will be called automatically the first time an MGH_WIDGET_CALLBACK
;   structure is created.
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
;       Written.
;-
pro MGH_WIDGET_CALLBACK__Define

   compile_opt DEFINT32
   compile_opt STRICTARR

    struct_hide, {MGH_WIDGET_CALLBACK, object: obj_new(), method: ''}

end
