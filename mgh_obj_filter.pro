; svn $Id$
;+
; NAME:
;   MGH_OBJ_FILTER
;
; PURPOSE:
;   Given a list of object references, this function returns a list filtered by class
;   type.
;
; CATEGORY:
;   Objects.
;
; CALLING SEQUENCE:
;   Result = MGH_OBJ_FILTER(Objects, COUNT=count, ISA=isa)
;
; INPUTS:
;   Objects:    The input list of objects.
;
; KEYWORD PARAMETERS:
;   COUNT:      Set this keyword to a named variable that will contain the number
;               of objects returned.
;
;   ISA:        This keyword specifies a class name or list of class names used for filtering. An
;               object is passed by the filter if it matches one or more of the classes (using the OBJ_ISA function).
;
; OUTPUTS:
;   The function returns the filtered list.
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
;   Mark Hadfield, Jul 2000:
;       Written.
;-

function MGH_OBJ_FILTER                         $
        , objects                               $
        , COUNT=count                           $
        , ISA=isa

   compile_opt DEFINT32
   compile_opt STRICTARR

    count = n_elements(objects)

    if count eq 0 then return, -1

    ; Filter the list of candidates by the ISA criterion. Multiple ISA entries.
    ; are ORed.

    if count gt 0 and n_elements(isa) gt 0 then begin
        filter = mgh_reproduce(0B, objects)
        for i=0,n_elements(isa)-1 do filter = filter or obj_isa(objects, isa[i])
        match = where(filter, count)
        if count gt 0 then result = objects[match] else result = -1
    endif else begin
        result = objects
    endelse

    return, result


end
