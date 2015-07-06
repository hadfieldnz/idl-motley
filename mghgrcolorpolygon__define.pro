; svn $Id$
;+
; CLASS NAME:
;   MGHgrColorPolygon
;
; PURPOSE:
;   This class implements a colour plane using an IDLgrPolygon. For a description
;   of what a colour plane is, see the documentation for MGHgrColorPlane.
;
; PROPERTIES:
;   The following properties are supported (amongst others):
;
;     DEFAULT_COLOR (Init,Get,Set)
;       The colour (indexed or RGB) of the surface, used if the
;       COLOR_VALUES property is not set.
;
;     COLOR_VALUES (Init,Get,Set)
;       A 2-D array of byte values representing the indexed colours of
;       the cells (STYLE=0) or vertices (STYLE=1).
;
;     DATAX, DATAY (Init,Get,Set)
;       1-D or 2-D arrays specifying the vertex positions. When
;       retrieved via GetProperty, DATAX & DATAY are always 2-D.
;
;     MISSING_POINTS (Init,Get,Set)
;       A 2-D array of integer or byte values specifying which cell
;       (STYLE=0) or vertex (STYLE=1) values are deemed to be
;       missing. For STYLE=0, missing cells are omitted from the
;       polygon; for STYLE=1, the cells adjacent to each missing
;       vertex are omitted.
;
;     PALETTE (Init,Get,Set)
;       A reference to the palette defining the byte-color mapping.
;
;     STYLE (Init,Get,Set)
;       An integer specifying whether colours are uniform over the
;       cells (STYLE=0) or interpolated from the vertices
;       (STYLE=1). Default is 0. If STYLE is changed without
;       specifying new geometry (DATAX, DATAY, COLOR_VALUES or
;       MISSING_POINTS) then the colour plane is resized and shifted
;       in such a way as to keep the notional data points (i.e the
;       cell centres for STYLE=0 and the vertices for STYLE=1) in the
;       same location.
;
;     XRANGE, YRANGE, ZRANGE (Get)
;
;     ZVALUE (Init,Get,Set)
;       Position in the Z direction.
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
;   Mark Hadfield, 1998-12:
;     Written as MGHgrColorPlane (I think).
;   Mark Hadfield, 2000-12:
;     Renamed MGHgrColorPolygon.
;   Mark Hadfield, 2001-10:
;     - Updated for IDL 5.5: keyword inheritance modified.
;     - The code now handles the case where MISSING_POINTS is
;       specified and is everywhere > 0 (i.e. no polygons to
;       display).
;   Mark Hadfield, 2002-07:
;     - The STYLE property can now be set via SetProperty.
;     - Vectorised and simplified code in SetPolygon method.
;   Mark Hadfield, 2004-07:
;     - Property handling modified to support property-sheet
;       functionality.
;     - IDL 6.0 syntax.
;-

; MGHgrColorPolygon::Init

function MGHgrColorPolygon::Init, Colors, $
     ALPHA_CHANNEL=alpha_channel, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay, DEFAULT_COLOR=default_color, $
     DEPTH_OFFSET=depth_offset, DESCRIPTION=description, HIDE=hide, $
     MISSING_POINTS=missing_points, $
     NAME=name, PALETTE=palette, STYLE=style, $
     REGISTER_PROPERTIES=register_properties, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDLgrModel::Init(DESCRIPTION=description, HIDE=hide, $
                               NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'

   self.normal_node = obj_new('IDLgrModel')
   self->Add, self.normal_node

   self.style = n_elements(style) gt 0 ? style : 0

   if n_elements(default_color) eq 0 then default_color = [255,255,255]

   self.polygon = $
        obj_new('IDLgrPolygon', ALPHA_CHANNEL=alpha_channel, DEPTH_OFFSET=depth_offset, $
                SHADING=style, COLOR=default_color, PALETTE=palette)

   self.normal_node->Add, self.polygon

   dims_changed = 0B

   self->SetDimensions, $
        COLOR_VALUES=color_values, DATAX=datax, DATAY=datay, $
        MISSING_POINTS=missing_points, DIMS_CHANGED=dims_changed

   if keyword_set(dims_changed) then begin

      self->SetVertices, $
           COLOR_VALUES=color_values, DATAX=datax, DATAY=datay, /DIMS_CHANGED

      if n_elements(missing_points) gt 0 then $
           self.missing_points = ptr_new(byte(missing_points))

      self->SetPolygons

      self->SetColors, COLOR_VALUES=color_values

   endif

   self.zvalue = 0
   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   self->MGHgrColorPolygon::SetProperty, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
        ZVALUE=zvalue

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'NAME', NAME='Name', /STRING
      self->RegisterProperty, 'DESCRIPTION', NAME='Description', /STRING
      self->RegisterProperty, 'STYLE', NAME='Style', ENUMLIST=['Block','Interpolated']
      self->RegisterProperty, 'HIDE', NAME='Show', ENUMLIST=['True','False']
      self->RegisterProperty, 'ALPHA_CHANNEL', NAME='Opacity', /FLOAT, $
           VALID_RANGE=[0,1,0.05D0]
      self->RegisterProperty, 'DEFAULT_COLOR', NAME='Default color', /COLOR
      self->RegisterProperty, 'ZVALUE', NAME='Z position', /FLOAT

   endif
   return, 1

END

; MGHgrColorPolygon::Cleanup
;
PRO MGHgrColorPolygon::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.missing_points

   self->IDLgrModel::Cleanup

end


; MGHgrColorPolygon::GetProperty
;
PRO MGHgrColorPolygon::GetProperty, $
     ALPHA_CHANNEL=alpha_channel, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay, DEFAULT_COLOR=default_color, $
     DEPTH_OFFSET=depth_offset, DESCRIPTION=description, HIDE=hide, $
     MISSING_POINTS=missing_points, NAME=name, PALETTE=palette, $
     PARENT=parent, STYLE=style, $
     XCOORD_CONV=xcoord_conv, XRANGE=xrange, $
     YCOORD_CONV=ycoord_conv, YRANGE=yrange, $
     ZCOORD_CONV=zcoord_conv, ZRANGE=zrange, $
     ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name, PARENT=parent

   self.polygon->GetProperty, $
        ALPHA_CHANNEL=alpha_channel, COLOR=default_color, $
        DEPTH_OFFSET=depth_offset, PALETTE=palette, $
        XRANGE=xrange, YRANGE=yrange

   if arg_present(color_values) then begin
      self.polygon->GetProperty, VERT_COLORS=vert_colors
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

   if arg_present(datax) or arg_present(datay) then begin
      self.polygon->GetProperty, DATA=data
      datax = reform(data[0,*], self.dims[0], self.dims[1])
      datay = reform(data[1,*], self.dims[0], self.dims[1])
   endif

   if arg_present(missing_points) then begin
      if ptr_valid(self.missing_points) then begin
         missing_points = *self.missing_points
      endif
   endif

   style = self.style

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   zrange = [self.zvalue, self.zvalue]

   zvalue = self.zvalue

end

; MGHgrColorPolygon::SetProperty
;
PRO MGHgrColorPolygon::SetProperty, $
     ALPHA_CHANNEL=alpha_channel, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay, $
     DEFAULT_COLOR=default_color, DEPTH_OFFSET=depth_offset, $
     DESCRIPTION=description, HIDE=hide, $
     MISSING_POINTS=missing_points, NAME=name, $
     PALETTE=palette, STYLE=style, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::SetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.polygon->SetProperty, $
        ALPHA_CHANNEL=alpha_channel, COLOR=default_color, $
        DEPTH_OFFSET=depth_offset, PALETTE=palette

   ;; The Restyle method sets the style; if the style has changed it
   ;; also changes any existing geometry data so as to preserve the
   ;; number and position of the data points.  These changes may be
   ;; overriden below if any geometry data have been specified in the
   ;; call to SetProperty, however the inefficiency is insignificant
   ;; and writing it this way makes the code simpler.

   if n_elements(style) gt 0 then self->Restyle, style

   ;; Work through remaining keywords, setting boolean switches as
   ;; necessary to indicate that polygon properties need to be
   ;; recalculated.

   dims_changed = 0B
   recalc_polygons = 0B
   recalc_position = 0B

   if (n_elements(color_values) gt 0 || n_elements(datax) gt 0 || $
       n_elements(datay) gt 0 || n_elements(missing_points) gt 0) then begin
      ;; DIMS_CHANGED is set as necessary by the SetDimensions method
      ;; to indicate that the polygon dimensions have been changed.
      self->SetDimensions, $
           COLOR_VALUES=color_values, DATAX=datax, DATAY=datay, $
           MISSING_POINTS=missing_points, DIMS_CHANGED=dims_changed
   endif

   self->SetVertices, $
        COLOR_VALUES=color_values, DATAX=datax, DATAY=datay, $
        DIMS_CHANGED=dims_changed

   if dims_changed then recalc_polygons = 1B

   if n_elements(missing_points) gt 0 then begin
      ptr_free, self.missing_points
      self.missing_points = ptr_new(byte(missing_points))
      recalc_polygons = 1B
   endif

   self->SetColors, COLOR_VALUES=color_values

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

   if recalc_polygons then self->SetPolygons

   if recalc_position then self->Reposition

end

; MGHgrColorPolygon::Reposition
;
pro MGHgrColorPolygon::Reposition

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.normal_node->Reset

   self.normal_node->Translate, 0, 0, self.zvalue

   self->Reset

   self->Scale, $
        self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->Translate, $
        self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrColorPolygon::Restyle
;
pro MGHgrColorPolygon::Restyle, style

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(style) eq 0 then return

   ostyle = self.style

   if style ne ostyle then begin

      self->GetProperty, $
           DATAX=datax, DATAY=datay, COLOR_VALUES=color_values, $
           MISSING_POINTS=missing_points

      self.polygon->SetProperty, SHADING=style

      self.style = style

      if size(datax, /N_DIMENSIONS) eq 2 then $
           datax = mgh_stagger(datax, DELTA=fix(ostyle)-fix(style))

      if size(datay, /N_DIMENSIONS) eq 2 then $
           datay = mgh_stagger(datay, DELTA=fix(ostyle)-fix(style))

      self->SetProperty, $
           DATAX=datax, DATAY=datay, COLOR_VALUES=color_values, $
           MISSING_POINTS=missing_points

   endif

end

; MGHgrColorPolygon::SetColors
;
PRO MGHgrColorPolygon::SetColors, COLOR_VALUES=color_values

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n0 = self.dims[0]
   n1 = self.dims[1]

   n_dimc =size(color_values, /N_DIMENSIONS)

   if n_dimc gt 0 then begin
      case self.style of
         0: begin
            case n_dimc of
               2: begin
                  vert_colors = bytarr(n0,n1)
                  vert_colors[0:n0-2,0:n1-2] = color_values
                  self.polygon->SetProperty, $
                       VERT_COLORS=reform(vert_colors,n0*n1)
               end
               3: begin
                  vert_colors = bytarr(3,n0,n1)
                  vert_colors[*,0:n0-2,0:n1-2] = color_values
                  self.polygon->SetProperty, $
                       VERT_COLORS=reform(vert_colors,3,n0*n1)
               end
            endcase
         end
         1: begin
            case n_dimc of
               2: begin
                  self.polygon->SetProperty, $
                       VERT_COLORS=reform(color_values,n0*n1)
               end
               3: begin
                  self.polygon->SetProperty, $
                       VERT_COLORS=reform(color_values,3,n0*n1)
               end
            endcase
         end
      endcase
   endif

end

; MGHgrColorPolygon::SetDimensions
;
PRO MGHgrColorPolygon::SetDimensions, $
     DIMS_CHANGED=dims_changed, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay, MISSING_POINTS=missing_points

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   dims_changed = 0B

   dims = self.dims

   case 1B of

      size(color_values, /N_DIMENSIONS) gt 0: begin

         ;; First try to get dimensions from the COLOR_VALUES keyword.

         n_dimc = size(color_values, /N_DIMENSIONS)
         dimc = size(color_values, /DIMENSIONS)

         ;; Interpret a 1-D array as a 2-D array with trailing dimension
         ;; 1.  and a 3D array as true colour data.
         case n_dimc of
            1: dimc = [dimc,1]
            2:
            3: dimc = dimc[1:2]
         endcase

         dims[*] = dimc + (1-self.style)

      end

      size(missing_points, /N_DIMENSIONS) gt 0: begin

         ;; Now try to get dimensions from the MISSING_POINTS keyword.

         dimm = size(missing_points, /DIMENSIONS)

         ;; Interpret a 1-D array as a 2-D array with trailing dimension 1.
         if n_elements(dimm) eq 1 then dimm = [dimm,1]

         dims[*] = dimm + (1-self.style)

      end

      else: begin

         ;; Now try to get dimensions from the DATAX & DATAY keywords.

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

   if (dims[0] ne self.dims[0]) || (dims[1] ne self.dims[1]) then dims_changed = 1B

   self.dims = dims

END

; MGHgrColorPolygon::SetPolygons
;
pro MGHgrColorPolygon::SetPolygons

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n0 = self.dims[0]
   n1 = self.dims[1]

   ;; Set up a vector of indices into the vertex array, describing a
   ;; tiled array of rectangles. Code resembles that in function
   ;; MGH_TRIANGULATE_RECTANGLE and (quite possibly) MESH_OBJ.

   polygons = lonarr(5,(n0-1),(n1-1))

   polygons[0,0,0] = replicate(4,1,(n0-1),(n1-1))

   for j=0,n1-2 do begin

      l0 = j*n0 + lindgen(1,n0-1)

      polygons[1,0,j] = l0
      polygons[2,0,j] = l0 + 1
      polygons[3,0,j] = l0 + n0 + 1
      polygons[4,0,j] = l0 + n0

   endfor

   polygons = reform(polygons, 5*(n0-1)*(n1-1), /OVERWRITE)

   ;; Go through the polygon descriptors, stripping out those affected
   ;; by missing data Perhaps this step could be omitted when we know
   ;; the MISSING_POINTS values & surface dimensions have not
   ;; changed.

   if ptr_valid(self.missing_points) then begin

      missing_points = *self.missing_points

      dim = size(missing_points, /DIMENSIONS)

      if n_elements(dim) ne 2 then $
           message, 'MISSING_POINTS array must have 2 dimensions'
      if dim[0] ne (n0+self.style-1) || dim[1] ne (n1+self.style-1) then $
           message, 'MISSING_POINTS dimensions do not match surface'

      case self.style of

         0: begin
            polygons = reform(polygons, 5, (n0-1)*(n1-1), /OVERWRITE)
            miss = where(missing_points gt 0, n_miss)
            if n_miss gt 0 then polygons[*,miss] = -1
            polygons = reform(polygons, 5*(n0-1)*(n1-1), /OVERWRITE)
         end

         1: begin
            polygons = reform(polygons, 5, (n0-1), (n1-1), /OVERWRITE)
            imiss5 = replicate(-1,5)
            ;; Lower left
            for j=1,n1-1 do for i=1,n0-1 do $
                 if missing_points[i,j] then polygons[0,i-1,j-1] = imiss5
            ;; Lower right
            for j=1,n1-1 do for i=0,n0-2 do $
                 if missing_points[i,j] then polygons[0,i,j-1] = imiss5
            ;; Upper left
            for j=0,n1-2 do for i=1,n0-1 do $
                 if missing_points[i,j] then polygons[0,i-1,j] = imiss5
            ;; Upper right
            for j=0,n1-2 do for i=0,n0-2 do $
                 if missing_points[i,j] then polygons[0,i,j] = imiss5
            polygons = reform(polygons, 5*(n0-1)*(n1-1), /OVERWRITE)
         end

      endcase

      wp = where(polygons ge 0, n_pol)
      polygons = n_pol gt 0 ? polygons[wp] : polygons[0]

   endif

   self.polygon->SetProperty, POLYGONS=polygons

END

; MGHgrColorPolygon::SetVertices
;
PRO MGHgrColorPolygon::SetVertices, $
     DIMS_CHANGED=dims_changed, COLOR_VALUES=color_values, $
     DATAX=datax, DATAY=datay

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   n0 = self.dims[0]
   n1 = self.dims[1]

   if keyword_set(dims_changed) then begin
      if n_elements(datax) eq 0 then datax = findgen(n0)
      if n_elements(datay) eq 0 then datay = findgen(n1)
      data = fltarr(2, n0*n1)
      polygons = -1
   endif else begin
      self.polygon->GetProperty, DATA=data, POLYGONS=polygons
   endelse

   if n_elements(datax) gt 0 then begin
      case size(datax, /N_DIMENSIONS) of
         1: data[0,*] = mgh_inflate(self.dims, datax, 1)
         2: data[0,*] = datax
      endcase
   endif

   if n_elements(datay) gt 0 then begin
      case size(datax, /N_DIMENSIONS) of
         1: data[1,*] = mgh_inflate(self.dims, datay, 2)
         2: data[1,*] = datay
      endcase
   endif

   self.polygon->SetProperty, DATA=data, POLYGONS=polygons

end

; MGHgrColorPolygon__Define

PRO MGHgrColorPolygon__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrColorPolygon, inherits IDLgrModel, $
         normal_node: obj_new(), dims: lonarr(2), $
         missing_points: ptr_new(), style: 0B, polygon: obj_new(), $
         xcoord_conv: dblarr(2), ycoord_conv: dblarr(2), zcoord_conv: dblarr(2), $
         zvalue: 0.D}

end

