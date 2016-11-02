; svn $Id$
;+
; NAME:
;   MGH_PACK
;
; PURPOSE:
;   This function reproduces (some of) the functionality of the
;   Fortran 90 PACK procedure, ie it packs data into a 1-D vector
;   according to the value of a mask variable. See also MGH_UNPACK.
;
; CALLING SEQUENCE:
;   result = MGH_PACK(array, mask)
;
; POSITIONAL PARAMETERS:
;   array (input, array of any dimension & type)
;     Data to be packed.
;
;   mask (input, integer array of same shape as "array")
;     An array of 1s and 0s, of the same shape as Array, defining the
;     valid values in array.
;
; RETURN VALUE:
;   The function returns a 1-D vector containing only the valid values
;   in Array
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
;   Mark Hadfield, 1996-08:
;     Written.
;   Mark Hadfield, 2002-08:
;     Updated.
;-
function MGH_PACK, array, mask, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR

   indices = where(mask, count)

   if count eq 0 then return, -1

   return, array[indices]

end
