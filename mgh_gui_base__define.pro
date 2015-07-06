;+
; CLASS:
;   MGH_GUI_Base
;
; PURPOSE:
;   This class encapsulates a base widget as an object.
;
; CATEGORY:
;   Widgets.
;
; OBJECT CREATION SEQUENCE:
;   As a non-blocking top-level base:
;
;     mgh_new, 'mgh_gui_base'
;
;   As a blocking top-level base:
;
;     mgh_new, 'mgh_gui_base', /BLOCK, RESULT=ogui
;     ogui->Manage
;     obj_destroy, ogui
;
;   See discussion on widget life cycles below.
;
;   As a child of another MGH_GUI_BASE object:
;
;     ochild = oparent->NewChild('MGH_GUI_Base', /OBJECT)
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported:
;
;     ALL (Get)
;       This property is a structure wrapping the object's other
;       gettable properties, with the exception of UVALUE.
;
;     BLOCK (Init, Get)
;       Set this property to 1 to create a blocking widget. Default
;       (0) is non-blocking. This property is passed to XMANAGER when
;       it is called by the Manage method. Note the section on
;       blocking environments in RESTRICTIONS below.
;
;     FRAME (Init)
;       Specify the width of the frame around the base. Default is 0.
;
;     GEOMETRY (Get)
;       This keyword returns a WIDGET_GEOMETRY structure that
;       describes the offset and size information for the GUI base. It
;       combines geometry data from the main and layout bases in an
;       attempt to preserve the illusion for children that they belong
;       to a single base. I'm not sure if it is 100% successful in
;       this respect, but then I'm not sure that the geometry data
;       reported by IDL for the bases themsleves is 100% correct.
;
;     GROUP_LEADER (Init, Set)
;       The widget ID of an existing widget that serves as "group
;       leader" for the newly-created widget. When a group leader is
;       killed, for any reason, all widgets in the group are also
;       destroyed. The widget can be in more than one group. Each time
;       the SetProperty method is used to specify a group leader this
;       adds to the existing list of group leaders. Group leader
;       associations cannot be destroyed.
;
;     MBAR (Init)
;       This is a flag that should be set to create a menu bar. Unlike
;       the keyword of the same name to WIGET_CONTROL, it does NOT
;       return the menu bar ID.
;
;     MODAL (Init, Get)
;       Set this property to 1 to create a modal widget. Default (0)
;       is non-modal. If the MODAL property is set, then a
;       GROUP_LEADER must also be specified at initialisation.
;
;     MANAGED (Get, Set)
;       This property applies only to a top-level base. It equals 1 if
;       the base is currently being managed by XMANAGER, otherwise
;       0. If it is set during or after initialisation then the Manage
;       method is called. Once a based is being managed, attempts to
;       set or unset the property have no effect. Default is 1.
;
;     NOTIFY_REALIZE (Init, Get)
;       Set this property to 1 to specify that the object's
;       NotifyRealize method will be called when its base is
;       realized. Default (0) is not to call NotifyRealize. Note that
;       this property is an integer, not a string like the
;       NOTIFY_REALIZE keyword to IDL's widget routines. Also note
;       that if the base is a child whose parent is already realised
;       at the time the child is created, then the NotifyRealize
;       method will never be called! (This is a "feature" of IDL's
;       widget routines.)
;
;     PROCESS_EVENTS (Init, Get, Set)
;       This property applies only to a child base. Set it to 0 to
;       specify that the base will *not* intercept and process events
;       from its children. Default (1) is to process. An MGH_CW_Base
;       with PROCESS_EVENTS equal to 0 is essentially a base widget
;       with a few useful widget-management methods.
;
;     REALIZED (Init, Get, Set)
;       This property equals 1 if the base has been realised,
;       otherwise 0. If it is set during or after initialisation then
;       the Realize method is called. Once a based has been realised,
;       attempts to set or unset the property have no effect. Default
;       is 1 for top-level bases and 0 for child bases.
;
;     SENSITIVE (Init, Get, Set)
;       This property equals 1 if the base is sensitive, otherwise
;       0. Note that a base will be reported as insensitive if any of
;       its parents is insensitive.
;
;     TITLE (Init, Get, Set)
;       This property applies only to a top-level base. It specifies
;       the title, which appears in the title bar.
;
;     TLB_SIZE_EVENTS (Init, Get, Set)
;       This property equals 1 if the base reports events when
;       resized, otherwise 0.  Behaviour for non-top-level bases is
;       undefined; as far as I can tell, the property can
;       be changed and retrieved but has no effect.
;
;     UPDATE (Get, Set)
;       Set this property to 1 to enable display updates, 0 to disable
;       them. As far as I can tell, the UPDATE status of a widget
;       cannot be changed until it has been realised.
;
;     VALID (Get)
;       This property equals 1 if the base has a valid ID, otherwise
;       0. Note that a GUI base object can persist after its
;       associated widgets have been destroyed, so it is possible to
;       have VALID equal to 0
;
;     VISIBLE (Init, Get, Set)
;       Set this property to 1 to make the widget base visible, 0 to
;       make it invisible. A modal widget cannot be made
;       invisible--this is a limitation of WIDGET_CONTROL--and
;       attempts to do so will be ignored.
;
; METHODS:
;   In addition to Init, Cleanup, GetProperty, SetProperty...
;
;     About (Procedure)
;       Print information about the object & its environment to the
;       console. This method is conventionally invoked via a
;       "Help.About" menu item. Subclasses of MGH_GUI_Base may call
;       the superclass's method then add information of their own.
;
;     Align (Procedure)
;       Reposition the main base relative to the screen or to another
;       widget. This method is intended to be used on top-level bases
;       only. It might be useful to extend it to child bases.
;
;     Dispose (Procedure)
;       Add one or more objects to the disposal container. They will
;       be destroyed when the object is destroyed.
;
;     Event (Function)
;         Default event handler. See the section below on
;         event-handler functions.
;
;     EventBase (Function)
;     EventMenuBar (Function)
;       Handles events from the main base and menu bar,
;       respectively. For an MGH_GUI_Base object, these methods call
;       EventUnexpected. Note that EventMenuBar only handles events
;       received form the menu-bar base itself, not from its
;       children. To ensure that events generated by the menu-bar
;       children do get handled by EventMenuBar, install a
;       MGH_GUI_PDMenu object or CW_PDMENU compound widget on the
;       menu-bar base.
;
;     EventGeneric (Function)
;       This method wraps the events it receives and passes them
;       on. It is intended to be called only by child bases to provide
;       generic event handling. An event structure is created with ID
;       equal to self.base and the original event is stored in tag
;       EVENT. EventGeneric is called from EventUnexpected when the
;       current object is a child and is of class "MGH_CW_Base' (not a
;       subclass). It can also be called selectively by subclasses. If
;       it is called by a top-level base object the event will be
;       swallowed by the event-handler procedure.
;
;     EventUnexpected (Function)
;       Handle events that have not otherwise been handled. If the
;       current object is a child of class "MGH_CW_Base' (not a
;       subclass) then this method employs EventGeneric (see above) to
;       carry out generic processing, then passes the event
;       on. Otherwise the method prints a warning message and returns
;       0.
;
;     Finalize (Procedure)
;       This is my attempt to resolve widget initialisation and
;       destruction issues in a simple and robust way. I think I'm
;       almost there! The Finalize method is normally called at the
;       end of the Init method and sets up the widget object so it can
;       interact with other widgets. For a non-blocking, top-level
;       base it calls the Realize and Manage methods. For a
;       blocking/modal top-level base it calls the Realize method
;       only; the creator of the object is expected to call
;       Manage. For child widgets it calls the NotifyRealize method *if*
;       the parent has already been realized.
;
;       Finalize accepts a single, optional, string parameter. If this
;       parameter is specifed an object, will be finalised only if its
;       class name matches the argument (case-insensitively). Normally
;       the Init method of a subclass of MGH_GUI_Base (say
;       MGH_GUI_MyClass) will end with
;
;         self->Finalize, 'MGH_GUI_MyClass'
;
;       Then finalisation will be carried out for members of
;       MGH_GUI_MyClass, but for all subclasses it will be postponed,
;       leaving the subclass's Init method to carry out finalisation.
;
;       There are some cases where one will need to call Finalize
;       unconditionally. This should be done, for example, in classes
;       that want to allow the user to interact with the object during
;       the Init method (see MGH_Surface_Movie). It is also
;       recommended when one wishes to set the alignment of a
;       top-level base, because this cannot be done until the base has
;       been realised (see MGH_Conductor).
;
;     FindChild (Function)
;       Find a child widget by name.
;
;     FlushEvents (Procedure)
;       The FlushEvents method causes all events queued for the
;       top-level base to be processed. It can be called periodically
;       by a routine that is controlling the widget, to allow the user
;       to interact with the widget. This allows the user to do
;       inappropriate things but is sometimes very valuable.
;
;     GetBase (Function)
;       Shorthand for GetProperty, BASE=...
;
;     Iconify (Procedure)
;       Minimise or restore the top-level base.
;
;     IsTLB (Function)
;       Return 1 if the base is a top-level base, 0 if it is a child.
;
;     Kill (Procedure)
;       Kill the widget hierarchy.
;
;     Manage (Procedure)
;       Submit the widget hierarchy to XMANAGER; if it is already
;       managed, return without error. If the applicaton is blocking
;       or modal, then this method returns only when the widget
;       hierarchy is destroyed.
;
;       This method will normally be called, if necessary, from the
;       Finalize method, with the important exception of a blocking or
;       modal top-level base, where the creator is reponsible for
;       calling Manage. (There's a good reason for this, but I keep
;       forgetting what it is.)
;
;     NewChild (Function & Procedure)
;       Create a new widget, either invoking a function or creating an
;       object. Optionally return the widget ID (function) or object
;       reference (object). Note that NewChild passes keywords to the
;       widget creator by reference; this is required because some
;       widget-creation functions (CW_BGROUP for one) pass information
;       back to the caller via keyword arguments.
;
;     Realize (Procedure)
;       Realise the widget hierarchy;; if it is already realised,
;       return without error.
;
;     Show (Procedure)
;       Show or hide the top-level base.
;
;     Update (Procedure)
;       Revise the widget appearance so that it agrees with the state
;       of the associated object. MGH_GUI_Base's Update procedure does
;       nothing and may be overridden as necessary in subclasses. It
;       is defined here to guarantee that all subclasses support this
;       method.
;
; A NOTE ON BLOCKING:
;   When running an object widget application, it is important to know
;   whether  the Manage method (which calls XMANAGER) will return
;   immediately, or whether it will return only when the widget tree
;   has been destroyed. I will call the former non-blocking operation
;   and the latter blocking operation, but note that when the terms
;   blocking and non-blocking are discussed in the IDL documentation
;   they refer to whether the command-line is available, which is not
;   quite the same thing.
;
;   The DESTROY property of an MGH_GUI_Base (and any subclass thereof)
;   controls whether the object is destroyed in the widget cleanup
;   method. The default is to set DESTROY to 1 for non-blocking
;   operation and 0 for blocking. The rationale is that for
;   non-blocking operation, destruction of the widget hierarchy will
;   occur some indefinite time after the Manage method returns, by
;   which time the creator will have exited or forgotten the object
;   reference. So the creator cannot be responsible for destroying the
;   object. On the other hand for blocking operation, destruction of
;   the widget hierarchy will have occurred before the Manage method
;   returns. If the object is left intact (though widget-less) then
;   the creator has an opportunity to query it before destroying
;   it. Furthermore if Manage has been called from an object's Init
;   method, then destroying the object inside the Manage method leads
;   to an error (though there is a workaround for this).
;
;   In setting the default value for the DESTROY property, it is
;   assumed that blocking will occur if either the BLOCK or the MODAL
;   property has been set, otherwise it won't. This seems to work fine
;   on the only platform I have used, i.e. IDLDE for Windows. I expect
;   that it would work on most other platforms but NOT on a platform
;   (like the VMS tty) that doesn't support non-blocking operation. (I
;   don't know about run-time IDL--I may getting around to checking
;   this out some day.) I don't know how to detect if a platform
;   supports non-blocking operation. In XMANAGER there is a call to
;   WIDGET_INFO using an undocumented keyword (/XMANAGER_BLOCK) that
;   looks as if it should do the trick, but what it returns is whether
;   the command line is active, i.e. the second sense of blocking
;   rather than the first.
;
;   Therefore the advice is: on platforms that do not support
;   non-blocking operation, always set the BLOCK property to 1.
;
; A NOTE ON EVENT HANDLING:
;   MGH_GUI_Base taps into the event-handling framework supported by
;   IDL's widget routines, notably XMANAGER and WIDGET_EVENT, as
;   follows. An event is a structure with, as a minimum, the tags ID,
;   TOP and HANDLER. Events are generated by widget elements and are
;   passed up through the widget tree. At any level in the tree, a
;   widget event can be intercepted by an event-handler function or
;   procedure. An event-handler function takes an event as its
;   argument and outputs an event (which may or may not be the same
;   one) as its return value. An event-handler function indicates that
;   an event has finally been handled by returning a non-structure
;   value. Otherwise the event is passed further up the tree. An
;   event-handler procedure never passes events on.
;
;   An MGH_GUI_Base intercepts events generated by its children by
;   registering an event procedure with XMANAGER (called by the Manage
;   method). This event procedure (which is called MGH_GUI_BASE_EVENT,
;   though this should not be be of any interest outside the
;   MGH_GUI_Base class) is passed the widget ID of the top-level base
;   and from this retrieves an object reference. (The convention that
;   supports this is documented in the MGH_WIDGET_SELF function.) It
;   then calls the object's Event method.
;
;   MGH_GUI_Base's Event method supports a generic method of event
;   handling known as callbacks. A callback stores an object-method
;   pair inside a structure, attached to the UVALUE of an
;   event-originating widget or compound
;   widget. MGH_GUI_Base::Event(event) tests the widget pointed to by
;   the ID field of each event to see if it contains a callback
;   structure. If it does, then the Event method checks to ensure that
;   the callback's object is the same as "self". If not, this is
;   treated as a non-fatal error. (The obvious alternative is to call
;   the object-method pair specified in the callback. There may be
;   situations where this is attractive but on the whole I think it
;   represents a major violation of encapsulation and sho should be
;   avoided). If all checks have been passed
;   MGH_GUI_Base::Event(event) evaluates
;
;     call_method(method, self, event)
;
;   and returns the result to IDL's event-handler framework. In the
;   case of an MGH_GUI_Base this is a procedure so it swallows the
;   event whatever its value.
;
;   Callbacks are named structures of type MGH_WIDGET_CALLBACK. The
;   structure is defined by MGH_WIDGET_CALLBACK__Define, they are
;   created by the widget base's Callback method, and the question,
;   "Is this a callback" is answered by the function MGH_IS_CALLBACK.
;
;   If MGH_GUI_Base::Event() fails to find a callback associated with
;   an event, and this event is still valid, then it expresses its
;   surprise by calling self->EventUnexpected(event). As defined for
;   MGH_GUI_Base, this prints a warning and swallows the event. This
;   could be overridden in a subclass, I guess.
;
; A NOTE ON REALIZATION
;   Realization of the widget creates problems in the case where a
;   child base is added to an already-realized parent. In this case
;   the child is immediately realized, but in IDL 5.5 and earlier the
;   NOTIFY_REALIZE procedure was never called. In IDL 5.6 the child's
;   NOTIFY_REALIZE procedure *is* called, provided it is specified in
;   the call to WIDGET_BASE that creates the child. The latter
;   behaviour is more correct, but creates problems when the child is
;   an MGH_GUI_BASE object, because MGH_GUI_BASE_NOTIFY_REALIZE needs
;   to retrieve an object reference, and that is not known when the
;   base is first created by a call to WIDGET_BASE. So the sequence is
;   now:
;     - Create the objects base widget with a call to WIDGET_BASE,
;       *without* specifying the NOTIFY_REALIZE property.
;     - Create the invisible child widget and store the reference to
;       "self" there.
;     - Set the base's NOTIFY_REALIZE property with a call to
;       WIdGET_CONTROL.
;     - In the Finalize method, check if the parent has been
;       realized. If so, call NotifyRealize.
;   This sequence should work with IDL versions before 5.6
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
;   Mark Hadfield, 1999-11:
;     Written as MGHwidgetBase, borrowing freely from ideas of Struan
;     Gray (http://www.sljus.lu.se/stm/IDL/Obj_Widgets/).
;   Mark Hadfield, 2000-07:
;     Added the DESTROY property, as part of a general re-think of
;     widget object life cycles.
;   Mark Hadfield, 2001-06:
;     Renamed MGH_GUI_Base and thoroughly overhauled:
;     - Operation as a child base now supported
;     - Handling of keywords is more robust.
;     - Several standard event handling functions are specified. Event
;       handling methods for each child widget can now be specified
;       via callbacks.
;   Mark Hadfield, 2001-10:
;     - Increased maximum number of arguments in NewChild method to 3.
;     - Updated for IDL 5.5.
;   Mark Hadfield, 2002-10:
;     - Changes were made to the initialisation sequence wrt the
;       NOTIFY_REALIZE procedure. See "A note on realization" above.
;     - Updated for IDL 5.6
;   Mark Hadfield, 2010-10:
;     - Now inherits from IDL_Object (introduced in IDL 8.0) and
;       not MGH_Debug
;-

pro mgh_gui_base_kill_notify, id

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   ;; Note that we have to arrange things so that this routine is
   ;; attached to the widget holding the object reference, because a
   ;; widget-cleanup routine can only access the widget that's passed
   ;; to it.

   widget_control, id, GET_UVALUE=uvalue

   self = mgh_widget_self(uvalue)

   if obj_valid(self) then begin
      self->MGH_GUI_Base::GetProperty, DESTROY=destroy
      if destroy then obj_destroy, self
   endif

end

pro mgh_gui_base_event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   self = mgh_widget_self(event.handler, FOUND=found)

   if ~ found then message, 'Could not find object reference'

   if ~ obj_valid(self) then message, 'Object is not valid'

   ;; Pass the event to the Event method. Ignore the result, as the
   ;; class's Event method will normally have a mechanism for printing
   ;; a warning message if an unexpected event is encountered.

   void = self->Event(event)

end


function MGH_GUI_BASE_EVENT_FUNC, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   self = mgh_widget_self(event.handler, FOUND=found)

   if ~ found then message, 'Could not find object reference'
   if ~ obj_valid(self) then message, 'Object is not valid'

   ;; Call the object's the Event method. Pass results to IDL's
   ;; widget-event chain.

   return, self->Event(event)

end

pro MGH_GUI_BASE_NOTIFY_REALIZE, id

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   self = mgh_widget_self(id, FOUND=found)

   if ~ found then message, 'Could not find object reference'
   if ~ obj_valid(self) then message, 'Object is not valid'

   ;; Call the object's NotifyRealize method.

   self->NotifyRealize

end

; The remaining routines define the MGH_GUI_Base class.

; MGH_GUI_Base::Init
;
function MGH_GUI_Base::Init, $
     BLOCK=block, DESTROY=destroy, MBAR=mbar, $
     MODAL=modal, NOTIFY_REALIZE=notify_realize, $
     PARENT=parent, PROCESS_EVENTS=process_events, $
     TITLE=title, VISIBLE=visible, _REF_EXTRA=extra

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  ;; Create a disposal container for easy clean up of resources.

  self.disposal = obj_new('IDL_Container')

  ;; Much of the widget base's behaviour depends on whether it is a
  ;; top-level base or a child. The former is the default; the latter
  ;; is achieved by specifying a PARENT property

  self.parent = n_elements(parent) gt 0 ? parent : 0

  ;; Specify a few key properties and create the main base. Pass to
  ;; it keywords related to TLB behaviour (adult only) and alignment
  ;; relative to parents (child only?). Keywords specifying layout of
  ;; children are passed to the layout base (later).

  if self->IsTLB() then begin
    self.block = keyword_set(block)
    self.modal = keyword_set(modal)
    self.destroy = n_elements(destroy) gt 0  $
      ? keyword_set(destroy) : ~ (self.block || self.modal)
    self.mbar = keyword_set(mbar) && ~ self.modal
    self.visible = n_elements(visible) gt 0  $
      ? keyword_set(visible) && ~ self.modal : 1B
    ;; The following nonsense arises because WIDGET_BASE allows
    ;; different combinations of keywords in different cases
    case 1B of
      self.modal: begin
        self.base = widget_base(/MODAL, _STRICT_EXTRA=extra)
      end
      self.mbar: begin
        self.base = widget_base(MAP=self.visible, MBAR=menu_bar, $
          _STRICT_EXTRA=extra)
        self.menu_bar = menu_bar
      end
      else: begin
        self.base = widget_base(MAP=self.visible, _STRICT_EXTRA=extra)
      endelse
    endcase
  endif else begin
    self.block = 0B
    self.mbar = 0B
    self.modal = 0B
    self.destroy = 1B
    self.visible = n_elements(visible) gt 0  ? keyword_set(visible) : 1B
    self.base = widget_base(self.parent, MAP=self.visible, _STRICT_EXTRA=extra)
  endelse

  ;; In IDL 5.4 the present function created a child base, called the "layout
  ;; base". This was the base to which other children were added and
  ;; it was also used to store a reference to the current object in
  ;; its UVALUE. It was done this way because it was necessary to
  ;; store the object reference in a child of the main widget and
  ;; there was no way of creating a zero-size, invisible child. The
  ;; context-menu bases introduced in IDL 5.5 meet this requirement
  ;; so we can dispense with the multi-tiered structure. The LAYOUT
  ;; tag in the class structure is retained for backward
  ;; compatibility.

  void = widget_base(self.base, /CONTEXT_MENU, $
    KILL_NOTIFY='MGH_GUI_BASE_KILL_NOTIFY', $
    UVALUE=mgh_widget_self(STORE=self))

  self.layout = self.base

  ;; Set the base's NOTIFY_REALIZE property.

  self.notify_realize = keyword_set(notify_realize)
  if self.notify_realize then $
    widget_control, self.base, NOTIFY_REALIZE='MGH_GUI_BASE_NOTIFY_REALIZE'

  ;; Set remaining properties & return

  if self->IsTLB() then begin
    process_events = 0
  endif else begin
    process_events = n_elements(process_events) gt 0 ? process_events : 1
  endelse

  ;; I don't think there is any valid reason to set UVALUE and UNAME
  ;; for a top-level base but I may change my mind.

  self->MGH_GUI_Base::SetProperty, PROCESS_EVENTS=process_events, $
    TITLE=title, UNAME=uname, UVALUE=uvalue

  self->Finalize, 'MGH_GUI_Base'

  return, 1

end


; MGH_GUI_Base::Cleanup
;
pro MGH_GUI_Base::Cleanup

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  obj_destroy, self.disposal

  if widget_info(self.base, /VALID_ID) then $
    widget_control, self.base, /DESTROY

end


; MGH_GUI_Base::GetProperty
;
pro MGH_GUI_Base::GetProperty, $
     ALL=all, BASE=base, BLOCK=block, DESTROY=destroy, GEOMETRY=geometry, $
     LAYOUT=layout, MANAGED=managed, MENU_BAR=menu_bar, MODAL=modal, $
     NOTIFY_REALIZE=notify_realize, PARENT=parent, PROCESS_EVENTS=process_events, $
     REALIZED=realized, $
     TITLE=title, TLB_SIZE_EVENTS=tlb_size_events, UNAME=uname, $
     UPDATE=update, UVALUE=uvalue, VALID=valid, $
     VISIBLE=visible, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   base = self.base

   block = self.block

   destroy = self.destroy

   layout = self.layout

   modal = self.modal

   menu_bar = self.menu_bar

   notify_realize = self.notify_realize

   process_events = self.process_events

   parent = self.parent

   title = self.title

   valid = widget_info(self.base, /VALID_ID)

   visible = self.visible

   if valid then begin
     geometry = widget_info(self.base, /GEOMETRY)
     managed = widget_info(self.base, /MANAGED)
     realized = widget_info(self.base, /REALIZED)
     sensitive = widget_info(self.base, /SENSITIVE)
     tlb_size_events = widget_info(self.base, /TLB_SIZE_EVENTS)
     uname = widget_info(self.base, /UNAME)
     update = widget_info(self.base, /UPDATE)
     widget_control, self.base, GET_UVALUE=uvalue
   endif else begin
     geometry = 0B
     managed = 0B
     realized = 0B
     sensitive = 0B
     tlb_size_events = 0B
     uname = 0B
     update = 0B
   endelse

   if arg_present(all) then begin
      all = { base:base, block:block, destroy:destroy, geometry:geometry, $
              layout:layout, managed:managed, menu_bar:menu_bar, modal:modal, $
              notify_realize:notify_realize, parent:parent, $
              process_events:process_events, realized:realized, title:title, $
              uname:uname, update:update, valid:valid, visible:visible}
   endif

end

; MGH_GUI_Base::SetProperty
;
pro MGH_GUI_Base::SetProperty, $
     GROUP_LEADER=group_leader, MANAGED=managed, $
     NOTIFY_REALIZE=notify_realize, $
     PROCESS_EVENTS=process_events, $
     REALIZED=realized, TITLE=title, TLB_SIZE_EVENTS=tlb_size_events, UNAME=uname, $
     UPDATE=update, UVALUE=uvalue, VISIBLE=visible, $
     XOFFSET=xoffset, YOFFSET=yoffset

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   valid = widget_info(self.base, /VALID_ID)

   if valid then begin

      if keyword_set(realized) then $
           self->Realize

      if keyword_set(managed) then $
           self->Manage

      if n_elements(notify_realize) gt 0 then begin
         self.notify_realize = keyword_set(notify_realize)
         nr = self.notify_realize ? 'MGH_GUI_BASE_NOTIFY_REALIZE' : ''
         widget_control, self.base, NOTIFY_REALIZE=nr
      endif

      if n_elements(uname) gt 0 then $
           widget_control, self.base, SET_UNAME=uname

      if n_elements(tlb_size_events) gt 0 then $
           widget_control, self.base, TLB_SIZE_EVENTS=tlb_size_events

      if n_elements(update) gt 0 then $
           widget_control, self.base, UPDATE=keyword_set(update)

      if n_elements(uvalue) gt 0 then $
           widget_control, self.base, SET_UVALUE=uvalue

      if n_elements(visible) gt 0 && ~ self.modal then begin
         self.visible = keyword_set(visible)
         widget_control, self.base, MAP=self.visible
      endif

      if n_elements(xoffset) gt 0 then $
           widget_control, self.base, XOFFSET=round(xoffset)

      if n_elements(yoffset) gt 0 then $
           widget_control, self.base, YOFFSET=round(yoffset)

      case self->IsTLB() of

         0: begin

            if n_elements(process_events) gt 0 then begin
               self.process_events = keyword_set(process_events)
               ef = self.process_events ? 'MGH_GUI_BASE_EVENT_FUNC' : ''
               widget_control, self.base, EVENT_FUNC=ef
            endif

         end

         1: begin

            for i=0,n_elements(group_leader)-1 do $
                 widget_control, self.base, GROUP_LEADER=group_leader[i]

            if keyword_set(managed) then $
                 self->Manage

            if n_elements(title) gt 0 then begin
               self.title = title
               widget_control, self.base, TLB_SET_TITLE=self.title
            endif

         end

      endcase

   endif

end

; MGH_GUI_Base::About
;
;   Print information about the object.
;
pro MGH_GUI_Base::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(lun) eq 0 then lun = -1

   printf, lun, FORMAT='(%"%s: hello, my base widget ID is %d")', $
           mgh_obj_string(self), self.base

   case self->IsTLB() of
      0: begin
         printf, lun, FORMAT='(%"%s: hello, my parent widget ID is %d")', $
                 mgh_obj_string(self), self.parent
      end
      1: begin
         printf, lun, FORMAT='(%"%s: I am a top-level base")', $
                 mgh_obj_string(self)
         printf, lun, FORMAT='(%"%s: my BLOCK & MODAL properties are %d %d")', $
                 mgh_obj_string(self), self.block, self.modal
      end
   endcase

   desc = mgh_widget_descendants(self.base)
   n_desc = n_elements(desc)
   printf, lun, FORMAT='(%"%s: I have %d widget descendants %s")', $
           mgh_obj_string(self), n_desc, strjoin(strtrim(desc,2), ' ')

end

; MGH_GUI_Base::Align
;
;   Align (i.e. reposition) the widget application. By default it is aligned
;   relative to the screen, but it can be aligned relative to another widget
;   application by specifying that application's widget ID or object reference
;   via the RELATIVE keyword.
;
pro MGH_GUI_Base::Align, Alignment, RELATIVE=relative

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.parent gt 0 then $
        message, /INFORM, "Sorry I don't do child widgets right now."

   ;; Convert the alignment argument to a 2-element numeric value

   case n_elements(alignment) of
      0:  wpos = [0.5,0.5]
      1:  wpos = [alignment,alignment]
      2:  wpos = alignment
      else:  message, 'Invalid value for widget position'
   endcase

   ;; Establish the offset and size of the rectangle in which the base
   ;; is to be aligned

   case size(relative, /TNAME) of

      ;; Align relative to screen
      'UNDEFINED': begin
         roffset = [0,0]
         rsize = get_screen_size()
      end

      ;; Align relative to a top level base widget specified by its ID
      'LONG': begin
         if ~ widget_info(relative, /VALID_ID) then $
              message, 'The RELATIVE widget ID is invalid'
         if widget_info(relative, /PARENT) ne 0 then $
              message, 'The RELATIVE widget is not a top level base'
         rgeom = widget_info(relative, /GEOMETRY)
         roffset = [rgeom.xoffset, rgeom.yoffset]
         rsize = [rgeom.scr_xsize, rgeom.scr_ysize] + 2*rgeom.margin
      end

      ;; Align relative to an MGH_GUI_Base object
      'OBJREF': begin
         if ~ obj_isa(relative, 'MGH_GUI_Base') then begin
            message, 'I can align relative to an object ' + $
                     'only if it is a MGH_GUI_Base'
         endif
         relative->GetProperty, GEOMETRY=rgeom
         roffset = [rgeom.xoffset, rgeom.yoffset]
         rsize = [rgeom.scr_xsize, rgeom.scr_ysize] + 2*rgeom.margin
      end

   endcase

   self->GetProperty, GEOMETRY=geom
   ;; This is our best estimate of our top level base's
   ;; screen size (see documentation for WIDGET_INFO's GEOMETRY
   ;; keyword
   size = [geom.scr_xsize, geom.scr_ysize] + 2*geom.margin

   offset = roffset + wpos*(rsize-size)

   self->MGH_GUI_Base::SetProperty, XOFFSET=offset[0], YOFFSET=offset[1]

end


; MGH_GUI_Base::CallBack
;
;   Return a callback to be stored in the UVALUE of a widget.
;
function MGH_GUI_Base::Callback, method

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = {MGH_WIDGET_CALLBACK}

   result.object = self
   result.method = method

   return, result

end


; MGH_GUI_Base::Clear
;
;   Delete all children from the base. Do not delete the
;   first one, which is an invisible and uninitialised context menu.
;
pro MGH_GUI_Base::Clear

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   child = mgh_widget_getchild(self.layout, /ALL, COUNT=n_child)

   for i=1,n_child-1 do widget_control, child[i], /DESTROY

end

; MGH_GUI_Base::Dispose
;
;   Add one or more objects to the widget's disposal container.
;
pro MGH_GUI_Base::Dispose, obj

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(obj)-1 do begin
      if obj_valid(obj[i]) then self.disposal->Add, obj[i]
   endfor

end


; MGH_GUI_Base::Event
;
;   The Event method is called by the event procedure. MGH_GUI_Base's
;   Event method resolves callbacks stored in the originating widget's
;   UVALUE. Subclasses can handle events by providing suitable
;   callbacks and/or by extending the Event method.
;
function MGH_GUI_Base::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ mgh_is_event(event) then return, 0

   ;; If the event originates from a known source, pass it to the
   ;; appropriate method

   if event.id eq self.base then $
        return, self->EventBase(event)

   if event.id eq self.menu_bar then $
        return, self->EventMenuBar(event)

   ;; If the UVALUE of the widget that generated the event is a
   ;; callback structure, then call the appropriate method. If the
   ;; callback points to another object, treat this as a non-fatal
   ;; error.

   widget_control, event.id, GET_UVALUE=uvalue
   if mgh_is_callback(uvalue) then begin
      case uvalue.object of
         self: return, call_method(uvalue.method, self, event)
         else: begin
            message, /INFORM, 'Foreign callback received by object '+ $
                     string(self, /PRINT)
            help, /STRUCT, uvalue
            return, 0
         end
      endcase
   endif

   ;; Dunno

   return, self->EventUnexpected(event)

end

; MGH_GUI_Base::EventBase
;
;   Handle events from the base widget.
;
function MGH_GUI_Base::EventBase, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self->EventUnexpected(event)

end

; MGH_GUI_Base::EventGeneric
;
;   Transform events in a generic way and pass them on.
;
function MGH_GUI_Base::EventGeneric, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ mgh_is_event(event) then return, 0

   ;; The event now appears to have come from self.base
   ;; The top of the widget hierarchy isunchanged
   ;; The handler will be filled in by WIDGET_EVENT

   return, {id: self.base, $
            top: event.top, $
            handler: 0, $
            uname: widget_info(event.id, /UNAME), $
            event: event}

end

; MGH_GUI_Base::EventMenuBar
;
;   Handle events from the menu bar
;
function MGH_GUI_Base::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self->EventUnexpected(event)

end

; MGH_GUI_Base::EventUnexpected
;
;   Deal with unexpected events
;
function MGH_GUI_Base::EventUnexpected, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ mgh_is_event(event) then return, 0

   if (self.parent gt 0) && (obj_class(self) eq 'MGH_GUI_BASE') then $
        return, self->EventGeneric(event)

   ;; No handler found; print a warning message and swallow the event.

   print, self, ': Unexpected event:'
   help, /STRUCT, event

   return, 0

end

; MGH_GUI_Base::Finalize
;
pro MGH_GUI_Base::Finalize, final

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(final) eq 0 then final = obj_class(self)

   if strmatch(obj_class(self), final, /FOLD_CASE) then begin

      case self->IsTLB() of

         0: begin
            if widget_info(self.parent, /REALIZED) then self->NotifyRealize
         end

         1: begin
            self->Realize
            self->Update
            if ~ (self.block || self.modal) then self->Manage
         end

      endcase

   endif

end

; MGH_GUI_Base::FindChild
;
function MGH_GUI_Base::FindChild, item

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, widget_info(self.layout, FIND_BY_UNAME=item)

end

; MGH_GUI_Base::FlushEvents
;
; The FlushEvents method causes all events queued for the base to be
; processed. It can be called periodically by a routine that is
; controlling the widget to allow the user to interact with the
; widget. This obviously has its dangers!
;
pro MGH_GUI_Base::FlushEvents

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   repeat begin
      event = widget_event(self.base, /NOWAIT)
   endrep until ~ widget_info(event.id, /VALID_ID)

end

; MGH_GUI_Base::GetBase
;
function MGH_GUI_Base::GetBase

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.base

end

; MGH_GUI_Base::Iconify
;
;   Minimise or restore the base.
;
pro MGH_GUI_Base::Iconify, flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = 1
   widget_control, self.base, ICONIFY=flag

end


; MGH_GUI_Base::IsTLB
;
function MGH_GUI_Base::IsTLB

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.parent eq 0

end


; MGH_GUI_Base::Kill
;
;   Kill the widget hierarchy. This causes MGH_GUI_BASE_KILL_NOTIFY to
;   be called.
;
pro MGH_GUI_Base::Kill

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   widget_control, self.base, /DESTROY

end

; MGH_GUI_Base::Manage
;
pro MGH_GUI_Base::Manage

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.parent gt 0 then return

   self->MGH_GUI_Base::GetProperty, MANAGED=managed, VALID=valid
   if valid && (~ managed) then begin
      xmanager, obj_class(self), self.base, $
                EVENT='MGH_GUI_BASE_EVENT', NO_BLOCK=(~ self.block)
   endif

end

; MGH_GUI_Base::NewChild
;
function MGH_GUI_Base::NewChild, widget, arg0, arg1, arg2, $
     OBJECT=object, PARENT=parent, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(type) eq 0 then type = 'function'

   if n_elements(widget) eq 0 then $
        message, 'You must specify a widget-creation function or class name'

   if size(widget, /TNAME) ne 'STRING' then $
        message, 'You must specify a widget-creation function or class name'

   ;; Locate parent

   if n_elements(parent) eq 0 then parent = self.layout

   case size(parent, /TNAME) eq 'STRING' of
      0: parentID = parent
      1: parentID = self->FindChild(parent)
   endcase

   case n_params() of
      1: begin
         case keyword_set(object) of
            0: begin
               return, call_function(widget, parentID, $
                                     _STRICT_EXTRA=extra)
            end
            1: begin
               return, obj_new(widget, PARENT=parentID, $
                               _STRICT_EXTRA=extra)
            end
         endcase
      end
      2: begin
         case keyword_set(object) of
            0: begin
               return, call_function(widget, parentID, arg0, $
                                     _STRICT_EXTRA=extra)
            end
            1: begin
               return, obj_new(widget, arg0, PARENT=parentID, $
                               _STRICT_EXTRA=extra)
            end
         endcase
      end
      3: begin
         case keyword_set(object) of
            0: begin
               return, call_function(widget, parentID, arg0, arg1, $
                                     _STRICT_EXTRA=extra)
            end
            1: begin
               return, obj_new(widget, arg0, arg1, PARENT=parentID, $
                               _STRICT_EXTRA=extra)
            end
         endcase
      end
      4: begin
         case keyword_set(object) of
            0: begin
               return, call_function(widget, parentID, arg0, arg1, arg2, $
                                     _STRICT_EXTRA=extra)
            end
            1: begin
               return, obj_new(widget, arg0, arg1, arg2, PARENT=parentID, $
                               _STRICT_EXTRA=extra)
            end
         endcase
      end
   endcase

end

pro MGH_GUI_Base::NewChild, widget, arg0, arg1, arg2, RESULT=result, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      1: result = self->NewChild(widget, _STRICT_EXTRA=extra)
      2: result = self->NewChild(widget, arg0, _STRICT_EXTRA=extra)
      3: result = self->NewChild(widget, arg0, arg1, _STRICT_EXTRA=extra)
      4: result = self->NewChild(widget, arg0, arg1, arg2, _STRICT_EXTRA=extra)
   endcase

end

; MGH_GUI_Base::NotifyRealize
;
pro MGH_GUI_Base::NotifyRealize

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

; MGH_GUI_Base::Realize
;
;   Realise the widget hierarchy (if necessary)
;
pro MGH_GUI_Base::Realize

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::GetProperty, REALIZED=realized
   if ~ realized then widget_control, self.base, /REALIZE

end

; MGH_GUI_Base::Show
;
;   Show/hide the base
;
pro MGH_GUI_Base::Show, flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = 1B
   if flag then widget_control, self.base, ICONIFY=0
   widget_control, self.base, SHOW=flag

end

; MGH_GUI_Base::Update
;
;   Update the widget appearance.
;
pro MGH_GUI_Base::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

end

; MGH_GUI_Base__Define
;
pro MGH_GUI_Base__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_Base, inherits IDL_Object, $
                 base: 0L, block: 0B, destroy: 0B, $
                 disposal: obj_new(), layout: 0L, mbar: 0B, menu_bar: 0L, $
                 notify_realize: 0B, modal: 0B, parent: 0L, $
                 process_events: 0B, title: '', visible: 0B}

end
