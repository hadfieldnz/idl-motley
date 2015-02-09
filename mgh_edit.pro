;+
; NAME:
;   MGH_EDIT
;
; PURPOSE:
;   The procedure opens a text editor to edit the specified file(s).
;
; CALLING SEQUENCE:
;   MGH_EDIT [,Name]
;
; POSITIONAL PARAMETERS:
;   name (input, optional, string scalar or array)
;     Normally this is an input argument specifying the file(s)
;     to be edited; if it is not supplied then the editor is
;     started with no file open. Several keywords (below) modify the
;     behaviour of this argument.
;
; KEYWORDS:
;   CLASS (input, switch)
;     If set, take the name argument as a list of class names and
;     search the IDL path for the corresponding <class>__define.pro
;     files.
;
;   COMMANDS (input, switch)
;     Collect and edit a list of commands from the command history.
;
;   EDITOR (input, scalar integer)
;     Specify which of several different editor commands to use.
;
;   NEW
;     If set, create the file if it does not already exist.
;
;   PICK (input)
;     If set, call DIALOG_PICKFILE to supply the file name and return
;     the value selected by the user via the name argument.
;
;   CLASS (input, switch)
;     If set, take the name argument as a list of routine names and
;     search the IDL path for the corresponding <routine>.pro
;     files.
;
;   VARIABLE (input)
;      If set, take name as a variable--save it to a temporary
;      file then open the file in the editor.
;
; SIDE EFFECTS:
;     A message is displayed. The editor is started & the specified
;     files (if any) is opened.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1993-10:
;     Created. Editor is launched using the WINSPAWN command (starts
;     editor via a DDE link).
;   Mark Hadfield, 1995-03:
;     When directory is not specified, now opens a file in the current
;     directory.
;   Mark Hadfield, 1995-12:
;     Removed OS detection and changed WINSPAWN call to SPAWN.
;   Mark Hadfield, 1996-09:
;     Back to WINSPAWN, which is now an enhanced wrapper for SPAWN.
;   Mark Hadfield, 2000-08:
;     Updated for IDL 5.4: added NOSHELL keyword for SPAWN, PROC_NAME
;     function replaced with FILE_WHICH.
;   Mark Hadfield, 2002-01:
;     Minor enhancements. Renamed MGH_EDIT.
;   Mark Hadfield, 2002-07:
;     Now calls Python (win32) script xmedit.pyw
;   Mark Hadfield, 2003-09:
;     Upgraded to Python 2.3. Note that Python executable name is
;     hard-wired!
;   Mark Hadfield, 2005-06:
;     Added CMD_OPTION keyword. Default editor is now Textpad.
;   Mark Hadfield, 2007-04:
;     TextPad program file name updated for version 5.
;   Mark Hadfield, 2009-10:
;     Available editors are now defined via the !MGH_EDITOR system
;     variable and selected with the EDITOR keyword. Moved into the
;     Motley library.
;   Mark Hadfield, 2011-09:
;     The name argument now accepts vector values when CLASS or
;     ROUTINE is set.
;   Mark Hadfield, 2014-06:
;     Updated formatting.
;-
pro mgh_edit, name, $
  CLASS=class, COMMANDS=commands, EDITOR=editor, PICK=pick, $
  NEW=new, ROUTINE=routine, VARIABLE=variable

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  defsysv, '!mgh_editor', EXISTS=exists
  if ~exists then $
    message, '!MGH_EDITOR system variable has not been defined.'
    
  if size(!mgh_editor, /TYPE) ne 7 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', '!MGH_EDITOR'
    
  if n_elements(editor) eq 0 then editor = 0
  
  ;; Determine file to be edited & create it if appropriate.
  
  n_name = n_elements(name)
  
  case 1B of
    keyword_set(pick): begin
      filename = dialog_pickfile(TITLE='Select file to edit', $
        MUST_EXIST=(~ keyword_set(new)))
      if strlen(filename) eq 0 then $
        message, 'File selection cancelled.'
    end
    keyword_set(class): begin
      if n_name gt 0 then begin
        filename = strarr(n_name)
        for i=0,n_name-1 do begin
          f = file_which(strlowcase(name[i])+'__define.pro', $
            /INCLUDE_CURRENT_DIR)
          if strlen(f) eq 0 then $
            message, 'Could not find class '+name[i]
          filename[i] = f
        endfor
      endif
    end
    keyword_set(routine): begin
      if n_name gt 0 then begin
        filename = strarr(n_name)
        for i=0,n_name-1 do begin
          f = file_which(strlowcase(name[i])+'.pro', $
            /INCLUDE_CURRENT_DIR)
          if strlen(f) eq 0 then $
            message, 'Could not find routine '+name[i]
          filename[i] = f
        endfor
      endif
    end
    keyword_set(variable): begin
      filename = filepath(cmunique_id()+'.txt', /TMP)
      txt_save, name, filename
    end
    keyword_set(commands): begin
      filename = filepath(cmunique_id()+'.pro', /TMP)
      cmd = reverse(recall_commands())
      l_good = where(strlen(cmd) gt 0, n_good)
      cmd = n_good gt 0 ? cmd[l_good] : ''
      txt_save, temporary(cmd), filename
    end
    keyword_set(new): begin
      filename = name
      ;; Create empty file; set APPEND to ensure that if the
      ;; file already exists, it is not overwritten.
      openw, lun, filename, /GET_LUN, /APPEND
      free_lun,lun
    end
    else: begin
      if n_elements(name) gt 0 then filename = name
    end
  endcase
  
  if n_elements(filename) gt 0 then begin
  
    filename = file_expand_path(filename)
    
    foreach f, filename do begin
      if ~ file_test(f, /READ) then $
        message, 'File '+f+' does not exist or cannot be read'
    endforeach
    
  endif
  
  ;; Construct and execute the editor command
  
  cmd = '"'+!mgh_editor[editor]+'"'
  
  if n_elements(filename) gt 0 then $
    foreach f, filename do cmd =[cmd,'"'+f+'"']
    
  message, /INFORM, 'Activating editor'
  
  if strcmp(!version.os_family, 'Windows', /FOLD_CASE) then begin
    spawn, /NOSHELL, /NOWAIT, strjoin(cmd, ' ')
  endif else begin
    spawn, strjoin([cmd,'&'], ' ')
  endelse

end

