;+
; NAME:
;   MGH_WIDGET_SELF
;
; PURPOSE:
;   Support the retrieval of object refernces from, and the storing of object
;   references in, structures of type MGH_WIDGET_SELF. These are associated with
;   the UVALUE of a widget element, to provide a bridge between the widget tree
;   and an associated widget object.
;
; CATEGORY:
;   Widgets.
;
; CALLING SEQUENCE:
;   There are three modes of operation, controlled by the type of the positional
;   argument and keywords:
;
;   1: Store an object reference in an MGH_WIDGET_SELF structure
;
;       struct = MGH_WIDGET_SELF(STORE_OBJECT=objref)
;
;   2: Retrieve an object reference from an MGH_WIDGET_SELF structure
;
;       objref = MGH_WIDGET_SELF(struct, FOUND=found)
;
;   3: Search for an MGH_WIDGET_SELF structure in the children of widgetID, then
;      retrieve and return the object reference.
;
;       objref = MGH_WIDGET_SELF(widgetID, FOUND=found)
;
; POSITIONAL PARAMETERS:
;   arg

;     A scalar of type structure (calling sequence 2) or integer
;     (calling sequence 3). Ignored for calling sequence 3.
;
; KEYWORD PARAMETERS:
;   FOUND
;     For calling sequences 2 & 3 this keyword returns 1 if an object
;     reference has been found otherwise 0. Note that the object
;     reference may not be valid, even if FOUND is 1.
;
;   STORE_OBJECT
;     Set this keyword to an object reference to select calling sequence 3.
;
; OUTPUTS:
;   Depends on calling sequence.
;
; THE CONVENTIONS FOR STORING MGH_WIDGET_SELF STRUCTURES
;   The classes that currently store MGH_WIDGET_SELF structures are MGH_GUI_Base
;   and MGH_GUI_PDmenu. They store the structure in the UVALUE of the first or
;   second child of the object's base widget (BASE property). The widget tree
;   is set up--with some difficulty, I might add--so that this widget never
;   generates events. (If it did, then the UVALUE might be needed for storing
;   callback structures.) It can't always be the first child because on top-level
;   bases this would be the menu-bar base and we definitely do want to use callbacks
;   for that.
;
;   As a slight generalisation, the MGH_WIDGET_SELF function (calling
;   sequence 3) looks for the structure in *all* the children of the widget.
;
; COMMENT:
;   Yes, I agree that it is ugly to bundle three fundamentallly
;   different modes of operation in one function. I do it this way
;   because I want to keep things localised and IDL has no suitable
;   larger units of organisation than functions.
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
;   Mark Hadfield, Jun 2001:
;     Written.
;-
pro MGH_WIDGET_SELF__Define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGH_WIDGET_SELF, self: obj_new()}

end


function mgh_widget_self, arg, FOUND=found, STORE_OBJECT=store_object

   compile_opt DEFINT32
   compile_opt STRICTARR

   ;; If an object reference has been passed to STORE_OBJECT, then wrap
   ;; it in a MGH_WIDGET_SELF structure and return the structure

   if n_elements(store_object) then begin
      if not obj_valid(store_object) then $
           message, 'Object is not valid'
      result = {MGH_WIDGET_SELF}
      result.self = store_object
      return, result
   endif

   ;; Otherwise we want to extract an object reference from a widget tree
   ;; or an MGH_WIDGET_SELF structure.

   if n_elements(arg) ne 1 then $
        message, 'The argument must be a single MGH_WIDGET_SELF structure or ' + $
                 'a single widget ID'

   found = 0B

   case size(arg, /TYPE) of

      ;; If argument is a structure, retrieve an object reference from it.

      8: begin
         if tag_names(arg, /STRUCTURE_NAME) eq 'MGH_WIDGET_SELF' then begin
            found = 1B
            return, arg.self
         endif
      end

      ;; If argument is not a structure, assume it is a widget ID and search for an
      ;; MGH_WIDGET_SELF structure in the children of the widget.

      else: begin

         if not widget_info(arg, /VALID_ID) then break

         id = widget_info(arg, /CHILD)

         while widget_info(id, /VALID_ID) do begin
            widget_control, id, GET_UVALUE=uvalue
            if size(uvalue, /TYPE) eq 8 then begin
               if tag_names(uvalue, /STRUCTURE_NAME) eq 'MGH_WIDGET_SELF' then begin
                  found = 1B
                  return, uvalue.self
               endif
            endif
            id = widget_info(id, /SIBLING)
         endwhile

      end

   endcase

   return, obj_new()

end

