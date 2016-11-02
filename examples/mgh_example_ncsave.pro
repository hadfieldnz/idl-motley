;+
; NAME:
;   MGH_EXAMPLE_NCSAVE
;
; PURPOSE:
;   Example program that saves an IDL structure as a netCDF file,
;   then restores it.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
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
