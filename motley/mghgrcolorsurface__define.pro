;+
; CLASS NAME:
;   MGHgrColorSurface
;
; PURPOSE:
;   This class implements a colour plane using an IDLgrSurface. For a
;   description of what a colour plane is, see the documentation for
;   MGHgrColorPlane.
;
; PROPERTIES:
;   The following properties are supported (amongst others):
;
;     DEFAULT_COLOR (Init,Get,Set)
;       The colour (indexed or RGB) of the surface, used if the
;       COLOR_VALUES property is not set.
;
;     COLOR_VALUES (Init,Get,Set)
;       An array of byte values dimensioned (m,n) or (3,m,n)
;       representing the colours of the cells (STYLE=0) or vertices
;       (STYLE=1).
;
;     DATAX, DATAY (Init,Get,Set)
;       1-D or 2-D arrays specifying the vertex positions.
;
;     MISSING_POINTS (Init,Get,Set)
;       A 2-D array of integer or byte values, with the same
;       dimensions as COLOR_VALUES, specifying which cell (STYLE=0) or
;       vertex (STYLE=1) values are deemed to be missing. Points are
;       omitted by setting the appropriate element of the
;       IDLgrSurface's DATAZ property to NaN.
;
;     PALETTE (Init,Get,Set)
;       A reference to the palette defining the byte<->color mapping.
;
;     STYLE (Init,Get)
;       An integer specifying whether colours are uniform over the
;       cells (STYLE=0) or interpolated from the vertices
;       (STYLE=1). Default is 0.
;
; CATEGORY:
;   Object graphics.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1998-09:
;     Written as MGHgrColorPlane2 (I think).
;   Mark Hadfield, 2000-12:
;     Renamed MGHgrColorSurface.
;   Mark Hadfield, 2004-07:
;     - Overhauled properties to support property-sheet
;       functionality. Properties now passed explicitly
;       to components--no EXTRA keywords.
;     - IDL 6.0 logical syntax.
;   Mark Hadfield, 2013-04:
;     Updated copyright/license notice.
;-

; MGHgrColorSurface::Init

function MGHgrColorSurface::Init, Colors, $
     ALPHA_CHANNEL=alpha_channel, COLOR_VALUES=color_values, $
     DEFAULT_COLOR=default_color, DEPTH_OFFSET=depth_offset, $
     DATAX=datax, DATAY=datay, DESCRIPTION=description, HIDE=hide, $
     MISSING_POINTS=missing_points, NAME=name, PALETTE=palette, $
     REGISTER_PROPERTIES=register_properties, STYLE=style, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, $
     ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(color_values) eq 0 && n_elements(colors) gt 0 then $
        color_values = colors

   ok = self->IDLgrModel::Init(DESCRIPTION=description, HIDE=hide, $
                               NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'

   self.normal_node = obj_new('IDLgrModel')
   self->Add, self.normal_node

   self.style = n_elements(style) gt 0 ? style : 0

   if n_elements(default_color) eq 0 then default_color = [255,255,255]

   osurf = obj_new('MGHgrSurface', $
                   ALPHA_CHANNEL=alpha_channel, DEPTH_OFFSET=depth_offset, $
                   SHADING=self.style, STYLE=([6,2])[self.style], $
                   COLOR=default_color, PALETTE=palette)

   self.surface = osurf

   self.normal_node->Add, osurf

   dims_changed = 0B
   self->SetDimensions, $
        DIMS_CHANGED=dims_changed, COLOR_VALUES=color_values, $
        DATAX=datax, DATAY=datay, MISSING_POINTS=missing_points

   if dims_changed then begin
      if n_elements(missing_points) gt 0 then $
           self.missing_points = ptr_new(byte(missing_points))
      self->SetGeometry, DATAX=datax, DATAY=datay, /RECALC_DATAZ
      self->SetColors, COLOR_VALUES=color_values
   endif

   self.zvalue = 0
   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   self->MGHgrColorSurface::SetProperty, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, $
        ZCOORD_CONV=zcoord_conv, ZVALUE=zvalue

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'NAME', NAME='Name', /STRING
      self->RegisterProperty, 'DESCRIPTION', NAME='Description', /STRING
      self->RegisterProperty, 'STYLE', NAME='Style', ENUMLIST=['Block','Interpolated']
      self->RegisterProperty, 'HIDE', NAME='Show', ENUMLIST=['True','False']
      self->RegisterProperty, 'ALPHA_CHANNEL', NAME='Opacity', /FLOAT, $
           VALID_RANGE=[0D0,1D0,0.05D0]
      self->RegisterProperty, 'DEFAULT_COLOR', NAME='Default color', /COLOR
      self->RegisterProperty, 'ZVALUE', NAME='Z position', /FLOAT

   endif

   return, 1

end

; MGHgrColorSurface::Cleanup
;
pro MGHgrColorSurface::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.missing_points

   self->IDLgrModel::Cleanup

end


; MGHgrColorSurface::GetProperty
;
PRO MGHgrColorSurface::GetProperty, $
     ALPHA_CHANNEL=alpha_channel, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay, $
     DEFAULT_COLOR=default_color, DEPTH_OFFSET=depth_offset, $
     DESCRIPTION=description, HIDE=hide, MISSING_POINTS=missing_points, $
     NAME=name, PALETTE=palette, PARENT=parent, STYLE=style, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name, PARENT=parent

   self.surface->GetProperty, $
        ALPHA_CHANNEL=alpha_channel, COLOR=default_color, DATAX=datax, DATAY=datay, $
        DEPTH_OFFSET=depth_offset, PALETTE=palette, XRANGE=xrange, YRANGE=yrange

   if arg_present(color_values) then begin
      self.surface->GetProperty, VERT_COLORS=vert_colors
      case size(vert_colors, /N_DIMENSIONS) of
         1: begin
            color_values = reform(vert_colors, self.dims[0], self.dims[1])
            if self.style eq 0 then $
                 color_values = color_values[0:self.dims[0]-2,0:self.dims[1]-2]
         end
         2: begin
            color_values = reform(vert_colors, 3, self.dims[0], self.dims[1])
            if self.style eq 0 then $
                 color_values = color_values[*,0:self.dims[0]-2,0:self.dims[1]-2]
         end
         else: color_values = -1
      endcase
   endif

   if arg_present(missing_points) then begin
      if ptr_valid(self.missing_points) then begin
         missing_points = *self.missing_points
      endif
   endif

   style = self.style

   zrange = [self.zvalue, self.zvalue]

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   zvalue = self.zvalue

end

; MGHgrColorSurface::SetProperty
;
PRO MGHgrColorSurface::SetProperty, $
     ALPHA_CHANNEL=alpha_channel, COLOR_VALUES=color_values, $
     DEFAULT_COLOR=default_color, DATAX=datax, DATAY=datay, $
     DESCRIPTION=description, HIDE=hide, MISSING_POINTS=missing_points, $
     NAME=name, PALETTE=palette, STYLE=style, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::SetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.surface->SetProperty, $
        ALPHA_CHANNEL=alpha_channel, COLOR=default_color, $
        DEPTH_OFFSET=depth_offset, PALETTE=palette

   if n_elements(style) gt 0 then self->Restyle, style

   recalc_position = 0B
   recalc_dataz = 0B

   self->SetDimensions, $
        DIMS_CHANGED=dims_changed, COLOR_VALUES=color_values, $
        DATAX=datax, DATAY=datay, MISSING_POINTS=missing_points

   if dims_changed then recalc_dataz = 1B

   if n_elements(missing_points) gt 0 then begin
      ptr_free, self.missing_points
      self.missing_points = ptr_new(byte(missing_points))
      recalc_dataz = 1B
   endif

   self->SetGeometry, $
        DATAX=datax, DATAY=datay, RECALC_DATAZ=recalc_dataz

   self->SetColors, $
        COLOR_VALUES=color_values

   if n_elements(xcoord_conv) eq 2 then begin
      self.xcoord_conv = xcoord_conv
      recalc_position = 1
   endif

   if n_elements(ycoord_conv) eq 2 then begin
      self.ycoord_conv = ycoord_conv
      recalc_position = 1
   endif

   if n_elements(zcoord_conv) eq 2 then begin
      self.zcoord_conv = zcoord_conv
      recalc_position = 1
   endif

   if n_elements(zvalue) eq 1 then begin
      self.zvalue = zvalue
      recalc_position = 1
   endif

   if recalc_position then self->Reposition

end

; MGHgrColorSurface::Reposition
;
pro MGHgrColorSurface::Reposition

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.normal_node->Reset

   self.normal_node->Translate, 0, 0, self.zvalue

   self->Reset

   self->Scale, self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->Translate, $
        self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrColorSurface::Restyle
;
pro MGHgrColorSurface::Restyle, style

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(style) eq 0 then return

   sorig = self.style

   if style ne sorig then begin

      self->GetProperty, $
           DATAX=datax, DATAY=datay, COLOR_VALUES=color_values, $
           MISSING_POINTS=missing_points

      self.surface->SetProperty, SHADING=style, STYLE=([6,2])[style]

      self.style = style

      if size(datax, /N_DIMENSIONS) eq 2 then $
           datax = mgh_stagger(datax, DELTA=fix(sorig)-fix(style))

      if size(datay, /N_DIMENSIONS) eq 2 then $
           datay = mgh_stagger(datay, DELTA=fix(sorig)-fix(style))

      self->SetProperty, $
           DATAX=datax, DATAY=datay, COLOR_VALUES=color_values, $
           MISSING_POINTS=missing_points

   endif

end

; MGHgrColorSurface::SetDimensions
;
;   Set the dimensions of the surface using COLOR_VALUES,
;   MISSING_POINTS or DATAX/Y information as available. The
;   DIMS_CHANGED keyword returns 1 if the dimensions are changed by
;   this method.
;
PRO MGHgrColorSurface::SetDimensions, $
     DIMS_CHANGED=dims_changed, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay, MISSING_POINTS=missing_points

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   dims_changed = 0B

   dims = self.dims

   case 1B of

      n_elements(color_values) gt 0: begin
         color_dims = size(color_values, /DIMENSIONS)
         case n_elements(color_dims) of
            2: dims[*] = color_dims + (1-self.style)
            3: begin
               if color_dims[0] ne 3 then begin
                  message, 'Expected (m,n) or (3,m,n) COLOR_VALUES array'
               endif
               dims[*] = color_dims[1:2] + (1-self.style)
            end
            else: message, 'Expected (m,n) or (3,m,n) COLOR_VALUES array'
         endcase
      end

      n_elements(missing_points) gt 0: begin
         dims[*] = size(missing_points, /DIMENSIONS) + (1-self.style)
      end

      else: begin
         if n_elements(datax) gt 0 then begin
            dimx = size(datax, /DIMENSIONS)
            case n_elements(dimx) of
               1: dims[0] = dimx[0]
               2: dims[*] = dimx
            endcase
         endif
         if n_elements(datay) gt 0 then begin
            dimy = size(datay, /DIMENSIONS)
            case n_elements(dimy) of
               1: dims[1] = dimy[0]
               2: dims[*] = dimy
            endcase
         endif
      endelse

   endcase

   if (dims[0] ne self.dims[0]) || (dims[1] ne self.dims[1]) then $
        dims_changed = 1B

   self.dims = dims

END

; MGHgrColorSurface::SetGeometry
;
PRO MGHgrColorSurface::SetGeometry, $
     DATAX=datax, DATAY=datay, RECALC_DATAZ=recalc_dataz

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Missing values are omitted via the DATAZ property of the
   ;; surface

   if keyword_set(recalc_dataz) then begin

      dataz = fltarr(self.dims[0],self.dims[1])

      if ptr_valid(self.missing_points) then begin

         missing_points = *self.missing_points

         dim = size(missing_points, /DIMENSIONS)
         if n_elements(dim) ne 2 then begin
            message, 'MISSING_POINTS array must have 2 dimensions'
         endif
         if dim[0] ne (self.dims[0]+self.style-1) $
              || dim[1] ne (self.dims[1]+self.style-1) then begin
            message, 'MISSING_POINTS dimensions do not match surface'
         endif

         miss = where(missing_points gt 0, count)
         if count gt 0 then begin
            case self.style of
               0: begin
                  d = dataz[0:self.dims[0]-2,0:self.dims[1]-2]
                  d[miss] = !values.f_nan
                  dataz[0:self.dims[0]-2,0:self.dims[1]-2] = d
               end
               1: begin
                  dataz[miss] = !values.f_nan
               end
            endcase
         endif
      endif

      self.surface->SetProperty, DATAZ=dataz

   endif

   if n_elements(datax) gt 0 then $
        self.surface->SetProperty, DATAX=datax
   if n_elements(datay) gt 0 then $
        self.surface->SetProperty, DATAY=datay

end

; MGHgrColorSurface::SetColors
;
PRO MGHgrColorSurface::SetColors, COLOR_VALUES=color_values

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(color_values) gt 0 then begin
      color_dims = size(color_values, /DIMENSIONS)
      case self.style of
         0: begin
            case n_elements(color_dims) of
               2: begin
                  vert_colors = bytarr(self.dims[0],self.dims[1])
                  vert_colors[0:self.dims[0]-2,0:self.dims[1]-2] = color_values
                  self.surface->SetProperty, $
                       VERT_COLORS=reform(vert_colors,self.dims[0]*self.dims[1])
               end
               3: begin
                  vert_colors = bytarr(3,self.dims[0],self.dims[1])
                  vert_colors[*,0:self.dims[0]-2,0:self.dims[1]-2] = color_values
                  self.surface->SetProperty, $
                       VERT_COLORS=reform(vert_colors,3,self.dims[0]*self.dims[1])
               end
            endcase
         end
         1: begin
            case n_elements(color_dims) of
               2: begin
                  self.surface->SetProperty, $
                       VERT_COLORS=reform(color_values, self.dims[0]*self.dims[1])
               end
               3: begin
                  self.surface->SetProperty, $
                       VERT_COLORS=reform(color_values, 3, self.dims[0]*self.dims[1])
               end
            endcase
         end
      endcase
   endif


END

; MGHgrColorSurface__Define

PRO MGHgrColorSurface__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrColorSurface, inherits IDLgrModel, $
         normal_node: obj_new(), dims: lonarr(2), $
         missing_points: ptr_new(), style: 0S, surface: obj_new(), $
         xcoord_conv: dblarr(2), ycoord_conv: dblarr(2), $
         zcoord_conv: dblarr(2), zvalue: 0.D}

end

