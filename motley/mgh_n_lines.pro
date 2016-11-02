; svn $Id$
;+
; NAME:
;   MGH_N_LINES
;
; PURPOSE:
;   This function counts the lines in a text file.
;
; CALLING SEQUENCE:
;   Result = MGH_N_LINES(File)
;
; POSITIONAL PARAMETERS:
;   file (input, string or integer scalar)
;     The name of a file or the unit number of an already-open file.
;
; KEYWORD PARAMETERS:
;   COMPRESS (input, switch)
;     Passed to the OPEN command. Ignored if the file is already open.
;
;   IGNORE_WHITE (input, switch)
;     If this keyword is set, don't count lines that contain only
;     white space.
;
; RETURN VALUE:
;   The function returns an integer equal to the number of lines in
;   the file. In the case where File is a unit number, the function
;   counts the number of lines REMAINING in the file then restores the
;   file pointer to the original position.
;
;###########################################################################
; Copyright (c) 1994-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, Sep 1994:
;     Written, based on a routine by Fred Knight.
;   Mark Hadfield, ???:
;     - Renamed from N_LINES to MGH_N_LINES.
;     - Added support for COMPRESS keyword.
;   Mark Hadfield, 2003-11:
;     Somewhat superseded by IDL function FILE_LINES, but not made obsolete
;     because there are several routines that rely on its more flexible
;     syntax.
;-
function mgh_n_lines, file, IGNORE_WHITE=ignore, COMPRESS=compress

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  case size(file, /TNAME) of
    'STRING': begin
      ;; Assume the argument is a file name and open it
      openr, lun, File, /GET_LUN, COMPRESS=compress
    end
    'LONG': begin
      ;; Assume the argument is a unit number and save the file
      ;; pointer position
      lun = file
      point_lun, -lun, pos
   end
   else: message, 'Invalid file specifier'
  endcase

  tmp = ''  &  result = 0

  while ~ eof(lun) do begin
    readf, lun, tmp
    result += keyword_set(ignore) ? 1 - mgh_str_iswhite(tmp) : 1
  endwhile

  case size(file, /TNAME) of
    'STRING': begin
      free_lun, lun          ; Close file
    end
    'LONG': begin
      point_lun, lun, pos    ; Restore file pointer position
    end
  endcase

  return, result

end
