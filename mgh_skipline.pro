;+
; NAME:
;   MGH_SKIPLINE
;
; PURPOSE:
;   Skip a specified number of lines in a text file, by reading and
;   discarding a string
;
; CALLING SEQUENCE:
;   mgh_skipline, lun [, n]
;
; POSITIONAL PARAMETERS:
;   lun (input, integer scalar)
;     Unit number.
;
;   n (input, integer scalar)
;     Number of lines to skip. Default is 1.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2013-04:
;     Written.
;-
pro mgh_skipline, lun, n

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  
  if n_elements(lun) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'lun'
        
  if n_elements(n) eq 0 then n = 1
  
  line = ''
  
  if n gt 0 then begin
    
    for i=0,n-1 do readf, lun, line
    
  endif

end

