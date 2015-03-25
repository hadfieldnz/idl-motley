; svn $Id$
;+
; CLASS:
;   MGH_GUI_PDmenu
;
; PURPOSE:
;   An object that implements pull-down menus.
;
; SUPERCLASSES:
;   None. Note that MGH_GUI_PDmenu shares much of is functionality of
;   other GUI objects but unlike them it is *not* a subclass of
;   MGH_GUI_Base.
;
; PROPERTIES:
;   The following properties are supported:
;
;     BASE (Init*, Get)
;       Base widget ID. This argument must be specified when creating
;       a menu-bar menu, otherwise it is ignored.
;
;     CHECKED_MENU (Init)
;       During object initialisation a set of buttons is always added
;       to the top level of the menu object. The CHECKED_MENU keyword
;       specifies whether these buttons have check boxes associated
;       with them. The keyword should either be a scalar or a vector
;       with the same number of elements as the items
;       argument. Default is 0.
;
;     COLUMN (Init)
;     ROW (Init)
;       Children of a MGH_GUI_PDmenu are always organised in either a
;       row or a column and centred. Set one of these keyword for
;       column or row alignment. Default is "row". Ignored by menu-bar
;       menus.
;
;     CONTEXT (Init, Get)
;       Set this keyword to create a context-sensitive menu.
;
;     MENU (Init)
;       During object initialisation a set of buttons is always added
;       to the top level of the menu object. The MENU keyword
;       specifies whether these buttons are menu-buttons (i.e. they
;       will be parents of other buttons) or not. It should either be
;       a scalar or a vector with the same number of elements as the
;       items argument. Default is 1 for menu-bar menus and 0 otherwise.
;
;     PARENT (Init*, Get)
;       Parent widget ID. This argument must be specified when
;       creating a non-menu-bar menu, otherwise it is ignored.
;
;     MBAR (Init, Get)
;       Set this keyword to create a menu attached to a top-level
;       base's menu bar.
;
;     UNAME (Init, Get, Set)
;       A string that can be used to identify the widget. Default is
;       ''.
;
;     UVALUE (Init, Get, Set)
;       User value. Default is undefined.
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
;   Mark Hadfield, 2001-06.
;     Written.
;   Mark Hadfield, 2003-06.
;     Added support for checked-menu functionality (IDL 6.0).
;   Mark Hadfield, 2004-05.
;     Added support for acelerator keys (IDL 6.1)
;-

; MGH_GUI_PDmenu_CLEANUP
;
pro MGH_GUI_PDmenu_CLEANUP, id

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   ;; Note that we have to arrange things so that this routine is
   ;; associated with the widget holding the object reference, because
   ;; widget-cleanup routines are very limited in the operations they
   ;; can carry out.

   widget_control, id, GET_UVALUE=uvalue

   self = mgh_widget_self(uvalue)

   if obj_valid(self) then obj_destroy, self

end

; MGH_GUI_PDmenu_EVENT
;
function MGH_GUI_PDmenu_EVENT, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   self = mgh_widget_self(event.handler, FOUND=found)

   if ~ found then $
        message, 'Could not find object reference'
   if ~ obj_isa(self, 'MGH_GUI_PDmenu') then $
        message, 'Object is not an instance of MGH_GUI_PDmenu'

   return, self->Event(event)

end

; MGH_GUI_PDmenu::Init
;
function MGH_GUI_PDmenu::Init, items, $
     BASE=base, CHECKED_MENU=checked_menu, COLUMN=column, CONTEXT=context, $
     MBAR=mbar, MENU=menu, PARENT=parent, ROW=row, UNAME=uname, UVALUE=uvalue, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(items) eq 0 then $
        message, 'At least one menu item must be specified'

   ;; Keyword defaults

   self.mbar = keyword_set(mbar)

   if ~ self.mbar then self.context = keyword_set(context)

   ;; Handling of parent/base argument depends on whether this is an
   ;; MBAR

   case self.mbar of
      0: begin
         if n_elements(parent) ne 1 then $
              message, 'A single parent widget must be specified'
         if ~ widget_info(parent, /VALID_ID) then $
              message, 'The parent widget is not valid'
         self.parent = parent
         if n_elements(column) eq 0 then column = 0
         if n_elements(row) eq 0 then row = 1 - column
         self.base = widget_base(parent, /BASE_ALIGN_CENTER, COLUMN=column, $
                                 CONTEXT_MENU=self.context, ROW=row, _STRICT_EXTRA=extra)
      end
      1: begin
         if n_elements(base) ne 1 then $
              message, 'A single menu bar base widget must be specified'
         if ~ widget_info(base, /VALID_ID) then $
              message, 'The menu bar base widget is not valid'
         self.base = base
      end
   endcase

   ;; Separator value for button UNAMEs

   self.sep = '.'

   ;; Intercept events

   widget_control, self.base, EVENT_FUNC='MGH_GUI_PDMENU_EVENT'

   ;; Add children.

   case self.mbar of
      0: if n_elements(menu) eq 0 then menu = 0
      1: if n_elements(menu) eq 0 then menu = 1
   endcase

   self->NewItem, items, CHECKED_MENU=checked_menu, MENU=menu

   ;; Store MGH_WIDGET_SELF reference in first child of base

   widget_control, widget_info(self.base, /CHILD), $
        KILL_NOTIFY='MGH_GUI_PDMENU_CLEANUP', SET_UVALUE=mgh_widget_self(STORE=self)

   ;; Set remaining properties

   self->MGH_GUI_PDmenu::SetProperty, UVALUE=uvalue, UNAME=uname

   return, 1

end


; MGH_GUI_PDmenu::Cleanup
;
pro MGH_GUI_PDmenu::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if widget_info(self.base, /VALID_ID) then $
        case self.mbar of
      0: widget_control, self.base, /DESTROY
      1: begin
         child = mgh_widget_getchild(self.base, /ALL, COUNT=n_child)
         for i=0,n_child-1 do $
              widget_control, child[i], /DESTROY
      end
   endcase

end

; MGH_GUI_PDmenu::GetProperty
;
pro MGH_GUI_PDmenu::GetProperty, $
     CONTEXT=context, MBAR=mbar, PARENT=parent, UNAME=uname, UVALUE=uvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   context = self.context

   mbar = self.mbar

   if arg_present(parent) then $
        parent = widget_info(self.base, /PARENT)

   uname = widget_info(self.base, /UNAME)

   widget_control, self.base, GET_UVALUE=uvalue

end

; MGH_GUI_PDmenu::SetProperty
;
pro MGH_GUI_PDmenu::SetProperty, $
     UNAME=uname, UVALUE=uvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(uname) gt 0 then $
        widget_control, self.base, SET_UNAME=uname

   if n_elements(uvalue) gt 0 then $
        widget_control, self.base, SET_UVALUE=uvalue

end

; MGH_GUI_PDmenu::About
;
pro MGH_GUI_PDmenu::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(lun) eq 0 then lun = -1

   printf, lun, self, ': Hello, my base widget ID is ', strtrim(self.base,2)
   printf, lun, self, ': My parent widget ID is ',strtrim(self.parent,2)
   printf, lun, self, ': My widget descendants are ', ' ' $
           +strtrim(mgh_widget_descendants(self.base),2)

   case 1 of
      self.mbar: $
           printf, lun, self, ': I am a menu-bar pull-down menu'
      self.context: $
           printf, lun, self, ': I am a context pull-down menu'
      else: $
           printf, lun, self, ': I am an ordinary pull-down menu'
   endcase

end

; MGH_GUI_PDmenu::ContextDisplay
;
pro MGH_GUI_PDmenu::ContextDisplay, x, y

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ self.context then $
        message, 'Method ContextDisplay was called on a non-context menu'

   widget_displaycontextmenu, self.parent, x, y, self.base


end

; MGH_GUI_PDmenu::Event
;
function MGH_GUI_PDmenu::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   ;; Construct new event. ID identifies the widget sending the event,
   ;; so we set it equal to the MGH_GUI_PDmenu's base; TOP identiifes
   ;; the top-level base of the hierarchy so we leave it
   ;; unchanged. HANDLER will be filled in by WIDGET_EVENT.

   return, {MGH_GUI_PDmenu_EVENT, id: self.base, top: event.top, handler: 0L, $
            value: widget_info(event.id, /UNAME)}

end

; MGH_GUI_PDmenu::FindItem
;
function MGH_GUI_PDmenu::FindItem, item

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, widget_info(self.base, FIND_BY_UNAME=strupcase(item))

end


; MGH_GUI_PDmenu::GetBase
;
function MGH_GUI_PDmenu::GetBase

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.base

end

; MGH_GUI_PDmenu::NewItem
;
pro MGH_GUI_PDmenu::NewItem, items, $
     ACCELERATOR=accelerator, CHECKED_MENU=checked_menu, MENU=menu, PARENT=parent, SEPARATOR=separator

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Locate parent

   if n_elements(parent) eq 0 then parent = self.base

   case size(parent, /TNAME) eq 'STRING' of
      0: parentID = parent
      1: parentID = self->FindItem(parent)
   endcase

   case parentID of
      self.base: parent_name = ''
      else: parent_name = widget_info(parentID, /UNAME)
   endcase

   ;; Resolve MENU and SEPARATOR settings

   n_items = n_elements(items)

   if n_elements(accelerator) eq 0 then accelerator = ''
   if n_elements(accelerator) eq 1 then $
        accelerator = replicate(accelerator[0], n_items)

   if n_elements(checked_menu) eq 0 then checked_menu = 0
   if n_elements(checked_menu) eq 1 then $
        checked_menu = replicate(checked_menu[0], n_items)

   if n_elements(menu) eq 0 then menu = 0B
   if n_elements(menu) eq 1 then menu = replicate(menu[0], n_items)

   if n_elements(separator) eq 0 then separator = 0
   if n_elements(separator) eq 1 then separator = replicate(separator[0], n_items)

   for i=0,n_items-1 do begin
      value = items[i]
      uname = strupcase(mgh_str_subst(strtrim(value,2),self.sep,''))
      if strlen(parent_name) gt 0 then uname = parent_name + self.sep + uname
      if menu[i] then begin
         if strlen(accelerator[i]) gt 0 then $
            message, 'ACCELERATOR string must be empty for pull-down menus'
         void = widget_button(parentID, CHECKED_MENU=checked_menu[i], /MENU, $
                              SEPARATOR=separator[i], UNAME=uname, VALUE=value)
        
      endif else begin
         void = widget_button(parentID, ACCELERATOR=accelerator[i], CHECKED_MENU=checked_menu[i], $
                              SEPARATOR=separator[i], UNAME=uname, VALUE=value)
      endelse
   endfor

end

; MGH_GUI_PDmenu::SetItem
;
pro MGH_GUI_PDmenu::SetItem, items, $
     SET_BUTTON=set_button, SENSITIVE=sensitive, VALUE=value

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(items)-1 do begin
      id = self->FindItem(items[i])
      if widget_info(id, /VALID_ID) then begin
         if n_elements(set_button) gt 0 then $
              widget_control, id, SET_BUTTON=set_button
         if n_elements(sensitive) gt 0 then $
              widget_control, id, SENSITIVE=sensitive
         if n_elements(value) gt 0 then $
              widget_control, id, SET_VALUE=value
      endif
   endfor

end


; MGH_GUI_PDmenu::Update
;
pro MGH_GUI_PDmenu::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end


; MGH_GUI_PDmenu__Define
;
pro MGH_GUI_PDmenu__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_PDmenu, base: 0L, mbar: 0B, context: 0B, parent: 0L, sep: ''}

end
