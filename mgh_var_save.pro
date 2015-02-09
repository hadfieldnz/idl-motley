; svn $Id$
;+
; NAME:
;   MGH_VAR_SAVE
;
; PURPOSE:
;   Procedure MGH_VAR_SAVE saves a single IDL variable to a binary file
;   in XDR format using SAVE. The variable can be retrieved with the
;   function VAR_RESTORE.
;
; CALLING SEQUENCE:
;   MGH_VAR_SAVE, Var, File
;
; INPUTS:
;   Var:        The variable to be saved.
;
;   File:       The name of the file to be created.
;
; SIDE EFFECTS:
;   Any existing file that matches the name File is deleted without warning.
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
;-

pro MGH_VAR_SAVE, var, file, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   save, var, FILE=file, _EXTRA=extra

end
