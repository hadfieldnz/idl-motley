;+
; NAME:
;   MGH_STR_VANILLA
;
; PURPOSE:
;   Convert arbitrary string to vanilla form, suitable for file name.
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   result = mgh_str_vanilla(instr)
;
; POSITIONAL PARAMETERS:
;   instr (input, string scalar or array)
;     Input string(s).
;
; RETURN VALUE:
;   The function returns a string variable with the same shape as the
;   original, with all unsafe characters replaced with safe ones.
;
;###########################################################################
; Copyright (c) 2005-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2005-02:
;     Written.
;   Mark Hadfield, 2009-07:
;     Substitution map is now a [2,n] array. Added a substitution for '*'.
;   Mark Hadfield, 2009-09:
;     Added a substitution for '?'.
;   Mark Hadfield, 2010-03:
;     Added a substitution for ','.
;   Mark Hadfield, 2013-05:
;     Added substitutions for '@' and '+'.
;   Mark Hadfield, 2015-11:
;     - Substitution map is now a hash object.
;     - The value "_" is now used for all substitution map keys.
;   Mark Hadfield, 2017-10:
;     Added a substitution for '.'.
;-
function mgh_str_vanilla, instr

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(instr) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'instr'

   if size(instr, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'instr'

   result = instr

   map = hash()
   map[' '] = '_'
   map[':'] = '_'
   map['/'] = '_'
   map['\'] = '_'
   map[')'] = '_'
   map['('] = '_'
   map['>'] = '_'
   map['<'] = '_'
   map['&'] = '_'
   map[','] = '_'
   map['.'] = '_'
   map['?'] = '_'
   map['@'] = '_'
   map['+'] = '_'
   map['*'] = '_'

   dim = size(map, /DIMENSIONS)

   foreach k,map->Keys() do $
      result = mgh_str_subst(temporary(result), k, map[k])

   return, result

end
