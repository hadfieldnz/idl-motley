;+
; NAME:
;   Class MGHncReadFile
;
; PURPOSE:
;   This class encapsulates a netCDF file for READ-ONLY access. It
;   exposes methods for manipulating dimensions, variables and
;   attributes.
;
; CATEGORY:
;   Scientific Data Formats.
;
; BACKGROUND:
;   The original reason for having a separate netCDF class for
;   read-only access (c.f. MGHncFile, which allows read-write access)
;   was to work around the limit of 32 on the number of open netCDF
;   files in versions before IDL 6.0. An MGHncReadFile
;   object does not keep its file open for the lifetime of the
;   object--instead it calls NCDF_OPEN each time data is required and
;   NCDF_CLOSE afterwards. This is reasonably efficient for read-only
;   access, because opening and closing the file is not too
;   expensive. It would not make sense if the file were to be changed,
;   because then changes would be flushed to disk on every close.
;
;   With the above modification it becomes practical to maintain
;   sequences of MGHncReadFile objects, as is done by the
;   MGHncSequence class. After some experience with the latter, I
;   found it desirable to also add to the MGHncReadFile class the
;   facility to specify that a subset of records (positions along the
;   unlimited dimension) were to be read. (For a while I kept track of
;   this inside MGHncSequence, but the arithmetic was horrendous.)
;
;   Some time in the future I may move the "open only when necessary"
;   functionality  into MGHncFile (or into a yet-to-be invented class)
;   in order to separate it from the "select records" functionality.
;
; PROPERTIES:
;   TMP (Init, Get)
;     Set this property to make a temporary copy of the netCDF
;     file. This can be highly advantageous when the original is on a
;     fast network drive, where opening and closing the file
;     repeatedly (as MGHncReadFile methods tend to do) is slow and
;     copying the whole file is reasonably fast.
;
;###########################################################################
; Copyright (c) 2000-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-02:
;     Written, based on MGHncFile.
;   Mark Hadfield, 2000-05:
;     Cleaned up code and added the ability to specify a subset of the
;     records: all operations involving the unlimited dimension can
;     see only this subset.
;   Mark Hadfield, 2001-11:
;     Major overhaul of interface along with MGHncFile and
;     MGHncSequence. Eliminated the separate class, MGHncReadFileVar,
;     for variable objects.
;   Mark Hadfield, 2002-04:
;     Added a facility I've been considering for a while to the VarGet
;     method: a zero value in the COUNT vector means get all data and
;     a negative value in the OFFSET vector specifies an offset
;     relative to the end of the dataset.
;   Mark Hadfield, 2004-10:
;     Found and fixed a long-standing bug in HasAtt method: argument
;     order should resemble that of NCDF_ATTGET, ie either of
;       result = onc->HasAtt(var, att)
;       result = onc->HasAtt(att, /GLOBAL).
;   Mark Hadfield, 2008-10:
;     Cleaned up the valid-range code in the _VarGet method. This
;     was failing to detect missing FLOAT and DOUBLE data. It's still
;     not right for BYTE data.
;   Mark Hadfield, 2009-07:
;     Corrected error in the VarInfo method, discovered by Foldy Lajos:
;     the value returned by NCDF_VARINQ for a 2-byte integer is 'SHORT',
;     not 'INT'.
;   Mark Hadfield, 2010-10:
;     - Negative values of self.ncid are no longer used to indicate
;       that the netCDF file is not open (because I am not sure if
;       NCDF_OPEN can return a negative value). Instead a separate
;       is_open property is maintained.
;     - Since NCDF_VARINQ in IDL 8.0 returns 'INT' for a 2-byte integer
;       (this may be a reversion to its previous behaviour) the code
;       in the VarInfo method can handle either 'INT' or 'SHORT'.
;   Mark Hadfield, 2013-02:
;     - Fixed a bug(possibly version-specific) in processing of variable
;       scaling attributes like "valid_range": it failed for variables with
;       no attributes.
;   Mark Hadfield, 2015-11:
;     - Simplified the code in the VarGet method considerably.
;   Mark Hadfield, 2019-05:
;     - In the VariInfo method, added an entry for type 'STRING'. This is supported
;       only by the NETCF4 format and cannot be read by Fortran programs.
;-

; MGHncReadFile::Init
;
function MGHncReadFile::Init, file, $
     FILE_NAME=file_name, RECORDS=records, TMP=tmp

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if (n_elements(file_name) eq 0) && (n_elements(file) gt 0) then $
        file_name = file

   if n_elements(file_name) ne 1 then $
        message, "A valid netCDF file name must be supplied."

   if size(file_name, /TNAME) ne 'STRING' then $
        message, "A valid netCDF file name must be supplied."

   self.file_name = file_name

   self.is_open = !false

   if n_elements(records) gt 0 then self.records = ptr_new(records)

   self.vars = obj_new('IDL_Container')

   if ~ file_test(self.file_name, /READ) then $
        message, "The specified netCDF file cannot be read: "+self.file_name

   if keyword_set(tmp) then begin
      gunzip = strmatch(self.file_name, '*.gz', /FOLD_CASE)
      self.temp_name = filepath(cmunique_id()+'.nc', /TMP)
      mgh_file_copy, self.file_name, self.temp_name, GUNZIP=gunzip, /VERBOSE
   endif else begin
      self.temp_name = self.file_name
   endelse

   return, 1

end

; MGHncReadFile::Cleanup
;
; Purpose:
;   Cleans up all memory associated with the MGHncReadFile. Closes the
;   netCDF file and copies & deletes tempfile files (if any).
;
pro MGHncReadFile::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->Close

   ptr_free, self.records

   obj_destroy, self.vars

   if self.temp_name ne self.file_name then $
        file_delete, self.temp_name

end

; MGHncReadFile::GetProperty
;
pro MGHncReadFile::GetProperty, $
     ALL=all, ATT_NAMES=att_names, $
     DIM_NAMES=dim_names, DIMENSIONS=dimensions, $
     FILE_NAME=file_name, N_DIMS=n_dims, $
     N_VARS=n_vars, N_ATTS=n_atts, $
     N_RECORDS=n_records, $
     RECORDS=records, TMP=tmp, $
     UNLIMITED=unlimited, VAR_NAMES=var_names, $
     WRITABLE=writable

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   file_name = self.file_name
   writable  = !false

   self->Open

   info = ncdf_inquire(self.ncid)
   n_dims  = info.ndims
   n_vars  = info.nvars
   n_atts  = info.ngatts

   tmp = self.file_name ne self.temp_name

   if arg_present(dim_names)  || arg_present(dimensions) || $
        arg_present(n_records) || arg_present(records) || $
        arg_present(unlimited) || arg_present(all) then begin
      if info.recdim ge 0 then begin
         if ptr_valid(self.records) then begin
            records = *self.records
            n_records = n_elements(records)
            ncdf_diminq, self.ncid, info.recdim, unlimited, void
         endif else begin
            records = -1
            ncdf_diminq, self.ncid, info.recdim, unlimited, n_records
         endelse
      endif else begin
         unlimited = ''
         n_records = 0
         records = -1
      endelse
      if n_dims gt 0 then begin
         dim_names = strarr(n_dims)
         dimensions = lonarr(n_dims)
         for i=0,n_dims-1 do begin
            ncdf_diminq, self.ncid, i, name, dimsize
            dim_names[i] = name
            dimensions[i] = (i eq info.recdim) ? n_records : dimsize
         endfor
      endif else begin
         dim_names = ''
         dimensions = 0
      endelse
   endif

   if arg_present(att_names) || arg_present(all) then begin
      if n_atts gt 0 then begin
         att_names = strarr(n_atts)
         for i=0,n_atts-1 do $
              att_names[i] = ncdf_attname(self.ncid, /GLOBAL, i)
      endif else begin
         att_names = ''
      endelse
   endif

   if arg_present(var_names) || arg_present(all) then begin
      if n_vars gt 0 then begin
         var_names = strarr(n_vars)
         for i=0,n_vars-1 do begin
            vinfo = ncdf_varinq(self.ncid, i)
            var_names[i] = vinfo.name
         endfor
      endif else begin
         var_names = ''
      endelse
   endif

   self->Close

   if arg_present(all) then begin
      all = {att_names:att_names, dim_names:dim_names, $
             dimensions:dimensions, file_name:file_name, n_atts:n_atts, $
             n_dims:n_dims, n_vars:n_vars, $
             n_records:n_records, records:records, tmp:tmp, $
             unlimited:unlimited, var_names:var_names, writable:writable}
   endif

end

; MGHncReadFile::AttGet
;
; Purpose:
;   Returns the value of an attribute in the netCDF file. Includes
;   workaround for NCDF_ATTGET bug: an attribute of netCDF type CHAR
;   is read as IDL BYTE type and must be converted to STRING
;
function MGHncReadFile::AttGet, P1, P2, GLOBAL=global

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->Open

   if keyword_set(global) then begin
      info = ncdf_attinq(self.ncid, /GLOBAL, P1)
      ncdf_attget, self.ncid, /GLOBAL, P1, result
   endif else begin
      info = ncdf_attinq(self.ncid, P1, P2)
      ncdf_attget, self.ncid, P1, P2, result
   endelse

   self->Close

   if info.datatype eq 'CHAR' then result = string(result)

   return, result

end

; MGHncReadFile::Close
;
; Purpose:
;   Close the netCDF file (if necessary).
;
pro MGHncReadFile::Close

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.is_open then begin
      ncdf_close, self.ncid
      self.is_open = !false
   endif

end

; MGHncReadFile::DimInfo (Procedure and Function)
;
; Purpose:
;   Return information about a netCDF dimension.
;
pro MGHncReadFile::DimInfo, Dim, $
     ALL=all, DIMSIZE=dimsize, IS_UNLIMITED=is_unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(dim, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   if n_elements(dim) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'

   if strlen(dim) eq 0 then $
        message, 'Dimension name is invalid'

   self->Open

   position = ncdf_dimid(self.ncid, dim)

   info = ncdf_inquire(self.ncid)
   is_unlimited = position eq info.recdim

   if is_unlimited then begin
      if ptr_valid(self.records) then begin
         dimsize = n_elements(*self.records)
         ncdf_diminq, self.ncid, info.recdim, unlimited, void
      endif else begin
         ncdf_diminq, self.ncid, info.recdim, unlimited, dimsize
      endelse
   endif else begin
      ncdf_diminq, self.ncid, position, name, dimsize
   endelse

   self->Close

   if arg_present(all) then all = {dimsize: dimsize, is_unlimited: is_unlimited}

end

function MGHncReadFile::DimInfo, dim, DIMSIZE=dimsize, IS_UNLIMITED=is_unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case !true of
      keyword_set(dimsize): self->DimInfo, dim, DIMSIZE=result
      keyword_set(is_unlimited): self->DimInfo, dim, IS_UNLIMITED=result
      else: self->DimInfo, dim, ALL=result
   endcase

   return, result

end

; MGHncReadFile::HasAtt
;
; Purpose:
;   Returns 1 if the specified attribute is found, otherwise 0.
;
function MGHncReadFile::HasAtt, P1, P2, GLOBAL=global

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(global) then begin
      !null = where(strmatch(self->AttNames(/GLOBAL), P1), count)
   endif else begin
      !null = where(strmatch(self->AttNames(P1), P2), count)
   endelse

   return, count gt 0

end

; MGHncReadFile::HasDim
;
; Purpose:
;   Indicates whether a netCDF file has a dimension with the specified
;   name
;
function MGHncReadFile::HasDim, Name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   !null = where(strmatch(self->DimNames(), name), count)

   return, count gt 0

end

; MGHncReadFile::Info
;
; Purpose:
;   Retrieve information about the netCDF file object. A synonym for
;   GetProperty.
;
pro MGHncReadFile::Info, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, _STRICT_EXTRA=extra

end

function MGHncReadFile::Info, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, mgh_get_property(self, _STRICT_EXTRA=extra)

end

; MGHncReadFile::Open
;
; Purpose:
;   Open the netCDF file (if necessary) and return the netCDF ID
;
function MGHncReadFile::Open

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   if ~ self.is_open then begin
      self.ncid = ncdf_open(self.temp_name, /NOWRITE)
      self.is_open = !true
   endif

   return, self.ncid

end

pro MGHncReadFile::Open, RESULT=result

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = self->Open()

end

; MGHncReadFile::VarGet
;
; Purpose:
;   Retrieves data from a netCDF variable, calling the _VarGet method
;   for auto-scaling.
;
function MGHncReadFile::VarGet, var, $
     COUNT=count, OFFSET=offset, STRIDE=stride, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(var) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'var'

   if size(var, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   if n_elements(var) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'

   if strlen(var) eq 0 then $
        message, 'Variable name is invalid'

   ;; Get info about the file and the variable

   self->GetProperty, N_RECORDS=n_records, RECORDS=records, $
        UNLIMITED=unlimited

   self->VarInfo, var, N_DIMS=n_dims, DIM_NAMES=dim_names, $
        DIMENSIONS=dimensions

   ;; Process data-subset arguments. Make local copies of parameters
   ;; to avoid trampling on others' feet.

   mystride = n_elements(stride) gt 0 ? stride : replicate(1, n_dims > 1)

   myoffset = n_elements(offset) gt 0 ? offset : replicate(0, n_dims > 1)

   mycount  = n_elements(count) gt 0 ? count : (dimensions-myoffset)/mystride

   for i=0,n_elements(myoffset)-1 do begin
      if myoffset[i] lt 0 then $
           myoffset[i] = myoffset[i] + dimensions[i]/mystride[i]
   endfor

   for i=0,n_elements(mycount)-1 do begin
      if mycount[i] eq 0 then $
           mycount[i] = (dimensions[i]-myoffset[i])/mystride[i]
   endfor

   ;; Special handling is required (see below) if this variable varies
   ;; in the unlimited dimension and the records have been specified
   ;; explicitly

   special = 0B

   if (n_records gt 0) && (records[0] ge 0) && (n_dims gt 0) && $
        (dim_names[n_dims-1] eq unlimited) then begin
      special = 1B
   endif

   ;; Get data

   if special then begin

      ;; Get data one record at a time. First create an output
      ;; array, retrieving a single value to determine the data
      ;; type

      value = self->_VarGet(var, COUNT=replicate(1,n_dims), _STRICT_EXTRA=extra)

      result = make_array(VALUE=value, DIMENSION=count)

      for i=0,mycount[n_dims-1]-1 do begin

         count_i = mycount
         count_i[n_dims-1] = 1

         offset_i = myoffset
         offset_i[n_dims-1] = $
            records[myoffset[n_dims-1]+mystride[n_dims-1]*i]

         stride_i = mystride
         stride_i[n_dims-1] = 1

         ;; Get this record's data. Specify the STRIDE keyword only if
         ;; necessary because there may be bugs in IDL's handling of it.

         if max(stride_i) gt 1 then begin
            data = self->_VarGet(var, COUNT=count_i, OFFSET=offset_i, STRIDE=stride_i, _STRICT_EXTRA=extra)
         endif else begin
            data = self->_VarGet(var, COUNT=count_i, OFFSET=offset_i, _STRICT_EXTRA=extra)
         endelse

         case n_dims of
            1: result[i] = temporary(data)
            2: result[*,i] = temporary(data)
            3: result[*,*,i] = temporary(data)
            4: result[*,*,*,i] = temporary(data)
            5: result[*,*,*,*,i] = temporary(data)
            6: result[*,*,*,*,*,i] = temporary(data)
            7: result[*,*,*,*,*,*,i] = temporary(data)
            8: result[*,*,*,*,*,*,*,i] = temporary(data)
         endcase

      endfor

      return, result

   endif else begin

      ;; Get data in one operation. Specify the STRIDE keyword only if
      ;; necessary because there are bugs in IDL's handling of it.

      if max(mystride) gt 1 then begin
         return, self->_VarGet(var, COUNT=mycount, OFFSET=myoffset, STRIDE=mystride, _STRICT_EXTRA=extra)
      endif else begin
         return, self->_VarGet(var, COUNT=mycount, OFFSET=myoffset, _STRICT_EXTRA=extra)
      endelse

   endelse

end

; MGHncReadFile::_VarGet
;
; Purpose:
;   Retrieves data from a netCDF variable. This is a hidden method called
;   by the VarGet method.
;
function MGHncReadFile::_VarGet, var, AUTOSCALE=autoscale, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   if size(var, /TYPE) ne 7 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   if n_elements(var) ne 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'

   if strlen(var) eq 0 then $
      message, 'Variable name is invalid'

   self->Open

   info = ncdf_varinq(self.ncid, var)

   ncdf_varget, self.ncid, var, result, _STRICT_EXTRA=extra

   if keyword_set(autoscale) && (info.datatype ne 'CHAR') then begin

      ;; Process numeric data according to the netCDF conventions
      ;; for generic applications--see "Attributes" section of netCDF manual.

      ;; Get a list of this variable's attributes

      att_names = ''
      if info.natts gt 0 then begin
         att_names = strarr(info.natts)
         for i=0,info.natts-1 do $
            att_names[i] = ncdf_attname(self.ncid, var, i)
      endif

      ;; Determine the valid range from "valid_*" attributes

      if max(strmatch(att_names,'valid_range')) gt 0 then $
         ncdf_attget, self.ncid, var, 'valid_range', valid_range
      if n_elements(valid_range) eq 2 then begin
         valid_min = valid_range[0]
         valid_max = valid_range[1]
      endif
      if (n_elements(valid_min) eq 0) && (max(strmatch(att_names,'valid_min')) gt 0) then $
         ncdf_attget, self.ncid, var, 'valid_min', valid_min
      if (n_elements(valid_max) eq 0) && (max(strmatch(att_names,'valid_max')) gt 0) then $
         ncdf_attget, self.ncid, var, 'valid_max', valid_max

      ;; No valid range found yet, try to determine it from fill value

      if (n_elements(valid_min) eq 0) || (n_elements(valid_max) eq 0) then begin
         if info.datatype ne 'BYTE' then begin
            if max(strmatch(att_names,'_FillValue')) gt 0 then begin
               ncdf_attget, self.ncid, var, '_FillValue', fill_value
            endif else begin
               fill_value = mgh_ncdf_fill(info.datatype)
            endelse
            case info.datatype of
               'FLOAT': begin
                  mach = machar()
                  delta = abs(2*mach.eps*fill_value)
               end
               'DOUBLE': begin
                  mach = machar(/DOUBLE)
                  delta = abs(2*mach.eps*fill_value)
               end
               else: begin
                  delta = 1
               end
            endcase
            if (n_elements(valid_min) eq 0) && (fill_value lt 0) then $
               valid_min = fill_value + delta
            if (n_elements(valid_max) eq 0) && (fill_value gt 0) then $
               valid_max = fill_value - delta
         endif
      endif

      ;; Keep a record of indices of valid data

      validity = mgh_reproduce(!true, result)
      if n_elements(valid_min) gt 0 then begin
         invalid = where(result lt valid_min[0], n_invalid)
         if n_invalid gt 0 then validity[invalid] = !false
      endif
      if n_elements(valid_max) gt 0 then begin
         invalid = where(result gt valid_max[0], n_invalid)
         if n_invalid gt 0 then validity[invalid] = !false
      endif

      ;; Clear math errors

      dummy = check_math()

      ;; Now scale

      if max(strmatch(att_names,'scale_factor')) gt 0 then $
         ncdf_attget, self.ncid, var, 'scale_factor', scale_factor
      if max(strmatch(att_names,'add_offset')) gt 0 then $
         ncdf_attget, self.ncid, var, 'add_offset', add_offset

      if n_elements(scale_factor) gt 0 then scale_factor = scale_factor[0]
      if n_elements(add_offset) gt 0 then add_offset = add_offset[0]

      ;; This code ensures that if either a scale factor or offset
      ;; exists, then they both exist and have compatible data types.

      if (n_elements(scale_factor) ge 1) && (n_elements(add_offset) eq 0) then $
         add_offset = 0*scale_factor
      if (n_elements(add_offset) ge 1) && (n_elements(scale_factor) eq 0) then $
         scale_factor = 1+0*add_offset

      if n_elements(scale_factor) gt 0 then begin
         tmp = mgh_reproduce(mgh_null(scale_factor), result)
         valid = where(temporary(validity), n_valid)
         if n_valid gt 0 then $
            tmp[valid] = add_offset + result[valid]*scale_factor
         result = temporary(tmp)
      endif else begin
         invalid = where(~ temporary(validity), n_invalid)
         if n_invalid gt 0 then result[invalid] = mgh_null(result)
      endelse

   endif

   self->Close

   if info.datatype eq 'CHAR' then result = string(result)

   return, result

end

; MGHncReadFile::VarInfo (Procedure and Function)
;
; Purpose:
;   Return information about the specified variable.
;
pro MGHncReadFile::VarInfo, var, $
     ALL=all, ATT_NAMES=att_names, DATATYPE=datatype, DIM_NAMES=dim_names, $
     DIMENSIONS=dimensions, FILL_VALUE=fill_value, N_ATTS=n_atts, N_DIMS=n_dims

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(var, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'var'

   if size(var, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   if n_elements(var) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'

   if strlen(var) eq 0 then $
        message, 'Variable name is invalid'

   ;; The logic for calculating the size of the unlimited dimension is
   ;; complicated so we won't repeat it here

   if arg_present(dim_names) || arg_present(dimensions) || arg_present(n_dims) || arg_present(all) then begin
      self->GetProperty, DIM_NAMES=file_dim_names, $
           DIMENSIONS=file_dimensions, N_DIMS=file_n_dims
   endif

   self->Open

   info = ncdf_varinq(self.ncid, var)

   datatype = info.datatype

   n_atts = info.natts
   n_dims = info.ndims

   if arg_present(att_names) || arg_present(all) then begin
      if n_atts gt 0 then begin
         att_names = strarr(n_atts)
         for i=0,n_atts-1 do $
               att_names[i] = ncdf_attname(self.ncid, var, i)
      endif else begin
         att_names = ''
      endelse
   endif

   if arg_present(dim_names) || arg_present(dimensions) || arg_present(all) then begin
      if n_dims gt 0 then begin
         dim_names = file_dim_names[info.dim]
         dimensions = file_dimensions[info.dim]
      endif else begin
         dim_names = ''
         dimensions = 0
      endelse
   endif

   if arg_present(fill_value) || arg_present(all) then begin
      for i=0,n_atts-1 do begin
         if ncdf_attname(self.ncid, var, i) eq '_FillValue' then begin
            ncdf_attget, self.ncid, var, '_FillValue', fill_value
            break
         endif
      endfor
      if n_elements(fill_value) eq 0 then begin
         case info.datatype of
            'BYTE'  : fill_value = -127B ; Huh?
            'CHAR'  : fill_value = ''
            'STRING': fill_value = ''
            'SHORT' : fill_value = -32767S
            'INT'   : fill_value = -32767S
            'LONG'  : fill_value = -2147483647L
            'FLOAT' : fill_value = 9.9692099683868690E+36
            'DOUBLE': fill_value = 9.9692099683868690D+36
         endcase
      endif
   endif

   self->Close

   if arg_present(all) then $
        all = {datatype: datatype, dim_names: dim_names, dimensions: dimensions, $
               n_dims: n_dims, n_atts: n_atts, fill_value: fill_value}

end

function MGHncReadFile::VarInfo, var, $
     ATT_NAMES=att_names, DATATYPE=datatype, DIM_NAMES=dim_names, DIMENSIONS=dimensions, $
     FILL_VALUE=fill_value, N_ATTS=n_atts, N_DIMS=n_dims

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case !true of
      keyword_set(att_names): self->VarInfo, var, ATT_NAMES=result
      keyword_set(datatype): self->VarInfo, var, DATATYPE=result
      keyword_set(dim_names): self->VarInfo, var, DIM_NAMES=result
      keyword_set(dimensions): self->VarInfo, var, DIM_NAMES=result
      keyword_set(fill_value): self->VarInfo, var, FILL_VALUE=result
      keyword_set(n_atts): self->VarInfo, var, n_atts=result
      keyword_set(n_dims): self->VarInfo, var, N_DIMS=result
      else: self->VarInfo, var, ALL=result
   endcase

   return, result

end

; MGHncReadFile__Define
;
pro MGHncReadFile__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHncReadFile, inherits MGHncHelper, $
                  file_name: '', temp_name: '', ncid: 0L, is_open: !false, $
                  records: ptr_new(), vars: obj_new()}

end
