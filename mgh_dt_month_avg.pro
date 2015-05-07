;+
; NAME:
;   MGH_DT_MONTH_AVG
;
; PURPOSE:
;   Given a time series, calculate monthly averages.
;
; CALLING SEQUENCE:
;   mgh_dt_month_avg, time, value, time_month, value_month
;
; POSITIONAL PARAMETERS:
;   time (input, numeric vector)
;     Time for the input series in Julian Days.
;
;   value (input, numeric vector)
;     Value for the input series. Must have the same number of elements
;     as time.
;
;   time_month (output, numeric vector)
;     Time for the output series in Julian Days, representing consecutive mid-month times.
;
;   value_month (output, numeric vector)
;     Values for the output series, representing 1-month average values.
;
;###########################################################################
; Copyright (c) 2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2015-02:
;     Written.
;-
pro mgh_dt_month_avg, time, value, time_month, value_month, $
  N_MIN=n_min, TIME_RANGE=time_range

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(time) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'time'

  if n_elements(value) eq 0 then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'value'
    
  n_time = n_elements(time)
  
  if n_elements(value) ne n_time then $
    message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'value'
    
  if n_elements(n_min) eq 0 then n_min = 1
    
  ;; Set up a vector of month beginning/end times. By default, this includes
  ;; the range of months represented in the data. The beggining/end
  ;; vector is used for determining the average values. Also set up a vector of
  ;; month mid-points, for output.

  if n_elements(time_range) eq 0 then begin
    t0 = mgh_dt_caldat(min(time))
    t1 = mgh_dt_caldat(max(time))
    time_range = [mgh_dt_julday(YEAR=t0.year, MONTH=t0.month),mgh_dt_julday(YEAR=t1.year, MONTH=t1.month+1)]
    mgh_undefine, t0, t1
  endif
  
  time_bnd = timegen(UNITS='month', START=time_range[0], FINAL=time_range[1])
  
  time_month = mgh_stagger(time_bnd, DELTA=-1)
  
  ;; Now create and fill the vector of monthly-average values. Use a naive
  ;; approach: find the times within each month using WHERE and then average.
  ;; A more elegant solution could almost certainly be devised using HISTOGRAM. 
  
  n_month = n_elements(time_month)
  value_month = replicate(!values.d_nan, n_month)
  for i_month=0,n_month-1 do begin
    l_match = where(time ge time_bnd[i_month] and time lt time_bnd[i_month+1], n_match)
    if n_match ge n_min then value_month[i_month] = mgh_avg(value[l_match]) 
  endfor
    
end

