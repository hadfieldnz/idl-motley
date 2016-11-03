;+
; NAME:
;   MGH_BAND_EDGE
;
; PURPOSE:
;   Given a 2D array as input, return a copy in which there is a band
;   adjacent to the edge with zero gradient normal to the edge
;
;###########################################################################
; Copyright (c) 2011 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; POSITIONAL ARGUMENTS:
;   data (input, 2D array)
;     The input array, can be any data type
;
; KEYWORD ARGUMENTS:
;   WIDTH (input, integer with one or 4 elements)
;     The width of the nudging band: if WIDTH is a scalar or 1-element
;     vector, the same value is used on all boundaries. If WIDTH is
;     a 4-element vector, the values are applied to the south, east, north
;     and west boundaries in turn.
;
; RETURN VALUE:
;   The function returns an array of the same type and dimensions as
;   the input.
;
; PROCEDURE
;   Copy interior values into the band.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2006-03:
;     Written to replace mgh_moma_top_smoothedge and similar.
;   Mark Hadfield, 2013-02:
;     WIDTH can now be a 4-element vector, allowing each edge
;     to be "banded" individually. The 4 elements are mapped onto
;     the south, east, north and west boundaries in turn.
;   Mark Hadfield, 2014-06:
;     Reformatted.
;-
function mgh_band_edge, data, WIDTH=width

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(width) eq 0 then width = 1

  my_width = n_elements(width) eq 1 ? replicate(width, 4) : width

  result = data

  dim = size(result, /DIMENSIONS)

  n0 = dim[0]
  n1 = dim[1]

  ;; Edges are taken anti-clockwise, starting with the "southern"

  ;; Southern edge
  if my_width[0] gt 0 then begin
    w = my_width[0]
    for i=0,n0-1 do result[i,0:w-1] = result[i,w]
  endif

  ;; Eastern edge
  if my_width[1] gt 0 then begin
    w = my_width[1]
    for j=0,n1-1 do result[n0-w:n0-1,j] = result[n0-1-w,j]
  endif

  ;; Northern edge
  if my_width[2] gt 0 then begin
    w = my_width[2]
    for i=0,n0-1 do result[i,n1-w:n1-1] = result[i,n1-1-w]
  endif

  ;; Western edge
  if my_width[3] gt 0 then begin
    w = my_width[3]
    for j=0,n1-1 do result[0:w-1,j] = result[w,j]
  endif

  return, result

end


