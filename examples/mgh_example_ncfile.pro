; svn $Id$
 ;+
; NAME:
;   MGH_EXAMPLE_NCFILE
;
; PURPOSE:
;   Example program for creating, copying, reading netCDF files.
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
;   Mark Hadfield, 2000-06:
;     Written.
;-

pro mgh_example_ncfile, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   case option of
      0: read_class = 'MGHncFile'
      1: read_class = 'MGHncReadFile'
      2: read_class = 'MGHncSequence'
   endcase

   message, /INFORM, 'I will use class '+read_class+' for reading netCDF files'

   files = filepath('mgh_example_ncfile_'+strtrim(sindgen(2),2)+'.nc', /TMP)

   message, /INFORM, 'Creating netCDF file '+files[0]

   onc = obj_new('MGHncFile', /CREATE, /CLOBBER, FILE_NAME=files[0])
   onc->AttAdd, /GLOBAL, 'title', 'Test file'
   onc->DimAdd, 'x',5
   onc->DimAdd, 'y',4
   onc->DimAdd, 't'
   onc->VarAdd, 's'
   onc->AttAdd, 's', 'description', 'A scalar variable'
   onc->VarAdd, 'x', ['x']
   onc->VarAdd, 'y', ['y'], /SHORT
   onc->AttAdd, 'y', 'valid_min', 0
   onc->AttAdd, 'y', 'valid_max', 10
   onc->VarAdd, 't', ['t']
   onc->VarAdd, 'v', ['x','y','t']
   onc->AttAdd, 'v', 'long_name', 'velocity'
   onc->AttAdd, 'v', 'units'    , 'm/s'
   onc->AttAdd, 'v', 'valid_range', [-100.,100.]
   onc->VarPut, 's', 0
   onc->VarPut, 'y', 5*indgen(4)
   onc->VarPut, 'v', findgen(5,4,6)
   obj_destroy, onc

   message, /INFORM, 'Copying contents to '+files[1]

   onc0 = obj_new(read_class, files[0])
   onc1 = obj_new('MGHncFile', files[1], /CREATE, /CLOBBER)
   onc1->DimCopy, onc0
   onc1->AttCopy, onc0, /GLOBAL
   onc1->VarCopy, onc0, /DEFINITION
   onc1->VarCopy, onc0, /ATTRIBUTES
   onc1->VarCopy, onc0, /DATA
   obj_destroy, [onc0,onc1]

   message, /INFORM, 'Reading netCDF file '+files[1]

   onc = obj_new(read_class, files[1])
   onc->About
   obj_destroy, onc

end
