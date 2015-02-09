; svn $Id$
;+
; CLASS NAME:
;   MGHgrDensityImage
;
; PURPOSE:
;   This class implements a density plot as an IDLgrImage.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   This class inherits from IDLgrImage.
;
; PROPERTIES:
;   The following properties are available, in addition to supported by IDLgrImage:
;
;     BYTE_RANGE (Init,Get)
;       The range of byte values to which the data range is to be mapped.
;
;     COLORSCALE (Init)
;       A reference to an object (like a color bar or another density
;       plane) from which default colour mapping information
;       (BYTE_RANGE, DATA_RANGE and PALETTE) can be retrieved.
;
;     DATA_RANGE (Init,Get)
;       The range of data values to be mapped onto the indexed color
;       range. Data values outside the range are mapped to the nearest
;       end of the range. If not specified, DATA_RANGE is calculated
;       from the range of data values the first time the data values
;       are assigned.
;
;     DATA_VALUES (Init,*Get,Set)
;       A 2-D array of data (interpreted as floating point) to be displayed.
;       The DATA_VALUES keyword is accepted by GetProperty if & only if the
;       STORE_DATA property has been set.
;
;     PALETTE (Init,Get,Set)
;       A reference to the palette defining the byte-colour mapping.
;
;     STORE_DATA (Init,Get):
;       This property determines whether the data values are stored
;       with the object. The default is 1 (values are stored); it
;       can be overridden by setting STORE_DATA to 0 when the object
;       is created.
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
;   Mark Hadfield, 1998-08:
;     Written.
;   Mark Hadfield, 2000-12:
;     Complete overhaul.
;   Mark Hadfield, 2004-05:
;     Revised code to use IDL 6.0 features. Removed call to MGH_GET_PROPERTY.
;-

; MGHgrDensityImage::Init

function MGHgrDensityImage::Init, Values, $
     BYTE_RANGE=byte_range, COLORSCALE=colorscale, DATA_RANGE=data_range, $
     DATA_VALUES=data_values, LOCATION=location, DIMENSIONS=dimensions, $
     PALETTE=palette, STORE_DATA=store_data, $
     STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Set object properties, keywords

   self.store_data = n_elements(store_data) gt 0 ? store_data : 1

   if n_elements(style) eq 0 then style = 0

   ;; Process values

   if n_elements(data_values) eq 0 then begin
      if n_elements(values) gt 0 then data_values = values
   endif

   if n_elements(data_values) eq 0 then $
        message, 'DATA_VALUES is undefined'

   if size(data_values, /N_DIMENSIONS) ne 2 then $
        message, 'DATA_VALUES must have two dimensions'

   dim = size(data_values, /DIMENSIONS)

   if n_elements(location) eq 0 then location = (style eq 0) ? [-0.5,-0.5] : [0,0]

   if n_elements(dimensions) eq 0 then dimensions = (style eq 0) ? dim+1 : dim

   ;; Set colour scaling

   if n_elements(colorscale) eq 1 then if obj_valid(colorscale) then begin
      colorscale->GetProperty, $
           BYTE_RANGE=c_byte_range, DATA_RANGE=c_data_range, PALETTE=c_palette
      if n_elements(byte_range) eq 0 then byte_range = c_byte_range
      if n_elements(data_range) eq 0 then data_range = c_data_range
      if n_elements(palette) eq 0 then palette = c_palette
   endif

   self.byte_range = $
        n_elements(byte_range) gt 0 ? byte_range : [0,0]
   self.data_range = $
        n_elements(data_range) gt 0 ? data_range : mgh_minmax(data_values, /NAN)

   if self.store_data then $
        self.data_values = ptr_new(data_values)

   self->CalculateColors, data_values, color_values

   ok = self->IDLgrImage::Init(DATA=color_values, LOCATION=location, $
                               DIMENSIONS=dimensions, PALETTE=palette, $
                               INTERPOLATE=style, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrImage'

   return, 1

end

; MGHgrDensityImage::GetProperty
;
pro MGHgrDensityImage::GetProperty, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, DATA_VALUES=data_values, $
     STORE_DATA=store_data, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->IDLgrImage::GetProperty, INTERPOLATE=style, _STRICT_EXTRA=extra

   byte_range = self.byte_range

   data_range = self.data_range

   store_data = self.store_data

   if arg_present(data_values) then begin
      if ~ ptr_valid(self.data_values) then begin
         message, 'Data values cannot be retrieved because they have not been ' + $
                  'stored with the object.'
      endif
      data_values = *self.data_values
   endif

end

; MGHgrDensityImage::SetProperty
;
pro MGHgrDensityImage::SetProperty, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, DATA_VALUES=data_values, $
     STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->Restyle, style

   recalc_colors = 0B

   if n_elements(byte_range) gt 0 then begin
      self.byte_range = byte_range
      recalc_colors = 1B
   endif

   if n_elements(data_range) gt 0 then begin
      self.data_range = data_range
      recalc_colors = 1B
   endif

   if n_elements(data_values) gt 0 then begin
      recalc_colors = 1B
      if self.store_data then begin
         ptr_free, self.data_values
         self.data_values = ptr_new(data_values)
      endif
   endif

   if recalc_colors then begin
      if n_elements(data_values) eq 0 then begin
         if ptr_valid(self.data_values) then begin
            data_values = *self.data_values
         endif
      endif
      if n_elements(data_values) eq 0 then $
           message, 'The surface cannot be changed because no data values are available.'
      if self.data_range[0] eq self.data_range[1] then $
           self.data_range = mgh_minmax(data_values, /NAN)
      self->CalculateColors, data_values, color_values
      self->IDLgrImage::SetProperty, DATA=color_values
   endif

   self->IDLgrImage::SetProperty, _STRICT_EXTRA=extra

end

; MGHgrDensityImage::CalculateColors
;
;   Given an array of numeric data values, return an array of indexed
;   colour values for the object's current colour scaling.
;
PRO MGHgrDensityImage::CalculateColors, data_values, color_values

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

   color_values = mgh_bytscl(data_values, BYTE_RANGE=byte_range, $
                             DATA_RANGE=self.data_range)

end

; MGHgrDensityImage::Restyle
;
pro MGHgrDensityImage::Restyle, style

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(style) eq 0 then return

   self->IDLgrImage::GetProperty, INTERPOLATE=ostyle

   if style ne ostyle then begin

      self->IDLgrImage::GetProperty, DATA=data, LOCATION=location, DIMENSIONS=dimensions

      n_dims = size(data, /N_DIMENSIONS)
      dims = size(data, /DIMENSIONS)
      if n_dims eq 3 then dims = dims[1:2]

      case fix(style)-fix(ostyle) of
         -1: begin
            del = dimensions/dims
            location = location - 0.5*del
            dimensions = dimensions + del
         end
         1: begin
            del = dimensions/(dims+1)
            location = location + 0.5*del
            dimensions = dimensions - del
         end
      endcase

      self->IDLgrImage::SetProperty, $
          INTERPOLATE=style, LOCATION=location, DIMENSIONS=dimensions

   endif

end

; MGHgrDensityImage__Define

pro MGHgrDensityImage__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrDensityImage, inherits IDLgrImage, data_range: fltarr(2), $
                 byte_range: bytarr(2), data_values: ptr_new(), store_data: 0B, $
                 style: 0B}

end

