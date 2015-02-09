; svn $Id$
;+
; NAME:
;   MGH_VAR_RESTORE
;
; PURPOSE:
;   Function MGH_VAR_RESTORE restores an IDL variable saved by VAR_SAVE.
;
; CALLING SEQUENCE:
;   Result = MGH_VAR_RESTORE(File)
;
; INPUTS:
;   File:        The name of the file to be restored.
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
;   Mark Hadfield, May 1998:
;       Written.
;   Mark Hadfield, Aug 2000:
;       Updated for IDL 5.4.
;-

function MGH_VAR_RESTORE, file, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

    var = ''

    if not file_test(file, /READ) then $
        message, 'File '+File+' not available for READ access'

    restore, file, _EXTRA=extra

    return, var

end
