;+
; NAME:
;   MGH_ADJACENT
;
; PURPOSE:
;   Given a 2D array defining a land-sea mask (sea=true; land=false), return
;   an array of the same shape marked with 1s on all the sea cells that are
;   adjacent to the land.
;
;   NB: Here "adjacent" means sharing a side with a land cell, not just sharing
;       a corner.
;
; POSITIONAL PARAMETERS:
;   data (input, 2D array)
;     The input array, any data type that can be interpreted as true/false.
;
; RETURN VALUE:
;   The function returns a byte array of the same dimensions as the input.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2014-06:
;     Written for use in MDC13301_ROMS_FRC_LOAD_SWFLUX.
;-
function mgh_adjacent, data

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  result = mgh_reproduce(0B, data)

  ;; Interior
  result[1:-2,1:-2] = $
    data[1:-2,1:-2] and $        ;;; Sea point
    (~ data[0:-3,1:-2] or $      ;;; Land to west
     ~ data[2:-1,1:-2] or $      ;;; Land to east
     ~ data[1:-2,0:-3] or $      ;;; Land to south
     ~ data[1:-2,2:-1])          ;;; Land to north

  ;; Southern edge
  result[1:-2,0] = $
    data[1:-2,0] and $           ;;; Sea point
    (~ data[0:-3,0] or $         ;;; Land to west
     ~ data[2:-1,0] or $         ;;; Land to east
     ~ data[1:-2,1])             ;;; Land to north

  ;; Northern edge
  result[1:-2,-1] = $
    data[1:-2,-1] and $          ;;; Sea point
    (~ data[0:-3,-1] or $        ;;; Land to west
     ~ data[2:-1,-1] or $        ;;; Land to east
     ~ data[1:-2,-2])            ;;; Land to south

  ;; Western edge
  result[0,1:-2] = $
    data[0,1:-2] and $           ;;; Sea point
    (~ data[1,1:-2] or $         ;;; Land to east
     ~ data[0,0:-3] or $         ;;; Land to south
     ~ data[0,2:-1])             ;;; Land to north

  ;; Eastern edge
  result[-1,1:-2] = $
    data[-1,1:-2] and $          ;;; Sea point
    (~ data[-2,1:-2] or $        ;;; Land to west
     ~ data[-1,0:-3] or $        ;;; Land to south
     ~ data[-1,2:-1] )           ;;; Land to north

  ;; SW corner
  result[0,0] = $
    data[0,0] and $              ;;; Sea point
    (~ data[1,0] or $            ;;; Land to east
     ~ data[0,1])                ;;; Land to north

  ;; NW corner
  result[0,-1] = $
    data[0,-1] and $             ;;; Sea point
    (~ data[1,-1] or $           ;;; Land to east
     ~ data[0,-2])               ;;; Land to south

  ;; SE corner
  result[-1,0] = $
    data[-1,0] and $             ;;; Sea point
    (~ data[-2,0] or $           ;;; Land to west
     ~ data[-1,1])               ;;; Land to north

  ;; NE corner
  result[-1,-1] = $
    data[-1,-1] and $            ;;; Sea point
    (~ data[-2,-1] or $          ;;; Land to west
     ~ data[-1,-2])              ;;; Land to south

  return, result

end


