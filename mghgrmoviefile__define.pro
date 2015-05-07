;+
; CLASS:
;   MGHgrMovieFile
;
; PURPOSE:
;   This class generates an animation file from a sequence of images.
;
;   The MGHgrMovieFile class is modelled on the IDLgrMPEG class. It stores
;   images on disk in a sequence of PPM or TIFF files (Put method) then combines them
;   into a multiple-image file (Save method) by spawning one of the following
;   programs:
;
;    - The ImageMagick "convert" command (http://www.imagemagick.org/)
;
;    - Klaus Ehrenfried's program "ppm2fli" for generating FLC
;      animations, (http://vento.pi.tu-berlin.de/fli.html).
;
;    - The Info-Zip "zip" command (http://www.cdrom.com/pub/infozip/)
;
;   The user is responsible for ensuring that the command names as
;   specified here invoke the command in the shell spawned by
;   IDL. This can be done in a variety of ways depending on the
;   operating system and shell.
;   
;   On Windows, best results are achieved by invoking Cygwin versions
;   of the commands. This is best done via a batch shell that
;   initialises the PATH variable appropriately.
;
;   In the current version, frames can only be added at the end of the
;   sequence.
;
; PROPERTIES:
;
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported
;
;     COUNT (Get)
;       The number of frames that have been put into the object.
;
;     DIMENSIONS (Get)
;       A 2-element integer array specifying the image dimensions in
;       pixels. This property is determined from the first frame added
;       to the object. It is used by the Save method when generating
;       FLC files, otherwise it is for information only.
;
;     FILE (Init, Get, Set)
;       A string specifying the name of the output file.
;
;     FORMAT (Init, Get, Set)
;       A string (converted internally to upper case) specifying the
;       output file format. See FILE FORMATS section below.
;
; FILE FORMATS:
;
;   With the exceptions noted below, the FORMAT property is
;   interpreted as an ImageMagick descriptor for a graphics-file
;   format supporting multiple images. Possible values include:
;
;     GIF
;       ImageMagick can produce multi-image GIFs. For several years,
;       LZW compression was missing from the binary distributions
;       so they produced only uncompressed GIFs. However as of
;       2004-04 it appears to have been reinstated.
;
;     HDF
;       The CONVERT documentation claims that it can write multiple
;       images to an HDF file, but messages on the ImageMagick
;       mailing list say that HDF is no longer supported.
;
;     PDF, PS
;       Images are written to a PDF or PS file, one image per page.
;       This could be used for printing, I guess.
;
;     TIFF
;       This is a handy format for holding a sequence of images with
;       no loss in quality, though there are no players offering
;       speedy playback.  Compression is an issue, because the normal
;       LZW compression is unavailable in ImagMagick by default
;       (cf. GIF above).  I have found Zip compression the best. It is
;       supported by ImageMagick and also by my preferred TIFF viewer,
;       Xnview (http://perso.wanadoo.fr/pierre.g/xnview/enhome.html).
;       Note that, for medium-to-large animations, memory is an issue, as 
;       the convert command that gathers the image sequence appears to 
;       keep the whole thing in memory
;
;   The following are handled by applications other than ImageMagick:
;
;     FLC
;       The FLC animation format (http://crusty.er.usgs.gov/flc.html),
;       originally developed by Autodesk is generally less
;       resource-hungry than MPEG. It is limited to 256 colours, which
;       are assigned in an optimal way by PPM2FLI.
;
;     ZIP
;       If this format is selected, the PPM files are gathered into a
;       ZIP archive.
;
;###########################################################################
; Copyright (c) 2000-2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-02:
;     Written.
;   Mark Hadfield, 2003-10:
;     Updated for IDL 6.0.
;   Mark Hadfield, 2004-04:
;     Location & names of the temporary PPM files have been
;     changed. This has been done to make the ZIP format more usable,
;     as the base name for the PPM files inside the ZIP file is now
;     based on the output file name.
;   Mark Hadfield, 2006-05:
;     Deleted code specific to MPEG. I don't use this class to create
;     MPEG files any more.
;   Mark Hadfield, 2009-10:
;     Fixes in the Save method to the spawned commands so that they work
;     on Windows and Unix.
;   Mark Hadfield, 2013-01:
;     Another fix to the Save method to make it more Cygwin-friendly on
;     Windows.
;   Mark Hadfield, 2015-05:
;     - The temporary image file sequence is now in TIFF format, unless
;       the the output format is FLC, in which case the original PPM format
;       is retained.
;     - The FORMAT property can no longer be changed after object is initialised.
;     - Dropped references to MNG support. (MNG may or may not still be
;       supported via ImageMagick.)
;     - Reformatted source code. 
;-
function MGHgrMovieFile::Init, $
     FILE=file, FORMAT=format

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(format) eq 0 then format = 'ZIP'
  self.format = strupcase(format)
  
  case self.format of
    'FLC': self.extension = 'ppm'
    else : self.extension = 'tif'
  endcase
  
  self.tempdir = filepath('', ROOT=filepath('', /TMP), SUBDIR=cmunique_id())
  
  file_mkdir, self.tempdir
  
  self->SetProperty, FILE=file
  
  return, 1

end


; MGHgrAnimation::Cleanup
;
pro MGHgrMovieFile::Cleanup

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  for p=0,self.count-1 do file_delete, self->FrameFileName(p)
  
  file_delete, self.tempdir

end

; MGHgrMovieFile::GetProperty
;
pro MGHgrMovieFile::GetProperty, $
     COUNT=count, DIMENSIONS=dimensions, FILE=file, FORMAT=format

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  count = self.count
  
  dimensions = self.dimensions
  
  file = self.file
  
  format = self.format

end

; MGHgrMovieFile::SetProperty
;
pro MGHgrMovieFile::SetProperty, $
     FILE=file

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(file) gt 0 then begin
    self.file = file
    if strlen(self.base) eq 0 then begin
      self.base = file_basename(self.file)
      p = strpos(self.base, '.')
      if p gt 0 then self.base = strmid(self.base, 0, p)
    endif
  endif

end

; MGHgrMovieFile::Count
;
function MGHgrMovieFile::Count

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  return, self.count

end


; MGHgrMovieFile::FrameFileName
;
function MGHgrMovieFile::FrameFileName, position

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(position) eq 0 then position = 0
  
  result = mgh_reproduce('', position)
  fmt = '(%"%s.%6.6d.%s")'
  for i=0,n_elements(position)-1 do $
    result[i] = filepath(string(FORMAT=fmt, self.base, position[i], self.extension), ROOT=self.tempdir)

  return, result

end


; MGHgrMovieFile::Put
;
pro MGHgrMovieFile::Put, image

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  position = self.count
  
  n_dims = size(image, /N_DIMENSIONS)
  
  if (n_dims lt 2) || (n_dims gt 3) then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'image'
    
  if product(self.dimensions) eq 0 then $
    self.dimensions=(size(image, /DIMENSIONS))[n_dims-2:n_dims-1]
    
  ;; Generate image file
  
  file = self->FrameFileName(position)
  
  case self.extension of
    'ppm': write_ppm, file, image 
    'tif': write_tiff, file, image, ORIENTATION=1
  endcase
  
  self.count += 1

end


; MGHgrMovieFile::Save
;
pro MGHgrMovieFile::Save

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if file_test(self.file) then file_delete, self.file
  
  ;; Most of the programs can or must read input file names
  ;; from a list file
  
  file_list = filepath('list.dat', ROOT=self.tempdir)
  
  ;; Spawn a program to build the file. The default
  ;; frame rate can be set via CONVERT's -delay switch
  ;; (delay in units of 10 ms) and PPM2FLI's -s switch
  ;; (delay in ms). It would be nice to be able to alter
  ;; this but I haven't got around to it. Handling of options
  ;; generally needs to be cleaned up.
  
  case 1B of
  
    self.format eq 'FLC': begin
      openw, lun, file_list, /GET_LUN
      ;; Write file in Unix format to allow the use of Cygwin ppm2fli
      for i=0,self.count-1 do $
        writeu, lun, self->FrameFileName(i)+string(10B)
      free_lun, lun
      sdim = string(FORMAT='(%"%dx%d")', 2*(self.dimensions/2))
      fmt = '(%"ppm2fli -vv -Qn 1024 -s 67 -g %s \"%s\" \"%s\"")'
      if !version.os_family eq 'Windows' then begin
        spawn, LOG_OUTPUT=1, $
          string(FORMAT=fmt, sdim, file_list, self.file)
      endif else begin
        spawn, string(FORMAT=fmt, sdim, file_list, self.file)
      endelse
      file_delete, file_list
    end
    
    self.format eq 'ZIP': begin
      openw, lun, file_list, /GET_LUN
      for i=0,self.count-1 do $
        printf, lun, self->FrameFileName(i)
      free_lun, lun
      fmt = '(%"zip -v -j -D \"%s\" -@ < \"%s\"")'
      if !version.os_family eq 'Windows' then begin
        spawn, LOG_OUTPUT=1, $
          string(FORMAT=fmt, self.file, file_list)
      endif else begin
        spawn, string(FORMAT=fmt, self.file, file_list)
      endelse
      
      file_delete, file_list
    end
    
    self.format eq 'TIFF': begin
      openw, lun, file_list, /GET_LUN
      for i=0,self.count-1 do $
        printf, lun, self->FrameFileName(i)
      free_lun, lun
      fmt = '(%"convert -verbose -adjoin -delay 7 @\"%s\" -compress Zip %s:\"%s\"")'
      if !version.os_family eq 'Windows' then begin
        ;; This command will fail if the size of the list file exceeds
        ;; 8192 characters. One could work around this limit by
        ;; including only the bare image file names in the list file
        ;; and cd'ing to the temporary directory before running the
        ;; command. (MGH 2015-05-05: Not sure if this restrictions still
        ;; applies.)
        spawn, LOG_OUTPUT=1, $
          string(FORMAT=fmt, file_list, self.format, self.file)
      endif else begin
        spawn, string(FORMAT=fmt, file_list, self.format, self.file)
      endelse
      file_delete, file_list
    end
    
    else: begin
      openw, lun, file_list, /GET_LUN
      for i=0,self.count-1 do $
        printf, lun, self->FrameFileName(i)
      free_lun, lun
      fmt = '(%"convert -verbose -adjoin -delay 7 @\"%s\" %s:\"%s\"")'
      if !version.os_family eq 'Windows' then begin
        spawn, LOG_OUTPUT=1, $
          string(FORMAT=fmt, file_list, self.format, self.file)
      endif else begin
        spawn, string(FORMAT=fmt, file_list, self.format, self.file)
      endelse
      file_delete, file_list
    end
    
  endcase

end


; MGHgrMovieFile__Define
;
pro MGHgrMovieFile__Define

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  struct_hide, {MGHgrMovieFile, inherits IDL_Object, $
    dimensions: lonarr(2), format: '', extension: '', $
    file: '', tempdir: '', base: '', count: 0}

end

