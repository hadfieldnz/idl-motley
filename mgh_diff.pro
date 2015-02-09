;+
; NAME:
;   MGH_DIFF
;
; PURPOSE:
;   This function calculates differences between adjacent elements of
;   an array.  It handles inputs with any number for dimensions and
;   differences them once. MGH_DIFF is similar to the standard IDL
;   function, TS_DIFF, except that:
;     - Differences are opposite in sign, ie. for an increasing
;       sequence of numbers MGH_DIFF returns positive differences,
;       whereas TS_DIFF returns negative differences.
;     - MGH_DIFF does not pad the result with trailing zeroes.
;     - MGH_DIFF does not support second and higher order differences
;       via recursion (because I do not know if this would generalise
;       well to higher dimensions).
;
; CALLING SEQUENCE:
;   result = mgh_diff(a)
;
; POSITIONAL PARAMETERS:
;   a (input, numeric array)
;     An array representing values on the grid.
;
;   d (input, integer scalar, optional)
;     Dimension (1-based) along which differencing is to be done.
;
; RETURN VALUE:
;   The function returns an array of the same type as the input,
;   contracted by 1 along the specified dimension.
;
;###########################################################################
; Copyright (c) 2005-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2003-07:
;     Written for 1-dimensional input arrays only.
;   Mark Hadfield, 2003-09:
;     Generalised for n-dimensional input arrays.
;   Mark Hadfield, 2015-01:
;     - Documentation updated.
;     - Source format updated.
;-
function mgh_diff, a, d

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  n_dim = size(a, /N_DIMENSIONS)
  dim = size(a, /DIMENSIONS)
  
  if size(a, /N_ELEMENTS) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'
    
  if n_elements(d) eq 0 then d = 1
  
  if d gt n_dim then message, 'Dimension not found in input array'
  
  ;; Copy input values into a temporary arrray, reformed to three
  ;; dimensions, such that the dimension to be differenced is the second
  ;; one.
  
  inner = 1
  for i=0,d-2 do inner *= dim[i]
  
  outer = 1
  for i=d,n_dim-1 do outer *= dim[i]
  
  r = reform(a, [inner,dim[d-1],outer])
  
  ;; Carry out differencing
  
  r = r[*,1:dim[d-1]-1,*] - r[*,0:dim[d-1]-2,*]
  
  ;; Reform result and return
  
  dim[d-1] -= 1
  
  return, reform(r, dim)

end
