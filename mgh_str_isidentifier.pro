; svn $Id$
;+
; NAME:
;   MGH_STR_ISIDENTIFIER
;
; PURPOSE:
;   This function determines whether a string is a valid IDL identifier
;   (see "Building IDL Applications", Chapter 2).
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   Result = MGH_STR_ISIDENTIFIER(InString)
;
; INPUTS:
;   InString:   A string scalar or array.
;
; OUTPUTS:
;   The function returns 1 if InString is a valid identifier, otherwise 0.
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
;   Mark Hadfield, 2000-12
;       Written.
;-
function MGH_STR_ISIDENTIFIER, InString

   compile_opt DEFINT32
   compile_opt STRICTARR

    ; A list of the IDL reserved words, for later use.

    reserved = $
        [ 'AND', 'BEGIN', 'BREAK', 'CASE', 'COMMON', 'COMPILE_OPT', 'CONTINUE', 'DO', 'ELSE' $
        , 'END', 'ENDCASE', 'ENDELSE', 'ENDFOR', 'ENDIF', 'ENDREP', 'ENDSWITCH' $
        , 'ENDWHILE', 'EQ', 'FOR', 'FORWARD_FUNCTION', 'FUNCTION', 'GE', 'GOTO' $
        , 'GT', 'IF', 'INHERITS', 'LE', 'LT', 'MOD', 'NE', 'NOT', 'OF' $
        , 'ON_IOERROR', 'OR', 'PRO', 'REPEAT', 'SWITCH', 'THEN', 'UNTIL', 'WHILE' $
        , 'XOR' $
        ]

    ; Generate the output array and process elements one at a time.

    result = mgh_reproduce(0B,Instring)

    for i=0,n_elements(InString)-1 do begin

        s = strupcase(instring[i])  &  b = byte(s)

        ; Check length is within bounds
        if strlen(s) lt 1 or strlen(s) gt 128 then continue

        ; Reject reserved words
        if total(strmatch(reserved, s, /FOLD_CASE)) gt 0 then continue

        ; Check first character is letter
        if (b[0] lt 65B) or (b[0] gt 90B) then continue

        ; Check all characters are acceptable
        a =    (b ge 65B and b le 90B) $   ;;; Letter
            or (b ge 48B and b le 57B) $   ;;; Digit
            or (b eq 36B) $                ;;; Dollar
            or (b eq 95B)                  ;;; Underscore
        if product(a) eq 0 then continue

        result[i] = 1

    endfor

    return, result

end
