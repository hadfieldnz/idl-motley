;+
; NAME:
;   MGH_RESOLVE_INDICES
;
; PURPOSE:
;   This procedure generates a series of indices for referencing a
;   vector.
;
;   I found myself writing this code over and over in my
;   model-analysis code so I put it in a separate procedure. The idea
;   is that we have a vector of known size and we want to specify a
;   subset of its elements. We can specify this subset using range and
;   stride parameters or by listing the indices. A negative value for
;   any of these parameters indicates a position relative to the end
;   of the vector
;
; CALLING SEQUENCE:
;   MGH_RESOLVE_INDICES, num, range, stride, indices
;
; POSITIONAL PARAMETERS:
;   num (input, compulsory, integer, scalar)
;     Number of elements in vector.
;
;   range (input, optional, integer, 2-element vector)
;     Minimum and maximum indices. Default is first and last.
;
;   stride (input, optional, integer, scalar)
;     Spacing of indices. Default is 1.
;
;   indices (input & output, integer, vector)
;     List of indices.
;
;###########################################################################
; Copyright (c) 2002 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-02:
;     Written.
;-
pro mgh_resolve_indices, num, range, stride, indices

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(num) ne 1 then $
        message, 'The number of elements is required'

   if n_elements(indices) eq 0 then begin

      if n_elements(range) eq 0 then range = [0,-1]

      if range[0] lt 0 then range[0] += num
      if range[1] lt 0 then range[1] += num

      if n_elements(stride) eq 0 then stride = 1

      indices = range[0]+stride*lindgen(1+(range[1]-range[0])/stride)

   endif

   indices = (indices+num) mod num

end
