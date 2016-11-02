;+
; NAME:
;   MGH_SSH_FILE_TEST
;
; PURPOSE:
;   This procedure tests for the existence of a remote file via SSH.
;
;   It uses the stat command on the remote host: this must be the GNU variant.
;
; CALLING SEQUENCE:
;   MGH_SSH_FILE_TEST, file
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
function mgh_ssh_file_test, file

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  info = mgh_ssh_file_info(file)

  return, info.exists

end
