;+
; NAME:
;   MGH_EXAMPLE_DENSITY
;
; PURPOSE:
;   Density plot example.
;
;   You might also like to try the command:
;
;     mgh_new, 'mgh_density', /EXAMPLE
;
;###########################################################################
; Copyright (c) 2001-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-06:
;     Written.
;   Mark Hadfield, 2004-07:
;     - Modified for new axis behaviour.
;     - IDL 6.0 syntax.
;   Mark Hadfield, 2012-08:
;     - Added copyright and license notice.
;-
pro mgh_example_density, m, n, $
     STYLE=style, IMPLEMENTATION=implementation, VERTICAL=vertical, XY2D=xy2d

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Colour density plot

   ;; VERTICAL=1 (default) gives a vertical colour bar and VERTICAL=0
   ;; gives a horizontal colour bar.
   if n_elements(vertical) eq 0 then vertical = 1

   ;; STYLE=0 gives a block-type plot and STYLE=1 gives an
   ;; interpolated plot.
   if n_elements(style) eq 0 then style = 0

   ;; IMPLEMENTATION controls the density plot implementation used.
   if n_elements(implementation) eq 0 then implementation = 0

   ;; Create the graph & set options.

   ograph = obj_new('MGHgrGraph2D')
   
   if vertical then begin
      ograph->GetProperty, XMARGIN=xmargin
      xmargin[1] = 0.40
      ograph->SetProperty, XMARGIN=xmargin
   endif else begin
      ograph->GetProperty, YMARGIN=ymargin
      ymargin[0] = 0.40
      ograph->SetProperty, YMARGIN=ymargin
   endelse

   ograph->SetProperty, NAME='Density plot example'

   ograph->NewMask

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   ;; Specify number of points in x & y directions
   if n_elements(m) eq 0 then m = 76
   if n_elements(n) eq 0 then n = m

   if (m < n) lt 3 then begin
      message, 'Number of data points is too small: (m,n)=('+ $
               strtrim(m,2)+','+strtrim(n,2)+')'
   endif

   ;; Set up arrays defining the location of the data values
   
   if keyword_set(xy2d) then begin
     xx = mgh_range(0,2,N_ELEMENTS=m) # replicate(1,n)
     yy = replicate(1,m) # mgh_range(0,2,N_ELEMENTS=n)
   endif else begin
     xx = mgh_range(0,2,N_ELEMENTS=m)
     yy = mgh_range(0,2,N_ELEMENTS=n)
   endelse

   ;; Create a data array. The missing value should appear in the lower left quadrant.

   thedata = mgh_dist(m,n)
   thedata[m/3,n/6] = !values.f_nan

   ;; Create palette

   ograph->NewPalette, mgh_get_ct('Prism', /SYSTEM), RESULT=opal

   ;; Because the X and Y geometry of a density plot
   ;; depend on the style, we create axes with default range
   ;; and fit them to the density plot below. (There are other
   ;; ways to do this, but this way illustrates the way axes
   ;; can be modified without breaking the connection between
   ;; axes and data atoms.)

   ograph->NewAxis, 0, /EXACT, /EXTEND, TITLE='X', RESULT=xaxis
   ograph->NewAxis, 1, /EXACT, /EXTEND, TITLE='Y', RESULT=yaxis

   ;; Create the density plot
   ;; The density plot requires the location of the vertices. With STYLE=0
   ;; we need one more vertex location in each direction than the number
   ;; of data values. The MGH_STAGGER function was written to do this.

   case implementation of

      0: begin
         ;; An implementation based on the MGHgrColorSurface class (the default)
         ograph->NewAtom, 'MGHgrDensityPlane', PLANE_CLASS='MGHgrColorSurface', $
              DATA_VALUES=thedata , PALETTE=opal, DEPTH_OFFSET=1, STYLE=style, $
              DATAX=mgh_stagger(xx, DELTA=(style eq 0)), $
              DATAY=mgh_stagger(yy, DELTA=(style eq 0)), $
              NAME='Density plot', RESULT=oden
      end

      1: begin
         ;; As 0, but based on the MGHgrColorPolygon class
         ograph->NewAtom, 'MGHgrDensityPlane', PLANE_CLASS='MGHgrColorPolygon', $
              DATA_VALUES=thedata, PALETTE=opal, DEPTH_OFFSET=1, STYLE=style, $
              DATAX=mgh_stagger(xx, DELTA=(style eq 0)), $
              DATAY=mgh_stagger(yy, DELTA=(style eq 0)), $
              NAME='Density plot', RESULT=oden
      end

      2: begin
         ;; An implementation in which data are regridded on an
         ;; IDLgrImage overlaid as a texture map on a rectangular IDLgrPolygon
         ograph->NewAtom, 'MGHgrDensityRect' , $
              DATA_VALUES=thedata, PALETTE=opal, DEPTH_OFFSET=1, STYLE=style, $
              DATAX=mgh_stagger(xx, DELTA=(style eq 0)), $
              DATAY=mgh_stagger(yy, DELTA=(style eq 0)), $
              NAME='Density plot', RESULT=oden
      end

      3: begin
         ;; An implementation in which data are regridded on an
         ;; naked IDLgrImage.
         ograph->NewAtom, 'MGHgrDensityRect2' , $
              DATA_VALUES=thedata, PALETTE=opal, STYLE=style, $
              DATAX=mgh_stagger(xx, DELTA=(style eq 0)), $
              DATAY=mgh_stagger(yy, DELTA=(style eq 0)), $
              NAME='Density plot', RESULT=oden
      end

      4: begin
         ;; An implementation using an IDLgrImage. It ignores non-uniform
         ;; grid spacing.
         xrange = mgh_minmax(mgh_stagger(xx, DELTA=(style eq 0)))
         yrange = mgh_minmax(mgh_stagger(xx, DELTA=(style eq 0)))
         ograph->NewAtom, 'MGHgrDensityImage' , $
              DATA_VALUES=thedata, PALETTE=opal, STYLE=style, $
              LOCATION=[xrange[0],yrange[0]], $
              DIMENSIONS=[xrange[1],yrange[1]]-[xrange[0],yrange[0]], $
              NAME='Density plot', RESULT=oden
      end

   endcase

   ;; Fit the axes to the atom

   xaxis[0]->GetProperty, ATOM_RANGE=xrange
   xaxis[0]->SetProperty, RANGE=xrange

   yaxis[0]->GetProperty, ATOM_RANGE=yrange
   yaxis[0]->SetProperty, RANGE=yrange

   ;; Draw the colour bar. The COLORSCALE keyword directs the colour
   ;; bar to get its BYTE_RANGE, DATA_RANGE and PALETTE properties
   ;; from the density plot.

   ograph->NewColorBar, COLORSCALE=oden, NAME='Colour bar', VERTICAL=vertical

   mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph

end

