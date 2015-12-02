;+
; NAME:
;   MGH_PERCENTILE
;
; PURPOSE:
;   This function returns one or more percentiles of a data array,
;   optionally ignoring missing data.
;
; CALLING SEQUENCE:
;   result = mgh_percentile(data, percentile)
;
; POSITIONAL PARAMETERS:
;   data (input, numeric array)
;     Input array.
;
; KEYWORD PARAMETERS:
;   METHOD (input, scalar integer)
;      Select method. Valid values are:
;        0 - Counting in sorted data, from Martin Schulz's PERCENTILES function.
;        1 - Interpolation of cumulative histogram.
;        2 - Interpolation in sorted data.
;      The default is currently method 2.
;
;   NAN (input, switch)
;      Set this keyword to specify that NaN values should be treated
;      as missing.
;
;   THRESHOLD (input, numeric scalar or vector)
;     One or more thresholds. The default is 50.
;
; RETURN VALUE:
;   The function returns an array or scalar containing the averages.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2009-01:
;     Written.
;   Mark Hadfield, 2015-11:
;     A significant, backwards-incompatible change: the positional argument "percentile"
;     has been replaced by the keyword argument "threshold". this allows the function
;     to be called via the CMAPPLY function.
;-
function mgh_percentile, data, METHOD=method, NAN=nan, THRESHOLD=threshold

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(data) eq 0 then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_UNDEFVAR', 'data'

   if n_elements(data) lt 2 then $
        message, 'Too few elements in data'

   if n_elements(threshold) eq 0 then threshold = 50

   if min(threshold) lt 0 || max(threshold) gt 100 then $
        message, 'threshold values must be in the range [0,100]'

   if n_elements(method) eq 0 then method = 2

   fractile = 1.D-2*threshold

   case method of

      0: begin

         if keyword_set(nan) then message, 'METHOD 0 does not currently support the NAN keyword'

         n_data = n_elements(data)

         ix = sort(data)

         result = mgh_reproduce(0.D, fractile)

         for i=0,n_elements(fractile)-1 do begin

            ;; Looks dodgy to me!
            ind = fractile[i] le 0.5 $
                  ? long(fractile[i]*n_data) $
                  : long(fractile[i]*(n_data+1))

            result[i] = data[ix[ind < (n_data-1)]]

         endfor

         return, result

      end

      1: begin

         data_range = mgh_minmax(data, NAN=nan)

         if keyword_set(nan) && min(finite(data_range)) eq 0 then return, !values.d_nan

         chis = mgh_histogram(data, BINSIZE=(data_range[1]-data_range[0])*1.D-5, $
                              /CUMULATIVE, YTIMES=0, NAN=nan)

         return, interpol(chis.xhist, chis.yhist, 1.D-2*threshold)

      end

      2: begin

         mydata = data

         if keyword_set(nan) then begin
            l_good = where(finite(mydata), n_good)
            if n_good lt 2 then return, !values.d_nan
            mydata = mydata[l_good]
         endif

         mydata = mydata[sort(mydata)]

         return, interpol(mydata, dindgen(n_elements(mydata)), fractile*double(n_elements(mydata)-1))

      end

   endcase

   return, result

end
