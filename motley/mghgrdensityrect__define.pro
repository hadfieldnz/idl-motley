; svn $Id$
;+
; CLASS NAME:
;   MGHgrDensityRect
;
; PURPOSE:
;   This class implements a "density plane", ie a representation of 2-D
;   numeric data on a flat surface using colour or grey-scale
;   density. A rectangular array of cells (quadrilaterals) is set out
;   and the data values are represented by the colour at the centre of
;   the cells (STYLE=0) or at the vertices (STYLE=1).
;
;   This density plot implementation (MDR) uses a rectangular
;   IDLgrPolygon with a texture-mapped image. The image has fixed
;   dimensions and data are regridded onto it. Compared with
;   MGHgrDensityPlane (MDP--an implementation based on an IDLgrSurface
;   or an IDLgrPolygon), an MDR is rendered faster (especially on
;   large datasets) but takes longer to initialise or to recalculate
;   for new data. The other major difference is that missing-data
;   cells in an MDR have byte value 0 whereas in an MDP they are
;   omitted from the object. The missing-cell behaviour of an MDR
;   could be changed using a true-colour, transparent image.
;
;   An MGHgrDensityRect (MDR) is very similar to an MGHgrDensityRect2
;   (MDR2), the difference being that in the MDR2 the image is not
;   texture-mapped on a polygon. The MDR2 is faster than the MDR but
;   doesn't fit well in a 3D environment.
;
; TO DO:
;   Make initialisation more robust: allow DATAX, DATAY and/or DATA_VALUES
;   to be initially undefined.
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
;   Mark Hadfield, 1998-09:
;     Written, based on earlier density plot implementations.
;   Mark Hadfield, 2002-07:
;     Now allows a curvilinear horizontal grid via 2-dimensional
;     DATAX and DATAY arrays.
;-

; MGHgrDensityRect::Init

function MGHgrDensityRect::Init, values, $
     BASE_COLOR=base_color, BYTE_RANGE=byte_range, COLORSCALE=colorscale, $
     DATA_RANGE=data_range, DATA_VALUES=data_values, $
     DATAX=datax, DATAY=datay, N_PIXELS=n_pixels, PALETTE=palette, $
     STORE_DATA=store_data, STYLE=style, ZVALUE=zvalue, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   ;; Initialise polygon

   ok = self->IDLgrPolygon::Init(DATA=[[0,0,0],[1,0,0],[1,1,0],[0,1,0]] , $
                                 TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]], $
                                 TEXTURE_MAP=obj_new('IDLgrImage'), $
                                 _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrPolygon'

   ;; Set keyword defaults

   if n_elements(base_color) eq 0 then base_color = [255,255,255]

   if n_elements(store_data) eq 0 then store_data = 1B

   if n_elements(zvalue) ne 1 then zvalue = 0

   if n_elements(data_values) eq 0 then $
        if n_elements(values) gt 0 then data_values = values

   if n_elements(colorscale) eq 1 then begin
      if obj_valid(colorscale) then begin
         colorscale->GetProperty, $
              BYTE_RANGE=c_byte_range, DATA_RANGE=c_data_range, PALETTE=c_palette
         if n_elements(byte_range) eq 0 then byte_range = c_byte_range
         if n_elements(data_range) eq 0 then data_range = c_data_range
         if n_elements(palette) eq 0 then palette = c_palette
      endif
   endif

   ;; Set a couple of tags in the class structure directly to avoid unnecessary
   ;; recalculations in the SetProperty call below

   self.dstyle = n_elements(style) gt 0 ? style : 0

   self.n_pixels = n_elements(n_pixels) gt 0 ? n_pixels : 512

   ;; Pass remaining keywords to SetProperty. It is responsible for setting
   ;; up the polygon and texture-map image

   self->SetProperty, $
        BASE_COLOR=base_color, BYTE_RANGE=byte_range, $
        DATA_RANGE=data_range, DATA_VALUES=data_values, DATAX=datax, DATAY=datay, $
        PALETTE=palette, STORE_DATA=store_data, ZVALUE=zvalue

   return, 1

end

; MGHgrDensityRect::Cleanup
;
pro MGHgrDensityRect::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR

   ptr_free, [self.data_values, self.datax, self.datay]

   self->IDLgrPolygon::GetProperty, TEXTURE_MAP=otmap
   obj_destroy, otmap

   self->IDLgrPolygon::Cleanup

end

; MGHgrDensityRect::GetProperty
;
pro MGHgrDensityRect::GetProperty, $
     ALL=all, BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
     DATA_VALUES=data_values, DATAX=datax, DATAY=datay, $
     N_PIXELS=n_pixels, PALETTE=palette, STORE_DATA=store_data, $
     STYLE=style, ZVALUE=zvalue, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->IDLgrPolygon::GetProperty, ALL=all, TEXTURE_MAP=otmap, _STRICT_EXTRA=extra
   otmap->GetProperty, PALETTE=palette

   byte_range = self.byte_range

   data_range = self.data_range

   n_pixels = self.n_pixels

   store_data = self.store_data

   style = self.dstyle

   zvalue = self.zvalue

   if arg_present(all) then $
        all = create_struct(all, 'byte_range', byte_range, 'data_range', data_range, $
                            'n_pixels', n_pixels, 'store_data', store_data, $
                            'style', style, 'zvalue', zvalue)

   ;; Remaining properties are calulcated only when necessary and not
   ;; returned in the ALL structure

   if arg_present(data_values) then begin
      case ptr_valid(self.data_values) of
         0: data_values = -1
         1: data_values = *self.data_values
      endcase
   endif

   if arg_present(datax) then begin
      case ptr_valid(self.datax) of
         0: datax = -1
         1: datax = *self.datax
      endcase
   endif

   if arg_present(datay) then begin
      case ptr_valid(self.datay) of
         0: datay = -1
         1: datay = *self.datay
      endcase
   endif

end

; MGHgrDensityRect::SetProperty
;
pro MGHgrDensityRect::SetProperty, $
     BASE_COLOR=base_color, BYTE_RANGE=byte_range, $
     DATA_RANGE=data_range, DATA_VALUES=data_values, $
     DATAX=datax, DATAY=datay, N_PIXELS=n_pixels, PALETTE=palette, $
     STORE_DATA=store_data, STYLE=style, ZVALUE=zvalue, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->IDLgrPolygon::SetProperty, COLOR=base_color, _STRICT_EXTRA=extra

   self->IDLgrPolygon::GetProperty, TEXTURE_MAP=otmap
   otmap->SetProperty, PALETTE=palette

   if n_elements(store_data) gt 0 then $
        self.store_data = store_data

   if n_elements(zvalue) gt 0 then begin
      self->IDLgrPolygon::GetProperty, DATA=data
      data[2,*] = zvalue
      self->IDLgrPolygon::SetProperty, DATA=data
   endif

   ;; If STYLE property has changed, recalculate geometry to keep data points
   ;; in same position

   self->Restyle, style

   ;; Setting remaining properties causes the object's dimensions and
   ;; colours to be recalculated

   recalc = 0B

   if n_elements(byte_range) gt 0 then begin
      self.byte_range = byte_range
      recalc = 1B
   endif

   if n_elements(data_range) gt 0 then begin
      self.data_range = data_range
      recalc = 1B
   endif

   if n_elements(data_values) gt 0 then begin
      ptr_free, self.data_values
      if self.store_data then self.data_values = ptr_new(data_values)
      recalc = 1B
   endif

   if n_elements(datax) gt 0 then begin
      ptr_free, self.datax
      if self.store_data then self.datax = ptr_new(datax)
      recalc = 1B
   endif

   if n_elements(datay) gt 0 then begin
      ptr_free, self.datay
      if self.store_data then self.datay = ptr_new(datay)
      recalc = 1B
   endif

   if n_elements(n_pixels) gt 0 then begin
      self.n_pixels = n_pixels
      recalc = 1B
   endif

   ;; If flag has been set, recalculate object colours and
   ;; dimensions. Properties DATA_VALUES, DATAX & DATAY may not have
   ;; been stored with the object, so pass them via keywords.

   if recalc then $
        self->Calculate, DATA_VALUES=data_values, DATAX=datax, DATAY=datay

end

pro MGHgrDensityRect::Calculate, $
     DATA_VALUES=data_values, DATAX=datax, DATAY=datay

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(data_values) eq 0 then begin
      if ptr_valid(self.data_values) then begin
         data_values = *self.data_values
      endif
   endif

   if n_elements(datax) eq 0 then begin
      if ptr_valid(self.datax) then begin
         datax = *self.datax
      endif
   endif

   if n_elements(datay) eq 0 then begin
      if ptr_valid(self.datay) then begin
         datax = *self.datay
      endif
   endif

   if size(data_values, /N_DIMENSIONS) ne 2 then $
        message, 'DATA_VALUES must be 2D'

   ;; Dimensions of data values

   dim = size(data_values, /DIMENSIONS)

   ;; Dimensions of vertices array

   dimv = dim + (self.dstyle eq 0)

   if n_elements(datax) eq 0 then datax = findgen(dimv[0]) - 0.5*self.dstyle
   if n_elements(datay) eq 0 then datay = findgen(dimv[1]) - 0.5*self.dstyle

   ;; Allow 1D or 2D DATAX, DATAY arrays. Check dimensions.

   xy2d = size(datax, /N_DIMENSIONS) eq 2

   case xy2d of

      0: begin
         if n_elements(datax) ne dimv[0] then $
              message, 'DATAX array size must match DATA_VALUES array size'
         if n_elements(datay) ne dimv[1] then $
              message, 'DATAY array size must match DATA_VALUES array size'
      end

      1: begin
         dimx = size(datax, /DIMENSIONS)
         if dimx[0] ne dimv[0] or dimx[1] ne dimv[1] then $
              message, 'DATAX array size must match DATA_VALUES array size'
         dimy = size(datay, /DIMENSIONS)
         if dimy[0] ne dimv[0] or dimy[1] ne dimv[1] then $
              message, 'DATAY array size must match DATA_VALUES array size'

      end

   endcase

   ;; Set edges of polygon to min & max of DATAX & DATAY.

   xrange = mgh_minmax(datax)
   yrange = mgh_minmax(datay)

   self->IDLgrPolygon::GetProperty, DATA=pdata
   pdata[0,*] = xrange[[0,1,1,0]]
   pdata[1,*] = yrange[[0,0,1,1]]
   self->IDLgrPolygon::SetProperty, DATA=pdata

   ;; Calculate position of each pixel in the "index space" of the
   ;; input grid. Arrays xpix and ypix are pixel-centre locations.

   xpix = mgh_stagger(mgh_range(xrange[0],xrange[1],N_ELEMENTS=self.n_pixels+1), DELTA=-1)
   ypix = mgh_stagger(mgh_range(yrange[0],yrange[1],N_ELEMENTS=self.n_pixels+1), DELTA=-1)

   case xy2d of

      0: begin
         ;; Two arrays dimensioned [n_pixels]. Don't need to worry about
         ;; missing values in this case.
         ii = mgh_locate(datax, XOUT=xpix)
         jj = mgh_locate(datay, XOUT=ypix)
      end

      1: begin
         ;; Two arrays dimensioned [n_pixels,n_pixels]
         loc = mgh_locate2(datax, datay, /GRID, XOUT=xpix, YOUT=ypix, MISSING=-1)
         ii = reform(loc[0,*,*])
         jj = reform(loc[1,*,*])
         mgh_undefine, loc
      end

   endcase

   ;; To get nearest-neighbour interpolation with STYLE = 0, just
   ;; round ii and jj

   if self.dstyle eq 0 then begin

      ii = round(ii-0.5)
      jj = round(jj-0.5)

   endif

   ;; Calculate byte range & data_range to be used in colour scaling

   case 1B of
      self.byte_range[1] ne self.byte_range[0]: begin
         byte_range = self.byte_range
      end
      obj_valid(palette): begin
         palette->GetProperty, N_COLORS=n_colors
         byte_range = [0,n_colors-1]
      end
      else: begin
         byte_range = [0,255]
      end
   endcase

   data_range = self.data_range
   if data_range[0] eq data_range[1] then $
        data_range = mgh_minmax(data_values, /NAN)
   if data_range[0] eq data_range[1] then $
        data_range = data_range + [-0.5,0.5]

   ;; Interpolate DATA_VALUES to pixel positions, byte-scale and load into the texture-map image

   image = mgh_bytscl(mgh_interpolate(data_values, ii, jj, GRID=(xy2d eq 0), $
                                      MISSING=!values.f_nan), $
                      BYTE_RANGE=byte_range, DATA_RANGE=data_range)

   self->IDLgrPolygon::GetProperty, TEXTURE_MAP=otmap
   otmap->SetProperty, DATA=image

end

; MGHgrDensityRect::Restyle
;
pro MGHgrDensityRect::Restyle, style

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(style) eq 0 then return

   if style ne self.dstyle then begin

      self->GetProperty, DATAX=datax, DATAY=datay

      delta = fix(self.dstyle)-fix(style)

      self.dstyle = style

      case size(datax, /N_DIMENSIONS) ge 1 of
         0: mgh_undefine, datax
         1: datax = mgh_stagger(datax, DELTA=delta)
      endcase

      case size(datay, /N_DIMENSIONS) ge 1 of
         0: mgh_undefine, datay
         1: datay = mgh_stagger(datay, DELTA=delta)
      endcase

       self->SetProperty, DATAX=datax, DATAY=datay

   endif

end

; MGHgrDensityRect__Define

pro MGHgrDensityRect__Define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGHgrDensityRect, inherits IDLgrPolygon, $
                 data_range: fltarr(2), byte_range: bytarr(2), zvalue: 0., $
                 data_values: ptr_new(), datax: ptr_new(), datay: ptr_new(), $
                 store_data: 0B, dstyle: 0B, n_pixels: 0S}

end

