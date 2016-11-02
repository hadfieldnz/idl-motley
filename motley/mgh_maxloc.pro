; svn $Id$
;+
; NAME:
;   MGH_MAXLOC
;
; PURPOSE:
;   This function returns the location of the maximum of an array, as a multi-dimensional subscript.
;
; CALLING SEQUENCE:
;   Result = mgh_maxloc(array)
;
; POSITIONAL PARAMETERS:
;   array (input, numeric, scalar or array)
;     Array for which we want the location of the maximum
;
; RETURN VALUE:
;   The function returns an integer vector with the number of elements
;   equal to the number of dimensions in the array.
;
; KEYWORD PARAMETERS:
;   ABSOLUTE (input, switch)
;     Set this keyword to cause the routine to use the absolute value
;     of each element in determining the maximum value.This keyword has
;     no effect for arrays of type byte or
;     unsigned integer.
;
;   NAN (input, switch)
;     Set this keyword to cause the routine to check for occurrences
;     of the IEEE floating-point value NaN in the input data.
;     Elements with the value NaN are treated as missing data.
;
; PROCEDURE:
;   Locate the maximum with the MAX function and convert to
;   multi-dimensional indices with ARRAY_INDICES.
;
; EXPLANATION:
;   The function is defined for convenience.
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
;   Mark Hadfield, 2007-02:
;     Written.
;-

function MGH_MAXLOC, array, ABSOLUTE=absolute, MINLOC=minloc, NAN=nan

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   on_error, 2

   void = max(array, subscript_max, ABSOLUTE=absolute, NAN=nan, $
              SUBSCRIPT_MIN=subscript_min)

   if arg_present(minloc) then minloc = array_indices(array, subscript_min)

   return, array_indices(array, subscript_max)

end

