;+
; NAME:
;   MGH_CUSTOM_CT
;
; PURPOSE:
;   Add several custom colour tables to the colour-table file
;
; CATEGORY:
;   Graphics
;   Color Specification.
;
; CALLING SEQUENCE:
;   MGH_CUSTOM_CT
;
; KEYWORD PARAMETERS:
;   BACKUP (input, switch)
;     This keyword controls whether a backup copy is made of the
;     colour table file. Default is 1 (make a backup). Set it to 0 to
;     inhibit the backup.
;
;   CLOBBER (input, switch)
;     This keyword controls whether an existing backup file will be
;     replaced, if necessary. Default is 0 (don't replace).
;
;   FILE (input, scalar string)
;     The name of the colour table file to be modified. Default is
;     the value of the system variable !MGH_CT_FILE or, failing that,
;     the IDL default: '<IDL_DIR>/resource/colors/colors1.tbl'.
;
;   RESTORE (input, switch)
;     Set this keyword to restore the backup copy of the colour table
;     file.
;
;   START (input, scalar integer)
;     The index at which the first of the additional tables is
;     loaded. Default is 41, which is equal to the first vacant index
;     in resource/colors/colors1.tbl.
;
; SIDE EFFECTS:
;   The colour table file is modified. If the BACKUP keyword is set
;   then a copy of the colour table file is created.
;
;###########################################################################
; Copyright (c) 2000-2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-10:
;     Written.
;   Mark Hadfield, 2005-08:
;     - Added CLOBBER keyword.
;     - Added several Matlab colour tables.
;     - Colour table names may now be set individually.
;   Mark Hadfield, 2011-10:
;     - Added a colour table suitable for plots of quantities like speed.
;   Mark Hadfield, 2011-11:
;     - Discovered and fixed a bug: duplicate indices in the CASE statement
;       meant that Matlab Cool was omitted.
;   Mark Hadfield, 2014-08:
;     - Modified the 'MGH Special 4' colour table: added a white band in the
;       middle. Much better! Also substituted a light red for yellow for small
;       positive values.
;-
pro mgh_custom_ct, $
     BACKUP=backup, CLOBBER=clobber, FILE=file, RESTORE=restore, START=start

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Set keyword defaults

   if n_elements(backup) eq 0 then backup = 1B

   if n_elements(file) eq 0 then begin
      defsysv, '!mgh_ct_file', EXISTS=exists
      file = temporary(exists) $
             ? !mgh_ct_file : filepath('colors1.tbl', subdir=['resource', 'colors'])
   endif

   if n_elements(restore) eq 0 then restore = 0B

   if n_elements(start) eq 0 then start = 41

   ;; File management

   if keyword_set(restore) then begin
      message, /INFORM, 'Restoring colour table file from backup and returning'
      file_bak = file+'.backup'
      file_copy, file_bak, file
      return
   endif

   if keyword_set(backup) then begin
      message, /INFORM, 'Backing up colour table file'
      file_bak = file+'.backup'
      catch, status
      if status ne 0 then goto, caught_err_copy
      if keyword_set(clobber) && file_test(file_bak, /REGULAR) then $
           file_delete, file_bak
      file_copy, file, file_bak
      caught_err_copy: catch, /CANCEL
      if status ne 0 then begin
         case !error_state.name of
            'IDL_M_FILE_CP_DSTEXISTS' : begin
               message, /INFORM, 'Error backing up colour-table file. ' + $
                        'Perhaps a write-protected backup file already exists?'
               return
            end
            else: begin
               help, /STRUCT, !error_state
               message, 'Unexpected error'
            end
         endcase
      endif
      file_chmod, file+'.backup', A_WRITE=0
   endif

   ;; Construct & load tables

   n = 0

   while 1 do begin

      case n of
         0: begin
            ct = mgh_make_ct(NAME='MGH Special '+strtrim(n+1, 2), $
                             [0,127.5,255], ['blue','red','green'])
         end
         1: begin
            ct = mgh_make_ct(NAME='MGH Special '+strtrim(n+1, 2), $
                             [0,127.5,255], ['blue','green','red'])
         end
         2: begin
            ct = mgh_make_ct(NAME='MGH Special '+strtrim(n+1, 2), $
                             [0,60,117,138,195,255], $
                             ['(0,30,127)','blue','yellow','red','green','(0,80,80)'])
         end
         3: begin
            ct = mgh_make_ct(NAME='MGH Special '+strtrim(n+1, 2), $
                             [0,117,127,128,138,255], $
                             ['green','blue','white','white','(255,50,50)','magenta'])
         end
         4: begin
            ct = mgh_make_ct(NAME='MGH Special '+strtrim(n+1, 2), $
                             [0,25,76,127,178,230,255], $
                             ['(0,30,127)','blue','yellow','red','green', $
                              '(200,0,200)','(0,127,30)'])
         end
         5: begin
            ;; This is the "Uddstrom SST" scale
            ct = mgh_make_ct(NAME='MGH Special '+strtrim(n+1, 2), $
                             [0,20,50,85,105,127,153,194,208,255], $
                             [[206,127,255], $
                              [127,  0,255], $
                              [  0,  0,255], $
                              [  0,255,255], $
                              [  0,237,  0], $
                              [123,255,  0], $
                              [255,255,  0], $
                              [255,  0,  0], $
                              [237,  0,127], $
                              [ 15,  0,  0]])
         end
         6: begin
            ct = mgh_make_ct(NAME='Matlab Jet', $
                             [0,31,95,159,224,255], $
                             ['(0,0,127)','blue','cyan','yellow','red','(127,0,0)'])
         end
         7: begin
            ct = mgh_make_ct(NAME='Matlab Hot', $
                             [0,95,191,255], $
                             ['black','red','yellow','white'])
         end
         8: begin
            ct = mgh_make_ct(NAME='Matlab Cool', $
                             [0,255], ['cyan','magenta'])
         end
         9: begin
            ct = mgh_make_ct(NAME='MGH Speed', $
                             [0,40,90,150,255], $
                             ['blue','green','red','yellow','(127,0,50)'])
         end
         10: begin
           ct = mgh_make_ct(NAME='MGH Speed 2', $
                            [0,30,60,100,160,255], $
                            ['white','blue','green','red','yellow','(127,0,50)'])
         end
         else: mgh_undefine, ct
      endcase

      if n_elements(ct) eq 0 then break

      message, /INFORM, 'Loading colour table at index '+strtrim(start+n,2)

      modifyct, start+n, ct.name, $
                ct.red, ct.green, ct.blue, FILE=file

      n += 1

   endwhile

end

