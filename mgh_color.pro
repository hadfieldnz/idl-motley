;+
; NAME:
;   MGH_COLOR
;
; PURPOSE:
;   This function accepts one or more colour specifiers in string form
;   and returns an array containing corresponding RGB colour values.
;   The colour data are specified in a file, mgh_color.dat, which
;   must be in the same directory as the source file.
;   
;   Note that much of the functionality of this routine is now provided
;   by the !color system variable, introduced in IDL 8.0.
;
; CATEGORY:
;   Graphics, Color Specification.
;
; CALLING SEQUENCE:
;   result = mgh_color(name)
;
; POSITIONAL PARAMETERS:
;   name (input, string)
;     Colour specifier. Each elements may be in one of two forms:
;
;       - If the string begins with "(" and ends with ")" then the
;         characters between are assumed to contain an RGB-coded
;         colour value in numeric form, eg. "(255,0,255)" or "(255 0
;         255)". The conversion is done using a READS statement and if
;         an IO error occurs the corresponding value in the output is
;         left at 0.
;
;       - Otherwise the specifier is matched against a list of
;         pre-defined colour names. If no match is found then black
;         [0,0,0] is returned.
;
; KEYWORD PARAMETERS:
;   DECOMPOSED (input, switch)
;     Set this keyword to return a scalar or n-element long-word
;     vector in which RGB values are stored in the least-significant
;     three bytes. (This is the form required by direct-graphics
;     devices when the DECOMPOSED keyword is set.) The default is to
;     return a [3] or [3,n] byte array, as required by the Object
;     Graphics system.
;
;   NAMES (input, switch)
;     Set this keyword to return a list of the colour names recognised
;     by the function. The "name" argument is then ignored.
;
;   REREAD (input, switch)
;     Set this keyword to cause the colour-data file to be
;     reread. Normally it is only read the first time the function is
;     run. This keyword is useful when testing changes to the
;     colour-data file.
;
;###########################################################################
; Copyright (c) 1998-2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1998-03:
;     Written, inspired by David Fanning's GETCOLOR.
;   Mark Hadfield, 2000-07:
;     Updated for IDL2 syntax
;   Mark Hadfield, 2001-10:
;     - Added DECOMPOSED keyword.
;     - Colour names & associated values are now read from a file.
;   Mark Hadfield, 2001-11:
;     Added support for numeric specifiers.
;   Mark Hadfield, 2004-03:
;     Now uses David Fanning's PROGRAMROOTDIR function to find the data
;     file.
;   Mark Hadfield, 2007-11:
;     Sometime in the last few years, this function has stopped using
;     PROGRAMROOTDIR.
;   Mark Hadfield, 2013-07:
;     Reformatted.
;   Mark Hadfield, 2014-06:
;     Determination of data file name simplified.
;-
pro mgh_color_reread

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  compile_opt HIDDEN

  common mgh_color_common, color_names, color_values
  
  ;; Read colour names & values from a data file.
  
  file = mgh_str_subst(routine_filepath('mgh_color', /IS_FUNCTION), '.pro', '.dat')
  
  if ~ file_test(file, /READ) then $
    message, 'Colour data file '+file+' not readable'
    
  ;; Open the file
  
  message, /INFORM, 'Reading colour data from '+file
  
  openr, lun, file, /GET_LUN
  
  line = ''
  
  ;; Read the file once to count colours
  
  l = 0
  while ~ eof(lun) do begin
    readf, lun, line
    if mgh_str_iswhite(line) then continue
    if strmid(line, 0, 1) eq '#' then continue
    l ++
  endwhile
  
  n_colors = l
  
  color_names = strarr(n_colors)
  color_values = bytarr(3, n_colors)
  
  ;; Rewind the file and read color data
  
  point_lun, lun, 0
  
  l = 0
  while ~ eof(lun) do begin
    readf, lun, line
    if mgh_str_iswhite(line) then continue
    if strmid(line, 0, 1) eq '#' then continue
    items = strsplit(line, ',', /EXTRACT, /PRESERVE_NULL, COUNT=n_items)
    if n_items ne 4 then $
      message, 'Unexpected line in data file: '+line
    color_names[l] = strlowcase(strtrim(items[0],2))
    color_values[*,l] = fix(items[1:3])
    l ++
  endwhile
  
  free_lun, lun
  
  ;; Check colour names are unique
  
  if n_elements(uniq(color_names, sort(color_names))) lt n_colors then $
    message, 'Color names not unique'
    
end

function mgh_color, name, $
  DECOMPOSED=decomposed, NAMES=names, REREAD=reread
  
  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
  
  common mgh_color_common, color_names, color_values
  
  on_error, 2
  
  if n_elements(reread) eq 0 then $
    reread = n_elements(color_names)*n_elements(color_values) eq 0
    
  if keyword_set(reread) then mgh_color_reread
  
  if keyword_set(names) then return, color_names
  
  if size(name, /N_ELEMENTS) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'name'
    
  if size(name, /TYPE) ne 7 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'name'
    
  n = size(name, /N_ELEMENTS)
  
  result = (size(name, /N_DIMENSIONS) eq 0) ? bytarr(3) : reform(bytarr(3,n),3,n)
    
  ;; Step through colours
  
  for i=0,n-1 do begin
  
    nam = name[i]
    
    if strmid(nam,0,1) eq '(' && $
      strmid(nam,0,1,/REVERSE_OFFSET) eq ')' then begin
      
      ;; Look for an RGB triple
      
      rgb = bytarr(3)
      
      on_ioerror, skip
      
      reads, strmid(nam,1,strlen(nam)-2), rgb
      
      skip: on_ioerror, null
      
      result[*,i] = rgb
      
    endif else begin
    
      ;; Try to match colour name with variable color_names. If it
      ;; is not found, leave result unchanged, so colour is black.
      
      w = where(strmatch(color_names, name[i], /FOLD_CASE), m)
      
      if m eq 1 then result[*,i] = color_values[*,w[0]]
      
    endelse
    
  endfor
  
  if keyword_set(decomposed) then $
    result = reform(result[0,*] + result[1,*]*2L^8 + result[2,*]*2L^16)
    
  return, result

end
