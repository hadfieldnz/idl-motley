;+
; NAME:
;   MGH_SSH_FILE_INFO
;
; PURPOSE:
;   This function retrieves information about a remote file via SSH.
;
;   It uses the stat command on the remote host: this must be the GNU variant.
;
; CALLING SEQUENCE:
;   result = mgh_ssh_file_info(file)
;
; POSITIONAL PARAMETERS:
;   file (input, scalar string)
;     Source file name, in host:path form.
;
;###########################################################################
; Copyright (c) 2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2015-07:
;     Written.
;-
function mgh_ssh_file_info, file

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(file) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'file'

  ff = strsplit(file, ':', /EXTRACT)

  if n_elements(ff) ne 2 then $
    message, 'File name must be in host:path form'

  cmd = string(FORMAT='(%"ssh %s \"stat %s\"")', ff)

  if strcmp(!version.os_family, 'Windows', /FOLD_CASE) then begin
    spawn, /HIDE, cmd, stdout, stderr
  endif else begin
    spawn, cmd, stdout, stderr
  endelse

  if strlen(stderr[0]) gt 0 then begin
    case 1B of
      strmatch(stderr[0], 'stat: cannot stat *: No such file or directory'): begin
        return, {name: file, exists: 0B}
      end
      else: begin
        message, 'Unexpected error output from remote stat command'
        return, {name: file, exists: 0B}
      end
    endcase
  endif

  ;; Get file size

  match = stregex(stdout[1], 'size: ([0-9]+)', /SUBEXPR, /EXTRACT, /FOLD_CASE)
  size = long64(match[1])

  ;; Get modification time

  match = stregex(stdout[5], 'modify: (.+)', /SUBEXPR, /EXTRACT, /FOLD_CASE)
  mtime = round(86400D0*(mgh_dt_julday(match[1])-mgh_dt_julday('1970')), /L64)

  return, {name: file, exists: 1B, size: size, mtime: mtime}

end
