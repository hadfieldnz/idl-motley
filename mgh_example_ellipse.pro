;+
; NAME:
;   MGH_EXAMPLE_ELLIPSE
;
; PURPOSE:
;   This procedure presents a series of example graphs using the
;   MGHgrEllipse class
;
; CALLING SEQUENCE:
;   MGH_EXAMPLE_ELLIPSE, option
;
; POSITIONAL PARAMETERS:
;   option (input)
;     Specify a value between 0 and 2 to select the plot.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-01:
;     Written.
;-
pro mgh_example_ellipse, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   case option of

      0: begin

         ;; A time series of ellipses. This example illustrates
         ;; how the ellipse plot object chooses sensible default values
         ;; for data that are not supplied and how to scale the ellipse
         ;; plot in a situation where the velocity scaling is to be
         ;; taken from one of the axes (here the Y axis).

         ;; Generate the data

         n = 21

         t = mgh_range(0, 6, N_ELEMENTS=n)

         sma = 1+0.5*sin(2*!pi*t/3)
         ecc = sin(!pi*t/3)
         inc = !pi*t/3

         sma[n/3] = !values.f_nan
         sma[2*n/3] = !values.f_nan

         ;; Generate the base & axes

         ograph = obj_new('MGHgrGraph2D', ASPECT=0.4)

         ograph->SetProperty, NAME='Ellipse time series example'

         ograph->NewFont, SIZE=10

         ograph->NewMask

         ograph->NewTitle

         ograph->NewAxis, 0, RANGE=mgh_minmax(t)+0.5*[-1,1], /EXACT, TITLE='Time'
         ograph->NewAxis, 1, RANGE=[-2,2]*max(abs(sma)), /EXACT, TITLE='Velocity', RESULT=oyaxis

         ;; The x & y axes have different units (time and velocity,
         ;; respectively). We want the ellipses to represent velocity in
         ;; both directions, so we choose normalised scaling, with a SCALE
         ;; property that is equal in the X & Y directions and taken
         ;; from the Y axis.

         ;; Note that this relationship will be broken if the Y axis scaling
         ;; is changed. I'm thinking about ways to address this.

         oyaxis[0]->GetProperty, YCOORD_CONV=ycoord

         ograph->NewAtom, 'MGHgrEllipse', RESULT=oellipse, $
            DATAX=t, DATAY=0, DATA_SMA=sma, DATA_ECC=ecc, DATA_INC=inc, $
            SCALE=ycoord[1], /NORM_SCALE, $
            ELLIPSE_COLORS=mgh_color(['red','blue','dark green','magenta'])

         mgh_new, 'MGH_Window', ograph

      end

      1: begin

         ;; Ellipses on a 2-D grid

         ;; Generate the data

         n = 25

         x = mgh_range(0, 1, N_ELEMENTS=n)
         y = mgh_range(0, 1, N_ELEMENTS=n)

         datax = rebin(x,n,n)
         datay = rebin(reform(y,1,n),n,n)

         data_sma = datay
         data_ecc = sin(2.*!pi*datax)*cos(2.*!pi*datay)
         data_inc = datax*!pi

         ;; Generate the base & axes

         ograph = obj_new('MGHgrGraph2D')

         ograph->SetProperty, NAME='Two-D ellipse field example'

         ograph->NewFont, SIZE=10

         ograph->NewMask

         ograph->NewTitle

         ograph->NewAxis, DIRECTION=0, RANGE=mgh_minmax(x), /EXACT, /EXTEND, TITLE='X'
         ograph->NewAxis, DIRECTION=1, RANGE=mgh_minmax(y), /EXACT, /EXTEND, TITLE='Y'

         ;; Velocity scale is not related to any axis scale.

         ograph->NewAtom, 'MGHgrEllipse', SCALE=0.05, /NORM_SCALE, $
            DATAX=datax, DATAY=datay, DATA_SMA=data_sma, DATA_ECC=data_ecc, DATA_INC=data_inc, $
            COLOR=mgh_color('red')

         mgh_new, 'MGH_Window', ograph

      end

      else: message, /INFORM, "Sorry, there is no such option'

   endcase

end

