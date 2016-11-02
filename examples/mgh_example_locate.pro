;+
; NAME:
;   MGH_EXAMPLE_LOCATE
;
; PURPOSE:
;   Examples of using the MGH_LOCATE family of functions with INTERPOLATE
;   to interpolate between rectilinear and curvilinear grids.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2003-09:
;     Written.
;-
pro mgh_example_locate, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   case option of

      0: begin

         ;; Interpolate from rectilinear grid to curvilinear grid

         ;; Specify input rectilinear grid and data. Input grid is
         ;; uniform on the interval -1 <= x <= 1, -1 <= y <= 1.

         idim = [101,101]

         xin = mgh_range(-1, 1, N_ELEMENTS=idim[0])
         yin = mgh_range(-1, 1, N_ELEMENTS=idim[1])

         zin = mgh_dist(idim[0], idim[1])

         ;; Plot input data

         mgh_new, 'mgh_density', zin, xin, yin, $
                  DATA_RANGE=[0,max(zin)], $
                  XAXIS_PROPERTIES={range:[-1,1]}, $
                  YAXIS_PROPERTIES={range:[-1,1]}

         ;; Specify output curvilinear grid, circle with radius 1.

         odim = [151,51]

         ang = mgh_range(0, 2*!pi, N_ELEMENTS=odim[0])
         rad = mgh_range(0, 1, N_ELEMENTS=odim[1])

         ang2d = mgh_inflate(odim, temporary(ang), 1)
         rad2d = mgh_inflate(odim, temporary(rad), 2)

         xout = rad2d * cos(ang2d)
         yout = rad2d * sin(ang2d)

         ;; Locate output grid in index space of input grid

         ii = mgh_locate(xin, XOUT=xout)
         jj = mgh_locate(yin, XOUT=yout)

         ;; Interpolate data to output grid

         zout = interpolate(zin, ii, jj)

         ;; Plot

         mgh_new, 'mgh_density', zout, xout, yout, $
                  DATA_RANGE=[0,max(zin)], $
                  XAXIS_PROPERTIES={range:[-1,1]}, $
                  YAXIS_PROPERTIES={range:[-1,1]}

      end

      1: begin

         ;; Interpolate from curvilinear grid to curvilinear grid

         ;; Specify input grid and data. Input grid starts off as
         ;; rectilinear but is then given some pincushion distortion

         idim = [101,101]

         x = mgh_range(-1, 1, N_ELEMENTS=idim[0])
         y = mgh_range(-1, 1, N_ELEMENTS=idim[1])

         xin = mgh_inflate(idim, temporary(x), 1)
         yin = mgh_inflate(idim, temporary(y), 2)

         fact = sqrt(0.5*(xin^2+yin^2))

         xin *= fact
         yin *= fact

         zin = mgh_dist(idim[0], idim[1])

         ;; Plot input data

         mgh_new, 'mgh_density', zin, xin, yin, $
                  DATA_RANGE=[0,max(zin)], $
                  XAXIS_PROPERTIES={range:[-1,1]}, $
                  YAXIS_PROPERTIES={range:[-1,1]}

         ;; Specify output curvilinear grid, circle with radius 1.

         odim = [151,51]

         ang = mgh_range(0, 2*!pi, N_ELEMENTS=odim[0])
         rad = mgh_range(0, 1, N_ELEMENTS=odim[1])

         ang2d = mgh_inflate(odim, ang, 1)
         rad2d = mgh_inflate(odim, rad, 2)

         xout = rad2d * cos(ang2d)
         yout = rad2d * sin(ang2d)

         ;; Locate output grid in index space of input grid. Output
         ;; is dimensioned [2,odim]

         loc = mgh_locate2(xin, yin, XOUT=xout, YOUT=yout)

         ii = reform(loc[0,*,*])
         jj = reform(loc[1,*,*])

         mgh_undefine, loc

         ;; Interpolate data to output grid

         zout = interpolate(zin, ii, jj)

         ;; Plot

         mgh_new, 'mgh_density', zout, xout, yout, $
                  DATA_RANGE=[0,max(zin)], $
                  XAXIS_PROPERTIES={range:[-1,1]}, $
                  YAXIS_PROPERTIES={range:[-1,1]}

      end

      2: begin

         ;; Interpolate from curvilinear grid to rectilinear grid

         ;; Same input grid as option 1

         idim = [101,101]

         x = mgh_range(-1, 1, N_ELEMENTS=idim[0])
         y = mgh_range(-1, 1, N_ELEMENTS=idim[1])

         xin = mgh_inflate(idim, temporary(x), 1)
         yin = mgh_inflate(idim, temporary(y), 2)

         fact = sqrt(0.5*(xin^2+yin^2))

         xin *= fact
         yin *= fact

         zin = mgh_dist(idim[0], idim[1])

         ;; Plot input data

         mgh_new, 'mgh_density', zin, xin, yin, $
                  DATA_RANGE=[0,max(zin)], $
                  XAXIS_PROPERTIES={range:[-1,1]}, $
                  YAXIS_PROPERTIES={range:[-1,1]}

         ;; Specify output rectilinear grid

         odim = [101,101]

         xout = mgh_range(-1, 1, N_ELEMENTS=odim[0])
         yout = mgh_range(-1, 1, N_ELEMENTS=odim[1])

         ;; Locate output grid in index space of input grid. The GRID
         ;; keyword to MGH_LOCATE2 specifies that the output grid
         ;; is rectilinear and specified by 1-D arrrays.

         loc = mgh_locate2(xin, yin, XOUT=xout, YOUT=yout, /GRID)

         ii = reform(loc[0,*,*])
         jj = reform(loc[1,*,*])

         mgh_undefine, loc

         ;; Interpolate data to output grid

         zout = interpolate(zin, ii, jj)

         ;; Plot

         mgh_new, 'mgh_density', zout, xout, yout, $
                  DATA_RANGE=[0,max(zin)], $
                  XAXIS_PROPERTIES={range:[-1,1]}, $
                  YAXIS_PROPERTIES={range:[-1,1]}

      end

   endcase



end

