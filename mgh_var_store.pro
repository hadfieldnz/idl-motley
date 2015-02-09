; svn $Id$
;+
; NAME:
;   MGH_VAR_STORE
;
; PURPOSE:
;   Procedure MGH_VAR_SAVE creates a copy of an IDL variable at a call level
;   different from the current one. It uses undocumented features of the
;   built-in function ROUTINE_NAMES. See:
;
;       http://astrog.physics.wisc.edu/~craigm/idl/introspect.html#ROUTINE_NAMES
;
; CALLING SEQUENCE:
;   MGH_VAR_STORE, var
;
; ARGUMENTS:
;   var (Input)
;       The variable to be saved.
;
; KEYWORDS:
;   CLOBBER (Input)
;       This keyword determines whether an existing variable is overwritten.
;       Default is 1 (overwrite)--it is assumed that the caller knows what
;       he/she is doing! Note that when CLOBBER is 0, checking the existence
;       of a variable involves making a temporary copy of it, which may be
;       expensive.
;
;   LEVEL (Input)
;       The level in the call stack at which the variable is to be stored.
;       Default is 1 (main program).
;
;   NAME (Input)
;       The name under which the variable is to be known at the new level.
;       Default is 'var0'
;
;   VERBOSE (Input)
;       This keyword determines whether an informational message is generated.
;       Default is 1 (write message).
;
; SIDE EFFECTS:
;   Existing variables may be overwritten (see CLOBBER keyword).
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
;   Mark Hadfield, 2001-11:
;       Written.
;-

pro MGH_VAR_STORE, var                          $
        , CLOBBER=clobber                       $
        , LEVEL=level                           $
        , NAME=name                             $
        , VERBOSE=verbose

   compile_opt DEFINT32
   compile_opt STRICTARR

    on_error, 2

    if n_elements(clobber) eq 0 then clobber = 1

    if n_elements(level) eq 0 then level = 1

    if n_elements(name) eq 0 then name = 'var0'

    if n_elements(verbose) eq 0 then verbose = 1

    if n_elements(var) eq 0 then $
        message, 'Variable undefined'

    if not mgh_str_isidentifier(name[0]) then $
        message, 'Invalid identifier name'

    if not keyword_set(clobber) then $
        if n_elements(routine_names(name[0], FETCH=level)) gt 0 then $
            message, 'Variable is already defined. Cannot overwrite when CLOBBER is not set.'

    if keyword_set(verbose) then $
        message, /INFORM, 'Storing '+size(var, /TNAME)+' data at level '+strtrim(level,2)+' as variable '+name[0]

    dummy = routine_names(name[0], var, STORE=level)

end
