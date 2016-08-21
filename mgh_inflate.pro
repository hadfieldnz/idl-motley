;+
; NAME:
;   MGH_INFLATE
;
; PURPOSE:
;   Given an n-dimensional rectangular grid defined by n one-dimensional
;   arrays, expand one of these arrays into n-dimensions.
;
; CATEGORY:
;   Finite-diffeence grids.
;
; CALLING SEQUENCE:
;   Result = MGH_INFLATE(dim, a, n)
;
; POSITIONAL PARAMETERS:
;   dim (input, integer vector)
;     The dimensions of the output array. The number of elements in the
;     data array, x, must equal dim[n], where n is the third positional
;     parameter, below.
;
;   a (input, numeric array)
;     A 1D array representing grid positions. The dimension
;     associated with these positions is specified by the
;     third positional parameter, n.
;
;   n (input, integer scalar)
;     The dimension number (1-based) associated with the data in x.
;     These data values are inflated over all the other dimensions.
;
; RETURN VALUE:
;   The function returns an array with the same type as x and the dimensions
;   specified by dim.
;
;###########################################################################
; Copyright (c) 2003-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2003-09:
;     Written
;   Mark Hadfield, 2003-09:
;     Order of parameters changed. The array of output dimensions now
;     comes first.
;-
function mgh_inflate, dim, a, n

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(a) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'

   if n_elements(dim) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'dim'

   if n_elements(n) eq 0 then n = 1

   n_dim = size(dim, /N_ELEMENTS)

   if (n lt 1) || (n gt n_dim) then $
        message, 'Dimension '+strtrim(n,2)+' is not available'

   n_val = size(a, /N_ELEMENTS)

   if n_val ne dim[n-1] then begin
      fmt = '(%"Number of elements %d does not match specified dimensions")
      message, string(FORMaT=fmt, n_val)
   endif

   ;; Generate a copy of the data in a, arranged so that values vary
   ;; along dimension n

   dim0 = replicate(1, n_dim)

   dim0[where((n-1) eq lindgen(n_dim))] = n_elements(a)

   b = reform(a, dim0)

   ;; Rebin result to n dimensions

   return, rebin(b, dim, /SAMPLE)

end
