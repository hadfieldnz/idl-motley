;+
; CLASS:
;   MGHdgAnimation
;
; PURPOSE:
;   A container holding a a sequence of MGH_Command objects, to be managed and
;   and displayed by a direct graphics animator window such as MGH_DgPlayer.
;
; PROPERTIES:
;
;   The following properties (ie keywords to the Init, GetProperty & SetProperty
;   methods) are supported
;
;     BASE (Init, Get, Set)
;       A scalar or 1-D array containing a list of MGH_Command objects
;       to be executed every time a frame is displayed
;
;     MULTIPLE (Get)
;       This is a logical (integer) value that tells users whether the
;       animation supports the simultaneous display of multiple
;       frames. For an MGHdgAnimation, MULTIPLE is 1.
;
;     SAVEABLE (Get)
;       This is a logical (integer) value that tells users whether the
;       animation can usefully be saved. For an MGHdgAnimation,
;       SAVEABLE is 1.
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
;   Mark Hadfield, 2001-09:
;     Written.
;-

; MGHdgAnimation::Init
;
function MGHdgAnimation::Init, BASE=base

   compile_opt DEFINT32
   compile_opt STRICTARR

   self.commands = obj_new('MGH_Vector')

   self->SetProperty, BASE=base

   return, 1

end


; MGHdgAnimation::Cleanup
;
pro MGHdgAnimation::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR

   if ptr_valid(self.base) then begin
      obj_destroy, *self.base
      ptr_free, self.base
   endif

   self.commands->GetProperty, COUNT=n_commands
   for i=0,n_commands-1 do obj_destroy, self.commands->Get(POSITION=i)

   obj_destroy, self.commands

end

; MGHdgAnimation::SetProperty
;
pro MGHdgAnimation::SetProperty, BASE=base

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(base) gt 0 then begin
      if ptr_valid(self.base) then begin
         obj_destroy, *self.base
         ptr_free, self.base
      endif
      self.base = ptr_new(base)
   endif

end

; MGHdgAnimation::GetProperty
;
pro MGHdgAnimation::GetProperty, $
     BASE=base, MULTIPLE=multiple, N_FRAMES=n_frames, SAVEABLE=saveable

   compile_opt DEFINT32
   compile_opt STRICTARR

   if arg_present(base) then begin
      if ptr_valid(self.base) then base = *self.base
   endif

   if arg_present(n_frames) then $
        self.commands->GetProperty, COUNT=n_frames

   multiple = 0B

   saveable = 1B

end

; MGHdgAnimation::AddFrame
;
pro MGHdgAnimation::AddFrame, command

   compile_opt DEFINT32
   compile_opt STRICTARR

   if size(command, /TNAME) ne 'OBJREF' then $
        message, 'Argument must be an object reference (scalar or array)'

   self.commands->Add, command

end

; MGHdgAnimation::AssembleFrame
;
function MGHdgAnimation::AssembleFrame, frames

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(frames) eq 0 then frames = 0

   self->GetProperty, BASE=base, N_FRAMES=n_frames

   ovec = obj_new('MGH_Vector')

   for i=0,n_elements(base)-1 do $
        ovec->Add, base[i]

   for j=0,n_elements(frames)-1 do begin

      if frames[j] le n_frames-1 then begin

         cmd = self->GetFrame(POSITION=frames[j])

         for i=0,n_elements(cmd)-1 do $
              ovec->Add, cmd[i]

      endif

   endfor

   result = ovec->ToArray()

   obj_destroy, ovec

   return, result

end

; MGHdgAnimation::GetFrame
;
function MGHdgAnimation::GetFrame, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   return, self.commands->Get(_STRICT_EXTRA=extra)

end


; MGHdgAnimation::N_Frames
;
function MGHdgAnimation::N_Frames

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->GetProperty, N_FRAMES=result

   return, result

end


; MGHdgAnimation::Restore
;
pro MGHdgAnimation::Restore

end


; MGHdgAnimation::Save
;
PRO MGHdgAnimation::Save, Filename

   compile_opt DEFINT32
   compile_opt STRICTARR

   mgh_var_save, self, filename

end

; MGHdgAnimation__Define
;
pro MGHdgAnimation__Define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGHdgAnimation, base: ptr_new(), commands: obj_new()}

end


