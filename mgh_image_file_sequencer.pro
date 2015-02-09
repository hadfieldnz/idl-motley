;+
; NAME:
;   MGH_IMAGE_FILE_SEQUENCER
;
; PURPOSE:
;   Display images from a seuqnce of files.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2013-09:
;     Written.
;-
pro mgh_image_file_sequencer, file, NAME=name

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(file) eq 0 then $
     message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'file'
     
  n_file = n_elements(file)
  
  ;; The default name for the embeded graph comes from the name of the first file. I'd like
  ;; to strip off the suffix and any sequqnce characters, but this is a bit tricky.
  
  if n_elements(name) eq 0 then begin
    name = file_basename(file[0])
  endif

  ;; Establish that all the files in the sequence can be read
  
  for f=0,n_file-1 do begin
    if ~ file_test(file[f]) then message, 'File cannot be read: '+file[f]
  endfor
  
  ;; Query first image to establish type, dimensions, etc
  
  ok = query_image(file[0], info)
  
  if info.has_palette then $
     message, 'Sorry, I do not do images with palettes yet.'
     
  ; Create the animator object 
     
  oanim = obj_new('MGH_Imagator', DIMENSIONS=info.dimensions, GRAPHICS_TREE_PROPERTIES={name: name})

  ;; Add images

  for f=0,n_file-1 do begin

    if oanim->Finished() then break
    
    data = read_image(file[f])
    
    oanim->AddImage, data
    
  endfor

  oanim->Finish

end

