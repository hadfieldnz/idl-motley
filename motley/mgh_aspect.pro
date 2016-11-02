;+
; NAME:
;   MGH_ASPECT
;
; PURPOSE:
;   Given x & y or longitude & latitude data, this function returns
;   the aspect ratio (y/x) of a rectangle spanning the data
;
; CALLING SEQUENCE:
;   result = mgh_aspect(x, y, LONLAT=lonlat)
;
; POSITIONAL PARAMETERS:
;   x, y (input, numeric arrays):
;    X & Y position, or longitude and latitude.
;
; KEYWORD PARAMETERS:
;   LONLAT (input, switch)
;     Set this keyword to interpret x & y as longitude & latitude.
;     The aspect ratio is one that gives true scaling halfway between
;     the minimum and maximum latitudes.
;
;   NAN (input, switch)
;     Set this keyword to ignore NaNs in the input
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2011-03:
;     Written.
;-
function mgh_aspect, x, y, LONLAT=lonlat, NAN=nan

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(x) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'x'
   if n_elements(y) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'y'

   if n_elements(x) lt 2 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'x'
   if n_elements(y) lt 2 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'y'

   mmx = mgh_minmax(x, NAN=nan)
   mmy = mgh_minmax(y, NAN=nan)

   result = double(mgh_diff(mmy))/double(mgh_diff(mmx))

   if keyword_set(lonlat) then result /= cos(!dtor*mgh_avg(mmy))

   return, result[0]

end


