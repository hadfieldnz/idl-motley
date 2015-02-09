; svn $Id$
;+
; NAME:
;   MGH_WIDGET_DESCENDANTS
;
; PURPOSE:
;   Given a widget ID, this function returns the widget ID(s) for
;   all children, and their children, and their children's children
;   etc.
;
; CATEGORY:
;   Widgets.
;
; CALLING SEQUENCE:
;   Result = MGH_WIDGET_DESCENDANTS(parent)
;
; POSITIONAL PARAMETERS:
;   parent (input, widget ID)
;     The ID of the widget we are searching.
;
;   already (private, optional)
;     This parameter is provided to support recursion and will not
;     normally be called by the user. It is an integer array to which
;     the results of the search will be appended.
;
; RETURN VALUE:
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
;   Mark Hadfield, Jan 2001:
;     Written, based on JD Smith's routine TREEDESC.
;-
function MGH_WIDGET_DESCENDANTS, parent, already

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   ;; Ensure local copy of current parent
   current = parent

   if current ne 0 then begin

      result = n_elements(already) eq 0 ? current : [already, current]

      ;; Descend one level
      current = widget_info(current, /CHILD)

      ;; Find siblings & descend their subtrees
      while current ne 0 do begin
         result = mgh_widget_descendants(current, result)
         current = widget_info(current, /SIBLING)
      endwhile

   endif

   return, result

end

