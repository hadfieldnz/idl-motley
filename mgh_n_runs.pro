; svn $Id$
;+
; NAME:
;   MGH_N_RUNS
;
; PURPOSE:
;   This function returns information about the data runs in an array.
;   Runs are defined as contiguous regions of non-zero data. The
;   function returns the number of runs; optional parameters return
;   information about the position & length of each run. The function
;   is useful for processing coastline data.
;
; CALLING SEQUENCE:
;   result = MGH_N_RUNS(array[, start, length])
;
; POSITIONAL PARAMETERS:
;   array (input, numeric array)
;     Input data, treated as 1-D.
;
;   start (output, integer vector)
;     The index at which each run starts. This parameter is given a
;     value only if the return value is greater than 0. Its number of
;     elements is equal to  return value. 
;
;   length (output, integer vector)
;     The number of contiguous values in each run. This parameter is
;     given a value only if the return value is greater than 0. Its
;     number of elements is equal to return value.
;
; RETURN VALUE:
;   The function returns the number of runs.
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
;   Mark Hadfield, 1995-12:
;     Written as N_RUNS.
;   Mark Hadfield, 2001-02:
;     Renamed MGH_N_RUNS and modified for IDL2 syntax.
;   Mark Hadfield, 2001-10:
;     WARNING: this change is not backward compatible! The input array
;     is now tested for non-zero values rather than for finite values
;     as previously. Code which called mgh_n_runs(x) for a real array
;     x should now call mgh_n_runs(finite(x)); code which called the
;     companion function mgh_n_holes(x) should now call
;     mgh_n_runs(~ finite(x))
;   Mark Hadfield, 2004-12:
;     Updated.
;-
function MGH_N_RUNS, array, start, length

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n_arr = n_elements(array)

   bad = where(array eq 0, n_bad)

   if n_bad eq 0 then begin
      start = [0]
      length = [n_arr]
      return, 1
   endif

   ;; Add fictitious "bad" values at beginning & end of array
   
   bad = [-1,bad,n_arr]
   n_bad = n_bad + 2

;  delta = bad[1:n_bad-1] - bad[0:n_bad-2]
   delta = mgh_diff(bad)

   run = where(delta gt 1, n_run)

   if n_run eq 0 then return, 0

   start = bad[run] + 1

   length = delta[run] - 1

   return, n_run

end
