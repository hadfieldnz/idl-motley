;+
; NAME:
;   MGH_SSH_FILE_SEARCH
;
; PURPOSE:
;   This function is similar to the IDL built-in FILE_SEARCH function but
;   operates on remote file systems via SSH.
;
;   Two methods are supported--see the METHOD keyword. Method 0 fails for
;   unknown reasons on some hosts. Method 1 is more robust but will fail
;   for path names containing whitespce. The default is method 1.
;
;   Both methods use shell pathname expansion and do not find hidden files.
;
;   For method 0, the login shell on the remote host must be GNU Bash (to
;   support a for loop in the remotely executed command.
;
;   On Windows there is no opportunity to respond to prompts.
;
; CALLING SEQUENCE:
;   result = mgh_ssh_file_search(pattern)
;
; POSITIONAL PARAMETERS:
;   pattern (input, string scalar or vector)
;     Pattern(s) to be searched for, in host:path form.
;
; KEYWORD PARAMETERS:
;   COUNT (output, integer)
;     The number of matches
;   METHOD (input, integer scalar)
;     This keyword determines the command that is submitted to the remote
;     host and the way it is interpreted. Method 0 uses a Bash for loop to
;     print each match to a separate line and reads the output into an array.
;     Method 1 (the default) uses echo to print all matches and then splits
;     the output.
;
;###########################################################################
; Copyright (c) 2018 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2015-07:
;     Written.
;   Mark Hadfield, 2018-08:
;     Added the METHOD keyword. The original method is method 0. A new method
;     is introduced as method 1 and is now the default.
;-
function mgh_ssh_file_search, pattern, COUNT=count, METHOD=method

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(pattern) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'pattern'

   if n_elements(method) eq 0 then method = 1

   result = []
   count = 0

   for p=0,n_elements(pattern)-1 do begin

      pp = strsplit(pattern[p], ':', /EXTRACT)

      if n_elements(pp) ne 2 then $
         message, 'Each search pattern must be in host:path form'

      case method of
         0: begin
            ;; Search for the files using SSH with a Bash for loop.
            ;; We use "test -a" to catch the case where the pattern is not expanded.
            fmt = '(%"ssh %s \"for match in %s; do (test -a $match && echo $match); done\"")'
         end
         1: begin
            ;; Search for the files using SSH with a simple shell expansion
            ;; We test below for the case where the pattern is not expanded.
            fmt = '(%"ssh %s \"echo %s\"")'
         end
      endcase

      cmd = string(FORMAT=fmt, pp)

      if strcmp(!version.os_family, 'Windows', /FOLD_CASE) then begin
         spawn, /HIDE, cmd, stdout, stderr
      endif else begin
         spawn, cmd, stdout, stderr
      endelse

      case method of
         0: begin
            if strlen(stdout[0]) gt 0 then begin
               result = [result,stdout]
               count += n_elements(stdout)
            endif
         end
         1: begin
            if stdout ne pp[1] then begin
               match = strsplit(stdout, /EXTRACT, COUNT=n_match)
               result = [result,match]
               count += n_match
            endif
         end
      endcase

   endfor

   return, result

end
