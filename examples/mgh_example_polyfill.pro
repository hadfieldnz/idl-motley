;+
; NAME:
;   MGH_EXAMPLE_POLYFILL
;
; PURPOSE:
; Testing various methods of polygon filling.
;
; This routine has been used to compare the behaviour of various
; filling methods when the polygon vertices move out of the positive
; quarter plane, see
;
;   http://groups.google.com/groups?hl=en&threadm=000c01c14c6e%243388ee50%24d938a8c0%40Hadfield&rnum=1&prev=/groups%3Fas_epq%3Dpolygon%2520filling%2520oddities%26as_ugroup%3Dcomp.lang.idl-pvwave
;
; Note that different filling routines do *not* give identical
; results. They use subtly different assumptions about the position of
; pixels and some of them (POLYFILLV) do suspect things with the
; polygon vertex positions. I have other test routines that explore
; these issues.
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
pro mgh_example_polyfill, option, SHIFT=shift

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(option) eq 0 then option = 0

  if n_elements(shift) eq 0 then shift = 0
  if n_elements(shift) eq 1 then shift = [shift,shift]

  ; Create a window dimensioned [500,500]

  window, XSIZE=500, YSIZE=500

  ; Set up coordinates defining a circle, radius 150, centred at 250

  n_vert = 50

  angle = 2.*!pi*findgen(n_vert+1)/float(n_vert)

  x = 250 + 150*sin(angle)
  y = 250 + 150*cos(angle)

  ; Shift the circle

  x = x + shift[0]
  y = y + shift[1]

  ; Generate & display and image using different methods depending on option argument

  case option of

    0: polyfill, x, y, /DEVICE

    1: begin
      image = replicate(0B, 500, 500)
      p = polyfillv(x, y, 500, 500)
      if min(p) ge 0 then image[p] = 255B
      tv, image
    end

    2: begin
      dname = !d.name
      set_plot, 'Z'
      device, SET_RESOLUTION=[500,500]
      erase
      polyfill, x, y, /DEVICE
      image = tvrd()
      erase
      set_plot, dname
      tv, image
    end

    3: begin
      pol = [transpose(x),transpose(y)]
      pol = mgh_polyclip(pol, 0, 0, 0, COUNT=count)
      pol = mgh_polyclip(pol, 0, 1, 0, COUNT=count)
      case count of
        0: image = bytarr(500,500)
        else: begin
          roi = obj_new('IDLanROI', pol)
          image = roi->ComputeMask(DIMENSIONS=[500,500])
          obj_destroy, roi
        end
      endcase
      tv, image
    end

    4: begin
      roi = obj_new('IDLanROI', x, y)
      xx = rebin(findgen(500),500,500)
      yy = rebin(findgen(1,500),500,500)
      inside = roi->ContainsPoints(xx[*],yy[*])
      obj_destroy, roi
      image = bytarr(500,500)
      image[where(inside)] = 255B
      tv, image
    end

    5: begin
      xx = rebin(findgen(500),500,500)
      yy = rebin(findgen(1,500),500,500)
      image = 255B*mgh_pnpoly(xx, yy, x, y)
      tv, image
    end

    6: begin
      image = 255*mgh_polyfilla(x, y, 500, 500, PACK=0)
      tv, image
    end

  endcase

end
