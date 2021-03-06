;+
; NAME:
;   Class MGHncHelper
;
; PURPOSE:
;   This class is a "helper" for the netCDF-file classes (MGHncFile,
;   MGHncReadFile & MGHncSequence). It is inherited by each of them to
;   provide common functionality.
;
; CATEGORY:
;   Scientific Data Formats.
;
;###########################################################################
; Copyright (c) 2001-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-11:
;     Written.
;   Mark Hadfield, 2003-07:
;     Added a VG method, a synonym for VarGet.
;   Mark Hadfield, 2010-11:
;     Now inherits IDL_Object.
;   Mark Hadfield, 2015-11:
;     Removed support for the ERR_STRING keyword in the HasVar method.
;   Mark Hadfield, 2016-03:
;     Changed the Retrieve method's HASH keyword to DICTIONARY; it now
;     causes the data to be returned in a Dictionary object. I intend
;     to make this the default behaviour.
;-
pro MGHncHelper::About, lun

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(lun) eq 0 then lun = -1

  self->Info, N_ATTS=n_atts, ATT_NAMES=att_names, N_DIMS=n_dims, $
    DIM_NAMES=dim_names, DIMENSIONS=dimensions, N_VARS=n_vars, $
    VAR_NAMES=var_names

  printf, lun, self, 'Catalogue of netCDF '+self->Info(/FILE_NAME)+':'
  printf, lun, self,'Global attributes:'
  printf, lun, self, (n_atts gt 0) ? att_names : '(none)'
  printf, lun, self,'Dimension names:'
  printf, lun, self, (n_dims gt 0) ? dim_names : '(none)'
  printf, lun, self,'Dimension sizes:'
  printf, lun, self, dimensions
  printf, lun, self,'Variables:'
  case n_vars gt 0 of
    0: printf, lun, self, '(none)'
    1: begin
      for i=0,n_vars-1 do begin
        printf, lun, self, 'Variable ', var_names[i]
        self->VarInfo, var_names[i], N_ATTS=n_atts, ATT_NAMES=att_names, $
          N_DIMS=n_dims, DIM_NAMES=dim_names, DIMENSIONS=dimensions
        printf, lun, self,'Attributes:'
        printf, lun, self, (n_atts gt 0) ? att_names : '(none)'
        printf, lun, self,'Dimension names:'
        printf, lun, self, (n_dims gt 0) ? dim_names : '(none)'
        printf, lun, self,'Dimensions:'
        printf, lun, self, dimensions
        printf, lun, self,'Selected data:'
        data = self->VarGet(var_names[i], /AUTOSCALE)
        printf, lun, self, data[0:(n_elements(data)-1) < 10]
      endfor
    end
  endcase

end

function MGHncHelper::AttNames, var, GLOBAL=global, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case keyword_set(global) of
      0: self->VarInfo, var, ATT_NAMES=att_names, N_ATTS=count
      1: self->GetProperty, ATT_NAMES=att_names, N_ATTS=count
   endcase

   return, att_names

end

function MGHncHelper::DimNames, COUNT=count, UNLIMITED=unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, DIM_NAMES=dim_names, N_DIMS=n_dims, UNLIMITED=unlim_name

   if keyword_set(unlimited) then begin
      count = long(strlen(unlim_name) gt 0)
      return, unlim_name
   endif else begin
      count = n_dims
      return, dim_names
   endelse

end

function MGHncHelper::HasVar, var

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(var) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'var'
   if n_elements(var) gt 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'
   if ~ isa (var, 'STRING') then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   !null = where(var eq self->VarNames(), count)

   return, count gt 0

end

function MGHncHelper::Retrieve, vars, $
     AUTOSCALE=autoscale, COUNT=count, DICTIONARY=dictionary, POINTER=pointer

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(autoscale) eq 0 then autoscale = 1B

  count = n_elements(vars)

  if count eq 0 then $
    self->GetProperty, VAR_NAMES=vars, N_VARS=count

  if keyword_set(dictionary) then begin

    result = dictionary()

    for i=0,count-1 do begin
      result[vars[i]] = self->VarGet(vars[i], AUTOSCALE=autoscale)
    endfor

  endif else begin

    if count eq 0 then return, -1

    data = ptrarr(count)

    for i=0,count-1 do begin
      data[i] = ptr_new(self->VarGet(vars[i], AUTOSCALE=autoscale), /NO_COPY)
    endfor

    result = mgh_struct_build(vars, data, POINTER=pointer)

    if ~ keyword_set(pointer) then ptr_free, data

  endelse

  return, result

end

function MGHncHelper::VarDimNames, var, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->VarInfo, var, DIM_NAMES=dim_names, N_DIMS=count

   return, dim_names

end

function MGHncHelper::VG, var, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self->VarGet(var, _STRICT_eXTRA=extra)

end

function MGHncHelper::VarNames, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, VAR_NAMES=result, N_VARS=count

   return, result

end

pro MGHncHelper__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHncHelper, inherits IDL_Object}

end

