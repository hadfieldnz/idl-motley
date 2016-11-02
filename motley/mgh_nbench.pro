; svn $Id$
;+
; NAME:
;   MGH_NBENCH
;
; PURPOSE:
;   This procedure reads the contents of a file & writes them to
;   another file. Cf. my Python script nbench.
;
; CALLING SEQUENCE:
;   MGH_NBENCH, InFile, OutFile
;
; INPUTS:
;   infile
;       Input file name.
;
;   outfile
;       Output file name.
;
; KEYWORD PARAMETERS:
;   BUFSIZE
;       This keyword has an effect only when the TEXT keyword *is not*
;       set. It specifies the size (in bytes) of chunks read &
;       written. Default is 2^16 (64kiB)
;
;   GUNZIP
;       If this keyword is set, read compressed data.
;
;   GZIP
;       If this keyword is set, write compressed data.
;
;   TEXT
;       If this keyword is set, treat the file as a text file,
;       transferring data line-by-line with formatted
;       read/writes. Otherwise, transfer data via a buffer with
;       unformatted read/writes of byte data.
;
;   UNIX
;       This keyword has an effect only when the TEXT keyword *is*
;       set. When UNIX is set, the lines of text are written via
;       unformatted writes terminated with a 10B character. Thus
;       Unix-format files are produced on all platforms.
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
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-12:
;       Written.
;-

pro MGH_NBENCH, directory, SIZE=size, BUFSIZE=bufsize

    compile_opt DEFINT32
   compile_opt STRICTARR

    if n_elements(directory) eq 0 then directory = filepath('', /TMP)

    if n_elements(bufsize) eq 0 then bufsize = 16 * 2^10

    if n_elements(size) eq 0 then size = 10 * 2^20

    buf = bytarr(bufsize)

    n_buf = size/bufsize

    file = filepath(cmunique_id(), ROOT=directory)

    if file_test(file) then message, 'File '+file+' already exists'

    mgh_tic

    openw, lun, file, /GET_LUN

    for i=0,n_buf do writeu, lun, buf

    free_lun, lun

    mgh_toc

    mgh_tic

    openr, lun, file, /GET_LUN

    for i=0,n_buf do readu, lun, buf

    free_lun, lun

    mgh_toc

    file_delete, file

end

