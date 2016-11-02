; svn $Id$
;+
; NAME:
;   MGHwaiter
;
; PURPOSE:
;   Maintains a widget which allows the user to abort or suspend execution.
;
; CATEGORY:
;   Utilities.
;
; PROCEDURE:
;   To allow user intervention in a lengthy calculation, we create an
;   MGHwaiter object. This appears as a widget base with 3 buttons:
;   'Abort', 'Suspend' and 'Resume', the last being initially
;   insensitive. We then call the object's Yield method at regular
;   intervals throughout the calculation.  The Yield method checks to
;   see if any of the buttons has been pressed.  If the Abort button
;   has been pressed, then Yield calls the MESSAGE procedure to raise
;   an error. If the Suspend button has been pressed, then Yield goes
;   into an infinite loop calling WAIT until Resume is pressed.
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
;   Mark Hadfield, Apr 1994:
;     Written as procedure YIELD. This was originally intended for use
;     under co-operative multi-tasking versions of Windows; it called
;     the Windows API "Yield" function to yield control to other
;     processes.
;   Mark Hadfield, Oct 1995:
;     Removed calls to the Win API Yield function. Now all the YIELD
;     procedure does is to maintain a widget and check its state.
;   Mark Hadfield, Jun 1999:
;     This application was converted to an object called MGHwaiter.
;   Mark Hadfield, May 2000:
;     MGHwaiter is now a subclass of MGH_GUI_Base and uses the
;     superclass's facilities for event handling and appearance
;     copntrol. This means it no longer requires the obsolete XMENU
;     routine.
;-
function MGHwaiter::Init, TITLE=title, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(title) eq 0 then title = 'IDL Waiter'

   ok = self->MGH_GUI_Base::Init(BLOCK=0, MODAL=0, /ROW, TITLE=title, $
                                 TLB_SIZE_EVENTS=0, TLB_FRAME_ATTR=1, $
                                 _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   self.abort = 0
   self.suspend = 0

   self.buttons[0] = widget_button(self.layout, VALUE='Abort')
   self.buttons[1] = widget_button(self.layout, VALUE='Suspend')
   self.buttons[2] = widget_button(self.layout, VALUE='Resume')

   widget_control, self.buttons[2], SENSITIVE=0

   self.tprev = systime(1)

   self->Realize

   self->Manage

   return, 1

end

; MGHwaiter::Event
;
function MGHwaiter::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   case event.id of

      self.buttons[0]: begin
         self.abort = 1
         widget_control, self.buttons[0], SENSITIVE=0
         widget_control, self.buttons[1], SENSITIVE=0
         widget_control, self.buttons[2], SENSITIVE=0
         return, 0
      end

      self.buttons[1]: begin
         self.suspend = 1
         widget_control, self.buttons[0], SENSITIVE=1
         widget_control, self.buttons[1], SENSITIVE=0
         widget_control, self.buttons[2], SENSITIVE=1
         return, 0
      end

      self.buttons[2]: begin
         self.suspend = 0
         widget_control, self.buttons[0], SENSITIVE=1
         widget_control, self.buttons[1], SENSITIVE=1
         widget_control, self.buttons[2], SENSITIVE=0
         return, 0
      end

   endcase

   return, event

end

pro MGHwaiter::Wait, delay

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(delay) eq 0 then delay = 1.

   t0 = systime(1)

   while systime(1) le t0+delay do self->Yield

end

pro MGHwaiter::Yield

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   on_error, 2

   tnow = systime(1)
   if (tnow-self.tprev) le 0.2 then return
   self.tprev = tnow

   while 1B do begin

      self->FlushEvents

      if self.abort then $
           message, "Operation aborted by MGHwaiter object."

      if ~ self.suspend then break

      wait, 0.2

   endwhile

end

pro MGHwaiter__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   struct_hide, {MGHwaiter, inherits MGH_GUI_Base, $
                 buttons: lonarr(3), tprev: 0D, abort: 0B, suspend: 0B}

end
