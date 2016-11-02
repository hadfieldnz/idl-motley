; svn $Id$
;+
; NAME:
;   MGH_TXT_RESTORE
;
; PURPOSE:
;   Read the contents of a text file into a string array.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;   Result = MGH_TXT_RESTORE(file)
;
; POSITIONAL PARAMETERS:
;   file (input, scalar string)
;     File name
;
; KEYWORD PARAMETERS:
;   COMPRESS (input, switch)
;     Set this keyword to indicate that the data in the file are compressed.
;
;   COUNT (output, scalar integer)
;     Set this keyword to a named variable to return the number of
;     lines read from the file
;
;   MAX_LINES (input, scalar integer)
;     This keyword has an effect only for method 2. It specifies the
;     maximum number of lines in the file. If the file is longer than
;     this, then the routine will stop with an error.
;
;   METHOD (input, scalar integer)
;     This keyword specifies the method to be used to read the file.
;     Acceptable values are:
;
;       0 - Read lines one at a time, accumulating them in a string
;           array. Extend the array as necessary in increments of
;           70% or so (see code). Trim the result before returning.
;
;       1 - Read the file once to count the lines, create a result
;           array of the required size, then read the file again.
;
;       2 - Create a result array of size MAX_LINES, read the file,
;           then trim the result. This method may return fewer lines
;           than the other methods, as all empty lines are trimmed
;           from the end.
;
;       3 - As 0, but accumulate the results in an MGH_Vector object
;           then move them into a string array at the end.
;
;     The default (last time I looked) is method 1.
;
; RETURN VALUE:
;   The function returns a string array, each element corresponding to
;   a line in the file. Empty lines are represented by null
;   strings. If the file is empty, then the function returns a single
;   null string.
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
;   Mark Hadfield, 1993-04:
;     Written as TXT_RESTORE, inspired by the GETFILE routine in the
;     JHUAPL library.
;   Mark Hadfield, 1998-06:
;     Switched to the two-pass method, as described above. For large
;     files this is MUCH faster than the method used in GETFILE,
;     viz. appending each line to the output array as it is read.
;   Mark Hadfield, 1999-10:
;     Switched to a single-pass method using an MGH_Vector
;     object. The two-pass method is retained as an option.
;   Mark Hadfield, 2000-08:
;     Renamed MGH_TXT_RESTORE and moved into my public library (mainly
;     because it's an example of using MGH_Vector).
;   Mark Hadfield, 2002-12:
;     - Added keywords METHOD and MAX_LINES, and eliminated the old
;       TWO_PASS keyword. There are now 4 methods available.
;     - The two-pass method, now method 1, has been modified to use
;       MGH_FILE_LINES, which calls FILE_LINES if the file is
;       uncompressed and counts lines with an IDL while lopp
;       if it is compressed.
;   Mark Hadfield, 2003-06:
;     - Upgraded to IDL 6.0. The two-pass method, now calls FILE_LINES
;       in all cases
;-

function MGH_TXT_RESTORE, file, $
     COMPRESS=compress, COUNT=count, MAX_LINES=max_lines, METHOD=method

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(method) eq 0 then method = 1

   case method of

      0: begin

         openr, /GET_LUN, lun, File, COMPRESS=compress

         size = 10000

         result = strarr(size)

         count = 0

         t = ''

         while ~ eof(lun) do begin

            readf, lun, t

            count ++

            if count gt size then begin
               delta = round(0.7*size)
               result = [temporary(result), strarr(delta)]
               size = n_elements(result)
            endif

            result[count-1] = t

         endwhile

         free_lun, lun

         if count eq 0 then return, ''

         return, result[0:count-1]

      end

      1: begin

         count = file_lines(file, COMPRESS=compress)

         if count eq 0 then return, ''

         result = strarr(count)

         openr, /GET_LUN, lun, File, COMPRESS=compress
         readf, lun, result
         free_lun, lun

         return, result

      end

      2: begin

         if n_elements(max_lines) eq 0 then max_lines = 50000

         result = strarr(max_lines)

         openr, /GET_LUN, lun, file, COMPRESS=compress

         on_ioerror, done

         readf, lun, result

         message, 'Number of lines in file exceeds MAX_LINES, ' + $
                  'which is '+strtrim(max_lines,2)

         done:

         free_lun, lun

         full = where(strlen(result) gt 0, n_full)

         if n_full eq 0 then begin
            count = 0
            return, ''
         endif

         count = full[n_full-1] + 1

         return, result[0:count-1]

      end

      3: begin

         openr, /GET_LUN, lun, File, COMPRESS=compress

         ostore = obj_new('MGH_Vector')

         t = ''
         while ~ eof(lun) do begin
            readf, lun, t
            ostore->Add, t
         endwhile

         free_lun, lun

         count = ostore->Count()

         if count eq 0 then begin
            obj_destroy, ostore
            return, ''
         endif

         result = strarr(count)
         for i=0,count-1 do result[i] = ostore->Get(POSITION=i)

         obj_destroy, ostore

         return, result

      end

      4: begin

         openr, /GET_LUN, lun, File, COMPRESS=compress

         count = 0

         t = ''

         while ~ eof(lun) do begin

            readf, lun, t

            result = (count eq 0) ? [t] : [result,t]

            count ++

         endwhile

         free_lun, lun

         if count eq 0 then return, ''

         return, result

      end

   endcase

end


