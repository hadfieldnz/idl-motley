;+
; NAME:
;   Class MGHncFile
;
; PURPOSE:
;   This class encapsulates a netCDF file for READ and WRITE
;   access. It exposes methods for manipulating dimensions, variables
;   and attributes. C.f. the MGHncReadFile class, which allows
;   read-only access.
;
; CATEGORY:
;   Scientific Data Formats.
;
; PROPERTIES:
;   ATT_NAMES (Get)
;     A list of global attributes taken from the netCDF file. If the
;     file has no attributes, then this property returns an empty string.
;     See N_ATTS.
;
;   FILE_NAME (Init, Get)
;     The name of the netCDF file wrapped by the MGHncFile object.
;
;   N_ATTS (Get)
;     The number of global attributes in the netCDF file.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1997-04:
;     Written as NcFile
;   Mark Hadfield, 1999-05:
;     Renamed to MGHncFile.
;   Mark Hadfield, 2000-05:
;     Minor changes to property & keyword names.
;   Mark Hadfield, 2000-11:
;     Retrieve method rewritten to use the MGH_STRUCT_BUILD function.
;   Mark Hadfield, 2001-06:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2001-11:
;     Major overhaul of interface along with MGHncReadFile and
;     MGHncSequence.
;   Mark Hadfield, 2003-01:
;     The VarGet method has been enhanced in the same ways as
;     MGHncReadFile's VarGet method: a zero value in the COUNT vector
;     means get all data and a negative value in the OFFSET vector
;     specifies an offset relative to the end of the dataset.
;   Mark Hadfield, 2003-05:
;     Discovered & fixed a long-standing bug in the VarGet method:
;     in the code activated by AUTOSCALE=1, the WHERE function was
;     returning a variable "count" which trampled on the keyword variable
;     of the same name. It becomes a problem when the keyword variable
;     is passed back to the caller and used in a second call to VarGet.
;     It's amazing I never hit this one before.
;   Mark Hadfield, 2003-05:
;     Code now upgraded for IDL 6.0, including its new features for
;     logical data. Added the new (experimental) NONULL keyword to
;     all calls to NCDF_ATTPUT.
;   Mark Hadfield, 2006-11:
;     Fixed bug: HasAtt didn't work on variable attributes. How did this
;     stay undiscovered for so long?!
;   Mark Hadfield, 2007-06:
;     Fixed bug reported by Metthew Savoie: UNLIMITED property incorrect
;     when the first dimension in the file is unlimited.
;   Mark Hadfield, 2009-02:
;     Corrected minor error in VarGet.
;   Mark Hadfield, 2010-10:
;     - The code in the VarInfo method to dermine the FILL_VALUE
;       property has been replaced with the corresponding code from the
;       MGHncReadFile object. It can cope with the NCDF_VARINQ function
;       returning a datatype of either 'INT' or 'SHORT' for a 2-byte
;       integer.
;     - The VarAdd method can now accept either INT or SHORT
;       keywords. Both cause the new variable to contain 2-byte
;       integer data.
;   Mark Hadfield, 2013-10:
;    - Added NETCDF3_64BIT and NETCDF4_FORMAT keywords, to be used when creating files.
;    - Removed NETCDF3_64BIT again: not available before version 8.2.1!
;   Mark Hadfield, 2014-03:
;    - An important fix to the AttPut method when writing IDL strings: the CHAR
;      keyword is now passed explicitly to NCDF_ATTPUT to ensure that strings
;      get written as the netCDF CHAR type rather than the netCDF STRING type. See
;      http://www.unidata.ucar.edu/mailing_lists/archives/netcdfgroup/2014/msg00100.html
;   Mark Hadfield, 2015-11:
;    - Removed all references to the now-obsolete MGHncFileVar class and its methods.
;   Mark Hadfield, 2015-12:
;    - Fixed bug in VarGet method: with AUTOSCALE set, the broadcasting of rescaled
;      valid values into the result array was not begin done properly. This bug was
;      introduced in revision 21 (6997ac4b6ee9328e5172836d84b03ce1c915b881).
;-
; MGHncFile::Init
;
; Purpose:
;   Initializes an MGHncFile object and either creates the associated
;   netCDF file or opens an existing one.
;
function MGHncFile::Init, file, $
     CLOBBER=clobber, CREATE=create, FILE_NAME=file_name, $
     MODIFY=modify, NETCDF4_FORMAT=netcdf4_format, TMP=tmp

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   if (n_elements(file_name) eq 0) && (n_elements(file) gt 0) then file_name = file

   if n_elements(file_name) ne 1 then $
      message, "A valid netCDF file name must be supplied."

   if size(file_name, /TNAME) ne 'STRING' then $
      message, "A valid netCDF file name must be supplied."

   self.ncid = -1

   self.file_name = file_name

   self.vars = obj_new('IDL_Container')

   mode = keyword_set(create) ? 'CREATE' : 'OPEN'

   self.writable = (mode eq 'OPEN' && keyword_set(modify)) || mode eq 'CREATE'

   if mode eq 'CREATE' then begin
      if n_elements(clobber) eq 0 then clobber = 1B
      if file_test(self.file_name) then begin
         if keyword_set(clobber) then begin
            file_delete, self.file_name
         endif else begin
            message, "The specified netCDF file already exists and cannot be overwritten unless CLOBBER is set."
         endelse
      endif
   endif

   if mode eq 'OPEN' then begin
      if ~ file_test(self.file_name, /READ) then $
         message, "The specified netCDF file cannot be read: "+self.file_name
   endif

   if keyword_set(tmp) then begin
      self.temp_name = filepath(cmunique_id()+'.nc', /TMP)
      case mode of
         'OPEN': begin
            message, /INFORM, 'Copying '+self.file_name+' to '+self.temp_name
            mgh_file_copy, self.file_name, self.temp_name
            self.ncid = ncdf_open(self.temp_name, WRITE=self.writable)
            self.define = 0
         end
         'CREATE': begin
            self.ncid = ncdf_create(self.temp_name, /CLOBBER, NETCDF4_FORMAT=netcdf4_format)
            self.define = 1
         end
      endcase
   endif else begin
      self.temp_name = self.file_name
      case mode of
         'OPEN': begin
            self.ncid = ncdf_open(self.file_name, WRITE=self.writable)
            self.define = 0
         end
         'CREATE': begin
            self.ncid = ncdf_create(self.file_name, CLOBBER=clobber, NETCDF4_FORMAT=netcdf4_format)
            self.define = 1
         end
      endcase
   endelse

   return, 1

end

; MGHncFile::Cleanup
;
; Purpose:
;   Cleans up all memory associated with the MGHncFile. Closes the
;   netCDF file and copies & deletes temporary files (if any).
;
pro MGHncFile::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.ncid ge 0 then ncdf_close, self.ncid

   if self.temp_name ne self.file_name then begin
      if self.writable then mgh_file_copy, self.temp_name, self.file_name
      file_delete, self.temp_name
   endif

   obj_destroy, self.vars

end

; MGHncFile::GetProperty
;
pro MGHncFile::GetProperty, $
     ALL=all, ATT_NAMES=att_names, DEFINE=define, DIM_NAMES=dim_names, DIMENSIONS=dimensions, $
     FILE_NAME=file_name, N_DIMS=n_dims, N_VARS=n_vars, N_ATTS=n_atts, NCID=ncid, $
     TMP=tmp, UNLIMITED=unlimited, VAR_NAMES=var_names, WRITABLE=writable

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   file_name = self.file_name
   ncid = self.ncid
   define = self.define
   writable = self.writable

   info = ncdf_inquire(self.ncid)
   n_dims  = info.ndims
   n_vars  = info.nvars
   n_atts  = info.ngatts

   tmp = self.file_name ne self.temp_name

   if arg_present(att_names) || arg_present(all) then begin
      if n_atts gt 0 then begin
         att_names = strarr(n_atts)
         for i=0,n_atts-1 do $
            att_names[i] = ncdf_attname(self.ncid, /GLOBAL, i)
      endif else begin
         att_names = ''
      endelse
   endif

   if arg_present(dim_names) || arg_present(dimensions) || arg_present(all) then begin
      if n_dims gt 0 then begin
         dim_names = strarr(n_dims)
         dimensions = lonarr(n_dims)
         for i=0,n_dims-1 do begin
            ncdf_diminq, self.ncid, i, name, dimsize
            dim_names[i] = name
            dimensions[i] = dimsize
         endfor
      endif else begin
         dim_names = ''
         dimensions = 0
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

   if arg_present(unlimited) || arg_present(all) then begin
      if info.recdim gt 0 then begin
         ncdf_diminq, self.ncid, info.recdim, unlimited, void
      endif else begin
         unlimited = ''
      endelse
   endif

   if arg_present(all) then $
        all = {att_names:att_names, dim_names:dim_names, dimensions:dimensions, $
               file_name:file_name, n_atts:n_atts, n_dims:n_dims, n_vars:n_vars, $
               ncid:ncid, tmp:tmp, unlimited:unlimited, var_names:var_names, $
               define:define, writable:writable}

end

; MGHncFile::AttAdd
;
; Purpose:
;   Add an attribute to the netCDF file.
;
pro MGHncFile::AttAdd, P1, P2, P3, GLOBAL=global, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if ~ self.writable then $
        message, /INFORM, "Can't add attributes to a READONLY netCDF."

   self->SetMode, /DEFINE

   if keyword_set(global) then begin
      if size(P2, /TYPE) eq 7 then begin
        ncdf_attput, self.ncid, /GLOBAL, P1, P2, /CHAR, _STRICT_EXTRA=extra
      endif else begin
        ncdf_attput, self.ncid, /GLOBAL, P1, P2, /NONULL, _STRICT_EXTRA=extra
      endelse
   endif else begin
     if size(P3, /TYPE) eq 7 then begin
       ncdf_attput, self.ncid, P1, P2, P3, /CHAR, _STRICT_EXTRA=extra
     endif else begin
      ncdf_attput, self.ncid, P1, P2, P3, /NONULL, _STRICT_EXTRA=extra
     endelse
   endelse

end

; MGHncFile::AttCopy
;
; Purpose:
;   Copy the specified attribute(s) from another netCDF file to the
;   current one.
;
pro MGHncFile::AttCopy, osrc, P1, P2, GLOBAL=global, UNPACK=unpack

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(global) then begin
      if n_elements(P1) eq 0 then begin
         P1 = osrc->AttNames(/GLOBAL, COUNT=n_atts)
         if n_atts eq 0 then return
      endif
      for i=0,n_elements(P1)-1 do $
         self->AttAdd, /GLOBAL, P1[i], osrc->AttGet(/GLOBAL, P1[i])
   endif else begin
      if n_elements(P1) ne 1 || size(P1, /TYPE) ne 7 then $
         message, 'Variable name argument must be a scalar string'
      if n_elements(P2) eq 0 then begin
         P2 = osrc->AttNames(P1, COUNT=n_atts)
         if n_atts eq 0 then return
      endif
      if keyword_set(unpack) then begin
         ;; If the UNPACK keyword is set, then we expect to be writing data
         ;; that has been autoscaled to the new variable.
         att_skip = ['add_offset','scale_factor','valid_min','valid_max','valid_range','_FillValue']
      endif else begin
         att_skip = !null
      endelse
      for i=0,n_atts-1 do begin
         skip = 0B
         for j=0,n_elements(att_skip)-1 do begin
            if P2[i] eq att_skip[j] then begin
               skip = 1B
               break
            endif
         endfor
         if ~ skip then begin
            att_name = P2[i]
            att_value = osrc->AttGet(P1, P2[i])
            ;; Special handling for the time coordinate "units" variable, but only in
            ;; the ROMS-supported "seconds" form. See section 4.4 in
            ;;
            ;;   http://www.cgd.ucar.edu/cms/eaton/netcdf/CF-20010629.htm
            if att_name eq 'units' && strmatch(att_value, 'seconds since *') then $
               att_value = mgh_str_subst(att_value, 'seconds', 'days')
            self->AttAdd, P1, att_name, att_value
         endif
      endfor
   endelse

end

; MGHncFile::AttGet
;
; Purpose:
;   Returns the value of an attribute in the netCDF file. Includes
;   workaround for NCDF_ATTGET bug: an attribute of netCDF type CHAR
;   is read as BYTE
;
function MGHncFile::AttGet, P1, P2, GLOBAL=global

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(global) then begin
      info = ncdf_attinq(self.ncid, /GLOBAL, P1)
      ncdf_attget, self.ncid, /GLOBAL, P1, result
   endif else begin
      info = ncdf_attinq(self.ncid, P1, P2)
      ncdf_attget, self.ncid, P1, P2, result
   endelse

   if info.datatype eq 'CHAR' then result = string(result)

   return, result

end

; MGHncFile::DimAdd
;
; Purpose:
;   Add a dimension to the netCDF file.
;
pro MGHncFile::DimAdd, DimName, DimSize

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ self.writable then $
        message, /inform, "Can't add dimensions to a READONLY netCDF."

   self->SetMode, /DEFINE

   if n_elements(dimsize) gt 0 then begin
      dimid = ncdf_dimdef(self.ncid, DimName, DimSize)
   endif else begin
      dimid = ncdf_dimdef(self.ncid, DimName, /UNLIMITED)
   endelse

end

; MGHncFile::DimCopy
;
; Purpose:
;   Copy one or more dimensions from another netCDF file to the current one.
;   The dims argument specifies the dimension(s) to be copied; if it is
;   omitted then all dimensions are copied.
;
pro MGHncFile::DimCopy, osrc, dims

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(osrc) ne 1 then $
        message, 'A single argument must be supplied specifying a netCDF-like object'

   if ~ obj_valid(osrc) then $
        message, 'A single argument must be supplied specifying a netCDF-like object'

   n_dims = n_elements(dims)

   if n_dims eq 0 then $
        osrc->GetProperty, DIM_NAMES=dims, N_DIMS=n_dims

   for i=0,n_dims-1 do begin
      diminfo = osrc->DimInfo(dims[i])
      if diminfo.is_unlimited then begin
         self->DimAdd, dims[i]
      endif else begin
         self->DimAdd, dims[i], diminfo.dimsize
      endelse
   endfor

end


; MGHncFile::DimInfo (Procedure and Function)
;
; Purpose:
;   Return information about a netCDF dimension.
;
pro MGHncFile::DimInfo, dim, ALL=all, DIMSIZE=dimsize, IS_UNLIMITED=is_unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(dim) eq 0 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'dim'

   if n_elements(dim) gt 1 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'dim'

   if size(dim, /TYPE) ne 7 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'dim'

   pos = ncdf_dimid(self.ncid, dim)

   ncdf_diminq, self.ncid, pos, name, dimsize

   d = ncdf_inquire(self.ncid)
   is_unlimited = pos eq d.recdim

   if arg_present(all) then all = {dimsize: dimsize, is_unlimited: is_unlimited}

end

function MGHncFile::DimInfo, dim, DIMSIZE=dimsize, IS_UNLIMITED=is_unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1 of
      keyword_set(dimsize): self->DimInfo, dim, DIMSIZE=result
      keyword_set(is_unlimited): self->DimInfo, dim, IS_UNLIMITED=result
      else: self->DimInfo, dim, ALL=result
   endcase

   return, result

end

; MGHncFile::HasAtt
;
; Purpose:
;   Returns 1 if the specified attribute is found, otherwise 0.
;
function MGHncFile::HasAtt, P1, P2, GLOBAL=global

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = 0B

   if keyword_set(global) then begin

      info = ncdf_inquire(self.ncid)
      count = info.ngatts
      for i=0,count-1 do begin
         if strmatch(P1, ncdf_attname(self.ncid, /GLOBAL, i)) then begin
            result = 1B
            break
         endif
      endfor

   endif else begin

      if size(P1, /TYPE) ne 7 then $
         message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'P1'
      if n_elements(P1) ne 1 then $
         message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'P1'
      if strlen(P1) eq 0 then $
         message, 'Variable name is invalid'
      info = ncdf_varinq(self.ncid, P1)
      count  = info.natts
      for i=0,count-1 do begin
         if strmatch(P2, ncdf_attname(self.ncid, P1, i)) then begin
            result = 1B
            break
         endif
      endfor

   endelse

   return, result

end

; MGHncFile::HasDim
;
; Purpose:
;   Indicates whether a netCDF file has a dimension with the specified
;   name
;
function MGHncFile::HasDim, name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = 0B

   info = ncdf_inquire(self.ncid)

   for d=0,info.ndims-1 do begin
      ncdf_diminq, self.ncid, d, d_name, dimsize
      if strmatch(d_name, name) then return, 1B
   endfor

   return, 0B

end

; MGHncFile::HasVar
;
; Purpose:
;   Indicates whether a netCDF file has a variable with the specified
;   name
;
function MGHncFile::HasVar, Name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   info = ncdf_inquire(self.ncid)

   for i=0,info.nvars-1 do begin
      info = ncdf_varinq(self.ncid, i)
      if strmatch(info.name, name) then return, 1B
   endfor

   return, 0B

end

; MGHncFile::Info
;
; Purpose:
;   Retrieve information about the netCDF file object. A synonym for
;   GetProperty.
;
pro MGHncFile::Info, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, _STRICT_EXTRA=extra

end

function MGHncFile::Info, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, mgh_get_property(self, _STRICT_EXTRA=extra)

end

; MGHncFile::SetMode
;
; Purpose:
;   Forces the netCDF into DEFINE or DATA mode, as specified.  Has no
;   effect if the netCDF is already in the specified mode.  This
;   routine is provided for use by MGHncFile methods and
;   should not need to be called otherwise.
;
pro MGHncFile::SetMode, DEFINE=define, DATA=data

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(define) && keyword_set(data) then $
      message, /INFORM, 'Both keywords set, DEFINE takes precedence.'

   if keyword_set(define) then begin
      if self.define ne 1 then begin
         ncdf_control, self.ncid, /REDEF
         self.define = 1
      endif
      return
   endif

   if keyword_set(data) then begin
      if self.define ne 0 then begin
         ncdf_control, self.ncid, /ENDEF
         self.define = 0
      endif
      return
   endif

end

; MGHncFile::Sync
;
; Purpose:
;   Flushes changes in the netCDF file to disk.
;
pro MGHncFile::Sync

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if ~ self.writable then begin
    message, /INFORM, "Can't synchronise a READONLY netCDF."
    return
  endif

  self->SetMode, /DATA

  ncdf_control, self.ncid, /SYNC

end

; MGHncFile::VarAdd
;
; Purpose:
;   Add a variable to a netCDF file.
;
;   The netCDF variable type can be specified via the various keywords
;   (BYTE, CHAR, etc) accepted by NCDF_VARDEF or via the NCTYPE
;   keyword, which accepts a string argument.
;
pro MGHncFile::VarAdd, var, Dims, $
     BYTE=kbyte, CHAR=kchar, INT=kint, SHORT=kshort, LONG=klong, FLOAT=kfloat, $
     DOUBLE=kdouble, STRING=kstring, NCTYPE=nctype

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ self.writable then $
        message, /INFORM, "Can't add variables to a READONLY netCDF."

   self->SetMode, /DEFINE

   if n_elements(nctype) gt 0 then begin
      case strupcase(nctype) of
         'BYTE'  : kbyte = 1
         'CHAR'  : kchar = 1
         'SHORT' : kshort = 1
         'INT'   : kint = 1
         'LONG'  : klong = 1
         'FLOAT' : kfloat = 1
         'DOUBLE': kdouble = 1
         'STRING': kstring = 1
      endcase
   endif

   if keyword_set(kint) then kshort = 1

   n_dims = n_elements(Dims)
   if n_dims eq 1 then if strlen(dims[0]) eq 0 then n_dims = 0

   if n_dims gt 0 then begin
      pos = lonarr(n_dims)
      for i=0,n_dims-1 do $
         pos[i] = ncdf_dimid(self.ncid, dims[i])
      varid = ncdf_vardef(self.ncid, var, pos, $
         BYTE=kbyte, CHAR=kchar, SHORT=kshort, LONG=klong, $
         FLOAT=kfloat, DOUBLE=kdouble, STRING=kstring)
   endif else begin
      varid = ncdf_vardef(self.ncid, var, $
         BYTE=kbyte, CHAR=kchar, SHORT=kshort, LONG=klong, $
         FLOAT=kfloat, DOUBLE=kdouble, STRING=kstring)
   endelse

end

; MGHncFile::VarCopy
;
; Purpose:
;   Copy the specified variable(s) from another netCDF file to the
;   current one.
;
pro MGHncFile::VarCopy, osrc, vars, $
     ATTRIBUTES=attributes, DATA=data, DEFINITIONS=definitions, UNPACK=unpack, RENAME=rename

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(osrc) ne 1 || size(osrc, /TYPE) ne 11 then $
        message, 'Source-netCDF argument is not a scalar object reference'

   if ~ obj_valid(osrc) then $
        message, 'Source-netCDF argument is not a valid object reference'

   if n_elements(vars) eq 0 then begin
      vars = osrc->VarNames(COUNT=count)
      if count eq 0 then return
   endif

   rename = n_elements(rename) gt 0 ? rename : vars

   if n_elements(rename) ne n_elements(vars) then $
        message, 'Number of new names does not match number of variables'

   for i=0,n_elements(vars)-1 do begin

      osrc->VarInfo, vars[i], ALL=info

      if keyword_set(unpack) then info.datatype = 'FLOAT'

      if keyword_set(definitions) then begin
         self->VarAdd, rename[i], info.dim_names, NCTYPE=info.datatype
      endif else begin
         if ~ self->HasVar(rename[i]) then begin
            fmt = '(%"Variable definitions are not being copied & destination does not have a variable with this name: %s")'
            message, string(FORMAT=fmt, rename[i])
         endif
      endelse

      if keyword_set(attributes) then self->AttCopy, osrc, vars[i], UNPACK=unpack

      if keyword_set(data) then $
           self->VarPut, rename[i], osrc->VarGet(vars[i], AUTOSCALE=unpack)

   endfor

end

; MGHncFile::VarGet
;
; Purpose:
;   Retrieves data from a netCDF variable.
;
function MGHncFile::VarGet, var, $
     AUTOSCALE=autoscale, COUNT=count, OFFSET=offset, STRIDE=stride

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(var, /TYPE) ne 7 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   if n_elements(var) ne 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'

   if strlen(var) eq 0 then $
      message, 'Variable name is invalid'

   ;; Get info about the variable

   self->VarInfo, var, $
      ATT_NAMES=att_names, DATATYPE=datatype, $
      DIMENSIONS=dimensions, N_ATTS=n_atts, N_DIMS=n_dims

   ;; Process data-subset arguments. Make local copies of parameters
   ;; to avoid trampling on others' feet.

   if n_elements(stride) gt 0 then begin
      mystride = stride
   endif else begin
      mystride = replicate(1, n_dims > 1)
   endelse

   if n_elements(offset) gt 0 then begin
      myoffset = offset
   endif else begin
      myoffset = replicate(0, n_dims > 1)
   endelse

   if n_elements(count) gt 0 then begin
      mycount = count
   endif else begin
      mycount = (dimensions-myoffset)/mystride
   endelse

   for i=0,n_elements(myoffset)-1 do begin
      if myoffset[i] lt 0 then $
         myoffset[i] = myoffset[i] + dimensions[i]/mystride[i]
   endfor

   for i=0,n_elements(mycount)-1 do begin
      if mycount[i] eq 0 then $
         mycount[i] = (dimensions[i]-myoffset[i])/mystride[i]
   endfor

   ;; Get data. Specify the STRIDE keyword only if necessary because there may
   ;; be bugs in IDL's handling of it.

   ;; This line of code seems to be unnecessary. (Oh no it isn't!!!)
   self->SetMode, /DATA

   if max(mystride) gt 1 then begin
      ncdf_varget, self.ncid, var, result, COUNT=mycount, OFFSET=myoffset, STRIDE=mystride
   endif else begin
      ncdf_varget, self.ncid, var, result, COUNT=mycount, OFFSET=myoffset
   endelse

   ;; Process numeric data according to the netCDF conventions for
   ;; generic applications--see "Attributes" section of netCDF manual.

   if keyword_set(autoscale) and datatype ne 'CHAR' then begin

      ;; Determine the valid range from "valid_*" attributes

      if max(strmatch(att_names,'valid_range')) gt 0 then $
         ncdf_attget, self.ncid, var, 'valid_range', valid_range
      if n_elements(valid_range) eq 2 then begin
         valid_min = valid_range[0]
         valid_max = valid_range[1]
      endif
      if (n_elements(valid_min) eq 0) && $
         (max(strmatch(att_names,'valid_min')) gt 0) then $
         ncdf_attget, self.ncid, var, 'valid_min', valid_min
      if (n_elements(valid_max) eq 0) && $
         (max(strmatch(att_names,'valid_max')) gt 0) then $
         ncdf_attget, self.ncid, var, 'valid_max', valid_max

      ;; No valid range found yet, try to determine it from fill value

      if (n_elements(valid_min) eq 0) || (n_elements(valid_max) eq 0) then begin
         if datatype ne 'BYTE' then begin
            if max(strmatch(att_names, '_FillValue')) gt 0 then begin
               ncdf_attget, self.ncid, var, '_FillValue', fill_value
            endif else begin
               fill_value = mgh_ncdf_fill(datatype)
            endelse
            case datatype of
               'FLOAT': begin
                  mach = machar()
                  delta = 2*mach.eps*fill_value
               end
               'DOUBLE': begin
                  mach = machar(/DOUBLE)
                  delta = 2*mach.eps*fill_value
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

      valid = mgh_reproduce(1B, result)
      if n_elements(valid_min) gt 0 then begin
         l_invalid = where(finite(result) and result lt valid_min[0], n_invalid)
         if n_invalid gt 0 then valid[l_invalid] = 0B
      endif
      if n_elements(valid_max) gt 0 then begin
         l_invalid = where(finite(result) and result gt valid_max[0], n_invalid)
         if n_invalid gt 0 then valid[l_invalid] = 0B
      endif

      ;; Clear math errors

      dummy = check_math()

      ;; Now scale

      if max(strmatch(att_names,'scale_factor')) gt 0 then begin
         ncdf_attget, self.ncid, var, 'scale_factor', scale_factor
         scale_factor = scale_factor[0]
      endif
      if max(strmatch(att_names,'add_offset')) gt 0 then begin
         ncdf_attget, self.ncid, var, 'add_offset', add_offset
         add_offset = add_offset[0]
      endif

      ;; This code ensures that if either a scale factor or offset
      ;; exists, then they both exist and have compatible data types.

      if (n_elements(scale_factor) ge 1) && (n_elements(add_offset) eq 0) then $
         add_offset = 0*scale_factor
      if (n_elements(add_offset) ge 1) && (n_elements(scale_factor) eq 0) then $
         scale_factor = 1+0*add_offset

      if n_elements(scale_factor) gt 0 then begin
         tmp = mgh_reproduce(mgh_null(scale_factor), result)
         l_valid = where(valid, n_valid)
         if n_valid gt 0 then tmp[l_valid] = add_offset + result[l_valid]*scale_factor
         result = temporary(tmp)
      endif else begin
         l_invalid = where(~ valid, n_invalid)
         if n_invalid gt 0 then result[l_invalid] = mgh_null(result)
      endelse

   endif

   ;; Return result

   if datatype eq 'CHAR' then result = string(result)

   return, result

end

; MGHncFile::VarInfo (Procedure and Function)
;
; Purpose:
;   Return information about the specified variable.
;
pro MGHncFile::VarInfo, var, $
     ALL=all, ATT_NAMES=att_names, DATATYPE=datatype, DIM_NAMES=dim_names, $
     DIMENSIONS=dimensions, FILL_VALUE=fill_value, N_ATTS=n_atts, N_DIMS=n_dims

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(var, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'var'

   if n_elements(var) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'var'

   if strlen(var) eq 0 then $
        message, 'Variable name is invalid'

   info = ncdf_varinq(self.ncid, var)

   datatype = info.datatype

   n_atts = info.natts

   n_dims = info.ndims

   if arg_present(att_names) || arg_present(fill_value) || arg_present(all) then begin
      if n_atts gt 0 then begin
         att_names = strarr(info.natts)
         for i=0,n_atts-1 do $
            att_names[i] = ncdf_attname(self.ncid, var, i)
      endif else begin
         att_names = ''
      endelse
   endif

   if arg_present(dim_names) || arg_present(dimensions) || arg_present(all) then begin
      if n_dims gt 0 then begin
         dim_names = strarr(info.ndims)
         dimensions = lonarr(info.ndims)
         for i=0,info.ndims-1 do begin
            ncdf_diminq, self.ncid, info.dim[i], name, dimsize
            dim_names[i] = name
            dimensions[i] = dimsize
         endfor
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
            'SHORT' : fill_value = -32767S
            'INT'   : fill_value = -32767S
            'LONG'  : fill_value = -2147483647L
            'FLOAT' : fill_value = 9.9692099683868690E+36
            'DOUBLE': fill_value = 9.9692099683868690D+36
         endcase
      endif

   endif

   if arg_present(all) then $
        all = {att_names:att_names, datatype:datatype, dim_names:dim_names, $
               dimensions:dimensions, n_dims:n_dims, n_atts:n_atts, $
               fill_value: fill_value}

end

function MGHncFile::VarInfo, var, $
     ATT_NAMES=att_names, DATATYPE=datatype, DIM_NAMES=dim_names, $
     DIMENSIONS=dimensions, FILL_VALUE=fill_value, N_ATTS=n_atts, N_DIMS=n_dims

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1 of
      keyword_set(att_names): self->VarInfo, var, ATT_NAMES=result
      keyword_set(datatype): self->VarInfo, var, DATATYPE=result
      keyword_set(dim_names): self->VarInfo, var, DIM_NAMES=result
      keyword_set(dimensions): self->VarInfo, var, DIMENSIONS=result
      keyword_set(fill_value): self->VarInfo, var, FILL_VALUE=result
      keyword_set(n_atts): self->VarInfo, var, N_ATTS=result
      keyword_set(n_dims): self->VarInfo, var, N_DIMS=result
      else: self->VarInfo, var, ALL=result
   endcase

   return, result

end

; MGHncFile::VarPut
;
; Purpose:
;   Writes data to the netCDF variable.
;
pro MGHncFile::VarPut, var, value, AUTOSCALE=autoscale, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(var) ne 1 || size(var, /TYPE) ne 7 then $
        message, 'Variable-name argument must be a scalar string'

   if strlen(var) eq 0 then $
        message, 'Variable name is invalid'

   if ~ self.writable then $
        message, /INFORM, "Can't write data to a READONLY netCDF."

   self->SetMode, /DATA

   self->VarInfo, var, $
      ATT_NAMES=att_names, DATATYPE=datatype

   ;; Determine if the data are to be scaled before writing

   scaling = $
      keyword_set(autoscale) && (datatype ne 'CHAR') && $
      (max(strmatch(att_names,'scale_factor')) gt 0 || max(strmatch(att_names,'add_offset')) gt 0)

   if scaling then begin

      if max(strmatch(att_names,'scale_factor')) gt 0 then begin
         ncdf_attget, self.ncid, var, 'scale_factor', scale_factor
         scale_factor = double(scale_factor[0])
      endif else begin
         scale_factor = 1.0D0
      endelse
      if max(strmatch(att_names,'add_offset')) gt 0 then begin
         ncdf_attget, self.ncid, var, 'add_offset', add_offset
         add_offset = double(add_offset[0])
      endif else begin
         add_offset = 0.0D0
      endelse

      ;; Determine the fill value. This is the dodgiest part of the whole process
      ;; as it ignores any valid_range, valid_min and valid_max attributes in the
      ;; destination variable.

      if max(strmatch(att_names, '_FillValue')) gt 0 then begin
         ncdf_attget, self.ncid, var, '_FillValue', fill_value
      endif else begin
         fill_value = mgh_ncdf_fill(datatype)
      endelse

      ;; Scale non-missing data. Results are always rounded, even if destination
      ;; variable is non-integral.

      my_value = mgh_reproduce(fill_value, value)

      l_valid = where(finite(value), n_valid)
      if n_valid gt 0 then my_value[l_valid] = round((value[l_valid]-add_offset)/scale_factor)

      ;; Write scaled data to file

      ncdf_varput, self.ncid, var, my_value, _STRICT_EXTRA=extra

   endif else begin

      ncdf_varput, self.ncid, var, value, _STRICT_EXTRA=extra

   endelse


end

; MGHncFile__Define
;
pro MGHncFile__define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGHncFile, inherits MGHncHelper, $
                 file_name: '', temp_name: '', format: '', $
                 vars: obj_new(), writable: 0B, define: 0B, ncid: 0L}

end

