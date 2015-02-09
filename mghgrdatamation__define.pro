;+
; CLASS:
;   MGHgrDatamation
;
; PURPOSE:
;   A container holding a graphics tree and a sequence of MGH_Command objects,
;   to be managed and displayed by an animator window such as MGH_Datamator.
;
; PROPERTIES:
;
;   The following properties (ie keywords to the Init, GetProperty & SetProperty
;   methods) are supported
;
;     CLONE (Get)
;       This is a logical (integer) value that tells the animator whether the frames
;       delivered by the animation's Get method are copies of the ones held
;       in the container (CLONE=1) or the originals (CLONE=0). For an
;       MGHgrDatamation, CLONE is 0.
;
;     GRAPHICS_TREE (Init, Get, Set)
;       This is a reference to an IDLgrView, IDLgrViewGroup or IDLgrScene
;       object. The frames in the animation are rendered by executing commands
;       which modify the graphics tree.
;
;     MULTIPLE (Get)
;       This is a logical (integer) value that tells users whether the animation
;       supports the simultaneous display of multiple frames. For an MGHgrDatamation,
;       MULTIPLE is 0.
;
;     SAVEABLE (Get)
;       This is a logical (integer) value that tells users whether the animation
;       can usefully be saved. For an MGHgrDatamation, SAVEABLE is 1. (This should be
;       changed so that SAVEABLE can be set to 1 if all object references are contained
;       in the graphics tree and zero otherwise.)
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
;     Written, after reading a book on Matlab graphics.
;-

; MGHgrDatamation::Init
;
function MGHgrDatamation::Init, GRAPHICS_TREE=graphics_tree

   compile_opt DEFINT32
   compile_opt STRICTARR

   self.commands = obj_new('MGH_Vector')

   self->SetProperty, GRAPHICS_TREE=graphics_tree

   return, 1

end


; MGHgrDatamation::Cleanup
;
pro MGHgrDatamation::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR

   obj_destroy, self.graphics_tree

   self.commands->GetProperty, COUNT=n_commands
   for i=0,n_commands-1 do obj_destroy, self.commands->Get(POSITION=i)

   obj_destroy, self.commands

end

; MGHgrDatamation::SetProperty
;
pro MGHgrDatamation::SetProperty, GRAPHICS_TREE=graphics_tree

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(graphics_tree) eq 1 then self.graphics_tree = graphics_tree

end

; MGHgrDatamation::GetProperty
;
pro MGHgrDatamation::GetProperty, $
     CLONE=clone, GRAPHICS_TREE=graphics_tree, MULTIPLE=multiple, $
     N_FRAMES=n_frames, SAVEABLE=saveable

   compile_opt DEFINT32
   compile_opt STRICTARR

   clone = 0B

   graphics_tree = self.graphics_tree

   if arg_present(n_frames) then $
        self.commands->GetProperty, COUNT=n_frames

   multiple = 0

   saveable = 1B

end

; MGHgrDatamation::AddFrame
;
pro MGHgrDatamation::AddFrame, command

   compile_opt DEFINT32
   compile_opt STRICTARR

   if size(command, /TNAME) ne 'OBJREF' then $
        message, 'Argument must be an object reference (scalar or array)'

   self.commands->Add, command

end

; MGHgrDatamation::AssembleFrame
;
pro MGHgrDatamation::AssembleFrame, frame

  compile_opt DEFINT32
  compile_opt STRICTARR

  if self.commands->Count() gt 0 then begin

    cmd = self->GetFrame(POSITION=frame)

    for i=0,n_elements(cmd)-1 do if obj_valid(cmd[i]) then cmd[i]->Execute

    !null = check_math()

  end

end

; MGHgrDatamation::GetFrame
;
function MGHgrDatamation::GetFrame, _EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   return, self.commands->Get(_EXTRA=extra)

end


; MGHgrDatamation::N_Frames
;
function MGHgrDatamation::N_Frames

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->GetProperty, N_FRAMES=result

   return, result

end


; MGHgrDatamation::Restore
;
pro MGHgrDatamation::Restore

end


; MGHgrDatamation::Save
;
PRO MGHgrDatamation::Save, Filename

   mgh_var_save, self, filename

END

; MGHgrDatamation__Define
;
pro MGHgrDatamation__Define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGHgrDatamation, graphics_tree: obj_new(), commands: obj_new()}

end


