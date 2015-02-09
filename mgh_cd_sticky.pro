;+
; NAME:
;   MGH_CD_STICKY
;
; PURPOSE:
;   A procedure to replace boilerplate directory-switching code in widget
;   applications
;
;###########################################################################
; Copyright (c) 2012, 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2012-02:
;     Written.
;   Mark Hadfield, 2013-06:
;     REmove extraneous ")" from informational message.
;-
pro mgh_cd_sticky, dir

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  
  if ~ !mgh_prefs.sticky then return
  
  if n_elements(dir) eq 0 then return
  
  if strlen(dir) eq 0 then return

  cd, CURRENT=old_dir
  
  if dir ne old_dir then begin
    message, /INFORM, string(dir, FORMAT='(%"Changing to directory %s")')
    cd, dir
  endif
   
end


