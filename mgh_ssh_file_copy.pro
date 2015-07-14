;+
; NAME:
;   MGH_SSH_FILE_COPY
;
; PURPOSE:
;   This procedure retrieves the contents of a remote file via SSH & writes
;   them to another file.
;
; CALLING SEQUENCE:
;   MGH_SSH_FILE_COPY, file_src, file_dest
;
; POSITIONAL PARAMETERS:
;   file_src (input, scalar string)
;     Source file name, in host:path form. The host portion may include a user
;     name (user@host). The path portion, when resolved by the user, must
;     correspond to a regular file on the remote system.
;
;   file_dest (input, scalar string)
;     Destination file name. This must be a valid path name for the local
;     file system and the directory portion of the path must be an
;     existing directory.
;
; KEYWORD PARAMETERS:
;   BUNZIP2 (input, logical)
;     If this keyword is set, read bzip2-compressed data. The BUNZIP2
;     and GUNZIP keywords cannot both be set.
;
;   GUNZIP (input, logical)
;     If this keyword is set, read gzip-compressed data. The BUNZIP2
;     and GUNZIP keywords cannot both be set.
;
; SIDE EFFECTS:
;   A new file is created.
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
pro mgh_ssh_file_copy, file_src, file_dest, $
     BUNZIP2=bunzip2, GUNZIP=gunzip, VERBOSE=verbose

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(file_src) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'file_src'

  if n_elements(file_dest) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'file_dest'

  src = strsplit(file_src, ':', /EXTRACT)

  if n_elements(src) ne 2 then $
    message, 'Source file name must be in host:path form'

  if keyword_set(verbose) then begin
    msg = string(FORMAT='(%"Copying file %s to %s")', file_src, file_dest)
    message, /INFORM, temporary(msg)
  endif

  case 1B of
    keyword_set(gunzip): $
      cmd = string(FORMAT='(%"ssh %s \"gunzip -c %s\" > \"%s\"")', src, file_dest)
    keyword_set(bunzip2): $
      cmd = string(FORMAT='(%"ssh %s \"bunzip2 -c %s\" > \"%s\"")', src, file_dest)
    else: $
      cmd = string(FORMAT='(%"ssh %s \"cat %s\" > \"%s\"")', src, file_dest)
  endcase

  if strcmp(!version.os_family, 'Windows', /FOLD_CASE) then begin
    spawn, /HIDE, /LOG_OUTPUT, cmd
  endif else begin
    spawn, cmd
  endelse

end
