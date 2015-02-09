;+
; CLASS NAME:
;   MGHgrDensityPlane
;
; PURPOSE:
;   This class implements a "density plane" graphics object, ie a
;   representation of 2-D numeric data on a flat surface using colour
;   or grey-scale density. It encapsulates an MGHgrColorPlane, which
;   handles all the geometry.
;
; CATEGORY:
;   Object graphics.
;
; PROPERTIES:
;   The following properties are supported (amongst others):
;
;     BYTE_RANGE (Init,Get)
;       The range of byte values to which the data range is to be mapped.
;
;     COLORSCALE (Init)
;       A reference to an object (like a colour bar or another density
;       plane) from which default colour mapping information
;       (BYTE_RANGE, DATA_RANGE, LOGARITHMIC and PALETTE) can be retrieved.
;
;     DATA_RANGE (Init,Get)
;       The range of data values to be mapped onto the indexed color
;       range. Data values outside the range are mapped to the nearest
;       end of the range. If not specified, DATA_RANGE is calculated
;       from the range of data values the first time the data values
;       are assigned.
;
;     DATA_VALUES (Init,*Get,Set)
;       A 2-D array of data (interpreted as floating point) to be
;       displayed. The DATA_VALUES keyword is accepted by GetProperty
;       if & only if the STORE_DATA property has been set.
;
;     PALETTE (Init,Get,Set)
;       A reference to the palette defining the byte-color mapping.
;
;     PLANE_CLASS (Init)
;       The name of the class for the colour plane object. The default
;       is 'MGHgrColorPlane'.
;
;     STORE_DATA (Init,Get):
;       This property determines whether the data values are stored
;       with the object. The default is 1 (values are stored) and it
;       can be overridden by setting STORE_DATA to 0 when the object
;       is created.
;
;###########################################################################
; Copyright (c) 1998-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1998-09:
;     Written.
;   Mark Hadfield, 2001-03:
;     Fixed bug: PARENT property was being returned by the embedded
;     color-plane atom, not by self. This lead to confusing problems
;     with the MGH_Player object.
;   Mark Hadfield, 2004-05:
;     Revised code to use IDL 6.0 features. Removed call to MGH_GET_PROPERTY.
;   Mark Hadfield, 2012-10:
;     Added LOGARITHMIC property.
;-
function MGHgrDensityPlane::Init, Values, $
     BYTE_RANGE=byte_range, $
     COLORSCALE=colorscale, $
     DESCRIPTION=description, $
     DATA_RANGE=data_range, $
     DATA_VALUES=data_values, $
     DATAX=datax, DATAY=datay, $
     LOGARITHMIC=logarithmic, NAME=name, $
     OMIT_MISSING=omit_missing, $
     PLANE_CLASS=plane_class, $
     REGISTER_PROPERTIES=register_properties, $
     STORE_DATA=store_data, $
     STYLE=style, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDLgrModel::Init(DESCRIPTION=description, NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'

   self.omit_missing = n_elements(omit_missing) gt 0 ? omit_missing : 1

   self.store_data = n_elements(store_data) gt 0 ? store_data : 1

   ;; Colour scaling
   if n_elements(colorscale) eq 1 && obj_valid(colorscale) then begin
      colorscale->GetProperty, $
           BYTE_RANGE=c_byte_range, DATA_RANGE=c_data_range, $
           LOGARITHMIC=c_logarithmic, PALETTE=c_palette
      if n_elements(byte_range) eq 0 then byte_range = c_byte_range
      if n_elements(data_range) eq 0 then data_range = c_data_range
      if n_elements(logarithmic) eq 0 then logarithmic = c_logarithmic
      if n_elements(palette) eq 0 then palette = c_palette
   endif

   if n_elements(byte_range) eq 2 then self.byte_range = byte_range

   if n_elements(plane_class) eq 0 then plane_class = 'MGHgrColorPlane'

   self.plane = obj_new(plane_class, PALETTE=palette, STYLE=style, _STRICT_EXTRA=extra)

   self->Add, self.plane

   if n_elements(data_values) eq 0 && n_elements(values) gt 0 then $
        data_values = values

   if n_elements(data_values) eq 0 then return, 1 ;;; Empty object

   dim = size(data_values, /DIMENSIONS)
   if n_elements(dim) ne 2 then message, 'DATA_VALUES must have two dimensions'

   if n_elements(data_range) eq 0 then begin
      data_range = mgh_minmax(data_values, /NAN)
      if data_range[1] eq data_range[0] then data_range += [-0.5,0.5]
   endif

   self.data_range = data_range
   self.logarithmic = keyword_set(logarithmic)

   if self.store_data then self.data_values = ptr_new(data_values)

   self->CalculateColors, data_values, color_values

   if self.omit_missing then missing_points = ~ finite(data_values)

   ;; I tried to catch errors thrown by the following SetProperty call
   ;; and re-issue them with some higher-level info. However this is
   ;; not working robustly yet. There are 2 issues:
   ;;   * An IDLgrSurface prints a message but does not abort or throw
   ;;   a catchable error.
   ;;   * Numeric error codes are unreliable. I need to look for
   ;;   message block and name descriptors.

;   catch, err
;   if err ne 0 then goto, skip_set

   self.plane->SetProperty, $
        DATAX=datax, DATAY=datay, COLOR_VALUES=color_values, $
        MISSING_POINTS=missing_points

;   skip_set: catch, /CANCEL
;   if err ne 0 then begin
;      case err of
;         -144: message, 'There is an inconsistency in the dimensions ' + $
;           'of the arguments supplied to the plane''s SetProperty method'
;         else: message, 'Caught unanticipated error '+strtrim(err,2)+' '+ $
;           !error_state.msg
;      endcase
;   endif

   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   self->MGHgrDensityPlane::SetProperty, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'NAME', NAME='Name', /STRING
      self->RegisterProperty, 'DESCRIPTION', NAME='Description', /STRING
      self->RegisterProperty, 'STYLE', NAME='Style', ENUMLIST=['Block','Interpolated']
      self->RegisterProperty, 'HIDE', NAME='Show', ENUMLIST=['True','False']
      self->RegisterProperty, 'ALPHA_CHANNEL', NAME='Opacity', /FLOAT, $
           VALID_RANGE=[0D0,1D0,0.05D0]
      self->RegisterProperty, 'ZVALUE', NAME='Z position', /FLOAT

   endif

   return, 1

END

; MGHgrDensityPlane::Cleanup
;
PRO MGHgrDensityPlane::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ptr_free, self.data_values

   self->IDLgrModel::Cleanup

end

; MGHgrDensityPlane::GetProperty
;
PRO MGHgrDensityPlane::GetProperty, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
     DATA_VALUES=data_values, LOGARITHMIC=logarithmic, $
     DESCRIPTION=description, OMIT_MISSING=omit_missing, $
     NAME=name, PARENT=parent, STORE_DATA=store_data, $
     STYLE=style, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, DESCRIPTION=description, NAME=name, PARENT=parent

   self.plane->GetProperty, STYLE=style, _STRICT_EXTRA=extra

   byte_range = self.byte_range

   data_range = self.data_range

   logarithmic = self.logarithmic

   omit_missing = self.omit_missing

   store_data = self.store_data

   if arg_present(data_values) then begin
      if ~ self.store_data then begin
         message, 'Data values cannot be retrieved because they have not ' + $
                  'been stored with the object.'
      endif
      data_values = *self.data_values
   endif

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

end

; MGHgrDensityPlane::SetProperty
;
pro MGHgrDensityPlane::SetProperty, $
     BYTE_RANGE=byte_range, $
     DATA_RANGE=data_range, $
     DATA_VALUES=data_values, $
     DESCRIPTION=description, NAME=name, $
     STYLE=style, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   recalc_position = 0B
   recalc_surface = 0B

   if n_elements(byte_range) gt 0 then begin
      self.byte_range = byte_range
      recalc_surface = 1B
   endif

   if n_elements(data_range) gt 0 then begin
      self.data_range = data_range
      recalc_surface = 1B
   endif

   if n_elements(data_values) gt 0 then begin
      recalc_surface = 1B
      if self.store_data then begin
         ptr_free, self.data_values
         self.data_values = ptr_new(data_values)
      endif
   endif

   if recalc_surface then begin
      if n_elements(data_values) eq 0 && ptr_valid(self.data_values) then $
           data_values = *self.data_values
      if n_elements(data_values) eq 0 then $
           message, 'The surface cannot be changed because data values are not available.'
      if ~ finite(self.data_range[0]) then $
           self.data_range = mgh_minmax(data_values, /NAN)
      self->CalculateColors, data_values, color_values
      if self.omit_missing then missing_points = ~ finite(data_values)
      self.plane->SetProperty, COLOR_VALUES=color_values, MISSING_POINTS=missing_points
   endif

   if n_elements(xcoord_conv) gt 0 then begin
      self.xcoord_conv = xcoord_conv
      recalc_position = 1B
   endif

   if n_elements(ycoord_conv) gt 0 then begin
      self.ycoord_conv = ycoord_conv
      recalc_position = 1B
   endif

   if n_elements(zcoord_conv) gt 0 then begin
      self.zcoord_conv = zcoord_conv
      recalc_position = 1B
   endif

   if n_elements(zvalue) gt 0 then begin
      self.zvalue = zvalue
      recalc_position = 1B
   endif

   if keyword_set(recalc_position) then self->Reposition

   self.plane->SetProperty, STYLE=style, _STRICT_EXTRA=extra

   self->IDLgrModel::SetProperty, DESCRIPTION=description, NAME=name

end

; MGHgrDensityPlane::CalculateColors
;
;   Given an array of numeric data values, return an array of indexed
;   colour values for the object's current colour scaling.
;
PRO MGHgrDensityPlane::CalculateColors, data_values, color_values

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, PALETTE=opal

   case 1B of
      self.byte_range[1] ne self.byte_range[0]: begin
         byte_range = self.byte_range
      end
      obj_valid(opal): begin
         opal->GetProperty, N_COLORS=n_colors
         byte_range = [0,n_colors-1]
      end
      else: begin
         byte_range = [0,255]
      end
   endcase
   
   if self.logarithmic then begin
      color_values = mgh_bytscl(alog10(data_values), $
                                BYTE_RANGE=byte_range, $
                                DATA_RANGE=alog10(self.data_range))
   endif else begin
      color_values = mgh_bytscl(data_values, $
                                BYTE_RANGE=byte_range, $
                                DATA_RANGE=self.data_range)
   endelse
   
end

; MGHgrDensityPlane::Reposition
;
pro MGHgrDensityPlane::Reposition

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->Reset

   self->Scale, self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->Translate, self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrDensityPlane__Define

pro MGHgrDensityPlane__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrDensityPlane, inherits IDLgrModel, $
         plane: obj_new(), byte_range: bytarr(2), $
         data_range: fltarr(2), logarithmic: 0B, $
         data_values: ptr_new(), $
         omit_missing: 0B, store_data: 0B, $
         xcoord_conv: fltarr(2), ycoord_conv: fltarr(2), zcoord_conv: fltarr(2)}

end

