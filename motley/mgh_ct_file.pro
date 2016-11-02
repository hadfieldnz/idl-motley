; svn $Id$
;+
; NAME:
;   MGH_CT_FILE
;
; PURPOSE:
;   This function returns the name of an IDL colour table file.
;
; CALLING SEQUENCE:
;   result = MGH_CT_FILE(SYSTEM=system)
;
; KEYWORDS:
;   SYSTEM (input, switch)
;     If SYSTEM is set, then the function returns the name of the
;     system colour-table file, <IDL_DIR>/resource/colors/colors1.tbl.
;     If sYSTEM is 0 or unspecified, then the function returns the
;     value of !MGH_CT_FILE, if that is available, or, failing that
;     the system colour-table file name.
;
; RETURN VALUE:
;   The function returns the file name as a scalar string.
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
;   Mark Hadfield, 2002-12:
;     Written.
;-

function MGH_CT_FILE, SYSTEM=system

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   sfile = filepath('colors1.tbl', subdir=['resource', 'colors'])

   case keyword_set(system) of

      0: begin
         defsysv, '!MGH_CT_FILE', EXISTS=exists
         return, exists ? !mgh_ct_file : sfile
      end

      1: return, sfile

   endcase

end

