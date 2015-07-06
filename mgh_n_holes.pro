; svn $Id$
;+
; NAME:
;   MGH_N_HOLES
;
; PURPOSE:
;   This function returns information about the holes in an array. Holes
;   are defined as contiguous regions of missing data (which are taken as
;   values for which the FINITE function returns 0). The procedure
;   returns the number of holes; optional parameters return information
;   about the position & length of each hole and the previous run.
;
;   See also MGH_N_RUNS, which returns information about runs of good data.
;
; CALLING SEQUENCE:
;   Result = MGH_N_HOLES(Array[, Start, Length, Previous])
;
; INPUTS:
;   Array:      An array of real numeric values, assumed 1-D.
;
; OUTPUTS:
;   The function returns the number of holes.
;
; OPTIONAL OUTPUTS:
;   The following output parameters are given values only if the return value
;   is greater than 0. They are 1-D arrays dimensioned by the return value.
;
;   Start:      The index at which each hole starts.
;
;   Length:     The number of contiguous missing values in each hole.
;
;   Previous:   The length of the previous run of good data. I'm not 100% sure
;               that this works.
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
;   Mark Hadfield, Dec 1995:
;       Written as N_HOLES.
;   Mark Hadfield, Apr 200:
;       Renamed MGH_N_HOLES and modified for IDL2 syntax.
;-
function MGH_N_HOLES, array, start, length, previous

    compile_opt DEFINT32
   compile_opt STRICTARR

    narr = n_elements(Array)

    good = where(finite(Array), ngood)

    if ngood eq 0 then begin
        start = [0]  &  length = [narr]  &  return, 1
    endif

    ; Add fictitious "good" values at beginning & end of array
    good = [-1,good,narr]  &  ngood = ngood + 2

    delta = good[1:ngood-1] - good[0:ngood-2]

    holes = where(delta gt 1, nh)

    if nh eq 0 then return,0

    start = good[holes] + 1

    length = delta[holes] - 1

    finish = start + length - 1

    previous = lonarr(nh)  &  previous[0] = start[0]
    if nh gt 1 then previous[1:nh-1] = start[1:nh-1] - finish[0:nh-2] - 1

    return, nh

end
