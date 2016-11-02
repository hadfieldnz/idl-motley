; svn $Id$
;+
; NAME:
;   MGH_UNPACK
;
; PURPOSE:
;   This function reproduces (some of) the functionality of the Fortran
;   90 UNPACK procedure, ie it reverses the packing of data according
;   to the value of a mask variable. See also MGH_PACK.
;
; CALLING SEQUENCE:
;   Result = MGH_UNPACK(Vector, Mask)
;
; INPUTS:
;   Vector:     A 1-D array of values to be unpacked. Number of elements
;               must be >= number of 1s in Mask.
;
;   Mask:       An array of 1s and 0s defining the locations where
;               the elements of Vector will be unpacked.
;
; KEYWORD PARAMETERS:
;   MISSING_VALUE: Set this keyword to a scalar to specify the value
;               that will be used for missing locations, i.e. those where
;               the mask value is zero.
;
; OUTPUTS:
;   The function returns an array with the same type as Vector and the same
;   shape as Mask.
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
;   Mark Hadfield, August 1996:
;       Written.
;   Mark Hadfield, May 2000:
;       Updated for IDL2 syntax and newer data types.
;-
function MGH_UNPACK, Vector, Mask, MISSING_VALUE=missing

   compile_opt DEFINT32
   compile_opt STRICTARR

    if n_elements(missing) eq 0 then begin

        t = size(vector, /TYPE)
        case t of
            1:  missing = 0B
            2:  missing = 0S
            3:  missing = 0L
            4:  missing = !values.f_nan
            5:  missing = !values.d_nan
            6:  missing = complex(!values.f_nan,!values.f_nan)
            7:  missing = ''
            9:  missing = dcomplex(!values.d_nan,!values.d_nan)
           12:  missing = 0U
           13:  missing = 0UL
           14:  missing = 0LL
           15:  missing = 0ULL
           else: message, 'Data type '+strtrim(t,2)+' not supported'
        endcase

    endif

    result = mgh_reproduce(missing, mask)

    indices = where(mask, count)

    if count gt 0 then result[indices] = vector

    return, result

end
