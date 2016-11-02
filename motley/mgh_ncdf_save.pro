; svn $Id$
;+
; NAME:
;   MGH_NCDF_SAVE
;
; PURPOSE:
;   Procedure MGH_NCDF_SAVE stores the information contained in an IDL
;   structure into a NetCDF file.
;
; CATEGORY:
;   CDF
;
; CALLING SEQUENCE:
;   MGH_NCDF_SAVE, InStruct, OutFile
;
; POSITIONAL PARAMETERS:
;   instruct (input, scalar, structure)
;     The structure to be saved.
;
;   outfile (input, scalar, string)
;     The name of the file to be created.
;
; RESTRICTIONS:
;   The complex data type is not supported.
;
; PROCEDURE:
;   A NetCDF file is created. For each tag, the data is stored in a
;   variable of the appropriate dimensions. New dimensions are created
;   for every array.
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
;   Mark Hadfield, 1995-11:
;     Written.
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6.
;   Mark Hadfield, 2004-06:
;     Fixed a couple of bugs: reference to undefined variable SZ; incorrect
;     dimensions for string variables.
;-

pro MGH_NCDF_SAVE, instruct, outfile, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   n_tags = n_tags(instruct)

   if n_tags le 0 then $
        message, 'The first argument must be a structure containing at least one tag.'

   if n_elements(OutFile) eq 0 then $
        message,'No file name was supplied.'
   if strlen(OutFile)  eq 0 then $
        message,'No file name was supplied.'

   if n_elements(tempfile) ne 1 then tempfile = 0

   tagname = tag_names(InStruct)

   ;; Create a netCDF

   onc = obj_new('MGHncFile', OutFile, /CREATE, _STRICT_EXTRA=extra)

   for i=0,n_tags-1 do begin

      byte  = 0
      char  = 0
      double = 0
      float = 0
      long  = 0
      short = 0

      case size(instruct.(i), /TNAME) of
         'BYTE': $
              byte = 1
         'INT': $
              short = 1
         'LONG': $
              long = 1
         'FLOAT': $
              float = 1
         'DOUBLE': $
              double = 1
         'STRING': $
              char   = 1
         else: $
              message, 'Variable type is not supported.'
      endcase

      ;; For each vector tag define a set of fixed-length dimensions
      ;; then create a variable. For scalar tags just create a scalar
      ;; variable.

      data = instruct.(i)
      if char then data = byte(data)

      dim = size(data, /DIMENSIONS)
      n_dim = size(data, /N_DIMENSIONS)

      case n_dim gt 0 of
         0: begin
            onc->VarAdd, tagname[i], $
                         BYTE=byte, SHORT=short, LONG=long, FLOAT=float, $
                         DOUBLE=double, CHAR=char
         end
         1: begin
            dname = strarr(n_dim)
            for j=0,n_dim-1 do begin
               dname[j] = tagname[i]+strtrim(j,2)
               onc->DimAdd, dname[j], dim[j]
            endfor
            onc->VarAdd, tagname[i], dname, $
                         BYTE=byte, SHORT=short, LONG=long, FLOAT=float, $
                         DOUBLE=double, CHAR=char
         end
      endcase

      onc->VarPut, tagname[i], temporary(data)

   endfor

   obj_destroy, onc

end

