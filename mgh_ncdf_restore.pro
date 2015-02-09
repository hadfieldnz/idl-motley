;+
; NAME:
;   MGH_NCDF_RESTORE
;
; PURPOSE:
;   This function retrieves data from a netCDF file (or sequence thereof)
;   in the form of an IDL structure.
;
; CATEGORY:
;   NetCDF
;
; CALLING SEQUENCE:
;   result = MGH_NCDF_RESTORE(file, variables)
;
; POSITIONAL PARAMETERS:
;   file (input, string, scalar or vector)
;     A list of netCDF file names. This list is passed to the Init
;     routine for the netCDF file object.
;
;   variables (input, string, scalar or vector, optional)
;     A list of variable names. Default is all variables in the file(s).
;
; KEYWORD PARAMETERS:
;   AUTOSCALE (input, switch)
;     Passed to the netCDF object's Retrieve method to determine whether
;     data are automatically scaled.
;
;   COUNT (output, integer)
;     This keyword returns the number of variables for which data have
;     been returned.
;
;   HASH (input, switch)
;     Passed to the netCDF object's Retrieve method to specify that
;     the result should be a hash.
;
;   NETCDF_CLASS (input, string, scalar)
;     The class of the netCDF file object to be created. Permissible
;     values are 'MGHncFile', 'MGHncReadFile' and
;     'MGHncSequence'. The default is 'MGHncSequence'.
;
;   POINTER (input, switch)
;     Passed to the netCDF object's Retrieve method to specify that
;     the result should be a structure with the data values contained
;     as pointer variables
;
;   Other keywords are passed to the netCDF object's Init method via
;   inheritance.
;
; RETURN VALUE:
;   The function returns an anonymous structure, with one tag per
;   variable.
;
; PROCEDURE:
;   An netCDF file object is created, its Retrieve method called and
;   the object then destroyed.
;
;###########################################################################
; Copyright (c) 1994-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 14 Mar 1994:
;     Written as NCDF_RESTORE.
;   Mark Hadfield, Apr 1997:
;     Rewritten to use the MGHncFile class.
;   Mark Hadfield, May 1998:
;     Extra keywords now passed to MGHncFile.
;   Mark Hadfield, Nov 2000:
;     Renamed MGH_NCDF_RESTORE, updated, moved to public directory,
;     added NETCDF_CLASS keyword & associated functionality.
;   Mark Hadfield, 2001-07:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2005-09:
;     Added POINTER keyword.
;   Mark Hadfield, 2011-11:
;     Added HASH keyword.
;   Mark Hadfield, 2013-10:
;     Added check for undefined file name.
;-
function mgh_ncdf_restore, file, variables, $
     AUTOSCALE=autoscale, COUNT=count, HASH=hash, NETCDF_CLASS=netcdf_class, $
     POINTER=pointer, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(file) eq 0 then message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'file'
   
   if n_elements(netcdf_class) eq 0 then netcdf_class = 'mghncsequence'

   onc = obj_new(netcdf_class, file, _STRICT_EXTRA=extra)

   result = onc->Retrieve(variables, AUTOSCALE=autoscale, COUNT=count, $
                          HASH=hash, POINTER=pointer)

   obj_destroy, onc

   return, result

end

