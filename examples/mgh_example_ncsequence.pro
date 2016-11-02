;+
; NAME:
;   MGH_EXAMPLE_NCSEQUENCE
;
; PURPOSE:
;   MGHncSequence object example
;
;###########################################################################
; Copyright (c) 2000 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;   Mark Hadfield, 2015-11:
;     Removed a reference to the obsolete MGHncFileVar class.
;-
pro mgh_example_ncsequence, N_FILES=n_files, N_RECORDS=n_records

   compile_opt DEFINT32
   compile_opt STRICTARR

   ;; The keywords to this routine specify the total number of files
   ;; and total number of records to be written in the sequence of
   ;; files

   if n_elements(n_files) eq 0 then n_files = 1

   if n_elements(n_records) eq 0 then n_records = 10

   ;; The variables file_n_records and file_offset have the same
   ;; meaning as they do as properties of an MGHncSequence object,
   ;; i.e. they specify the number of records in each file, and the
   ;; position of the first record in each file relative to the
   ;; complete sequence of records.

   if n_files gt 1 then begin
      n = n_records/n_files     ; Number of records in all files but the last
      file_offset = n*lindgen(n_files)
      file_n_records = [replicate(n,n_files-1), n_records-file_offset[n_files-1]]
   endif else begin
      file_n_records = n_records
      file_offset = 0
   endelse

   ;; Specify the file names

   files = filepath('mgh_example_ncfile_'+cmunique_id()+'_'+sindgen(n_files)+'.nc',/TMP)

   ;; Use the MGHncFile object ot create a sequence of netCDF files

   for i=0,n_files-1 do begin

      onc = obj_new('MGHncFile', files[i], /CREATE, /CLOBBER)
      onc->AttAdd, /GLOBAL, 'title', 'Test file '+strtrim(i,2)

      onc->DimAdd, 'x', 5
      onc->DimAdd, 'y', 3
      onc->DimAdd, 't'

      onc->VarAdd, 'x', ['x']
      onc->VarAdd, 'y', ['y']
      onc->VarAdd, 't', ['t'], /LONG
      onc->VarAdd, 'v', ['x','y','t'], /SHORT
      onc->AttAdd, 'v', 'long_name', 'vvvvvv'
      onc->AttAdd, 'v', 'units', 'W'
      onc->AttAdd, 'v', 'scale_factor', 10.

      ;; Put time data. The idea is to create a continuous sequence
      ;; of time values

      onc->VarPut, 't', file_offset[i] + lindgen(file_n_records[i])

      ;; Put some v data in the first record of each file.

      onc->VarPut, 'v', 1+fltarr(5,3), COUNT=[5,3,1], OFFSET=[0,0,0]

      obj_destroy, onc

   endfor

   oseq = obj_new('MGHncSequence', files)

   oseq->GetProperty, N_FILES=n_files, N_RECORDS=n_records
   print, 'Catalogue of netCDF sequence'
   print, 'Number of files =',n_files
   print, 'Number of records =',n_records
   print, 'Dimensions:'
   d = oseq->DimNames()  &  print, d
   print, 'Unlimited dimension:'
   d = oseq->DimNames(/UNLIMITED)  &  print, d
   print, 'Global attributes:'
   a = oseq->AttNames(/GLOBAL, COUNT=count)
   if count gt 0 then begin
      for j=0,count-1 do print, a[j], ': ', oseq->AttGet(a[j], /GLOBAL)
   endif else begin
      print, 'None'
   endelse
   print, 'Variables:'
   v = oseq->VarNames()
   print, v
   print, ''

   ;; Go through variables extracting data & attributes

   for i=0,n_elements(v)-1 do begin
      print, 'Catalogue of variable '+v[i]+':'
      print, '    Dimensions used:'
      vd = oseq->VarDimNames(v[i], COUNT=count)
      if count gt 0 then print, '    ', vd else print, '    None'
      print, '    Attributes:'
      va = oseq->AttNames(v[i], COUNT=count)
      if count gt 0 then begin
         for j=0,count-1 do print, '    ', va[j], ': ', $
           oseq->AttGet(v[i], va[j])
      endif else begin
         print, 'None'
      endelse
      print, '    Data:'
      print, '    ', (oseq->VarGet(v[i], /AUTOSCALE))[*]
   endfor

   ;; Now a partial get

   print, 'Partial get of data from variable t:'
   print, '    ', oseq->VarGet('t', COUNT=[n_records-2], OFFSET=[1])

   obj_destroy, oseq

end
