; svn $Id$
;+
; NAME:
;   MGH_LOOP
;
; PURPOSE:
;   This routine starts an event-processing loop and sets up
;   a widget interface that allows the user to stop it. It is
;   useful to allow non-blocking widget applications to be used
;   when execution is stopped at a breakpoint.
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
;   Mark Hadfield, 2004-06:
;     Written.
;-

function MGH_Loop::Init, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt HIDDEN

   ok = self->MGH_GUI_Base::Init(BLOCK=0, /COLUMN, VISIBLE=0, $
                                 TLB_SIZE_EVENTS=0, TLB_FRAME_ATTR=1+8, $
                                 TITLE='IDL Event Loop', _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   self->NewChild, 'widget_base', XSIZE=200, YPAD=0, YSIZE=0

   self.button = self->NewChild('widget_button', VALUE='End Loop')

   self.exit = 0

   self->Finalize

   if self->IsTLB() then self->Align, [0.50,0.75]

   self->SetProperty, /VISIBLE

   return, 1

end

function MGH_Loop::Event, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if event.id eq self.button then begin
      self.exit = 1
      return, 0
   end

   return, self->MGH_GUI_Base::Event(event)

end

pro MGH_Loop::Loop

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   while 1 do begin
      void = widget_event(/NOWAIT)
      if ~obj_valid(self) || self.exit then break
      wait, 0.05
   endwhile

end

pro MGH_Loop__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Loop, inherits MGH_GUI_Base, $
                 button: 0L, exit: 0B}

end

pro mgh_loop

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   oloop = obj_new('mgh_loop')

   oloop->Loop

   obj_destroy, oloop

end
