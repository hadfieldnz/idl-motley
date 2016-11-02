; svn $Id$
;+
; NAME:
;   MGH_NCDF_ABOUT
;
; PURPOSE:
;   This procedure prints summary information about a netCDF file.
;   It is a wrapper for the MGHncHelper::About method.
;
; CALLING SEQUENCE:
;   MGH_NCDF_ABOUT, file
;
; POSITIONAL PARAMETERS:
;   file (input, string, scalar or vector)
;     A list of netCDF file names. This list is passed to the Init
;     routine for the netCDF file object.
;
;   lun (input, integer, scalar, optional)
;     Logical unit number to which data are to be printed. If this is
;     omitted output is sent to the console
;
; KEYWORD PARAMETERS:
;   NETCDF_CLASS (input, string, scalar)
;     The class of the netCDF file object to be created. Permissible
;     values are 'MGHncFile', 'MGHncReadFile' and
;     'MGHncSequence'. The default is 'MGHncReadFile'.
;
;   Other keywords are passed to the netCDF object's Init method via
;   inheritance.
;
; PROCEDURE:
;   An netCDF file object is created, its About method called and
;   the object then destroyed.
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
;   Mark Hadfield, 2005-07:
;     Written.
;   Mark Hadfield, 2009-07:
;     Default NETCDF_CLASS changed from MGHncSequence to MGHncReadFile.
;-
pro mgh_ncdf_about, file, lun, $
     NETCDF_CLASS=netcdf_class, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; No argument checking here because it is carried out by the
   ;; object's Init method.

   if n_elements(netcdf_class) eq 0 then netcdf_class = 'MGHncReadFile'

   onc = obj_new(netcdf_class, file, _STRICT_EXTRA=_extra)

   onc->About, lun

   obj_destroy, onc

end

