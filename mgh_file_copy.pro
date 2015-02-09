;+
; NAME:
;   MGH_FILE_COPY
;
; PURPOSE:
;   This procedure reads the contents of a file & writes them to
;   another file.
;
; CALLING SEQUENCE:
;   MGH_FILE_COPY, InFile, OutFile
;
; POSITIONAL PARAMETERS:
;   infile (input, scalar string)
;     Input file name.
;
;   outfile (input, scalar string)
;     Output file name.
;
; KEYWORD PARAMETERS:
;   BUFSIZE (input, scalar integer)
;     This keyword has an effect only when the TEXT keyword *is not*
;     set. It specifies the size (in bytes) of chunks read &
;     written. Default is 2^16 (64kiB)
;
;   GUNZIP (input, logical)
;     If this keyword is set, read compressed data.
;
;   GZIP (input, logical)
;     If this keyword is set, write compressed data.
;
;   TEXT (input, logical)
;     If this keyword is set, treat the file as a text file,
;     transferring data line-by-line with formatted
;     read/writes. Otherwise, transfer data via a buffer with
;     unformatted read/writes of byte data.
;
;   UNIX (input, logical)
;     This keyword has an effect only when the TEXT keyword *is*
;     set. When UNIX is set, the lines of text are written via
;     unformatted writes terminated with a 10B character. Thus
;     Unix-format files are produced on all platforms.
;
; SIDE EFFECTS:
;   A new file is created.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1997-01:
;     Written.
;   Mark Hadfield, 1999-09:
;     Added GZIP, GUNZIP & TEXT functionality.
;   Mark Hadfield, 2000-08:
;     With the move to version 5.4, removed BINARY keyword in calls
;     to OPENR & OPENW. this should make the procedure portable to
;     non-Windows platforms.
;   Mark Hadfield, 2000-10:
;     Worked around EOF bug in IDL 5.4 beta by changing EOF to
;     MGH_EOF (which see).
;   Mark Hadfield, 2000-11:
;     EOF bug fixed in IDL 5.4 final so MGH_EOF changed back to
;     EOF.
;   Mark Hadfield, 2001-07:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2002-11:
;     Added YIELD keyword--yielding is done via an MGH_Waiter object.
;   Mark Hadfield, 2003-01:
;     Yielding is now turned on by default and is done via a call to
;     widget_event.
;   Mark Hadfield, 2005-02:
;     Fixed bug: binary NOT operator used when the LOGICAL_PREDICATE
;     compile option is in effect.
;   Mark Hadfield, 2009-10:
;     Removed YIELD functionality.
;   Mark Hadfield, 2011-08:
;     Added GUNZIP functionality.
;   Mark Hadfield, 2012-01:
;     Added BUNZIP2 functionality.
;   Mark Hadfield, 2013-06:
;     Increased BUFSIZE default from 64kiB to 256 kiB in an attempt
;     to improve speed of transfers from HPCF.
;   Mark Hadfield, 2014-07:
;     REvised source indentation
;-
pro mgh_file_copy, InFile, OutFile, $
     BUFSIZE=bufsize, BUNZIP2=bunzip2, GUNZIP=gunzip, GZIP=gzip, TEXT=text, $
     UNIX=unix, VERBOSE=verbose

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE
   
  if keyword_set(bunzip2) then begin
  
    if keyword_set(verbose) then begin
      msg = string(FORMAT='(%"Copying file %s to %s")', infile, outfile)
      message, /INFORM, temporary(msg)
    endif
    
    cmd = string(FORMAT='(%"bunzip2 -c \"%s\" > \"%s\"")', InFile, OutFile)
    
    if !version.os_family eq 'Windows' then begin
      spawn, /HIDE, cmd
    endif else begin
      spawn, cmd
    endelse
    
  endif else begin
  
    openr, inlun, InFile, /GET_LUN, COMPRESS=keyword_set(gunzip)
    openw, outlun, OutFile, /GET_LUN, COMPRESS=keyword_set(gzip)
    
    if keyword_set(verbose) then begin
      fs = fstat(inlun)
      fmt = '(%"Copying file %s (%0.3f MiB) to %s")'
      msg = string(FORMAT=temporary(fmt), infile, 2.^(-20)*fs.size, outfile)
      message, /INFORM, temporary(msg)
    endif
    
    if keyword_set(text) then begin
    
      while ~ eof(inlun) do begin
        sline = ''
        readf, inlun, sline
        if keyword_set(unix) then begin
          writeu, outlun, sline, string(10B)
        endif else begin
          printf, outlun, sline
        endelse
      endwhile
      
    endif else begin
    
      if n_elements(bufsize) eq 0 then bufsize = 2^18
      
      buf = bytarr(bufsize)
      
      catch, err
      if err ne 0 then goto, caught_err_binary
      
      while ~ eof(inlun) do begin
        readu, inlun, buf
        writeu, outlun, buf
      endwhile
      
      caught_err_binary:
      catch, /CANCEL
      if err ne 0 then begin
        case !error_state.name of
          'IDL_M_FILE_EOF' : begin
            info = fstat(inlun)
            if info.transfer_count gt 0 then $
              writeu, outlun, buf[0:info.transfer_count-1]
          end
          else: begin
            help, /STRUCT, !error_state
            message, 'Unexpected error'
          end
        endcase
      endif
      
    endelse
    
    free_lun, inlun
    free_lun, outlun
    
  endelse

end
