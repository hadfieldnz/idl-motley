;+
; NAME:
;   MGH_PERIM
;
; PURPOSE:
;   For a 2D rectilinear or curvilinear grid, return the perimeter
;   locations
;
; CALLING SEQUENCE:
;   result = mgh_perim(x, y)
;
; POSITIONAL PARAMETERS:
;   x, y (input, numeric 1D or 2D array)
;     X, Y positions of the grid nodes in either of the forms commonly
;     use for 2D grids: 1D arrays dimensioned [m] and [n] for
;     a rectilinear grid or 2D arrays both dimensioned [m,n] for a 
;     curvilinear grid. 
;
; RETURN_VALUE:
;   The function returns the perimeter locations in a [2,n] array.
;
;###########################################################################
; Copyright (c) 2000-2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2009-09:
;     Written.
;-
function mgh_perim, x, y

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(x) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'x'
  if n_elements(y) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'y'
    
  if size(x, /N_DIMENSIONS) ne size(y, /N_DIMENSIONS) then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'x', 'y'
    
  case size(x, /N_DIMENSIONS) of
  
    1: begin
      dim = [n_elements(x),n_elements(y)]
      xp = [x[0:dim[0]-2], $
            replicate(x[dim[0]-1], dim[1]-1), $
            reverse(x[1:dim[0]-1]), $
            replicate(x[0], dim[1]-1)]
        
      yp = [replicate(y[0], dim[0]-1), $
            y[0:dim[1]-2], $
            replicate(y[dim[1]-1], dim[0]-1), $
            reverse(y[1:dim[1]-1])]
    end
    
    2: begin
      if ~ array_equal(size(x, /DIMENSIONS), size(y, /DIMENSIONS)) then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_mismatcharr', 'x', 'y'
      dim = size(x, /DIMENSIONS)
      xp = [x[0:dim[0]-2,0], $
            reform(x[dim[0]-1,0:dim[1]-2]), $
            reverse(x[1:dim[0]-1,dim[1]-1]), $
            reverse(reform(x[0,1:dim[1]-1]))]
        
      yp = [y[0:dim[0]-2,0], $
            reform(y[dim[0]-1,0:dim[1]-2]), $
            reverse(y[1:dim[0]-1,dim[1]-1]), $
            reverse(reform(y[0,1:dim[1]-1]))]
    end
    
  endcase
  
  return, transpose([[temporary(xp)],[temporary(yp)]])

end
