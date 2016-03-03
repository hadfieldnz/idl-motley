;+
; NAME:
;   Class MGHncSequence
;
; PURPOSE:
;   This class allows read-only access to a sequence of netCDF
;   files. A virtual unlimited dimension is constructed so that the
;   sequence of files can be treated as a single netCDF file. (See
;   documentation below, especially the ENSEMBLE and UNLIMITED
;   properties.) It was inspired by the NCO operators ncrcat and
;   ncecat, see:
;
;     http://nco.sourceforge.net/nco.html#ncecat-netCDF-Ensemble-Concatenator
;     http://nco.sourceforge.net/nco.html#ncrcat-netCDF-Record-Concatenator
;
; PROPERTIES:
;   ENSEMBLE (Init, Get)
;     Set this property to 1 to indicate that the files in the
;     sequence are to be treated as an ensemble in the sense used in
;     the NCO documentation, i.e. a synthetic unlimited dimension is
;     constructed, with each netCDF file object corresponding to one
;     record. If this property is 0 (the default) then the files are
;     concatenated along a dimension that they all share. See
;     UNLIMITED property.
;
;   FILE_N_RECORDS (Get)
;     An integer array with dimension N_FILES giving the number of
;     records in each of the netCDF files in the sequence
;
;   FILE_NAME (Init, Get)
;     A string array with dimension N_FILES giving the name of each of
;     the netCDF files in the sequence. If a single-element string is
;     passed to the Init method, then an attempt is made to expand it
;     using findfile.
;
;   FILE_OFFSET (Get)
;     An integer array with dimension N_FILES giving the position, for
;     each of the netCDF files, of the file's first record in the
;     sequence of records formed by all the files.
;
;   NAME (Init, Get, Set)
;     An identifying string. Default is the empty string.
;
;   N_FILES (Get)
;     The number of MGHncReadFile objects in the sequence.
;
;   N_RECORDS (Get)
;     The total number of records
;
;   TMP (Init)
;     This property is passed to all MGHncReadFile objects created
;     during initialisation. If it is set, then a temporary copy is
;     made of each of the netCDF files.
;
;   UNLIMITED (Init, Get)
;     This property is the name of the sequence's unlimited
;     dimension. Its value depends on the value of the ENSEMBLE
;     property:
;
;       ENSEMBLE=0: The sequence's unlimited dimension must be shared
;       by all the files in the sequence. By default it is determined
;       from the unlimited dimension of of the first file added to the
;       sequence, but it can also be specified when the sequence is
;       initialised. The MGHncSequence object also supports the
;       special case where no unlimited dimension is specified and a
;       single netCDF file with no unlimited dimension is added; in
;       this case the sequence has no unlimited dimension.
;
;       ENSEMBLE=1: The sequence's unlimited dimension is a synthetic
;       dimension corresponding to file number. The default value is
;       'record' but any other name can be specified.
;
;###########################################################################
; Copyright (c) 1999-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-05:
;     Written.
;   Mark Hadfield, 2001-06:
;     * Updated for IDL 5.5.
;     * Added support for ensemble-type sequences.
;   Mark Hadfield, 2001-11:
;     Major overhaul of interface along with MGHncFile and MGHncReadFile.
;   Mark Hadfield, 2002-03:
;     * Added TMP keyword.
;     * Added support for wrapping a single file with no unlimited
;     dimension. This makes subclasses like MGHromsHistory more
;     versatile.
;   Mark Hadfield, 2009-10:
;     Removed calls to widget_event(/NOWAIT).
;   Mark Hadfield, 2010-09:
;     I achieved a *major* speed-up in MGHncSequence::VarGet for sequences
;     containing a large number of files (~1000 or more) by removing a call to
;     MGHncSequence::VarInfo from inside the files loop to outside the loop.
;   Mark Hadfield, 2010-11:
;     Fixed bug introduced by IDL 8.0: the datatype name returned for
;     short-integer netCDF variables changed from "SHORT" to "INT', breaking
;     the data-unpacking code.
;   Mark Hadfield, 2015-03:
;     The Add method no longer checks that the objects being added are of type
;     MGHncReadFile. This allows, for example, the addition of MGHncSequence
;     objects to allow concatenation in more than one dimension. However this
;     functionality still has some bugs: something to do with recursive calls
;     to VarGet.
;   Mark Hadfield, 2015-11:
;     Removed support for the ERR_STRING keyword in the HasVar method.
;   Mark Hadfield, 2016-03:
;     Simplified the logic in the GetProperty method (without breaking it, I hope).
;-
; MGHncSequence::Init
;
function MGHncSequence::Init, files, $
     ENSEMBLE=ensemble, FILE_NAME=file_name, NAME=name, TMP=tmp, UNLIMITED=unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.ensemble = keyword_set(ensemble)

   self.name = n_elements(name) gt 0 ? name : ''

   if self.ensemble then begin
      self.unlimited = n_elements(unlimited) gt 0 ? unlimited : 'record'
   endif else begin
      self.unlimited = n_elements(unlimited) gt 0 ? unlimited : ''
   endelse

   if n_elements(file_name) eq 0 && n_elements(files) gt 0 then $
        file_name = files

   self.ncfiles = obj_new('IDL_Container')

   if n_elements(file_name) gt 0 then begin
      if n_elements(file_name) eq 1 then begin
         f0 = file_name[0]
         if strlen(f0) eq 0 then $
              message, 'File name pattern is empty'
         fn = file_search(f0, COUNT=n_files)
         if n_files eq 0 then $
              message, 'No matching files found: '+f0
      endif else begin
         fn = file_name
      endelse
      foreach f, fn do $
           self->Add, obj_new('MGHncReadFile', FILE_NAME=f, TMP=tmp)
   endif

   return, 1

end

; MGHncSequence::Cleanup
;
pro MGHncSequence::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.ncfiles

end

; MGHncSequence::GetProperty
;
pro MGHncSequence::GetProperty, $
     ALL=all, ATT_NAMES=att_names, $
     DIM_NAMES=dim_names, DIMENSIONS=dimensions, $
     ENSEMBLE=ensemble, $
     FILE_N_RECORDS=file_n_records, $
     FILE_NAME=file_name, FILE_OFFSET=file_offset, $
     N_ATTS=n_atts, N_DIMS=n_dims, $
     N_FILES=n_files, N_RECORDS=n_records, $
     N_VARS=n_vars, NAME=name, $
     UNLIMITED=unlimited, VAR_NAMES=var_names, $
     WRITABLE=writable

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ensemble = self.ensemble

   name = self.name

   n_files = self.ncfiles->Count()

   writable = !false

   if arg_present(att_names) || arg_present(n_atts) || arg_present(all) then begin
      if n_files gt 0 then begin
         onc = self.ncfiles->Get()
         onc->GetProperty, ATT_NAMES=att_names, N_ATTS=n_atts
      endif else begin
         n_atts = 0
         att_names = ''
      endelse
   endif

   if arg_present(var_names) || arg_present(n_vars) || arg_present(all) then begin
      if n_files gt 0 then begin
         onc = self.ncfiles->Get()
         onc->GetProperty, VAR_NAMES=var_names, N_VARS=n_vars
      endif else begin
         n_vars = 0
         var_names = ''
      endelse
   endif

   if arg_present(file_name) || arg_present(all) then begin
      if n_files gt 0 then begin
         file_name = strarr(n_files)
         for i=0,n_files-1 do begin
            onc = self.ncfiles->Get(POSITION=i)
            onc->GetProperty, FILE=file
            file_name[i] = file
         endfor
      endif else begin
         file_name = ''
      endelse
   endif

   if arg_present(dim_names) || arg_present(n_dims) || arg_present(n_records) || arg_present(file_offset) || $
      arg_present(file_n_records) || arg_present(unlimited) || arg_present(all) then begin
      unlimited = self.unlimited
      if n_files gt 0 then begin
         if self.ensemble then begin
            onc = self.ncfiles->Get()
            onc->GetProperty, N_DIMS=n_dims, DIM_NAMES=dim_names, DIMENSIONS=dimensions
            if n_dims gt 0 then begin
               dim_names = [dim_names,unlimited]
               dimensions = [dimensions,n_files]
            endif else begin
               dim_names = unlimited
               dimensions = [n_files]
            endelse
            n_dims = n_dims + 1
            n_records = n_files
            file_n_records = replicate(1, n_files)
            file_offset = lindgen(n_files)
         endif else begin
            onc = self.ncfiles->Get()
            onc->GetProperty, N_DIMS=n_dims, DIM_NAMES=dim_names, DIMENSIONS=dimensions
            n_records = 0
            file_n_records = lonarr(n_files)
            file_offset = lonarr(n_files)
            onc = self.ncfiles->Get(/ALL)
            for f=0,n_files-1 do begin
               n = strlen(unlimited) eq 0 ? 0 : onc[f]->DimInfo(unlimited, /DIMSIZE)
               file_n_records[f] = n
               n_records = n_records + n
               if f gt 0 then $
                  file_offset[f] = file_offset[f-1] + file_n_records[f-1]
            endfor
            dimensions[n_dims-1] = n_records
         endelse
      endif else begin
         dim_names = ''
         n_dims = -1
         n_records = -1
         file_offset = -1
         file_n_records = -1
      endelse
   endif

   if arg_present(all) then $
        all = {att_names:att_names, dim_names:dim_names, dimensions:dimensions, $
               ensemble:ensemble, file_n_records:file_n_records, $
               file_name:file_name, file_offset:file_offset, n_atts:n_atts, $
               n_dims:n_dims, n_files:n_files, n_records:n_records, $
               n_vars:n_vars, name:name, unlimited:unlimited, $
               var_names:var_names, writable:writable}

end

; MGHncSequence::SetProperty
;
pro MGHncSequence::SetProperty, NAME=name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(name) gt 0 then self.name = name

end

; MGHncSequence::Add
;
; Purpose:
;   Given a list of MGHncReadFile objects, this method adds them all
;   to the ncfiles container, checking to ensure they all have the
;   same unlimited dimension.
;
pro MGHncSequence::Add, file, _REF_EXTRA=extra

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if size(file, /TNAME) ne 'OBJREF' then $
    message, 'A list of object references must be supplied'

  n_file = n_elements(file)

  if n_file eq 0 then return

  for i_file=0,n_file-1 do begin

    ofile = file[i_file]

    if ~ self.ensemble then begin

      ;; If the name of the sequence's unlimited dimension has not
      ;; yet been established, take it from the current
      ;; file. Otherwise check that the current file has the
      ;; unlimited dimension. This code allows there to be only one
      ;; file in the sequence, with no unlimited dimension. In that
      ;; case the MGHncSequence object should act like an
      ;; MGHncReadFile object with no unlimited dimension.

      if strlen(self.unlimited) eq 0 then begin
        self.unlimited = ofile->DimNames(/UNLIMITED)
      endif else begin
        if ~ ofile->HasDim(self.unlimited) then begin
          fmt = '(%"Sequence unlimited dimension not found in netCDF file at index %d")'
          message, string(FORMAT=fmt, i_file)
        endif
      endelse

    endif

    self.ncfiles->Add, ofile, _STRICT_EXTRA=extra

  endfor

end

; MGHncSequence::AttGet
;
; Purpose:
;   Returns the value of an attribute (from the first netCDF file).
;
function MGHncSequence::AttGet, P1, P2, GLOBAL=global

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = -1

   self->GetProperty, N_FILES=n_files

   if n_files gt 0 then begin

      onc = self.ncfiles->Get(POSITION=0)

      if keyword_set(global) then begin
        result = onc->AttGet(/GLOBAL, P1)
      endif else begin
        result = onc->AttGet(P1, P2)
      endelse

   endif

   return, result

end

; MGHncSequence::Count
;
; Purpose:
;   Returns the number of NcFile objects in the container
;
function MGHncSequence::Count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.ncfiles->Count()

end

; MGHncSequence::DimInfo (Function)
;
; Purpose:
;   Returns information about a netCDF dimension. There is special
;   handling for the unlimited dimension.
;
pro MGHncSequence::DimInfo, Dim, $
     ALL=all, DIMSIZE=dimsize, IS_UNLIMITED=is_unlimited

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(dim) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'dim'

   if size(dim, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'dim'

   if n_elements(dim) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'dim'

   if strlen(dim) eq 0 then $
        message, 'Dimension name is invalid'

   self->GetProperty, N_FILES=n_files, UNLIMITED=unlimited

   is_unlimited = (dim eq unlimited)

   if n_files gt 0 then begin
      if is_unlimited then begin
         self->GetProperty, N_RECORDS=dimsize
      endif else begin
         onc = self.ncfiles->Get()
         onc->DimInfo, dim, DIMSIZE=dimsize
      endelse
   endif else begin
      dimsize = 0
   endelse

   if arg_present(all) then $
        all = {dimsize: dimsize, is_unlimited: is_unlimited}

end

function MGHncSequence::DimInfo, dim, $
     DIMSIZE=dimsize, IS_UNLIMITED=is_unlimited, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1B of
      keyword_set(dimsize): $
           self->DimInfo, dim, DIMSIZE=result
      keyword_set(is_unlimited): $
           self->DimInfo, dim, IS_UNLIMITED=result
      else: $
           self->DimInfo, dim, ALL=result
   endcase

   return, result

end

; MGHncSequence::Get
;
;   Wrapper for the ncfiles container's Get mthod
;
function MGHncSequence::Get, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.ncfiles->Get(_STRICT_EXTRA=_extra)

end

; MGHncSequence::HasDim
;
; Purpose:
;   Indicates whether the first netCDF file has a dimension with the
;   specified name
;
function MGHncSequence::HasDim, Name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, N_FILES=n_files

   if n_files eq 0 then return, 0B

   onc = self.ncfiles->Get()
   return, onc->HasDim(name)

end

; MGHncSequence::HasVar
;
; Purpose:
;   Indicates whether the first netCDF file has a variable with the
;   specified name
;
function MGHncSequence::HasVar, varname

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, N_FILES=n_files

   if n_files eq 0 then $
      message, 'There are no netCDF files in the sequence'

   onc = self.ncfiles->Get()

   return, onc->HasVar(varname)

end

; MGHncSequence::Info
;
; Purpose:
;   Retrieve information about the netCDF file object. A synonym for
;   GetProperty.
;
pro MGHncSequence::Info, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, _STRICT_EXTRA=extra

end

function MGHncSequence::Info, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, mgh_get_property(self, _STRICT_EXTRA=extra)

end

; MGHncSequence::VarInfo (Procedure & Function)
;
; Purpose:
;   Returns information about a netCDF variable
;
pro MGHncSequence::VarInfo, var, $
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

   self->GetProperty, N_FILES=n_files, N_RECORDS=n_records, UNLIMITED=unlimited

   if n_files gt 0 then begin
      onc = self.ncfiles->Get()
      onc->VarInfo, var, $
         ATT_NAMES=att_names, DATATYPE=datatype, $
         DIM_NAMES=dim_names, DIMENSIONS=dimensions, $
         FILL_VALUE=fill_value, N_ATTS=n_atts, N_DIMS=n_dims
      if self.ensemble then begin
         dim_names = (n_dims gt 0) ? [dim_names,'record'] : ['record']
         dimensions = (n_dims gt 0) ? [dimensions,n_files] : [n_files]
         n_dims = n_dims + 1
      endif else begin
         if n_dims gt 0 && strmatch(dim_names[n_dims-1], unlimited) then $
            dimensions[n_dims-1] = n_records
      endelse
   endif else begin
      att_names = ''
      datatype = ''
      dim_names = ''
      dimensions = -1
      fill_value = -1
      n_atts = 0
      n_dims = 0
   endelse

   if arg_present(all) then $
        all = {att_names:att_names, datatype:datatype, dim_names:dim_names, $
               dimensions:dimensions, fill_value:fill_value, n_atts:n_atts, $
               n_dims:n_dims}

end

function MGHncSequence::VarInfo, var, $
     ATT_NAMES=att_names, DATATYPE=datatype, DIM_NAMES=dim_names, $
     DIMENSIONS=dimensions, FILL_VALUE=fill_value, N_ATTS=n_atts, N_DIMS=n_dims

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1B of
      keyword_set(att_names): $
          self->VarInfo, var, ATT_NAMES=result
      keyword_set(datatype): $
          self->VarInfo, var, DATATYPE=result
      keyword_set(dimensions): $
          self->VarInfo, var, DIMENSIONS=result
      keyword_set(dim_names): $
          self->VarInfo, var, DIM_NAMES=result
      keyword_set(fill_value): $
          self->VarInfo, var, FILL_VALUE=result
      keyword_set(n_atts): $
          self->VarInfo, var, N_ATTS=result
      keyword_set(n_dims): $
          self->VarInfo, var, N_DIMS=result
      else: $
          self->VarInfo, var, ALL=result
   endcase

   return, result

end

; MGHncSequence::HasAtt
;
; Purpose:
;   Returns 1 if the specified attribute is found, otherwise 0.
;
function MGHncSequence::HasAtt, P1, P2, GLOBAL=global

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, N_FILES=n_files

   if n_files gt 0 then begin
      onc = self.ncfiles->Get()
      return, onc->HasAtt(p1, p2, GLOBAL=global)
   endif else begin
      return, 0
   endelse

end

; MGHncSequence::Remove
;
;   Wrapper for the ncfiles container's Remove method
;
pro MGHncSequence::Remove, p1, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: self.ncfiles->Remove, _STRICT_EXTRA=extra
      1: self.ncfiles->Remove, p1, _STRICT_EXTRA=extra
   endcase

end

; MGHncSequence::VarGet
;
; Purpose:
;   Get data for a specified variable
;
function MGHncSequence::VarGet, VarName, $
     COUNT=count, OFFSET=offset, STRIDE=stride, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, N_FILES=n_files

   if n_files eq 0 then return, ''

   ;; Special handling if the variable varies in the unlimited dimension

   if self.ensemble then begin
     dims = self->VarDimNames(varname, COUNT=n_dims)
     unlim = 1B
   endif else begin
     dims = self->VarDimNames(varname, COUNT=n_dims)
     unlim = 0B
     if n_dims gt 0 then begin
       dunlim = self->DimNames(/UNLIMITED, COUNT=n_dunlim)
       unlim = (n_dunlim gt 0) && (dims[n_dims-1] eq dunlim)
     endif
   endelse

   case unlim of

      0B: begin
         onc0 = self.ncfiles->Get()
         return, onc0->VarGet(varname, COUNT=count, OFFSET=offset, $
                              STRIDE=stride, _STRICT_EXTRA=extra)
      end

      1B: begin

         ;; We retrieve the data in a series of VarGet operations, one
         ;; per file.  The only tricky bit is to establish the correct
         ;; OFFSET and COUNT for each file

         self->GetProperty, $
              N_RECORDS=n_records, FILE_N_RECORDS=file_n_records, $
              FILE_OFFSET=file_offset

         onc0 = self.ncfiles->Get()

         dimsize = lonarr(n_dims)
         for d=0,n_dims-2 do $
              dimsize[d] = onc0->DimInfo(dims[d], /DIMSIZE)
         dimsize[n_dims-1] = n_records

         my_stride = n_elements(stride) gt 0 ? stride : replicate(1, n_dims)
         my_offset = n_elements(offset) gt 0 ? offset : replicate(0, n_dims)
         my_count = n_elements(count) gt 0 ? count : (dimsize - my_offset)/my_stride

         for i=0,n_elements(my_offset)-1 do begin
            if my_offset[i] lt 0 then $
                 my_offset[i] = my_offset[i] + dimsize[i]/my_stride[i]
         endfor

         for i=0,n_elements(my_count)-1 do begin
            if my_count[i] eq 0 then $
                 my_count[i] = (dimsize[i]-my_offset[i])/my_stride[i]
         endfor

         ;; Is this a character variable? If so, the output array has one
         ;; dimension fewer than the netCDF variable.
         self->VarInfo, varname, DATATYPE=datatype
         is_char = temporary(datatype) eq 'CHAR'

         ;; Determine the datatype of the return value (*not* the same as
         ;; the netCDF datatype if autoscaling is in effect) and create
         ;; an output array.
         val0 = onc0->VarGet(varname, COUNT=replicate(1, n_dims), $
                             _STRICT_EXTRA=extra)
         result = make_array(VALUE=mgh_null(val0), DIMENSION=my_count)


         ;; Create a list of records to be retrieved. These are record
         ;; numbers relative to the sequence as a whole. Also create a
         ;; byte array to keep track of which records have been found
         rget = my_offset[n_dims-1] + my_stride[n_dims-1]*lindgen(my_count[n_dims-1])
         bget = bytarr(my_count[n_dims-1])

         for f=0,n_files-1 do begin

            ;; Establish which of the records are in this file
            locs = where(rget ge file_offset[f] and $
                         rget le (file_offset[f]+file_n_records[f]-1), n)

            if n gt 0 then begin

               bget[locs] = 1B

               onc = self.ncfiles->Get(POSITION=f)

               if self.ensemble then begin
                 ;; Still some bugs here
                 count_f = n_dims lt 2 ? [1] : my_count[0:n_dims-2]
                 offset_f = n_dims lt 2 ? [0] : my_offset[0:n_dims-2]
                 n0 = locs[0]  &  n1 = n0
               endif else begin
                 count_f = my_count
                 count_f[n_dims-1] = n
                 offset_f = my_offset
                 offset_f[n_dims-1] = rget[locs[0]] - file_offset[f]
                 n0 = locs[0]
                 n1 = locs[0]+count_f[n_dims-1]-1
               endelse

               ;; Below the STRIDE keyword is omitted if possible,
               ;; because NCDF_VGET appears to be less efficient when
               ;; a STRIDE is specified, even when it is unity in
               ;; every dimension.

               if max(my_stride) gt 1 then begin

                  case (n_dims-is_char) of
                     1: begin
                        result[n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     2: begin
                        result[0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     3: begin
                        result[0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     4: begin
                        result[0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     5: begin
                        result[0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     6: begin
                        result[0,0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     7: begin
                        result[0,0,0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                     8: begin
                        result[0,0,0,0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, STRIDE=my_stride, $
                                         _STRICT_EXTRA=extra)
                     end
                  endcase

               endif else begin

                  case (n_dims-is_char) of
                     1: begin
                        result[n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     2: begin
                        result[0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     3: begin
                        result[0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     4: begin
                        result[0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     5: begin
                        result[0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     6: begin
                        result[0,0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     7: begin
                        result[0,0,0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                     8: begin
                        result[0,0,0,0,0,0,0,n0] = $
                             onc->VarGet(varname, COUNT=count_f, $
                                         OFFSET=offset_f, _STRICT_EXTRA=extra)
                     end
                  endcase

               endelse

            endif

         endfor

         miss = where(bget eq 0, n_miss)
         if n_miss gt 0 then begin
            msg = ['Records not found:', strtrim(rget[miss],2)]
            message, strjoin(msg, ' ')
         endif

         return, result

      end

   endcase

end

; MGHncSequence__Define
;
pro MGHncSequence__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHncSequence, inherits MGHncHelper, $
                  ensemble: 0B, name: '', ncfiles: obj_new(), $
                  unlimited: ''}

end

