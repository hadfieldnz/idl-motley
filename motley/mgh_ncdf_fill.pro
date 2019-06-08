;+
; NAME:
;   MGH_NCDF_FILL
;
; PURPOSE:
;   For a given netCDF variable type, this function returns the default fill
;   value, as specified in netcdf.h
;
; CALLING SEQUENCE:
;   result = mgh_ncdf_fill(type)
;
; POSITIONAL PARAMETERS:
;   type (input, string scalar)
;     A netCDF data type, as in the datatype field of the output ncdf_varinq.
;
;###########################################################################
; Copyright (c) 2008 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2008-11:
;     Written.
;   Mark Hadfield, 2010-10:
;     Added an entry for type 'INT', which seems to be an alias, introduced
;     in IDL 8.0, for 'SHORT'.
;   Mark Hadfield, 2019-05:
;     Added an entry for type 'STRING'. This is supported only by the NETCF4
;     format and cannot be read by Fortran programs.
;-
function mgh_ncdf_fill, type

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(type, /N_ELEMENTS) eq 0 then type = 'FLOAT'

   if size(type, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'type'

   if size(type, /N_ELEMENTS) gt 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'type'

   case strupcase(type) of
      'BYTE'  : result = byte(-127)
      'CHAR'  : result = ''
      'STRING': result = ''
      'INT'   : result = -32767S
      'SHORT' : result = -32767S
      'LONG'  : result = -2147483647L
      'FLOAT' : result = 9.9692099683868690E+36
      'DOUBLE': result = 9.9692099683868690D+36
   endcase

   return, result

end

