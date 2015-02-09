;+
; CLASS:
;   MGH_Datamator
;
; PURPOSE:
;   A window for displaying & managing picture sequences.
;
; CATEGORY:
;       Widgets, Object Graphics.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported:
;
;     BUFFER_RESOLUTION (Init, Get, Set)
;       Resolution for off-screen buffers, used by
;       WritePictureToClipboard, WritePictureToImageFile and
;       WritePictureToVRML methods.
;
;     CHANGEABLE (Init, Get)
;       This property determines whether the ANIMATION property can be
;       changed once it has been first set. It is 1 (on) by default;
;       it should be set to 0 when the MGH_Datamator is to be used in
;       a composite application which needs to ensure that the
;       ANIMATION is not changed behind its back.
;
;     DISPLAY (Init, Get, Set)
;       This property specifies whether the Display (aka Draw) method
;       will be called (to display the current frame) when the AddItem
;       method is called. The default is 1 (to display). There are two
;       reasons why it might be appropriate to set DISPLAY to zero:
;         * To improve load time (sometimes by a large margin) at the
;         cost of user feedback.
;         * To inhibit display of partial frames, when the animation
;         contains more than one sequence. In this case the Display
;         method can be called once the new frame has been completely
;         assembled.
;
;     DIMENSIONS (Init, Get, Set)
;       A 2-element array specifying the width & height of the
;       graphics window. If the picture and the window are both
;       "fittable"  (see FITTABLE keyword) then UNITS & DIMENSIONS are
;       taken from the picture.
;
;     FITTABLE (Init, Get)
;       This property determines whether the window will try to resize
;       itself to fit the graphics tree. Default is 1 (try to fit) by
;       default. For a fit to occur, the picture must also be
;       fittable, as determined by the MGH_PICTURE_IS_FITTABLE
;       function.
;
;     FINISHED (Init, Get, Set)
;       This is a flag specifying whether the loading of frames into
;       the animation has finished. The value can be set via a menu
;       item. It is recommended that the routine controlling the
;       animator should check the value of this flag regularly via the
;       Finished method and skip the remaining frames if the flag has
;       been set.
;
;     GRAPHICS_TREE (Init, Get, Set)
;       A reference to the graphics tree that is drawn when the
;       animator's Draw method is called. The graphics tree object is
;       contained in the ANIMATION object. When the GRAPHICS_TREE
;       object is changed, then other aspects of the animator's
;       state are chacked to ensure they are consistent with it.
;
;     MOUSE_ACTION (Init, Get, Set)
;       A 3-element string array specifying the mouse handler object
;       to be associated with each mouse button. Mouse press, release
;       & motion events which originate from the draw widget are sent
;       to "mouse handler" objects, one handler per mouse button. The
;       SetProperty method is responsible for managing these
;       objects. Each time a new value of MOUSE_ACTION is passed to
;       SetProperty this method destroys all existing mouse handlers
;       then creates a new set according to rules hard-wired into the
;       code.
;
;     MOUSE_LIST (Init, Get)
;       This property is a string array that defines the set of values
;       available from the "mouse action" droplists on the status
;       bar. Note that this property affects the user interface
;       only. It does not affect the range of permissible values for
;       the elements of MOUSE_ACTION--these values are determined by
;       the code in SetProperty.
;
;     N_FRAMES (Get)
;       The number of frames currently managed by the animator. This
;       property (which is inherited from MGH_Animator) is stored in
;       the object structure. It is Updateed as necessary by the
;       CountFrames method, which determines it from the animation's
;       COUNT property.
;
;     RESIZEABLE (Init, Get)
;       This property controls what action is taken in response to
;       resize events. Valid values are:

;         0: Base resizing does not change the window or picture
;         dimensions.
;
;         1: Base resizing changes the window & picture dimensions.
;
;         2: Base resizing changes the window & picture dimensions in
;         such a way that the aspect ratio is preserved. This is the
;         default. The resizing of the window interacts with the
;         automatic fitting of the window to the picture, in a way
;         that depends on whether the picture is fittable
;         (i.e. function MGH_PICTURE_IS_FITTABLE returns 1) and
;         whether the window is fittable (FITTABLE property is 1).
;
;     RESOLUTION (Get)
;       Taken from the graphics window.
;
;     TITLE (Get)
;       The title, which appears in the title bar, is calculated from
;       the animation name.
;
;     UNITS (Init, Get, Set)
;       Units for the DIMENSIONS.
;
;     VISIBLE (Init, Set)
;       Set this property to 1 to make the window visible, 0 to make
;       it invisible.
;
;   ... and many more.
;
; METHODS:
;   Include the following
;
;     Finish (Procedure)
;       Set the FINISHED property to 1. This method should be called
;       when loading of frames is completed.
;
;     Finished (Function)
;       Check the value of the FINISHED property, after first flushing
;       the event queue for the top-level base. A program that is
;       adding frames to an MGH_Datamator object should call this
;       method before every frame and break out of the loop if it
;       returns 1. This gives the user an opportunity to terminate the
;       loading of frames.
;
;     WriteAnimationToMovieFile (Procedure):
;       Export the animation in bitmap form to a movie file
;       (multi-frame image file or zipped collection of images).
;
;     WritePictureToClipboard (Procedure):
;     WritePictureToImageFile (Procedure):
;     WritePictureToGraphicsFile (Procedure):
;     WritePictureToVRML (Procedure):
;       Export the current frame of the animation in one of several
;       formats. These methods were all copied verbatim from
;       MGH_Window--code re-use by cut & paste!
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
;   Mark Hadfield, 2001-06:
;       Written.
;-

; MGH_Datamator::Init
;
function MGH_Datamator::Init, $
     ANIMATION_CLASS=animation_class, ANIMATION_PROPERTIES=animation_properties, $
     DISPLAY=display, GRAPHICS_TREE=graphics_tree, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Properties

   self.display = 1B
   if n_elements(display) gt 0 then self.display = keyword_set(display)

   self.finished = 0

   ;; Other keywords

   if n_elements(animation_class) eq 0 then $
        animation_class = 'MGHgrDatamation'

   ;; Create an animation

   animation = obj_new(animation_class, GRAPHICS_TREE=graphics_tree, $
                       _STRICT_EXTRA=animation_properties)

   ;; Initialise and realise the player base.

   ok = self->MGH_Player::Init(/SLAVE, ANIMATION=animation, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Player'

   self->Realize

   ;; Finalise

   self->Finalize

   return, 1

end


; MGH_Datamator::Cleanup
;
pro MGH_Datamator::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::Cleanup

end


; MGH_Datamator::GetProperty
;
pro MGH_Datamator::GetProperty, $
     DISPLAY=display, FINISHED=finished, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   display = self.display

   finished = self.finished

   self->MGH_Player::GetProperty, _STRICT_EXTRA=extra

end

; MGH_Datamator::SetProperty
;
pro MGH_Datamator::SetProperty, $
     DISPLAY=display, FINISHED=finished, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(display) gt 0 then $
        self.display = display

   if n_elements(finished) gt 0 then begin
      self.finished = finished
      self->MGH_Player::SetProperty, SLAVE=(1-self.finished)
   endif

   self->MGH_Player::SetProperty, _STRICT_EXTRA=extra

end

; MGH_Datamator::AddFrame
;
pro MGH_Datamator::AddFrame, command

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.animation->AddFrame, command

   self.animation->GetProperty, N_FRAMES=n_frames

   self.animator->SetProperty, N_FRAMES=n_frames

   self->UpdateMenuBar

   if self.display then self->Display, n_frames-1

end

; MGH_Datamator::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Datamator::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::BuildMenuBar

   ombar = mgh_widget_self(self.menu_bar)

   if obj_valid(ombar) then begin

      ombar->NewItem, PARENT='File', ['Finish Loading'], SEPARATOR=[1]

   endif

end


; MGH_Datamator::EventMenuBar
;
function MGH_Datamator::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.FINISH LOADING': begin
         self->SetProperty, FINISHED=1
         self->Update
         return,1
      end

      else: return, self->MGH_Player::EventMenuBar(event)

   endcase

end

; MGH_Datamator::Finish
;
; Purpose:
;   Set the FINISHED property to 1 and Update the display
;
pro MGH_Datamator::Finish

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->SetProperty, /FINISHED

   self->Update

end

; MGH_Datamator::Finished
;
; Purpose:
;   Return the value of the FINISHED property, after first flushing events.
;
function MGH_Datamator::Finished

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->FlushEvents

   return, self.finished

end


; MGH_Datamator::UpdateMenuBar
;
pro MGH_Datamator::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin
      self->GetProperty, FINISHED=finished
      obar->SetItem, 'File.Finish Loading', SENSITIVE=(~ finished)
   endif

   self->MGH_Player::UpdateMenuBar

end


pro MGH_Datamator__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGH_Datamator, inherits MGH_Player, display: 0B, finished: 0B}

end


