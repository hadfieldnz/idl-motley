; svn $Id$
;+
; CLASS:
;   MGHgrAtomation
;
; PURPOSE:
;   A container designed to hold a graphics tree and one or more sequences of
;   graphics objects to be managed and displayed by an animator window such as
;   MGH_Player.
;
; PROPERTIES:
;
;   The following properties (ie keywords to the Init, GetProperty & SetProperty
;   methods) are supported
;
;     CLONE (Get)
;       This is a logical (integer) value that tells the animator
;       whether the frames delivered by the animation's Get method are
;       copies of the ones held in the container (CLONE=1) or the
;       originals (CLONE=0). For an MGHgrAtomation, CLONE is 0.
;
;     GRAPHICS_TREE (Init, Get, Set)
;       This is a reference to an IDLgrView, IDLgrViewGroup or
;       IDLgrScene object to be used as the non-changing part of the
;       animated sequence.
;
;     MULTIPLE (Init, Get, Set)
;       This is a logical value that indicates whether this animation
;       supports the simultaneous display of multiple frames. It is
;       used by animation-manager classes like MGH_Player. For an
;       MGHgrAtomation object it can be 0 or 1 and the default is 1.
;
;     N_SEQUENCES (Init, Get)
;       The number of sequences of atoms/models.
;
;     SAVEABLE (Get)
;       This is a logical value that tells the animator
;       whether the animation can usefully be saved. For an
;       MGHgrAtomation, SAVEABLE is 1.
;
;     SOCKET (Init, Get, Set)
;       This is an object array, dimensioned (N_SEQUENCES) containing
;       references to nodes in the graphics tree. The socket for each
;       sequence is the point where the graphics objects contained in
;       that sequence are added to the tree, in order for each frame
;       to be rendered.
;
;   The animation object doesn't do anything with the GRAPHICS_TREE
;   and SOCKET objects, it just holds the references for use by the
;   animator
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
;   Mark Hadfield, 1998-09:
;     Written.
;   Mark Hadfield, 1999-01:
;     Added the BASE property (since renamed GRAPHICS_TREE) for more
;     efficient display of sequences in which part of the picture
;     remains the same between frames.
;   Mark Hadfield, 1999-06:
;     Added the SOCKET property for compatibility with the revised
;     version of MGH_Animator.  The MGH_Animator now requires the
;     animation to hold a sequence of atoms or models, rather than a
;     sequence of views. The animator now adds the frames to the
;     graphics tree before drawing them, then removes them afterwards,
;     so it needs to know where to add them.
;   Mark Hadfield, 2000-03
;     As a result of experience with 3D graphics, where I want to add
;     atoms at different socket points, I modified this class so it
;     can maintain several sequences of atoms.  The number of
;     sequences is specified by the N_SEQUENCES property. The SOCKET
;     property is now an array of object references. Calls to Add &
;     Get now accept an optional INDEX keyword, which specifies which
;     sequence is being operated on.
;   Mark Hadfield, 2001-06:
;     - BASE property renamed GRAPHICS_TREE.
;     - Add method renamed AddAtom.
;   Mark Hadfield, 2004-03:
;     - Fixed bug: SetProperty was inadvertently setting MULTIPLE to
;       0.
;-

; MGHgrAtomation::Init
;
function MGHgrAtomation::Init, $
     GRAPHICS_TREE=graphics_tree, MULTIPLE=multiple, N_SEQUENCES=n_sequences, $
     SOCKET=socket

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self.multiple = n_elements(multiple) gt 0 ? keyword_set(multiple) : 1

   self.n_sequences = n_elements(n_sequences) gt 0 ? n_sequences : 1

   sequence_array = objarr(self.n_sequences)
   for i=0,self.n_sequences-1 do $
         sequence_array[i] = obj_new('MGH_Container')
   self.sequence = ptr_new(sequence_array)

   self.socket = ptr_new(objarr(self.n_sequences))

   self.assembly = obj_new('MGH_Container', DESTROY=0)

   self->SetProperty, GRAPHICS_TREE=graphics_tree, SOCKET=socket

   return, 1

end


; MGHgrAtomation::Cleanup
;
pro MGHgrAtomation::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.graphics_tree

   sequence = *self.sequence
   for i=0,self.n_sequences-1 do obj_destroy, sequence[i]

   ptr_free, self.sequence

   ptr_free, self.socket

   obj_destroy, self.assembly

end

; MGHgrAtomation::SetProperty
;
pro MGHgrAtomation::SetProperty, $
     GRAPHICS_TREE=graphics_tree, MULTIPLE=multiple, SOCKET=socket

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(multiple) gt 0 then $
        self.multiple = keyword_set(multiple)

   ;; Note that every time the GRAPHICS_TREE property is changed
   ;; then a default is calculated for the SOCKET property.

   if n_elements(graphics_tree) eq 1 then begin
      while self.assembly->Count() gt 0 do self.assembly->Remove, POSITION=0
      self.graphics_tree = graphics_tree
      if n_elements(socket) eq 0 then begin
         if obj_isa(graphics_tree, 'IDLgrView') then begin
            self->GetProperty, N_SEQUENCES=n_sequences
            socket = replicate(graphics_tree->IDLgrView::Get(), n_sequences)
         endif
      endif
   endif


   if n_elements(socket) gt 0 then begin
      if n_elements(socket) ne self.n_sequences then $
           message, 'Number of socket references does not match number of ' + $
                    'sequences in this animator object.'
      ptr_free, self.socket
      self.socket = ptr_new(socket)
   endif

end

; MGHgrAtomation::GetProperty
;
pro MGHgrAtomation::GetProperty, $
     GRAPHICS_TREE=graphics_tree, CLONE=clone, MULTIPLE=multiple, $
     N_FRAMES=n_frames, N_SEQUENCES=n_sequences, SAVEABLE=saveable, SOCKET=socket

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   clone = 0

   graphics_tree = self.graphics_tree

   if arg_present(n_frames) then begin
      n_frames = 0
      sequence = *self.sequence
      for i=0,self.n_sequences-1 do $
            n_frames = n_frames > sequence[i]->Count()
   endif

   multiple = self.multiple

   n_sequences = self.n_sequences

   saveable = 1

   if arg_present(socket) then begin
      case ptr_valid(self.socket) of
         0: socket = obj_new()
         1: socket = *self.socket
      endcase
   endif

end

; MGHgrAtomation::AddFrame
;
pro MGHgrAtomation::AddFrame, atoms, INDEX=index, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(atoms) ne self.n_sequences then $
        message, 'Number of atoms in frame must match number of sequences'

   sequence = *self.sequence

   for i=0,n_elements(atoms)-1 do $
         sequence[i]->Add, atoms[i], _STRICT_EXTRA=extra

end

; MGHgrAtomation::AssembleFrame
;
pro MGHgrAtomation::AssembleFrame, frames

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(frames) eq 0 then frames = 0

   self->GetProperty, GRAPHICS_TREE=graphics_tree, N_SEQUENCES=n_sequences, SOCKET=socket

   ;; Dismantle

   while self.assembly->Count() gt 0 do begin

      item = self.assembly->Get(POSITION=0)
      self.assembly->Remove, POSITION=0

      if obj_valid(item) then begin
         item->GetProperty, PARENT=parent
         parent->Remove, item
      endif

   endwhile

   for f=0,n_elements(frames)-1 do begin

      for i=0,n_sequences-1 do begin

         item = self->Get(POSITION=frames[f], INDEX=i)

         self.assembly->Add, item

         if obj_valid(item) then socket[i]->Add, item

      endfor

   endfor

end


; MGHgrAtomation::Get
;
function MGHgrAtomation::Get, INDEX=index, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(index) eq 0 then index = 0

   sequence = (*self.sequence)[index]

   result = (position lt sequence->Count()) $
            ? sequence->Get(POSITION=position) $
            : obj_new()

   return, result

end


; MGHgrAtomation::N_Frames
;
function MGHgrAtomation::N_Frames

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->GetProperty, N_FRAMES=result

   return, result

end


; MGHgrAtomation::Restore
;
pro MGHgrAtomation::Restore

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

end


; MGHgrAtomation::Save
;
PRO MGHgrAtomation::Save, Filename

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   mgh_var_save, self, filename

END


; MGHgrAtomation__Define
;
pro MGHgrAtomation__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHgrAtomation, name: '', multiple: 0B, n_sequences: 0, $
                 sequence: ptr_new(), graphics_tree: obj_new(), $
                 socket: ptr_new(), assembly: obj_new()}

end


