;+
; NAME:
;   MGH_SSH_FILE_SEARCH
;
; PURPOSE:
;   This function is similar to the IDL built-in FILE_SEARCH function but
;   operates on remote file systems via SSH
;
;   The login shell on the remote host must be GNU bash
;
; CALLING SEQUENCE:
;   result = mgh_ssh_file_search(pattern)
;
; POSITIONAL PARAMETERS:
;   pattern (input, string scalar or vector)
;     Pattern(s) to be searched for, in host:path form.
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
function mgh_ssh_file_search, pattern, COUNT=count

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(pattern) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'pattern'

  result = []
  count = 0

  for p=0,n_elements(pattern)-1 do begin

    pp = strsplit(pattern[p], ':', /EXTRACT)

    if n_elements(pp) ne 2 then $
      message, 'Each search pattern must be in host:path form'

    ;; The use of a Bash for loop in the following command does not
    ;; seem to work for some remote hosts.
    fmt = '(%"ssh %s \"for match in %s; do (test -a $match && echo $match); done\"")'
    cmd = string(FORMAT=fmt, pp)

    if strcmp(!version.os_family, 'Windows', /FOLD_CASE) then begin
      spawn, /HIDE, cmd, stdout, stderr
    endif else begin
      spawn, cmd, stdout, stderr
    endelse

    if strlen(stdout[0]) gt 0 then begin
      result = [result,stdout]
      count += n_elements(stdout)
    endif

  endfor

  return, result

end
