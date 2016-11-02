; svn $Id$
;+
; NAME:
;   MGH_AVI_DLL
;
; PURPOSE:
;   Return the path name of the AVI DLL. It must be in the same
;   directory as the present file.
;
; CALLING SEQUENCE:
;	 path = MGH_AVI_DLL()
;
; RETURN VALUE:
;   The function returns a string giving the path name of the AVI
;   DLL.
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
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2006-05:
;     Written.
;-
function mgh_avi_dll

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   src = routine_info('mgh_avi_dll', /SOURCE, /FUNCTIONS)

   return, filepath('avi.dll', ROOT=file_dirname(src.path))

end
