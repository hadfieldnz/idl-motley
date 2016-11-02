;+
; NAME:
;   MGH_EXAMPLE_FILE_COPY
;
; PURPOSE:
;   Example of MGH_FILE_COPY routine.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-02:
;     Written.
;-
pro mgh_example_file_copy

   compile_opt DEFINT32
   compile_opt STRICTARR

   tmpfile = filepath('test_copy_'+cmunique_id(), /TMP)

   openw, lun, tmpfile, /GET_LUN
   for i=0,1000 do writeu, lun, bindgen(256)
   free_lun, lun

   info = file_info(tmpfile)

   message, /INFORM, 'Temporary file '+tmpfile+' has size '+ $
            strtrim(info.size,2)

   mgh_file_copy, tmpfile, tmpfile+'_1.gz', /GZIP

   info = file_info(tmpfile+'_1.gz')

   message, /INFORM, 'Copied to compressed file '+tmpfile+ $
            '_1.gz with size '+strtrim(info.size,2)

   mgh_file_copy, tmpfile+'_1.gz', tmpfile+'_2', /GUNZIP

   info = file_info(tmpfile+'_2')

   message, /INFORM, 'Copied back to uncompressed file '+tmpfile+ $
            '_2 with size '+strtrim(info.size,2)

end

