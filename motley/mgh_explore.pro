;+
; NAME:
;   MGH_EXPLORE
;
; PURPOSE:
;   The procedure opens a file manager at a specified directory,
;   optionally with a specific file selected.
;
;   For info on Explorer command-line switches, see
;     http://support.microsoft.com/kb/130510
;
;   For info on command-line switches for Linux file managers, try
;     $ nautilus --help
;     $ dolphin --help
;
;   Currently, the Gnome Nautilus file manager is hard-coded into
;   the Unix version of the routine.
;
; CALLING SEQUENCE:
;   mgh_explore, name
;
; POSITIONAL ARGUMENTS:
;   name (input, scalar string)
;     Normally this is an input argument specifying the directory to
;     be explored; if it is not supplied then the Explorer is opened
;     at the current directory. The FILE, CLASS & ROUTINE keywords (below)
;     modifiythe behaviour of this argument.
;
; KEYWORD PARAMETERS:
;   CLASS (input, switch)
;     If set, take name as the name of a class, search the IDL
;     path for <class>__define.pro, and open the containing directory
;     with the routine selected.
;
;   FILE (input, switch)
;     If set, take name as the name of a file and open the containing
;     directory with the file selected.
;
;   ROUTINE (input, switch)
;     If set, take name as the name of a routine, search the IDL
;     path for <routine>.pro file, and open the containing
;     directory with the routine selected.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-01:
;     Written, for Windows only
;   Mark Hadfield, 2005-06
;     Deleted WAIT keyword: it was irrelevant as Explorer always returns
;     immediately after opening a window.
;   Mark Hadfield, 2012-01
;     When the FILE, CLASS or ROUTINE keyword is set, use Explorer's
;     select switch to open a folder with the relevant file selected.
;   Mark Hadfield, 2018-01:
;     Now works on Linux with the Nautilus file manager.
;   Mark Hadfield, 2018-11:
;     On Linux, the Nautilus file manager command is now terminated with
;     an ampersand (no-wait) character.
;-
pro mgh_explore_unix, name, $
   FILE=file, CLASS=class, ROUTINE=routine

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case !true of

      keyword_set(file): begin
         if n_elements(name) eq 0 then $
            message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'name'
         cmd = string(FORMAT='(%"nautilus --select \"%s\" &")', name)
      end

      keyword_set(class): begin
         file_pro = file_which(strlowcase(name)+'__define.pro', /INCLUDE_CURRENT_DIR)
         if strlen(file_pro) eq 0 then $
            message, 'Could not find class '+name
         cmd = string(FORMAT='(%"nautilus --select \"%s\" &")', file_pro)
      end

      keyword_set(routine): begin
         file_pro = file_which(strlowcase(name)+'.pro', /INCLUDE_CURRENT_DIR)
         if strlen(file_pro) eq 0 then $
            message, 'Could not find routine '+name
         cmd = string(FORMAT='(%"nautilus --select \"%s\" &")', file_pro)
      end

      else: begin
         if n_elements(name) eq 0 then cd, CURRENT=name
         cmd = string(FORMAT='(%"nautilus \"%s\" &")', name)
      endelse

   endcase

   spawn, cmd

end

pro mgh_explore_windows, name, $
     FILE=file, CLASS=class, ROUTINE=routine

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case !true of

      keyword_set(file): begin
         if n_elements(name) eq 0 then $
              message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'name'
         cmd = string(FORMAT='(%"explorer /select,\"%s\"")', name)
      end

      keyword_set(class): begin
         file_pro = file_which(strlowcase(name)+'__define.pro', /INCLUDE_CURRENT_DIR)
         if strlen(file_pro) eq 0 then $
              message, 'Could not find class '+name
         cmd = string(FORMAT='(%"explorer /select,\"%s\"")', file_pro)
      end

      keyword_set(routine): begin
         file_pro = file_which(strlowcase(name)+'.pro', /INCLUDE_CURRENT_DIR)
         if strlen(file_pro) eq 0 then $
              message, 'Could not find routine '+name
         cmd = string(FORMAT='(%"explorer /select,\"%s\"")', file_pro)
      end

      else: begin
         if n_elements(name) eq 0 then cd, CURRENT=name
         cmd = string(FORMAT='(%"explorer \"%s\"")', name)
      endelse

   endcase

   spawn, /NOSHELL, /NOWAIT, cmd

end

pro mgh_explore, name, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   if n_elements(name) gt 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'name'

   case !true of
      strcmp(!version.os_family, 'Windows', /FOLD_CASE): begin
         mgh_explore_windows, name, _STRICT_EXTRA=extra
      end
      strcmp(!version.os_family, 'unix', /FOLD_CASE): begin
         mgh_explore_unix, name, _STRICT_EXTRA=extra
      end
   endcase


end
