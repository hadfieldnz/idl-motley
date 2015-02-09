;+
; NAME:
;   MGH_STR_SUBST
;
; PURPOSE:
;   String substitution.
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   Result = MGH_STR_SUBST(Original, Old, New)
;
; INPUTS:
;   Original:   The string to be processed. May be an array.
;
;   Old:        Remove this substring ...
;
;   New:        ...and replace it with this.
;
; OUTPUT PARAMETERS:
;   This function returns a string (array) with the same shape as the
;   original. 
;
; PROCEDURE:
;   If both Old and New are single characters, arguments are converted to
;   BYTE type and the substitution is done using the WHERE function. Otherwise
;   a more complicated scan through the original is done. Note that this is
;   substantially slower.
;
;   Like most text-editor search & replace commands, the m-character ->
;   n-character substitution can leave instances of the 'old' string
;   in the output.
;       print,MGH_STR_SUBST('aaaaa','aaa','aa')
;           aaaa
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
;   Mark Hadfield, 1993-10:
;     Written, based on IDL Astronomy Library functions REPCHR and
;     REPSTR, and a recursion algorithm from William Thompson.
;   Mark Hadfield, 1999-10:
;     For the multiple-character case, removed recursion code. This is
;     handled more simply by setting up an output array then stepping
;     through the elements.
;   Mark Hadfield, 2010-11:
;     Modernised the code.
;-
function mgh_str_subst, original, old, new

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  
  if n_elements(original) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'original'
  if n_elements(old) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'old'
  if n_elements(new) eq 0 then new = ''
   
  if ~ isa(original, 'STRING') then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'original'
  if ~ isa(old, 'STRING') then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'old'
  if ~ isa(new, 'STRING') then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'new'

  if strlen(old)*strlen(new) eq 1 then begin
  
    b = byte(Original)        ; convert string to a byte array.
    bold = byte(Old)          ; convert old to byte.
    w = where( b EQ bold[0], count) ; find occurrences of old.
    if count eq 0 then return, Original ; if none, return Original string.
    bnew = byte(New)          ; convert new to byte.
    b[w] = bnew[0]            ; replace old by new.
    return, string(b)         ; return new string.
    
  endif else begin
  
    result = mgh_reproduce('', original)
    
    for i=0,n_elements(original)-1 do begin
    
      l1 = strlen(old)
      l2 = strlen(new)
      last_pos = 0
      lo = 9999
      pos = 0
      copy = Original[i]
      while (pos lt lo-l1) and (pos ge 0) do begin
        lo = strlen(copy)
        pos = strpos(copy,old,last_pos)
        if (pos ge 0) then begin
          first_part = strmid(copy, 0, pos)
          last_part  = strmid(copy, pos+l1, 9999)
          copy = first_part + new + last_part
        endif
        last_pos = pos + l2
      endwhile
      
      result[i] = copy
      
    endfor
    
    return, result
    
  endelse

end
