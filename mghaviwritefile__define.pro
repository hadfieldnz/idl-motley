;+
; NAME:
;   Class MGHaviWriteFile
;
; PURPOSE:
;   This class encapsulates an AVI file to be written using the
;   functions supported by the AVI DLL.
;
; PROPERTIES:
;   BIT_RATE (Init)
;     Maximum video data rate in bits per second as a scalar integer.
;     The interpretation of this parameter depends on the codec. In my
;     experience it is best left at its default of 0 (unconstrained).
;
;   CODEC (Init, Get)
;     Video codec name as a 4-character string. This must match the
;     4-character descriptor (FOURCC) one of the codecs installed on
;     the machine. (The comparison is case-insensitive.) If the CODEC
;     argument to the Init function is omitted, then a dialogue will
;     appear offering a choice of codecs & compression options.
;
;   DIMENSIONS (Init, Get)
;     Image dimensions as a 2-element integer vector. Note that some
;     codecs impose conditions on the dimensions. These conditions
;     vary with the codec and its settings. For some codecs the
;     dimensions be a multiple of 2, 4 or 8 and some codecs in some
;     configurations support only a few fixed dimensions. As a
;     practical compromise, it is wise for the calling application to
;     round the dimensions to the nearest multiple of 4.
;
;   FILE_NAME (Init, Get)
;     The name of the AVI file wrapped by the MGHaviWriteFile object.
;
;   FRAME_RATE (Init)
;     Video playback rate in frames per second as a scalar integer.
;     Default is 15 fps.
;
;   IFRAME_GAP (Init)
;     Spacing between I-frames in the video stream as a scalar
;     integer. (I-frames, or key frames are frames that can be
;     reconstructed without using data from any surrounding frames in
;     the animation.) A large IFRAME_GAP reduces file size but makes
;     navigation to arbitrary positions in the animation slow. For
;     quick navigation set IFRAME_GAP to a smallish value like
;     10. Default is 0 (I-frame spacing left to the codec).
;
;   QUALITY (Init)
;     Video quality as a scalar integer between 0 (lowest) and 100
;     (highest). The interpretation of this parameter depends on the
;     codec.
;
;   TRUE_COLOR (Init)
;     A logical value specifying whether the frames are to be supplied
;     as [3,m,n] true-colour images (TRUE_COLOR=1) or [m,n] pseudo-colour
;     images (TRUE_COLOR=0). Default is 1.
;
; AUTHORSHIP:
;   The IDL code in this file is based on code written by Oleg
;   Kornilov and provides an interface to C code also written by
;   Oleg.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2006-05:
;     Written, based on routines in Oleg's movie_io.pro.
;-
function MGHaviWriteFile::Init, $
     file, dimensions, red, green, blue, $
     BIT_RATE=bit_rate, CODEC=codec, FILE_NAME=file_name, FRAME_RATE=frame_rate, $
     IFRAME_GAP=iframe_gap, QUALITY=quality, TRUE_COLOR=true_color

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Specify file name

   if (n_elements(file_name) eq 0) && (n_elements(file) gt 0) then file_name = file

   if n_elements(file_name) ne 1 then $
        message, "A valid AVI file name must be supplied."

   if size(file_name, /TNAME) ne 'STRING' then $
        message, "A valid AVI file name must be supplied."

   self.file_name = file_name

   ;; Check dimensions are supplied.

   if n_elements(dimensions) ne 2 then $
        message, 'Illegal dimensions'

   ;; Specify keyword defaults

   if n_elements(bit_rate) eq 0 then bit_rate = 0

   if n_elements(codec) gt 0 then self.codec = byte(codec)

   if n_elements(frame_rate) eq 0 then frame_rate = 15

   if n_elements(iframe_gap) eq 0 then iframe_gap = 0

   if n_elements(quality) eq 0 then quality = 100
   quality = quality < 100 > 0

   if n_elements(true_color) eq 0 then true_color = 1B

   ;; Construct the ID variable (which initially encodes the number of
   ;; bits per pixel and the image dimensions). For pseudo-colour
   ;; animations get the palette.

   r = bytarr(256)
   g = bytarr(256)
   b = bytarr(256)
   
   if keyword_set(true_color) then begin
      id=[24L,long(dimensions),lonarr(6)]
   endif else begin
      id=[8L,long(dimensions),lonarr(6)]
      if n_elements(red) eq 0 then $
           tvlct, red, green, blue, /GET
      r[0] = red
      g[0] = green
      b[0] = blue
   endelse

   ;; Invoke the DLL to create the AVI file. Note that the "ID"
   ;; variable passed to it must be writable, so we cannot pass
   ;; "self.id".

   err = call_external(mgh_avi_dll(), 'avi_openw', id, self.file_name, $
                       r, g, b, byte(frame_rate), self.codec, byte(quality), $
                       long(iframe_gap), long(bit_rate))

   if err gt 0 then begin
      case err of
         1: error_message = 'Unable to create file '+self.file_name
         2: error_message = 'Unable to allocate memory'
         3: error_message = 'Unable to create stream'
         4: error_message = 'Unable to set options'
         5: error_message = 'Unable to create compressed stream'
         6: error_message = 'Unable to set stream format'
      endcase
      message, error_message
      return, 0
   endif

   self.id = id

   return, 1

end

; MGHaviWriteFile::Cleanup
;
pro MGHaviWriteFile::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   err = call_external(mgh_avi_dll(), 'avi_closew', self.id)

end


; MGHaviWriteFile::GetProperty
;
pro MGHaviWriteFile::GetProperty, $
     CODEC=codec, DIMENSIONS=dimensions, FILE_NAME=file_name, $
     POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   codec = string(self.codec)

   dimensions = self.id[1:2]

   file_name = self.file_name

   position = self.id[3]

end

; MGHaviWriteFile::Put
;
pro MGHaviWriteFile::Put, image, frame

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(image) ne self.id[0]/8*self.id[1]*self.id[2] then $
        message, 'Number of elements in image inconsistent with AVI properties'

   if n_elements(frame) eq 0 then frame = self.id[3]

   error = call_external(mgh_avi_dll(),'avi_put', self.id, long(frame), byte(image))

   if error then message, 'Error writing frame'

   self.id[3] += 1

end

pro MGHaviWriteFile__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHaviWriteFile, file_name: '', codec: bytarr(4), id: lonarr(9)}

end

