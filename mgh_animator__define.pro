;+
; CLASS:
;   MGH_Animator
;
; PURPOSE:
;   This class supports basic animation functionality, common to the
;   MGH_DGplayer, MGH_Player and MGH_Conductor classes.
;
; SUPERCLASSES:
;   MGH_GUI_Base
;
; PROPERTIES:
;   In addition to those inherited from MGH_GUI_Base:
;
;     N_FRAMES (Get)
;       Number of frames currently held by the animator.
;
;     PLAYBACK (Get, Set)
;       A named structure of type MGH_ANIMATOR_PLAYBACKINFO containing
;       properties controlling playback. See below.
;
;     POSITION (Get, Set)
;       The current position of the animator. During playback the
;       animator controls the POSITION property but there are times
;       when it is desirable to control it from outside.
;
;   There are several properties controlling playback. They are
;   accessed collectively via the PLAYBACK property or individually
;   via the GetPlayback and SetPlayback methods.
;
;     LOOP
;       Controls what happens when playback reaches one of the
;       endpoints:
;         0 - Stop
;         1 - Return to opposite end of animation and repeat in same
;             direction
;         2 - Play in reverse direction from current end point.
;
;     DELAY
;       A 3-element integer array specifying the delay in milliseconds,
;       in the form [between frames, additional on first frame,
;       additional on last frame]
;
;     RANGE
;       A 3-element integer array specifying the playback range and
;       stride, in the form [first frame, last frame, stride]. If
;       USE_RANGE is not set, then this is ignored (but remembered).
;
;     USE_RANGE
;       Set this property to have the playback range and stride
;       controlled by the RANGE property. Default is all frames @
;       stride one.
;
; METHODS:
;   The methods in this class provide minimal functionality and will
;   normally be overriden or extended by subclasses:
;
;     BuildDelayBar
;       Show or hide (actually create or destroy) a widget bar with
;       fields for setting the delay.
;
;     BuildPlayBar
;       Show or hide (actually create or destroy) a bar with "Play",
;       "Stop", etc buttons plus a droplist to control the LOOP
;       parameter.
;
;     BuildRangeBar
;       Show or hide (actually create or destroy) a bar with fields
;       for activating the USE_RANGE prperty and setting the RANGE
;       parameters.
;
;     BuildSliderBar
;       Show or hide (actually create or destroy) a bar with a slider,
;       which displays and can be used to reset, the current position.
;
;     CountFrames (deleted??)
;       This method is called before the N_FRAMES property is
;       evaluated and provides an opportunity to update the
;       property. In MGH_Animator this does nothing; subclasses may
;       override it to count frames in an animation.
;
;     Display
;       Display current frame (if a frame is specified then make it
;       the current frame first) and update animation widgets.
;
;     GetPlayBack
;       Return parameters that control playback.
;
;     Play
;       Initiate playback
;
;     PlayNext
;       Specify next frame for playback and set a widget timer
;       event. This routine is the main driver of the animation
;       logic.
;
;     PlayStop
;       Stop playback.
;
;     TimeFrames
;       Play the animation once and report the time per frame. The
;       frames to be played are controlled by the RANGE and USE_RANGE
;       properties. This method calls Display for each frame; this
;       displays the frame and updates the slider bar. It does not
;       exercise the event-driven animation logic in the Play,
;       PlayNext and Playstop methods. I did some ad hoc tests with a
;       naked MGH_Animator object with 10,000 frames on my current
;       machine (Pentium 3 800 MHz, Windows 2000, IDL 5.5). The
;       results:
;
;         a) Calling the Display method with the slider-bar update
;         disabled (commented out) takes 0.008 ms per frame. Yes
;         that's 8 microseconds!
;
;         b) Calling the Display method with the normal slider-bar
;         update takes 0.03 ms per frame.
;
;         c) Playing the animation normally with zero delay takes
;         0.08 ms per frame, ie. an additional 0.05 ms compared with b).
;
;       Thus the animation overhead is negligible in normal
;       animated-graphics applications, where delays & drawing times
;       are ~ 30 ms or more.
;
;     Update
;       This is a method inherited from MGH_GUI_Base and
;       conventionally called to tell  a widget application to update
;       its state and appearance. The MGH_Animator method counts
;       frames and calls the individual Update... routine for each of
;       the widget components.
;
;     UpdateDelayBar
;     UpdatePlayBar
;     UpdateRangeBar
;     UpdateSliderBar
;       Update the respective widget component.
;
; OPERATION:
;   Too complicated to describe fully here, but note the following
;   accelerator keys:
;     Ctrl+Space - Stop/Start
;     Ctrl+Up    - Set play direction backward.
;     Ctrl+Down  - Set play direction forward.
;     Ctrl+Home  - Go to beginning of animation (or beginning of range
;                  if USE_RANGE is in effect).
;     Ctrl+End   - Go to end of animation (or end of range if USE_RANGE
;                  is in effect).
;     Ctrl+Left  - Go back one step (one stride if USE_RANGE is in
;                  effect).
;     Ctrl+Right - Go forward one step (one stride if USE_RANGE is in
;                  effect).
;
;###########################################################################
; Copyright (c) 2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-11.
;     Written as MGHgrAnimatorBase.
;   Mark Hadfield, 2000-05.
;     Allowed for larger delay on first & last frames. Delays now in
;     milliseconds.
;   Mark Hadfield, 2001-07.
;     Renamed MGH_Animator. Overhauled as part of a thorough rewrite
;     of widget and graphics classes.
;   Mark Hadfield, 2001-11.
;     Implemented context menus.
;   Mark Hadfield, 2002-10.
;     Implemented check buttons on the context menus.
;   Mark Hadfield, 2004-05.
;     Implemented accelerator keys for the play bar and changed
;     the play bar's layout to make key-driven operation more logical.
;   Mark Hadfield, 2007-10.
;     Changed order of operation in the PlayNext method to work
;     around problem in IDL 7.0 pre-release: IDL was losing track of
;     widget timer events (but only one in every ten or so) if they came
;     due when IDL was busy. Solution is to call the Display method
;     before generating a new timer event.
;-

; MGH_Animator::Init
;
; Purpose:
;   Initialise an MGH_Animator object.
;
function MGH_Animator::Init, $
     CLIENT=client, EXAMPLE=example, $
     EXPAND_DELAY_BAR=expand_delay_bar, $
     EXPAND_PLAY_BAR=expand_play_bar, $
     EXPAND_RANGE_BAR=expand_range_bar, $
     EXPAND_SLIDER_BAR=expand_slider_bar, $
     PLAYBACK=playback, SLAVE=slave, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Initialise the widget base

   ok = self->MGH_GUI_Base::Init(/COLUMN, /BASE_ALIGN_CENTER, YPAD=0, $
                                 _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Specify client

   if n_elements(client) gt 0 then self.client = client

   ;; Set defaults for playback info

   self.playback.active = 0
   self.playback.loop = 1
   self.playback.forward = 1
   self.playback.use_range = 0
   self.playback.range = [0,-1,1]
   self.playback.delay = [70,500,500]

   ;; Store bitmaps for button widgets...

   ;; ...Play forward/backward

   im = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]

   self.bitmaps[0] = ptr_new(cvttobm(im))
   self.bitmaps[1] = ptr_new(cvttobm(reverse(im)))
   mgh_undefine, im

   ;; ...Stop

   im = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]

   self.bitmaps[2] = ptr_new(cvttobm(im))
   mgh_undefine, im

   ;; ...Go to beginning/end of range

   im = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,1,0,0,0,0,0,0,0,0,0,1,1,0,0], $
         [0,0,1,1,1,0,0,0,0,0,0,0,1,1,0,0], $
         [0,0,1,1,1,1,1,0,0,0,0,0,1,1,0,0], $
         [0,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0], $
         [0,0,1,1,1,1,1,1,1,1,1,0,1,1,0,0], $
         [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0], $
         [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0], $
         [0,0,1,1,1,1,1,1,1,1,1,0,1,1,0,0], $
         [0,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0], $
         [0,0,1,1,1,1,1,0,0,0,0,0,1,1,0,0], $
         [0,0,1,1,1,0,0,0,0,0,0,0,1,1,0,0], $
         [0,0,1,0,0,0,0,0,0,0,0,0,1,1,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]

   self.bitmaps[3] = ptr_new(cvttobm(reverse(im)))
   self.bitmaps[6] = ptr_new(cvttobm(im))
   mgh_undefine, im

   ;; ...Go backward/forward one step

   im = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,1,1,0,0,1,0,0,0,0,0,0,0,0,0,0], $
         [0,1,1,0,0,1,1,1,0,0,0,0,0,0,0,0], $
         [0,1,1,0,0,1,1,1,1,1,0,0,0,0,0,0], $
         [0,1,1,0,0,1,1,1,1,1,1,1,0,0,0,0], $
         [0,1,1,0,0,1,1,1,1,1,1,1,1,1,0,0], $
         [0,1,1,0,0,1,1,1,1,1,1,1,1,1,1,0], $
         [0,1,1,0,0,1,1,1,1,1,1,1,1,1,1,0], $
         [0,1,1,0,0,1,1,1,1,1,1,1,1,1,0,0], $
         [0,1,1,0,0,1,1,1,1,1,1,1,0,0,0,0], $
         [0,1,1,0,0,1,1,1,1,1,0,0,0,0,0,0], $
         [0,1,1,0,0,1,1,1,0,0,0,0,0,0,0,0], $
         [0,1,1,0,0,1,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
         [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]

   self.bitmaps[4] = ptr_new(cvttobm(reverse(im)))
   self.bitmaps[5] = ptr_new(cvttobm(im))
   mgh_undefine, im

   ;; A slave??

   self.slave = n_elements(slave) gt 0 ? keyword_set(slave) : 0

   ;; Default for UI components

   if n_elements(expand_slider_bar) eq 0 then expand_slider_bar = 1B
   if n_elements(expand_play_bar) eq 0 then expand_play_bar = (self.slave eq 0)
   if n_elements(expand_delay_bar) eq 0 then expand_delay_bar = 0B
   if n_elements(expand_range_bar) eq 0 then expand_range_bar = 0B

   ;; Build UI components.

   self->BuildSliderBar, keyword_set(expand_slider_bar)
   self->BuildPlayBar, keyword_set(expand_play_bar)
   self->BuildDelayBar, keyword_set(expand_delay_bar)
   self->BuildRangeBar, keyword_set(expand_range_bar)

   self->BuildSliderContext
   self->BuildPlayContext
   self->BuildDelayContext
   self->BuildRangeContext

   ;; For testing and demonstration purposes:

   if keyword_set(example) then self.n_frames = 10000

   ;; Finalise appearance & return.

   self->MGH_Animator::SetProperty, PLAYBACK=playback

   self->Finalize, 'MGH_Animator'

   return, 1

end


; MGH_Animator::Cleanup
;
pro MGH_Animator::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::Cleanup

   ptr_free, self.bitmaps

end

; MGH_Animator::GetProperty
;
pro MGH_Animator::GetProperty, $
     ALL=all, $
     EXPAND_DELAY_BAR=expand_delay_bar, $
     EXPAND_PLAY_BAR=expand_play_bar, $
     EXPAND_RANGE_BAR=expand_range_bar, $
     EXPAND_SLIDER_BAR=expand_slider_bar, $
     N_FRAMES=n_frames, POSITION=position, $
     PLAYBACK=playback, SLAVE=slave, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::GetProperty, ALL=all, _STRICT_EXTRA=extra

   expand_delay_bar = self.expand_delay_bar
   expand_play_bar = self.expand_play_bar
   expand_range_bar = self.expand_range_bar
   expand_slider_bar = self.expand_slider_bar

   n_frames = self.n_frames

   playback = self.playback

   position = self.position

   slave = self.slave

   if arg_present(all) then begin
      all = create_struct(all, $
                          'expand_delay_bar', expand_delay_bar, $
                          'expand_play_bar', expand_play_bar, $
                          'expand_range_bar', expand_range_bar, $
                          'expand_slider_bar', expand_slider_bar, $
                          'n_frames', n_frames, 'playback', playback, $
                          'position', position, 'slave', slave)
   endif


end

; MGH_Animator::SetProperty
;
pro MGH_Animator::SetProperty, $
     EXPAND_DELAY_BAR=expand_delay_bar, $
     EXPAND_PLAY_BAR=expand_play_bar, $
     EXPAND_RANGE_BAR=expand_range_bar, $
     EXPAND_SLIDER_BAR=expand_slider_bar, $
     N_FRAMES=n_frames, PLAYBACK=playback, $
     POSITION=position, SLAVE=slave, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(slave) gt 0 then begin
      self->PlayStop
      self.slave = keyword_set(slave)
      case self.slave of
         0B: begin
            expand_slider_bar = 1
            expand_play_bar = 1
         end
         1B: begin
            expand_delay_bar = 0
            expand_play_bar = 0
            expand_range_bar = 0
         end
      endcase
   endif

   if n_elements(expand_delay_bar) gt 0 then $
        self->BuildDelayBar, keyword_set(expand_delay_bar)

   if n_elements(expand_play_bar) gt 0 then $
        self->BuildPlayBar, keyword_set(expand_play_bar)

   if n_elements(expand_range_bar) gt 0 then $
        self->BuildRangeBar, keyword_set(expand_range_bar)

   if n_elements(expand_slider_bar) gt 0 then $
        self->BuildSliderBar, keyword_set(expand_slider_bar)

   if n_elements(n_frames) gt 0 then $
        self.n_frames = n_frames

   if n_elements(playback) gt 0 then begin
      playback_tmp = self.playback
      struct_assign, playback, playback_tmp, /NOZERO
      self.playback = playback_tmp
   endif

   if n_elements(position) gt 0 then $
        self.position = position

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_Animator::About
;
pro MGH_Animator::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   self->GetProperty, N_FRAMES=n_frames, POSITION=position

   printf, lun, FORMAT='(%"%s: I am positioned at frame %d in range 0-%d")', $
           mgh_obj_string(self), position, n_frames-1

end

; MGH_Animator::BuildDelayBar
;
pro MGH_Animator::BuildDelayBar, expand

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default is to toggle the state of the bar

   if n_elements(expand) eq 0 then expand = (self.expand_delay_bar eq 0)

   ;; Check that the base exists. Once created, this will not be
   ;; destroyed, thus ensuring that the order of toolbars will not
   ;; change

   case widget_info(self.delay_bar, /VALID_ID) of
      0: begin
         obar = self->NewChild('MGH_GUI_Base', /OBJECT, $
                               UVALUE=self->Callback('EventDelayBar'))
         self.delay_bar = obar->GetBase()
         new = 1B
      end
      1: begin
         obar = mgh_widget_self(self.delay_bar)
         new = 0B
      end
   endcase

   ;; If bar is already in required state, then no action is
   ;; necessary

   if (~ new) && (keyword_set(expand) eq self.expand_delay_bar) then return

   ;; Clear all children from the base

   obar->Clear

   ;; Now populate the bar

   case keyword_set(expand) of

      0: begin

         ocont = obar->NewChild('MGH_GUI_Base', /OBJECT, XSIZE=200, $
                                YSIZE=5, /FRAME, /CONTEXT_EVENTS, $
                                PROCESS_EVENTS=0, UNAME='DELAY_BASE')

      end

      1: begin

         ocont = obar->NewChild('MGH_GUI_Base', /OBJECT, /ROW, $
                                /ALIGN_CENTER, /BASE_ALIGN_CENTER, $
                                /CONTEXT_EVENTS, XPAD=10, PROCESS_EVENTS=0, $
                                UNAME='DELAY_BASE')

         ocont->NewChild, 'widget_label', VALUE='Delay (ms): '
         ocont->NewChild, 'widget_text', XSIZE=4, /EDITABLE, $
              /KBRD_FOCUS_EVENTS, UNAME='DELAY_SET_MIN'
         ocont->NewChild, 'widget_label', VALUE=' + first '
         ocont->NewChild, 'widget_text', XSIZE=4, /EDITABLE, $
              /KBRD_FOCUS_EVENTS, UNAME='DELAY_SET_FIRST'
         ocont->NewChild, 'widget_label', VALUE=' + final '
         ocont->NewChild, 'widget_text', XSIZE=4, /EDITABLE, $
              /KBRD_FOCUS_EVENTS, UNAME='DELAY_SET_FINAL'

      end

   endcase

   self.expand_delay_bar = keyword_set(expand)

end

; MGH_Animator::BuildDelayContext
;
pro MGH_Animator::BuildDelayContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.delay_context gt 0 then return

   self->NewChild, 'MGH_GUI_PDMenu', ['Delay Bar'], RESULT=omenu, $
        /OBJECT, /CONTEXT, /CHECKED_MENU, $
        UVALUE=self->Callback('EventDelayContext')

   self.delay_context = omenu->GetBase()

end

; MGH_Animator::BuildPlayBar
;
pro MGH_Animator::BuildPlayBar, expand

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default is to toggle the state of the bar

   if n_elements(expand) eq 0 then expand = (self.expand_play_bar eq 0)

   ;; Check that the base exists. Once created, this will not be
   ;; destroyed, thus ensuring that the order of toolbars will not
   ;; change

   case widget_info(self.play_bar, /VALID_ID) of
      0: begin
         obar = self->NewChild('MGH_GUI_Base', /OBJECT, $
                               UVALUE=self->Callback('EventPlayBar'))
         self.play_bar = obar->GetBase()
         new = 1B
      end
      1: begin
         obar = mgh_widget_self(self.play_bar)
         new = 0B
      end
   endcase

   ;; If bar is already in required state, then no action is necessary

   if (~ new) && (keyword_set(expand) eq self.expand_play_bar) then return

   ;; Clear all children from the base

   obar->Clear

   ;; Now populate the bar

   case keyword_set(expand) of

      0: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, XSIZE=200, YSIZE=5, $
              /FRAME, /CONTEXT_EVENTS, PROCESS_EVENTS=0, UNAME='PLAY_BASE'

      end

      1: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, /ROW, /BASE_ALIGN_CENTER,  $
              /CONTEXT_EVENTS, XPAD=10, SPACE=5, PROCESS_EVENTS=0, $
              UNAME='PLAY_BASE', RESULT=obase

         obase->NewChild, 'widget_button', VALUE=*self.bitmaps[0], $
              UNAME='PLAY_GO_STOP', TOOLTIP='Start/Stop', ACCELERATOR='Ctrl+Space'

         ;; All children after the Play/Stop button are in a separate base
         ;; to allow them to be smaller.

         obase->NewChild, 'widget_base', /ROW, /BASE_ALIGN_CENTER, RESULT=base0

         obase->NewChild, 'widget_base', /EXCLUSIVE, /ROW, PARENT=base0, RESULT=base1
         obase->NewChild, 'widget_button', PARENT=base1, UNAME='PLAY_DIR_BACKWARD', $
              VALUE='B', TOOLTIP='Set backward play', /NO_RELEASE, ACCELERATOR='Ctrl+Up'
         obase->NewChild, 'widget_button', PARENT=base1, UNAME='PLAY_DIR_FORWARD', $
              VALUE='F', TOOLTIP='Set forward play', /NO_RELEASE, ACCELERATOR='Ctrl+Down'

         obase->NewChild, 'widget_button', PARENT=base0, VALUE=*self.bitmaps[3], $
              UNAME='PLAY_START', TOOLTIP='Go to start', ACCELERATOR='Ctrl+Home'
         obase->NewChild, 'widget_button', PARENT=base0, VALUE=*self.bitmaps[4], $
              UNAME='PLAY_STEP_BACKWARD', TOOLTIP='Step backward', $
              ACCELERATOR='Ctrl+Left'
         obase->NewChild, 'widget_button', PARENT=base0, VALUE=*self.bitmaps[5], $
              UNAME='PLAY_STEP_FORWARD', TOOLTIP='Step forward', $
              ACCELERATOR='Ctrl+Right'
         obase->NewChild, 'widget_button', PARENT=base0, VALUE=*self.bitmaps[6], $
              UNAME='PLAY_FINISH', TOOLTIP='Go to finish', ACCELERATOR='Ctrl+End'

         obase->NewChild, /OBJECT, 'MGH_GUI_Droplist', PARENT=base0, $
              UNAME='PLAY_LOOP', VALUE=['Once', 'Repeat', 'Autoreverse ']

      end

   endcase

   self.expand_play_bar = keyword_set(expand)

end

; MGH_Animator::BuildPlayContext
;
pro MGH_Animator::BuildPlayContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.play_context gt 0 then return

   self->NewChild, 'MGH_GUI_PDMenu', ['Play Bar'], /OBJECT, /CONTEXT, $
        /CHECKED_MENU, UVALUE=self->Callback('EventPlayContext'), RESULT=omenu

   self.play_context = omenu->GetBase()

end

; MGH_Animator::BuildRangeBar
;
;   Show or hide (actually create or destroy) the bar to be used for setting
;   playback range. Default action is to toggle, but this can be overridden by
;   the FLAG keyword.
;

pro MGH_Animator::BuildRangeBar, expand

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default is to toggle the state of the bar

   if n_elements(expand) eq 0 then expand = (self.expand_range_bar eq 0)

   ;; Check that the base exists. Once created, this will not be
   ;; destroyed, thus ensuring that the order of toolbars will not
   ;; change

   case widget_info(self.range_bar, /VALID_ID) of
      0: begin
         obar = self->NewChild('MGH_GUI_Base', /OBJECT, $
                               UVALUE=self->Callback('EventRangeBar'))
         self.range_bar = obar->GetBase()
         new = 1B
      end
      1: begin
         obar = mgh_widget_self(self.range_bar)
         new = 0B
      end
   endcase

   ;; If bar is already in required state, then no action is
   ;; necessary

   if (~ new) && (keyword_set(expand) eq self.expand_range_bar) then return

   ;; Clear all children from the base

   obar->Clear

   ;; Now populate the bar

   case keyword_set(expand) of

      0: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, XSIZE=200, YSIZE=5, $
              /FRAME, /CONTEXT_EVENTS, PROCESS_EVENTS=0, UNAME='RANGE_BASE'

      end

      1: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, /ROW, /ALIGN_CENTER, $
              /BASE_ALIGN_CENTER, /CONTEXT_EVENTS, XPAD=10, PROCESS_EVENTS=0, $
              UNAME='RANGE_BASE', RESULT=obase

         obase->NewChild, 'widget_label', VALUE=' Range '
         obase->NewChild, 'widget_text', XSIZE=4, /EDITABLE, $
              /KBRD_FOCUS_EVENTS, UNAME='RANGE_SET_MIN'
         obase->NewChild, 'widget_label', VALUE=' to '
         obase->NewChild, 'widget_text', XSIZE=4, /EDITABLE, $
              /KBRD_FOCUS_EVENTS, UNAME='RANGE_SET_MAX'
         obase->NewChild, 'widget_label', VALUE=' Stride '
         obase->NewChild, 'widget_text', XSIZE=4, /EDITABLE, $
              /KBRD_FOCUS_EVENTS, UNAME='RANGE_SET_STRIDE'

         obase->NewChild, 'widget_base', /NONEXCLUSIVE, RESULT=abase
         obase->NewChild, 'widget_button', PARENT=abase, UNAME='RANGE_ALL', $
              VALUE='All', TOOLTIP='Select all frames'

      end

   endcase

   self.expand_range_bar = keyword_set(expand)

end


; MGH_Animator::BuildRangeContext
;
pro MGH_Animator::BuildRangeContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.range_context gt 0 then return

   self->NewChild, 'MGH_GUI_PDMenu', ['Range Bar'], /OBJECT, /CONTEXT, $
        /CHECKED_MENU, UVALUE=self->Callback('EventRangeContext'), RESULT=omenu

   self.range_context = omenu->GetBase()

end

; MGH_Animator::BuildSliderBar
;
pro MGH_Animator::BuildSliderBar, expand

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Default is to toggle the state of the bar

   if n_elements(expand) eq 0 then expand = (self.expand_slider_bar eq 0)

   ;; Check that the base exists. Once created, this will not be
   ;; destroyed, thus ensuring that the order of toolbars will not
   ;; change

   case widget_info(self.slider_bar, /VALID_ID) of
      0: begin
         self->NewChild, 'MGH_GUI_Base', /OBJECT, $
              UVALUE=self->Callback('EventSliderBar'), RESULT=obar
         self.slider_bar = obar->GetBase()
         new = 1B
      end
      1: begin
         obar = mgh_widget_self(self.slider_bar)
         new = 0B
      end
   endcase

   ;; If bar is already in required state, then no action is necessary

   if (~ new) && (keyword_set(expand) eq self.expand_slider_bar) then return

   ;; Clear all children from the base

   obar->Clear

   ;; Now populate the bar

   case keyword_set(expand) of

      0: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, XSIZE=200, YSIZE=5, /FRAME, $
              /CONTEXT_EVENTS, PROCESS_EVENTS=0, UNAME='SLIDER_BASE'

      end

      1: begin

         obar->NewChild, 'MGH_GUI_Base', /OBJECT, /COLUMN, /ALIGN_CENTER, $
              /BASE_ALIGN_CENTER, /CONTEXT_EVENTS, XPAD=10, PROCESS_EVENTS=0, $
              UNAME='SLIDER_BASE', RESULT=obase

         obase->NewChild, 'widget_label', UNAME='SLIDER_LABEL', VALUE=' ', $
              /DYNAMIC_RESIZE
         obase->NewChild, 'widget_slider', UNAME='SLIDER', VALUE=0, $
              MINIMUM=0, MAXIMUM=1, /SUPPRESS_VALUE, XSIZE=200

      end

   endcase

   self.expand_slider_bar = keyword_set(expand)

end

; MGH_Animator::BuildSliderContext
;
pro MGH_Animator::BuildSliderContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.slider_context gt 0 then return

   self->NewChild, 'MGH_GUI_PDMenu', ['Slider Bar','Go To Frame...'], $
        /OBJECT, /CONTEXT, CHECKED_MENU=[1,0], $
        UVALUE=self->Callback('EventSliderContext'), RESULT=omenu

   self.slider_context = omenu->GetBase()

end

; MGH_Animator::Display
;
pro MGH_Animator::Display, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(position) eq 0 then position = self.position

   position = (position > 0) < (self.n_frames-1)

   self.position = position

   if obj_valid(self.client) then self.client->Display, position

   self->UpdateSliderBar

end

; MGH_Animator::EventBase
;
function MGH_Animator::EventBase, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case tag_names(event,/STRUCTURE_NAME) of
      'WIDGET_TIMER': begin
         self->PlayNext
         return, 0
      end
      else: return, self->EventUnexpected(event)
   endcase

end

; MGH_Animator::EventDelayBar
;
function MGH_Animator::EventDelayBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.uname of

      'DELAY_BASE': begin
         widget_displaycontextmenu, $
              event.event.id, event.event.x, event.event.y, self.delay_context
         return, 0
      end

      'DELAY_SET_MIN': begin
         widget_control, event.event.id, GET_VALUE=value
         self.playback.delay[0] = long(value[0]) > 0
         self->UpdateDelayBar
         return, 0
      end

      'DELAY_SET_FIRST': begin
         widget_control, event.event.id, GET_VALUE=value
         self.playback.delay[1] = long(value[0]) > 0
         self->UpdateDelayBar
         return, 0
      end

      'DELAY_SET_FINAL': begin
         widget_control, event.event.id, GET_VALUE=value
         self.playback.delay[2] = long(value[0]) > 0
         self->UpdateDelayBar
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventDelayContext
;
function MGH_Animator::EventDelayContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'DELAY BAR': begin
         self->BuildDelayBar
         self->UpdateDelayBar
         self->UpdateDelayContext
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventPlayBar
;
function MGH_Animator::EventPlayBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Events from the play bar have been wrapped by the MGH_GUI_Base.

   case event.uname of

      'PLAY_BASE': begin
         widget_displaycontextmenu, $
              event.event.id, event.event.x, event.event.y, self.play_context
         return, 0
      end

      'PLAY_GO_STOP': begin
         case self.playback.active of
            0B: self->PlayGo
            1B: self->PlayStop
         endcase
         return, 0
      end

      'PLAY_DIR_BACKWARD': begin
         self.playback.forward = 0B
         self->UpdatePlayBar
         return, 0
      end

      'PLAY_DIR_FORWARD': begin
         self.playback.forward = 1B
         self->UpdatePlayBar
         return, 0
      end

      'PLAY_START': begin
         self->PlayStop
         frame = self.playback.use_range ? self.playback.range[0] : 0
         self->Display, frame
         return, 0
      end

      'PLAY_STEP_BACKWARD': begin
         self->PlayStop
         delta = self.playback.use_range ? self.playback.range[2] : 1
         limit = self.playback.use_range ? self.playback.range[0] : 0
         frame = (self.position - delta) > limit
         self->Display, frame
         return, 0
      end

      'PLAY_STOP': begin
         self->PlayStop
         return, 0
      end

      'PLAY_STEP_FORWARD': begin
         self->PlayStop
         delta = self.playback.use_range ? self.playback.range[2] : 1
         limit = self.playback.use_range ? self.playback.range[1] : self.n_frames-1
         frame = (self.position + delta) < limit
         self->Display, frame
         return, 0
      end

      'PLAY_FINISH': begin
         self->PlayStop
         frame = self.playback.use_range ? self.playback.range[1] : self.n_frames-1
         self->Display, frame
         return, 0
      end

      'PLAY_LOOP': begin
         self->SetPlayBack, LOOP=event.event.index
         self->UpdatePlayBar
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventPlayContext
;
function MGH_Animator::EventPlayContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'PLAY BAR': begin
         self->BuildPlayBar
         self->UpdatePlayBar
         self->UpdatePlayContext
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventRangeBar
;
function MGH_Animator::EventRangeBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Events from the range bar have been wrapped by the MGH_GUI_Base.

   case event.uname of

      'RANGE_BASE': begin
         widget_displaycontextmenu, $
              event.event.id, event.event.x, event.event.y, self.range_context
         return, 0
      end

      'RANGE_ALL': begin
         self->SetPlayBack, USE_RANGE=~event.event.select
         self->UpdateRangeBar
         return, 0
      end

      'RANGE_SET_MIN': begin
         self->GetPlayBack, RANGE=range
         widget_control, event.event.id, GET_VALUE=value
         range[0] = long(strtrim(value[0],2)) > 0
         self->SetPlayBack, RANGE=range
         self->UpdateRangeBar
         return, 0
      end

      'RANGE_SET_MAX': begin
         self->GetPlayBack, RANGE=range
         widget_control, event.event.id, GET_VALUE=value
         range[1] = long(strtrim(value[0],2)) > 0
         self->SetPlayBack, RANGE=range
         self->UpdateRangeBar
         return, 0
      end

      'RANGE_SET_STRIDE': begin
         self->GetPlayBack, RANGE=range
         widget_control, event.event.id, GET_VALUE=value
         range[2] = long(strtrim(value[0],2)) > 1
         self->SetPlayBack, RANGE=range
         self->UpdateRangeBar
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventRangeContext
;
function MGH_Animator::EventRangeContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'RANGE BAR': begin
         self->BuildRangeBar
         self->UpdateRangeBar
         self->UpdateRangeContext
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventSliderBar
;
function MGH_Animator::EventSliderBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Events from the slider bar have been wrapped by the MGH_GUI_Base.

   case event.uname of

      'SLIDER_BASE': begin
         widget_displaycontextmenu, event.event.id $
              , event.event.x, event.event.y, self.slider_context
         return, 0
      end

      'SLIDER': begin
         self->PlayStop
         self->Display, event.event.value
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::EventSliderContext
;
function MGH_Animator::EventSliderContext, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'SLIDER BAR': begin
         self->BuildSliderBar
         self->UpdateSliderBar
         self->UpdateSliderContext
         return, 0
      end

      'GO TO FRAME': begin
         self->PlayStop
         mgh_new, 'MGH_GUI_SetArray', $
                  CAPTION='Position', CLIENT=self, /FLOATING, /INTEGER, $
                  GROUP_LEADER=self.base, /IMMEDIATE, N_ELEMENTS=1, $
                  PROPERTY_NAME='POSITION'
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Animator::GetPlayBack
;
pro MGH_Animator::GetPlayBack, $
     LOOP=loop, DELAY=delay, FORWARD=forward, RANGE=range, USE_RANGE=use_range

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   loop = self.playback.loop

   delay = self.playback.delay

   forward = self.playback.forward

   range = self.playback.range

   use_range = self.playback.use_range

end

; MGH_Animator::PlayGo
;
pro MGH_Animator::PlayGo, DIRECTION=direction

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.playback.active = 1B

   if n_elements(direction) eq 1 then $
        self.playback.forward = direction gt 0

   self.playback.next = self.position

   if obj_valid(self.client) then begin
      self.client->GetProperty, N_FRAMES=n_frames
      self.n_frames = n_frames
   endif

   self->PlayNext

   self->UpdateSliderBar
   self->UpdatePlayBar
   self->UpdateDelayBar
   self->UpdateRangeBar

end

; MGH_Animator::PlayNext
;
pro MGH_Animator::PlayNext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if (~ self.playback.active) then return

   self->GetProperty, N_FRAMES=n_frames

   current = self.playback.next

   ;; Check that the current frame is still in bounds. This could be
   ;; violated if one of the animations is altered during playback.

   if (current lt 0) || (current gt n_frames-1) then begin
      self->PlayStop
      return
   endif

   range = self.playback.use_range ? self.playback.range : [0,n_frames-1,1]

   self->Display, current

   ;; Set delay, adding extra at end points

   delay = self.playback.delay[0]
   if current lt range[0]+range[2] then delay = delay + self.playback.delay[1]
   if current gt range[1]-range[2] then delay = delay + self.playback.delay[2]

   case self.playback.loop of

      0: begin    ;; Stop at end

         next = current + (-1+2*(self.playback.forward gt 0))*range[2]

         if (next ge range[0]) && (next le range[1]) then begin

            widget_control, self.base, TIMER=1.E-3*delay

            self.playback.next = next

         endif else begin

            self->PlayStop

         endelse

      end

      1: begin    ;; Return to other end

         widget_control, self.base, TIMER=1.E-3*delay

         case self.playback.forward of

            0: begin
               next = current - range[2]
               self.playback.next = next ge range[0] ? next : range[1]
            end

            1: begin
               next = current + range[2]
               self.playback.next = next le range[1] ? next : range[0]
            end

         endcase

      end

      2: begin    ;; Forward & back

         widget_control, self.base, TIMER=1.E-3*delay

         next = current + (-1+2*(self.playback.forward gt 0))*range[2]

         case 1B of
            next lt range[0]: begin
               self.playback.forward = 1B
               self.playback.next = current + range[2]
               self->UpdatePlayBar
            end
            next gt range[1]: begin
               self.playback.forward = 0B
               self.playback.next = current - range[2]
               self->UpdatePlayBar
            end
            else: self.playback.next = next
         endcase

      end

   endcase

;   self->Display, current

end

; MGH_Animator::PlayStop
;
pro MGH_Animator::PlayStop

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.playback.active = 0B

   self->UpdateDelayBar
   self->UpdatePlayBar
   self->UpdateRangeBar

end

; MGH_Animator::SetPlayBack
;
pro MGH_Animator::SetPlayBack, $
     LOOP=loop, DELAY=delay, DIRECTION=direction, RANGE=range, USE_RANGE=use_range

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(loop) gt 0 then $
        self.playback.loop = ((loop > 0) < 2)

   if n_elements(delay) gt 0 then self.playback.delay = delay

   if n_elements(direction) gt 0 then self.playback.forward = direction

   if n_elements(range) gt 0 then self.playback.range = range

   if n_elements(use_range) gt 0 then begin
      self.playback.use_range = use_range
      if n_elements(range) eq 0 then $
           self.playback.range = [0, (self.n_frames-1) > 0 , 1]
   endif

end

; MGH_Animator::TimeFrames
;
pro MGH_Animator::TimeFrames, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(lun) eq 0 then lun = -1

   range = self.playback.use_range ? self.playback.range : [0,self.n_frames-1,1]

   ;; Number of frames for reporting purposes. Is this correct?
   num = 1+(range[1]-range[0])/range[2]

   printf, lun, FORMAT='(%"%s: timing %d frames")', $
           mgh_obj_string(self), num

   pos = self.position

   t0 = systime(1)

   for frame=range[0],range[1],range[2] do $
        self->Display, frame

   t1 = systime(1)

   printf, lun, FORMAT='(%"%s: elapsed time = %f, mean = %f")', $
           mgh_obj_string(self), t1-t0, (t1-t0)/float(num)

   self->Display, pos

end

; MGH_Animator::Update
;
pro MGH_Animator::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if obj_valid(self.client) then begin
      self.client->GetProperty, N_FRAMES=n_frames
      self.n_frames = n_frames
      self.position = (self.position > 0) < (self.n_frames-1)
   endif

   self->UpdateSliderBar
   self->UpdatePlayBar
   self->UpdateDelayBar
   self->UpdateRangeBar

   self->UpdateSliderContext
   self->UpdatePlayContext
   self->UpdateDelayContext
   self->UpdateRangeContext

   self->Display

end

; MGH_Animator::UpdateDelayBar
;
pro MGH_Animator::UpdateDelayBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.expand_delay_bar of

      0:

      1: begin

         obar = mgh_widget_self(self.delay_bar)

         wid = obar->FindChild('DELAY_SET_MIN')
         widget_control, wid, SET_VALUE=' '+strtrim(self.playback.delay[0],2)
         widget_control, wid, SENSITIVE=(~ self.playback.active)

         wid = obar->FindChild('DELAY_SET_FIRST')
         widget_control, wid, SET_VALUE=' '+strtrim(self.playback.delay[1],2)
         widget_control, wid, SENSITIVE=(~ self.playback.active)

         wid = obar->FindChild('DELAY_SET_FINAL')
         widget_control, wid, SET_VALUE=' '+strtrim(self.playback.delay[2],2)
         widget_control, wid, SENSITIVE=(~ self.playback.active)

      end

   endcase

end

; MGH_Animator::UpdateDelayContext
;
pro MGH_Animator::UpdateDelayContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.delay_context)

   self->GetProperty, EXPAND_DELAY_BAR=expand_delay_bar

   omenu->SetItem, 'Delay Bar', SET_BUTTON=expand_delay_bar

end

; MGH_Animator::UpdatePlayBar
;
pro MGH_Animator::UpdatePlayBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.expand_play_bar of

      0:

      else: begin

         obar = mgh_widget_self(self.play_bar)

         wid = obar->FindChild('PLAY_GO_STOP')
         widget_control, wid, $
              SENSITIVE=(self.n_frames gt 0)
         case 1B of
            self.playback.active: begin
               widget_control, wid, SET_VALUE=*self.bitmaps[2]
            end
            self.playback.forward: begin
               widget_control, wid, SET_VALUE=*self.bitmaps[0]
            end
            else: begin
               widget_control, wid, SET_VALUE=*self.bitmaps[1]
            end
         endcase

         wid = obar->FindChild(self.playback.forward ? 'PLAY_DIR_FORWARD' : 'PLAY_DIR_BACKWARD')
         widget_control, wid, /SET_BUTTON

         wid = obar->FindChild('PLAY_START')
         widget_control, wid, $
              SENSITIVE=(self.n_frames gt 0)
         wid = obar->FindChild('PLAY_FINISH')
         widget_control, wid, $
              SENSITIVE=(self.n_frames gt 0)

         odrop = mgh_widget_self(obar->FindChild('PLAY_LOOP'))
         odrop->SetProperty, INDEX=self.playback.loop

      end

   endcase

end

; MGH_Animator::UpdatePlayContext
;
pro MGH_Animator::UpdatePlayContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.play_context)

   if obj_valid(omenu) then begin

      self->GetProperty, EXPAND_PLAY_BAR=expand_play_bar

      omenu->SetItem, 'Play Bar', SET_BUTTON=expand_play_bar


   endif

end

; MGH_Animator::UpdateRangeBar
;
pro MGH_Animator::UpdateRangeBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.expand_range_bar of

      0:

      else: begin

         obar = mgh_widget_self(self.range_bar)

         wid = obar->FindChild('RANGE_ALL')
         widget_control, wid, SET_BUTTON=(~ self.playback.use_range)
         widget_control, wid, SENSITIVE=(~ self.playback.active)

         wid = obar->FindChild('RANGE_SET_MIN')
         widget_control, wid, $
              SENSITIVE=self.playback.use_range && (~ self.playback.active)

         if self.playback.use_range then begin
            widget_control, wid, $
                 SET_VALUE=' '+ format_axis_values([self.playback.range[0]])
         endif

         wid = obar->FindChild('RANGE_SET_MAX')
         widget_control, wid, $
              SENSITIVE=self.playback.use_range && (~ self.playback.active)
         if self.playback.use_range then begin
            widget_control, wid, $
                 SET_VALUE=' '+format_axis_values([self.playback.range[1]])
         endif

         wid = obar->FindChild('RANGE_SET_STRIDE')
         widget_control, wid, $
              SENSITIVE=self.playback.use_range && (~ self.playback.active)
         if self.playback.use_range then begin
            widget_control, wid, $
                 SET_VALUE=' '+format_axis_values([self.playback.range[2]])
         endif

      end

   endcase

end

; MGH_Animator::UpdateRangeContext
;
pro MGH_Animator::UpdateRangeContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.range_context)

   if obj_valid(omenu) then begin

      self->GetProperty, EXPAND_RANGE_BAR=expand_range_bar
      omenu->SetItem, 'Range Bar', SET_BUTTON=expand_range_bar

   endif

end

; MGH_Animator::UpdateSliderBar
;
pro MGH_Animator::UpdateSliderBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case self.expand_slider_bar of

      0:

      else: begin

         obar = mgh_widget_self(self.slider_bar)

         ;; Slider base

         widget_control, self.slider_bar, SENSITIVE=1-self.slave

         ;; Slider label

         id = obar->FindChild('SLIDER_LABEL')

         case self.n_frames of
            0: widget_control, id, SET_VALUE='No frames'
            else: begin
               widget_control, id, $
                    SET_VALUE=string(FORMAT='(%"Frame %d in range 0-%d")', $
                                     self.position,self.n_frames-1)
            endelse
         endcase

         ;; Slider. It appears to be necessary to set the slider
         ;; maxiumum first then the slider value.

         id = obar->FindChild('SLIDER')

         widget_control, id, SET_SLIDER_MAX=(self.n_frames-1) > 1
         widget_control, id, SET_VALUE=self.position
         widget_control, id, SENSITIVE=(self.n_frames gt 0)

      end

   endcase

end

; MGH_Animator::UpdateSliderContext
;
pro MGH_Animator::UpdateSliderContext

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   omenu = mgh_widget_self(self.slider_context)

   if obj_valid(omenu) then begin
      self->GetProperty, EXPAND_SLIDER_BAR=expand_slider_bar
      omenu->SetItem, 'Slider Bar', SET_BUTTON=expand_slider_bar
   endif

end

; MGH_Animator_PlayBackInfo__Define
;
pro MGH_Animator_PlayBackInfo__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Animator_PlayBackInfo, active: 0B, loop: 0B, $
                 forward: 0B, use_range: 0B, range: lonarr(3), next: 0L, $
                 delay: lonarr(3)}

end

; MGH_Animator__Define
;
pro MGH_Animator__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Animator, inherits MGH_GUI_Base, client: obj_new(), $
                 delay_bar: 0L, delay_context: 0L, expand_delay_bar: 0B, $
                 expand_play_bar: 0B, expand_range_bar: 0B, $
                 expand_slider_bar: 0B, n_frames: 0L, position: 0L, $
                 playback: {MGH_Animator_PlayBackInfo}, play_bar: 0L, $
                 play_context: 0L, range_bar: 0L, range_context: 0L, $
                 slave: 0B, slider_bar: 0L, slider_context: 0L, $
                 bitmaps: ptrarr(7)}

end


