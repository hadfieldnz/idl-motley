; svn $Id$
 ;+
; NAME:
;   MGH_EXAMPLE_NCSAVE
;
; PURPOSE:
;   Example program that saves an IDL structure as a netCDF file,
;   then restores it.
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
;   Mark Hadfield, 2004-06:
;     Written.
;-

pro mgh_example_ncsave

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   tmpfile = filepath('mgh_example_ncfile_tmp.idl_data', /TMP)

   s0 = {a: 0, b: bindgen(3,4,5), c: ['Hello','world'], d: mgh_dist(50)}

   help, /STRUCT, s0

   mgh_ncdf_save, s0, tmpfile, /CLOBBER

   s1 = mgh_ncdf_restore(tmpfile)

   help, /STRUCT, s1

end
