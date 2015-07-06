 ;+
; NAME:
;   MGH_EXAMPLE_ROI
;
; PURPOSE:
;   What *is* an ROI anyway? And how do I make it line up with an
;   image?
;
;   In my experience IDL, is disturbingly vague about registration
;   between images and vector elements. The developers obviously
;   assume that you will always deal with images having large numbers
;   of elements, where a mismatch of a pixel here or there doesn't
;   matter much. But I often to deal with small data sets, and I find
;   it makes a difference whether the position of pixel is taken to be
;   its centre or one of its corners.
;
;   In this example a simple ROI is set up and used to compute a mask.
;
;###########################################################################
; Copyright (c) 2013-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2013-06:
;     Changed calls to MGH_POLYCLIP to accommodated changes in that function.
;   Mark Hadfield, 2015-02:
;     Updated source code.
;-
pro mgh_example_roi, $
     CLIP=clip, N_GRID=n_grid, N_ROI=n_roi, OPTION=option, $
     REVERSE=reverse, SHIFT=shift

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(clip) eq 0 then clip = 1

  if n_elements(n_grid) eq 0 then n_grid = 10

  if n_elements(n_roi) eq 0 then n_roi = 32

  if n_elements(option) eq 0 then option = 0

  if n_elements(shift) eq 0 then shift = 0
  if n_elements(shift) eq 1 then shift = [shift,shift]

  ograph = obj_new('MGHgrGraph2D')

  ograph->SetProperty, NAME='ROI example'

  ograph->GetProperty, DELTAZ=deltaz

  ograph->NewAxis, 0, RANGE=[-0.5,n_grid+0.5], /EXACT
  ograph->NewAxis, 1, RANGE=[-0.5,n_grid+0.5], /EXACT

  case option of

    0: begin
      xx = [1.5,n_grid-1.5]
      yy = [1.5,n_grid-1.5]
      xroi = keyword_set(reverse) ? xx[[0,1,0,1]] : yy[[0,1,1,0]]
      yroi = yy[[0,0,1,1]]
    end

    1: begin

      ang = 2.*!pi*findgen(n_roi)/n_roi

      xroi = n_grid * (0.5+0.3*cos(ang))
      yroi = n_grid * (0.5+0.3*sin(ang))

    end

    2: begin

      ang = 2.*!pi*findgen(n_roi)/n_roi
      rad = replicate(0.4,n_roi)
      rad[2*lindgen(n_roi/2)] = 0.2

      xroi = n_grid * (0.5+rad*cos(ang))
      yroi = n_grid * (0.5+rad*sin(ang))

    end

  endcase

  xroi += shift[0]
  yroi += shift[1]

  if keyword_set(clip) then begin
    pol = [transpose(xroi),transpose(yroi)]
    pol = mgh_polyclip(pol, 0, 0, 0, COUNT=n_vert)
    if n_vert eq 0 then $
      message, 'No ROI vertices left after clipping'
    pol = mgh_polyclip(pol, n_grid, 0, 1, COUNT=n_vert)
    if n_vert eq 0 then $
      message, 'No ROI vertices left after clipping'
    pol = mgh_polyclip(pol, 0, 1, 0, COUNT=n_vert)
    if n_vert eq 0 then $
      message, 'No ROI vertices left after clipping'
    pol = mgh_polyclip(pol, n_grid, 1, 1, COUNT=n_vert)
    if n_vert eq 0 then $
      message, 'No ROI vertices left after clipping'
    xroi = reform(pol[0,*])
    yroi = reform(pol[1,*])
  endif

  ograph->NewAtom, 'IDLgrROI', xroi, yroi, $
    STYLE=2, COLOR=mgh_color('yellow'), NAME='My ROI', RESULT=myroi

  ok = myroi->ComputeGeometry(AREA=area, CENTROID=centroid, PERIMETER=perimeter)

  if ok then begin
    print, 'Area:', area
    print, 'Centroid:', centroid
    print, 'Perimeter:', perimeter
  endif else begin
    message, 'ComputeGeometry failed'
  endelse

  ;; Calculate the mask for an array of pixels dimensioned
  ;; [n_grid,n_grid] with origin (centre of pixel [0,0]) at
  ;; [0.5,0.5]. This geometry is needed to get the ROI boundaries and
  ;; the pixels to line up.  We are effectively assuming here that
  ;; the pixel boundaries are at (x or y) = [0.5,1.5,...,n_grid-0.5]
  ;; & the pixel edges are at (x or y) = [0,1,...n_grid]

  mask1 = myroi->ComputeMask(MASK_RULE=1, LOCATION=[0.5,0.5], $
    DIMENSIONS=[n_grid,n_grid])
  mask2 = myroi->ComputeMask(MASK_RULE=2, LOCATION=[0.5,0.5], $
    DIMENSIONS=[n_grid,n_grid])

  ;; Combine the masks so that the variable "mask" has value 255 when
  ;; the pixel is fully inside the ROI, 0 when it is fully outside
  ;; and 127 when it is on the boundary.

  mask = (mask1/2+mask2/2)

  ;; Display the mask using an IDLgrImage object. Note that the image
  ;; is added to its model in position 0 so that all other atoms are
  ;; drawn over it.

  ograph->NewAtom, 'IDLgrImage', (mask1/2+mask2/2), $
    LOCATION=[0,0], DIMENSIONS=[n_grid,n_grid], NAME='Mask', POSITION=0

  ;; Show pixel corners

  ograph->NewSymbol, /FILL, COLOR=mgh_color('blue'), RESULT=osym

  n_vert = n_grid+1

  xvert = findgen(n_vert)
  yvert = findgen(n_vert)

  ograph->NewAtom, 'IDLgrPolyline', $
    rebin(xvert,n_vert,n_vert), rebin(reform(yvert,1,n_vert),n_vert,n_vert), $
    LINESTYLE=6, SYMBOL=osym, NAME='Pixel corners'

  mgh_new, 'MGH_Window', ograph

end


