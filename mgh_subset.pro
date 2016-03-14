;+
; NAME:
;   MGH_SUBSET
;
; PURPOSE:
;   Given a 1D monotonic vector (xin) representing location, and a pair of
;   positions (bound), this function returns the indices into the vector that
;   bracket those positions.
;
;   This function addresses a very common situation: we have a vector
;   representing (say) longitude for a global dataset and we wish
;   to pull out a subset of the data.
;
; CALLING SEQUENCE:
;   result = mgh_subset(xin, bound)
;
; POSITIONAL PARAMETERS:
;   xin (input, 1-D numeric array)
;     X positions of the vertices of the input grid. The X values
;     should be monotonic (if not, results will be unpredictable);
;     they need not be uniform.
;
;   bound (input, 2-element numeric array)
;     The boundaries of the subset in the position space defined by xin.
;     If the first (second) element of bound is non-finite, then the
;     corresponding result will be 0 (n_elements(xin)-1).
;
; KEYWORD PARAMETERS:
;   EMPTY (output, logical scalar)
;     Set this keyword to a named variable to return a logical value
;     indicating whether the range is empty. If the EMPTY parameter
;     is not present, and the range is actually empty, then an error
;     message is issued.
;
;   HALO (input, integer scalar)
;     Set this keyword to specify the number of extra data points (if
;     available) to be included at each end of the output range.
;
; RETURN_VALUE:
;   The function returns a 2-element integer vector representing the range
;   of indices.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2003-04:
;     Written.
;   Mark Hadfield, 2004-04:
;     Added handling for non-finite bounds..
;   Mark Hadfield, 2004-11:
;     Added handling for single-element input vector. I'm not at all sure
;     this is well-behaved, but it gets me past the immediate problem
;     that prompted the change.
;   Mark Hadfield, 2002-07:
;     Changed default setting for ROUND from 0 to -1, as the behaviour
;     with ROUND = 0 is usually not we want.
;   Mark Hadfield, 2008-02:
;     Added EMPTY keyword
;   Mark Hadfield, 2009-09:
;     - Removed the ROUND keyword and added the HALO keyword.
;     - Now uses simpler logic based on simple comparisons.
;     - Added EMPTY keyword.
;   Mark Hadfield, 2010-11:
;     - The behaviour in the case that the subset is empty has changed:
;       if the EMPTY parameter is not present, the function now raises an
;       error; otherwise the empty parameter returns true and the function
;       return value is !null.
;   Mark Hadfield, 2014-07:
;     - Reformatted.
;-
function mgh_subset, xin, bound, EMPTY=empty, HALO=halo

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(xin) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'xin'

   if size(xin, /N_DIMENSIONS) gt 1 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'xin'

   if n_elements(bound) ne 2 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'bound'

   if n_elements(halo) eq 0 then halo = 0

   empty = !false

   inside = mgh_reproduce(!true, xin)

   if finite(bound[0]) then $
      inside = inside and xin gt bound[0]

   if finite(bound[1]) then $
      inside = inside and xin lt bound[1]

   if max(inside) eq 0 then begin
      if arg_present(empty) then begin
         empty = !true
         return, !null
      endif else begin
         message, 'Range is empty'
      endelse
   endif

   empty = !false

   result = mgh_minmax(where(temporary(inside)))

   result = (result + [-1,1]*halo > 0) < (n_elements(xin) - 1)

   return, result

end

