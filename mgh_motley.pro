;+
; NAME:
;   MGH_MOTLEY
;
; PURPOSE:
;   Initialise the MGH_Motley library
;
; EFFECTS:
;   Various session-wide initialisation tasks are carried out:
;
;    - Message block MGH_MBLK_MOTLEY is loaded.
;
;    - The MGH_PRINTER function is invoked to create a new system
;      variable, !MGH_PRINTER, holding a reference to an IDLgrPrinter
;      object.
;
;    - A new system variable, !MGH_PREFS, is created, holding miscellaneous user
;      preferences.
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
;   Mark Hadfield, 2001-07:
;     Written.
;   Mark Hadfield, 2002-11:
;     Converted to a script (to allow use of the .compile executive function).
;   Mark Hadfield, 2004-05:
;     Back to a routine.
;-
pro mgh_motley

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Load message block. The .msg file must be in the same directory
   ;; as the MGH_MOTLEY code.

   src = routine_info('mgh_motley', /SOURCE)

   define_msgblk_from_file, /IGNORE_DUPLICATE, $
        filepath('mgh_mblk_motley.msg', ROOT=file_dirname(src.path))

   ;; Initialise printer

   void = mgh_printer()

   ;; Create preferences system variable, if necessary.

   defsysv, '!mgh_prefs', EXISTS=exists

   if ~ exists then begin
      defsysv, '!mgh_prefs', $
               {avi_options: {codec: 'MSVC', quality: 85, iframe_gap: 10, frame_rate: 15}, $
                sticky: 1B}
   endif

end

