; svn $Id$
;+
; NAME:
;   MGH_WIDGET_GETCHILD
;
; PURPOSE:
;   Given a widget ID, this function returns a the widget ID(s) for one or more
;   of its children. It is intended to have similar semantics to IDL_Container::Get.
;
; CATEGORY:
;   Widgets.
;
; CALLING SEQUENCE:
;   Result = MGH_WIDGET_GETCHILD(Parent)
;
; INPUTS:
;   Parent:     The ID of the widget we are searching.
;
; KEYWORD PARAMETERS:
;   ALL:        If this keyword is set, return all widgets that meet the criteria.
;
;   COUNT:      This keyword returns the number of children found.
;
; OUTPUTS:
;   The function returns an integer scalar or array.
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
;   Mark Hadfield, May 1998:
;       Written.
;-
function MGH_WIDGET_GETCHILD, Parent, UVALUE=uvalue, POSITION=position, ALL=all, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR

    count = 0

    if not widget_info(Parent, /VALID_ID) then return, -1

    ; Start by creating a list of all children. This is admittedly
    ; inefficient in some circumstances, but simplifies later
    ; calculations.

    child = widget_info(Parent, /CHILD)

    if child eq 0 then return, -1

    count = 1  &  children = [child]

    while 1 do begin
        child = widget_info(child, /SIBLING)
        if child eq 0 then break
        count = count + 1
        children = [children, child]
    endwhile

    ; Further filtering of the list can be done here.

    if n_elements(uvalue) eq 1 then begin

        equal = mgh_reproduce(0,children)

        for i=0,n_elements(equal)-1 do begin
            widget_control, children[i], GET_UVALUE=uval
            switch 1 of
                n_elements(uval) ne 1: $
                    begin
                        equal[i] = 0
                        break
                    end
                (size(uval))[0] ne (size(uvalue))[0]: $
                    begin
                        equal[i] = 0
                        break
                    end
                else: $
                    begin
                        equal[i] = uval[0] eq uvalue[0]
                        break
                    end
            endswitch
        endfor

        match = where(equal,count)

        if count eq 0 then return, -1

        children = children[match]

    endif

    ; Return a list of children or a single one, depending on the
    ; ALL and POSITION keywords.

    if keyword_set(all) then return, children

    if n_elements(position) gt 0 then begin

        if max(position) ge count or min(position) lt 0 then $
            message, 'Position value out of range'

        count = n_elements(position)

        return, children[position]

    endif else begin

        count = 1  &  return, children[0]

    endelse


end

