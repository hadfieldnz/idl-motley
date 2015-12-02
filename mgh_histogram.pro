;+
; NAME:
;   MGH_HISTOGRAM
;
; PURPOSE:
;   Given a set of values, this function returns a structure
;   containing the histogram plus supporting information.
;
;   Note that the HISTOGRAM function has been improved(?) since
;   I wrote MGH_HISTOGRAM and the latter may not take full advantage
;   of the new functionality.
;
; CALLING SEQUENCE:
;   Result = MGH_HISTOGRAM(arr)
;
; ARGUMENTS:
;   arr (input)
;     The array to calculate the histogram of.
;
; KEYWORDS:
;   CUMULATIVE (input, switch)
;     If set, return cumulative frequency distribution.
;
;   BINSIZE (input, numeric scalar)
;     The size of each bin of the histogram, scalar.  Default is 1.
;
;   PAD (input, switch)
;     Set this keyword to add an empty bins to each end of the
;     histogram.
;
;   X0 (input, numeric scalar)
;     HISTOGRAM normally puts bin boundaries at multiples of
;     BINSIZE. This can create problems when the data are discrete,
;     and lie on the boundaries. Parameter X0 defines a false origin
;     used by HISTOGRAM so that bin boundaries are at X0 + (n * BINSIZE).
;
;   YTIMES (input, numeric scalar)
;     Multiplier for Y vector. Setting YTIMES = 1 gives the output of
;     HISTOGRAM unscaled. If YTIMES is undefined, then it defaults to
;     1. However if YTIMES is equal to 0 then the output from
;     HISTOGRAM is scaled so that the area under the curve is 1 for a
;     partial frequency distribution or so that the velue at the
;     largest bin is 1, for cumulative frequency distribution
;     (assuming no missing data). The same scaling can be achieved by
;     setting:
;
;       YTIMES = 1./( n_elements(Arr)*bin )     partial
;       YTIMES = 1./n_elements(Arr)             cumulative
;
;     Note that the modified value will be returned on output.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-02:
;       Written.
;   Mark Hadfield, 2015-12:
;       Minor updates.
;-
function mgh_histogram, arr, $
     BINSIZE=binsize, X0=x0, YTIMES=ytimes, $
     CUMULATIVE=cumulative, NAN=nan, PAD=pad

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(arr) eq 0 then message, 'No data'

   ;; Set defaults for keywords. For consistency with other routines,
   ;; default behaviour is to try to treat NaN and Infinity as real
   ;; values

   if n_elements(nan) eq 0 then nan = 0
   if n_elements(x0) eq 0 then x0 = 0.
   if n_elements(cumulative) eq 0 then cumulative = 0
   if n_elements(ytimes) eq 0 then ytimes = 1.

   binsize = n_elements(binsize) eq 0 ? 1. : double(abs(binsize))

   if keyword_set(nan) then begin
      !null = where(finite(arr), count)
   endif else begin
      count = n_elements(arr)
   endelse

   if count lt 2 then $
      message, 'Input array must contain at least 2 non-missing elements'
   if min(arr, NAN=nan) eq max(arr, NAN=nan) then $
      message, 'Input array must contain distinct values'

   if ytimes eq 0 then begin
      ytimes = keyword_set(cumulative) ? 1./count : 1./( count*binsize )
   endif

   ;; Compute the histogram and abcissa.
   if keyword_set(nan) then begin
      y = floor((Arr[where(finite(Arr))]-x0) / binsize)
   endif else begin
      y = floor((Arr-x0) / binsize)
   endelse

   yhist = histogram(y, NAN=nan )
   nhist = n_elements(yhist)

   ;; Calculate (cumulative) frequency distribution.
   if keyword_set(cumulative) then begin
      xhist = lindgen(nhist+1)*binsize + min(y*binsize) + x0
      ytemp = fltarr(nhist+1)
      for i=1,nhist do ytemp[i] = ytemp[i-1]+yhist[i-1]
      yhist = ytemp
   endif else begin
      xhist = lindgen(nhist)*binsize + min(y*binsize) + binsize/2. + x0
   endelse

   ;; Scale results
   yhist = yhist * ytimes

   ;; If NAN keyword is set, suppress math error messages.
   if keyword_set(nan) then OK = check_math()

   if keyword_set(pad) then begin
      n_his = n_elements(xhist)
      xhist = [2*xhist[0]-xhist[1],xhist,2*xhist[n_his-1]-xhist[n_his-2]]
      if keyword_set(cumulative) then begin
         yhist = [0,yhist,ytimes]
      endif else begin
         yhist = [0,yhist,0]
      endelse
   endif

   return, {yhist: yhist, xhist: xhist, cumulative: cumulative, ytimes: ytimes, binsize: binsize, x0: x0}

end
