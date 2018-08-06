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
; Copyright (c) 2001-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-07:
;     Written.
;   Mark Hadfield, 2002-11:
;     Converted to a script (to allow use of the .compile executive function).
;   Mark Hadfield, 2004-05:
;     Back to a routine.
;   Mark Hadfield, 2018-08:
;     Removed the avi_options preference, as it is obsolete.
;-
pro mgh_motley

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Load the mgh_blk_motley message block. The .msg file must be in the same
   ;; directory as this routine.

   src = routine_info('mgh_motley', /SOURCE)

   define_msgblk_from_file, /IGNORE_DUPLICATE, $
        filepath('mgh_mblk_motley.msg', ROOT=file_dirname(src.path))

   ;; Initialise printer

   void = mgh_printer()

   ;; Create a preferences system variable, if necessary.

   defsysv, '!mgh_prefs', EXISTS=exists

   if ~ exists then begin
      defsysv, '!mgh_prefs', {sticky: !true}
   endif

end

