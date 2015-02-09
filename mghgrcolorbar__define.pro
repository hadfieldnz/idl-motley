;+
; CLASS NAME:
;   MGHgrColorBar
;
; PURPOSE:
;   This class implements an object graphics colour bar, ie a rectangular bar
;   showing a mapping between numeric values and colours.
;
; SUPERCLASSES:
;   This class inherits from IDLgrModel.
;
; PROPERTIES:
;   The following properties are supported:
;
;   AXIS (Get)
;     This keyword returns a reference to the axis object. It can be
;     used to modify the axis properties.
;
;   BYTE_RANGE (Init,Get,Set)
;     The range of byte values to which the data range is to be mapped.
;
;   COLORSCALE (Init)
;     A reference to an object from which default colour mapping
;     information (BYTE_RANGE, DATA_RANGE, LOGARITHMIC and PALETTE) can
;     be retrieved.
;
;   DATA_RANGE (Init,Get,Set)
;     The range of data values to be mapped onto the indexed color
;     range. Data values outside the range are mapped to the nearest
;     end of the range.
;
;   LOGARITHMIC (Init,Get,Set)
;     Set this property for a logarithmic mapping between the data values
;     and the coloour scale.
;
;   DIMENSIONS (Init,Get,Set)
;     X & Y dimensions of the rectangle in data units.
;
;   LOCATION (Init,Get,Set)
;     Location of the lower left corner of the rectangle in data units.
;
;   PALETTE (Init,Get,Set)
;     A reference to the palette defining the byte-color mapping.
;
;   SHOW_AXIS (Init,Get,Set)
;     This property determines whether & where the axis should be
;     drawn.
;       0 - Do not display axis (the default)
;       1 - Display axis on left side or below the color ramp
;           (default).
;       2 - Display axis on right side or above the color ramp I am
;           not 100% sure this works correctly in all cases.
;
;   TICKIN (Init,Get,Set)
;     Controls whether tick marks are directed inwards (1) or outwards
;     (0). The default is 0.
;
;   TITLE (Init,Get,Set)
;     A reference to a text object representing the axis title. If
;     this is specified as a string, then a text object is created
;     automatically using the current setting of the FONT property.
;
;   VERTICAL (Init,Get,Set)
;     Set this property to 1 for a colour bar with its axis in the Y
;     direction and 0 for a colour bar with its axis in the X
;     direction. Default is 0.
;
;   XCOORD_CONV (Init,Get,Set)
;   YCOORD_CONV (Init,Get,Set)
;   ZCOORD_CONV (Init,Get,Set)
;     Coordinate transformations specifying the relationship between
;     normalised & data units.
;
;   XRANGE (Get)
;   YRANGE (Get)
;   ZRANGE (Get)
;     Position of the extremes of the object in data units.
;
; METHODS:
;   The usual.
;
;###########################################################################
; Copyright (c) 1998-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, Aug 1998:
;     Written.
;   Mark Hadfield, Aug 1999:
;     Changed the colour ramp from an IDLgrSurface to an
;     MGHgrColorPlane for better vector output under IDL 5.3.
;   Mark Hadfield, 2001-07:
;     Updated for IDL 5.5. With the new DEPTH_OFFSET keyword I was
;     able to omit some awkward & fragile vertical-positioning code in
;     the Draw method.
;   Mark Hadfield, 2011-06:
;     Cleaned up some ugly code for setting BYTE_RANGE & DATA_RANGE.
;   Mark Hadfield, 2012-10:
;     Added LOGARITHMIC property.
;-
function MGHgrColorBar::Init, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
     COLORSCALE=colorscale, LOGARITHMIC=logarithmic, $
     DESCRIPTION=description, DIMENSIONS=dimensions, $
     FONT=font, HIDE=hide, LOCATION=location, NAME=name, PALETTE=palette, $
     REGISTER_PROPERTIES=register_properties, $
     SHOW_AXIS=show_axis, SHOW_CONTOUR=show_contour, SHOW_OUTLINE=show_outline, $
     TICKIN=tickin, TICKLEN=ticklen, TITLE=title, VERTICAL=vertical, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     AXIS_PROPERTIES=axis_properties, $
     CONTOUR_PROPERTIES=contour_properties, CONTOUR_VALUES=contour_values

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDLgrModel::Init(DESCRIPTION=description, HIDE=hide, $
                               NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'

   if n_elements(font) eq 1 && obj_valid(font) then $
      self.font = font

   ;; Create child objects

   self.normal_node = obj_new('IDLgrModel')

   self.disposal = obj_new('MGH_Container', DESTROY=1)

   self.ramp = obj_new('MGHgrColorPlane', STYLE=0, DEPTH_OFFSET=1)

   self.outline = obj_new('IDLgrPolyline', [0,1,1,0,0], [0,0,1,1,0], intarr(5), $
                          COLOR=[0B,0B,0B])

   self.contour = obj_new('IDLgrContour', COLOR=[255B,255B,255B])

   self.axis = obj_new('MGHgrAxis', /EXACT, TICKLEN=0.3, FONT=self.font, _STRICT_EXTRA=axis_properties)

   ;; Set up the object hierarchy

   self->Add, self.normal_node

   self.normal_node->Add, [self.ramp, self.axis, self.contour, self.outline]

   ;; Specify defaults

   self.vertical = $
        n_elements(vertical) gt 0 ? keyword_set(vertical) : 0

   self.dimensions = self.vertical ? [0.15,1.0] : [1.0,0.15]

   self.byte_range = [0,0]
   self.data_range = [0,0]
   self.logarithmic = 0
   self.location = [0,0,0]
   self.show_axis = 1
   self.show_outline = 1
   self.show_contour = 0
   self.tickin = 0
   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   if n_elements(colorscale) eq 1 && obj_valid(colorscale) then begin
      colorscale->GetProperty, $
           BYTE_RANGE=c_byte_range, DATA_RANGE=c_data_range, $
           LOGARITHMIC=c_logarithmic, PALETTE=c_palette
      if n_elements(byte_range) eq 0 then byte_range = c_byte_range
      if n_elements(data_range) eq 0 then data_range = c_data_range
      if n_elements(logarithmic) eq 0 then logarithmic = c_logarithmic
      if n_elements(palette) eq 0 then palette = c_palette
   endif

   self->SetProperty, $
        BYTE_RANGE=byte_range, $
        CONTOUR_PROPERTIES=contour_properties, CONTOUR_VALUES=contour_values, $
        DATA_RANGE=data_range, LOGARITHMIC=logarithmic, $
        DIMENSIONS=dimensions, LOCATION=location, $
        PALETTE=palette, SHOW_AXIS=show_axis, $
        SHOW_CONTOUR=show_contour, SHOW_OUTLINE=show_outline, $
        TICKLEN=ticklen, TICKIN=tickin, $
        TITLE=title, XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, $
        ZCOORD_CONV=zcoord_conv

   if keyword_set(register_properties) then begin
      self->RegisterProperty, 'Name', /STRING
      self->RegisterProperty, 'Description', /STRING
   endif

   return, 1

end

; MGHgrColorBar::Cleanup
;
PRO MGHgrColorBar::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.disposal

   self->IDLgrModel::Cleanup

end

; MGHgrColorBar::SetProperty
;
PRO MGHgrColorBar::SetProperty, $
     AXIS_PROPERTIES=axis_properties, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
     LOGARITHMIC=logarithmic, $
     CONTOUR_VALUES=contour_values, CONTOUR_PROPERTIES=contour_properties, $
     DESCRIPTION=description, DIMENSIONS=dimensions, FONT=font, HIDE=hide, $
     LOCATION=location, NAME=name, PALETTE=palette, $
     SHOW_AXIS=show_axis, SHOW_CONTOUR=show_contour, SHOW_OUTLINE=show_outline, $
     TICKLEN=ticklen, TICKIN=tickin, TITLE=title, $
     VERTICAL=vertical, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   recalc = 0B

   self->IDLgrModel::SetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.ramp->SetProperty, PALETTE=palette

   if n_elements(axis_properties) gt 0 then $
        self.axis->SetProperty, _STRICT_EXTRA=axis_properties

   if n_elements(byte_range) gt 0 then begin
      self.byte_range = byte_range
      recalc = 1B
   endif

   if n_elements(contour_properties) gt 0 || $
        n_elements(contour_values) gt 0 then begin
      self.contour->SetProperty, C_VALUE=contour_values, _STRICT_EXTRA=contour_properties
   endif

   if n_elements(data_range) gt 0 then begin
      self.data_range = data_range
      recalc = 1B
   endif

   if n_elements(logarithmic) gt 0 then begin
      self.logarithmic = logarithmic
      recalc = 1B
   endif

   if n_elements(dimensions) gt 0 then begin
      self.dimensions = dimensions
      recalc = 1B
   endif

   nloc = n_elements(location)
   if nloc ge 2 then begin
      self.location[0:nloc-1] = location
      recalc = 1B
   endif

   if n_elements(show_axis) eq 1 then begin
      self.show_axis = show_axis
      recalc = 1B
   endif

   if n_elements(show_contour) eq 1 then begin
      self.show_contour = show_contour
      recalc = 1B
   endif

   if n_elements(show_outline) eq 1 then begin
      self.show_outline = show_outline
      recalc = 1B
   endif

   if n_elements(ticklen) eq 1 then begin
      self.axis->SetProperty, TICKLEN=ticklen
      recalc = 1B
   endif

   if n_elements(tickin) gt 0 then begin
      self.tickin = keyword_set(tickin)
      recalc = 1B
   endif

   if n_elements(vertical) gt 0 then begin
      self.vertical = keyword_set(vertical)
      recalc = 1B
   endif

   if n_elements(xcoord_conv) eq 2 then begin
      self.xcoord_conv = xcoord_conv
      recalc = 1B
   endif

   if n_elements(ycoord_conv) eq 2 then begin
      self.ycoord_conv = ycoord_conv
      recalc = 1B
   endif

   if n_elements(zcoord_conv) eq 2 then begin
      self.zcoord_conv = zcoord_conv
      recalc = 1B
   endif

   if n_elements(font) gt 0 then begin
      self.font = font
      self.axis->SetProperty, FONT=font
   endif


;   if n_elements(font) eq 1 && obj_valid(font) then begin
;      self.font = font
;      self.axis->GetProperty, TICKTEXT=tt
;      tt->SetProperty, FONT=font
;   endif

   if n_elements(title) gt 0 then $
        self.axis->SetProperty, TITLE=title

;   case size(title, /TYPE) of
;      7: begin
;         otitle = obj_new('IDLgrText', title[0], FONT=self.font, RECOMPUTE_DIMENSIONS=2)
;         self.disposal->Add, otitle
;         self.axis->SetProperty, TITLE=otitle
;      end
;      11: self.axis->SetProperty, TITLE=title[0]
;      else: dummy = 0
;   endcase

   if recalc then self->Calculate

end


; MGHgrColorBar::GetProperty
;
pro MGHgrColorBar::GetProperty, $
     ALL=all, AXIS=axis, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
     LOGARITHMIC=logarithmic, $
     CONTOUR_VALUES=contour_values, $
     DESCRIPTION=description, DIMENSIONS=dimensions, $
     FONT=font, HIDE=hide, LOCATION=location, NAME=name, $
     PALETTE=palette, PARENT=parent, SHOW_AXIS=show_axis, $
     SHOW_CONTOUR=show_contour, SHOW_OUTLINE=show_outline, $
     TICKLEN=ticklen, TICKIN=tickin, TITLE=title, $
     XCOORD_CONV=xcoord_conv, XRANGE=xrange, $
     YCOORD_CONV=ycoord_conv, YRANGE=yrange, $
     ZCOORD_CONV=zcoord_conv, ZRANGE=zrange

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name, $
        PARENT=parent

   self.axis->GetProperty, TICKLEN=ticklen, TITLE=title

   axis = self.axis

   byte_range = self.byte_range

   data_range = self.data_range

   logarithmic = self.logarithmic

   dimensions = self.dimensions

   font = self.font

   location = self.location

   show_axis = self.show_axis

   show_contour = self.show_contour

   show_outline = self.show_outline

   tickin = self.tickin

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   if arg_present(contour_values) then begin
      self.contour->GetProperty, DATA=cdata
      case n_elements(cdata) gt 0 of
         0: contour_values = -1
         1: self.contour->GetProperty, C_VALUE=contour_values
      endcase
   endif

   self.ramp->GetProperty, $
        PALETTE=palette, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

   if self.show_outline then begin

      self.outline->GetProperty, $
           XRANGE=outline_xrange, YRANGE=outline_yrange, ZRANGE=outline_zrange

      xrange[0] = xrange[0] < outline_xrange[0]
      xrange[1] = xrange[1] > outline_xrange[1]

      yrange[0] = yrange[0] < outline_yrange[0]
      yrange[1] = yrange[1] > outline_yrange[1]

      zrange[0] = zrange[0] < outline_zrange[0]
      zrange[1] = zrange[1] > outline_zrange[1]

   endif

   if self.show_axis gt 0 then begin

      self.axis->GetProperty, $
           XCOORD_CONV=axis_xcoord, XRANGE=axis_xrange, $
           YCOORD_CONV=axis_ycoord, YRANGE=axis_yrange, $
           ZCOORD_CONV=axis_zcoord, ZRANGE=axis_zrange

      xrange[0] = xrange[0] < (axis_xrange[0]*axis_xcoord[1] + axis_xcoord[0])
      xrange[1] = xrange[1] > (axis_xrange[1]*axis_xcoord[1] + axis_xcoord[0])

      yrange[0] = yrange[0] < (axis_yrange[0]*axis_ycoord[1] + axis_ycoord[0])
      yrange[1] = yrange[1] > (axis_yrange[1]*axis_ycoord[1] + axis_ycoord[0])

      zrange[0] = zrange[0] < (axis_zrange[0]*axis_zcoord[1] + axis_zcoord[0])
      zrange[1] = zrange[1] > (axis_zrange[1]*axis_zcoord[1] + axis_zcoord[0])

   endif

   self.normal_node->GetProperty, TRANSFORM=normal_transform
   xrange = xrange * normal_transform[0,0] + normal_transform[3,0]
   yrange = yrange * normal_transform[1,1] + normal_transform[3,1]
   zrange = zrange * normal_transform[2,2] + normal_transform[3,2]

   if arg_present(all) then $
        all = {byte_range: byte_range, data_range: data_range, logarithmic: logarithmic, $
               axis: axis, dimensions: dimensions, font: font, hide: hide, location: location, $
               palette: palette, parent: parent, show_axis: show_axis, $
               show_outline: show_outline, show_contour: show_contour, $
               tickin: tickin, ticklen: ticklen, title: title, $
               xcoord_conv: xcoord_conv, xrange: xrange, $
               ycoord_conv: ycoord_conv, yrange: yrange, $
               zcoord_conv: zcoord_conv, zrange: zrange}

end


; MGHgrColorbar::AddSlave
;
pro MGHgrColorbar::AddSlave, object

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

      for i=0,n_elements(object)-1 do begin

         spos = string(i, FORMAT='(I0)')

         if ~ obj_valid(object[i]) then $
              message, 'Invalid object at position '+spos

         container->Add, object[i]

      endfor

end

; MGHgrColorBar::Calculate
;
PRO MGHgrColorBar::Calculate

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.byte_range[1] ne self.byte_range[0] then begin
      byte_range = self.byte_range
   endif else begin
      self->GetProperty, PALETTE=palette
      if obj_valid(palette) then begin
         palette->GetProperty, N_COLORS=n_colors
         byte_range = [0,n_colors-1]
      endif else begin
         byte_range = [0B,255B]
      endelse
   endelse

   if self.data_range[0] ne self.data_range[1] then begin
      data_range = self.data_range
   endif else begin
      data_range = float(byte_range)
   endelse
   
   logarithmic = self.logarithmic

   tickdir = (self.show_axis eq 2) ? self.tickin : 1 - self.tickin

   self.axis->SetProperty, DIRECTION=self.vertical, $
        RANGE=data_range, LOG=logarithmic, $
        HIDE=(self.show_axis eq 0), $
        TICKDIR=tickdir, TEXTPOS=(self.show_axis eq 2), /EXACT

   self.outline->SetProperty, HIDE=(self.show_outline eq 0)

   nramp = byte_range[1]-byte_range[0]+1

   axis_norm_range = [0.5/nramp,1-0.5/nramp]
   axis_coord_conv = mgh_norm_coord(data_range, axis_norm_range)

   case self.vertical of
      0: begin
         ;; If the colour bar is horizontal then the ramp has
         ;; [nramp,1] cells, so DATAX is dimensioned [nramp+1], DATAY
         ;; is dimensioned [2] and COLOR_VALUES is dimensioned
         ;; [nramp,1]. Care is needed in the expression for
         ;; COLOR_VALUES to preserve the trailing dimension.
         self.ramp->SetProperty, $
              DATAX=findgen(nramp+1)/nramp, DATAY=[0,1], $
              COLOR_VALUES=reform(byte_range[0]+indgen(nramp),nramp,1)
         self.axis->SetProperty, $
              NORM_RANGE=axis_norm_range, $
              LOCATION=(self.show_axis eq 2) ? [0,1,0] : [0,0,0]
         self.contour->SetProperty, $
              GEOMX=data_range, GEOMY=[0,1], GEOMZ=0, /PLANAR, $
              XCOORD_CONV=axis_coord_conv, YCOORD_CONV=[0,1], DATA=data_range#[1,1], $
              HIDE=(self.show_contour eq 0)
      end
      1: begin
         ;; If the colour bar is vertical then the ramp has [1,nramp]
         ;; cells, so DATAX is dimensioned [2], DATAY is dimensioned
         ;; [nramp+1] and COLOR_VALUES is dimensioned [1,nramp]
         self.ramp->SetProperty, $
              DATAX=[0,1], DATAY=findgen(nramp+1)/nramp, $
              COLOR_VALUES=byte_range[0]+indgen(1,nramp)
;         self.axis->SetProperty, $
;              XCOORD_CONV=[0,1], YCOORD_CONV=axis_coord_conv, $
;              LOCATION=(self.show_axis eq 2) ? [1,0,0] : [0,0,0]
         self.axis->SetProperty, $
              NORM_RANGE=axis_norm_range, $
              LOCATION=(self.show_axis eq 2) ? [1,0,0] : [0,0,0]
         self.contour->SetProperty, $
              GEOMX=[0,1], GEOMY=data_range, GEOMZ=0, /PLANAR, $
              XCOORD_CONV=[0,1], YCOORD_CONV=axis_coord_conv, DATA=[1,1]#data_range, $
              HIDE=(self.show_contour eq 0)
      end

   endcase

   self.normal_node->Reset

   self.normal_node->Scale, self.dimensions[0], self.dimensions[1], 1

   self.normal_node->Translate, self.location[0], self.location[1], self.location[2]

   self->Reset

   self->Scale, self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->Translate, self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrColorBar__Define

pro MGHgrColorBar__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrColorBar, inherits IDLgrModel, normal_node: obj_new(), $
         disposal: obj_new(), axis: obj_new(), outline: obj_new(), $
         ramp: obj_new(), contour: obj_new(), font: obj_new(), $
         slave: obj_new(), $
         byte_range: bytarr(2), data_range: fltarr(2), logarithmic: 0B, $
         dimensions: dblarr(2) , location: dblarr(3), show_axis: 0B, $
         show_contour: 0B, show_outline: 0B, tickin: 0B, vertical: 0B, $
         xcoord_conv: dblarr(2), ycoord_conv: dblarr(2), zcoord_conv: fltarr(2)}

end


