; svn $Id$
;+
; NAME:
;   MGH_BYTSCL
;
; PURPOSE:
;   This function, like the standard IDL BYTSCL routine, converts
;   numeric values to byte values. It is more flexible than BYTSCL in
;   two respects:
;
;     - It allows one to specify the lower limit of the range of byte
;       values as well as the upper limit.
;
;     - It allows the mapping to be inverted, ie. large numeric values
;       mapping to small byte values.
;
; CALLING SEQUENCE:
;   result = MGH_BYTSCL(data)
;
; POSITIONAL PARAMETERS:
;   data (input, numeric scalar or array)
;     Data values to be scaled.
;
; KEYWORD PARAMETERS:
;   BYTE_RANGE (input, 2-element byte vector)
;     This keyword specifies the range of byte values to which the
;     data range is to be mapped. Default is [0B,255B]
;
;   DATA_RANGE (input, 2-element numeric vector)
;     The range of data values to be mapped onto the byte range. Data
;     values outside the range are mapped to the nearest end of the
;     range. If not specified, DATA_RANGE is calculated from the
;     maximum and minimum of data.
;
;   MISSING (input, byte scalar)
;     Output value for missing data. Default is 0B.
;
;   NAN (input, logical)
;     This keyword controls whether IEEE NaN values are treated as
;     missing, in which case they are mapped to the MISSING value. The
;     default is one--which differs from BYTSCL's default of zero--so
;     the keyword must be explicitly set to zero to disable NaN processing.
;
; RETURN VALUE:
;   The function returns a byte array with the same shape as the input.
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
;     Mark Hadfield, 1993-04:
;       Written.
;     Mark Hadfield, 1996-07:
;       Added BOTTOM, NAN and MISSING keywords.
;     Mark Hadfield, 2000-05:
;       IDL2 syntax.
;     Mark Hadfield, 2001-11:
;       Changed keyword names to bring them into line with other routines.
;-

function MGH_BYTSCL, data, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, MISSING=missing, NAN=nan

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   if n_elements(byte_range) eq 0 then $
        byte_range = [0B,255B]

   if n_elements(data_range) eq 0 then $
        data_range = mgh_minmax(data, /NAN)

   if n_elements(missing) eq 0 then $
        missing = 0B

   if n_elements(nan) eq 0 then $
        nan = 1B

   if byte_range[0] eq byte_range[1] then $
        message, 'BYTE_RANGE elements must not be the same'

   if data_range[0] eq data_range[1] then $
        message, 'DATA_RANGE elements must not be the same'

   if min(byte_range) lt 0 then $
        message, 'BYTE_RANGE values must not be less than 0'

   if max(byte_range) gt 255 then $
        message, 'BYTE_RANGE values must not be greater than 255'

   result = mgh_reproduce(0B,data)

   ii = where(finite(data), n_good, COMPLEMENT=jj, NCOMPLEMENT=n_bad)

   if n_good gt 0 then begin
      case (data_range[1] lt data_range[0]) of
         0: begin
            result[ii] = byte_range[0] + (byte_range[1]-byte_range[0]) $
                         * float((data_range[0] > data[ii] < $
                                  data_range[1])-data_range[0]) $
                         / float(data_range[1]-data_range[0])
         end
         1: begin
            result[ii] = byte_range[0] + (byte_range[1]-byte_range[0]) $
                         * float(data_range[0]-(data_range[1] > data[ii] < $
                                                data_range[0])) $
                         / float(data_range[0]-data_range[1])
         end
      endcase
   endif

   if n_bad gt 0 then result[jj] = missing

   return, result

end


