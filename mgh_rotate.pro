;+
; NAME:
;   MGH_ROTATE
;
; PURPOSE:
;   This provides a handy shortcut for rotation of vectors on the
;   X,Y plane. Given arguments x & y representing
;   x & y components, respectively, and an angle, the
;   procedure rotates the (x,y) vector through the angle using the mathematical
;   convention (radians, anti-clockwise) and returns the components of the result.
;   
;   The arguments can all be scalars or arrays. Incompatible dimensions will
;   be picked up during processing.
;
; CALLING SEQUENCE:
;   mgh_rotate, x, y, angle
;
; POSITIONAL ARGUMENTS:
;   x, y (non-complex scalar or array, input and output)
;      X & Y components of the vector, modified on output.
;
;   angle (numeric scalar or array)
;      Angle in radians. (A complex value of angle is permitted and 
;      will produce a change in the vector length.)
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2011-12:
;     Written.
;   Mark Hadfield, 2015-02:
;     Source re-indented.
;-
pro mgh_rotate, x, y, a

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
   
  if n_elements(x) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'x'
  if n_elements(y) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'y'
  if n_elements(a) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'
    
  if ~ arg_present(x) then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_missingarg', 'x'
  if ~ arg_present(y) then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_missingarg', 'y'
    
  cj = complex(0, 1)
  
  xy = complex(temporary(x), temporary(y))*exp(cj*a)
  
  x = real_part(xy)
  y = imaginary(temporary(xy))
   
end


