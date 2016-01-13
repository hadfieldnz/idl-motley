;+
; NAME:
;   MGHgrEllipse
;
; PURPOSE:
;   This class implements a set of ellipse plots (eg. tidal ellipses or
;   variance ellipses) by joining up the appropriate vertices in a single IDLgrPolyline.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASS:
;   IDLgrModel
;
; PROPERTIES:
;   Properties not recognised by this class are passed to the barb
;   object (an IDLgrPolyline). The following properties are supported
;   directly
;
;     ELLIPSE_COLORS (Init)
;       A vector of indexed or RGB colours (ie an [n] or [3,n] byte
;       array) specifying the colour of each barb.
;
;     DATA_SMA, DATA_ECC, DATA_INC (Init)
;       These specify the size/shape parameters (semi-major axis,
;       eccentricity and inclination) for each ellipse. The ellipses
;       are drawn in the (x, y) plane. Inclination follows the mathematical
;       convention.
;
;     DATAX, DATAY, DATAZ (Init)
;       Each of these  is a scalar or vector specifying the location
;       of the base of each barb. Optional, default = 0.
;
;     NORM_SCALE (Init, Get, Set)
;       A 2-element boolean vector specifying how the SCALE property is to
;       be interpreted for each direction. If NORM_SCALE is true for a
;       given direction, then the corresponding SCALE is interpreted
;       as a length in normalised coordinates, otherwise it is
;       interpreted as a length in data coordinates (the same ones as used
;       for DATA[X,Y,Z]).
;
;     SCALE (Init, Get, Set)
;       A 2-element double-precision vector specifying the radius of a
;       unit circle. This property can be (and often will be)
;       passed to Init or GetProperty as a scalar. Default is [1,1].
;
;     N_VERTEX (Init, Get, Set)
;       The number of vertices used to draw each ellipse. The default is 48.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2016-01:
;     Written, based on MGHgrBarb.
;-
function MGHgrEllipse::Init, $
     ELLIPSE_COLORS=ellipse_colors, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, $
     DATA_SMA=data_sma, DATA_ECC=data_ecc, DATA_INC=data_inc, $
     DESCRIPTION=description, HIDE=hide, NAME=name, $
     NORM_SCALE=norm_scale, N_VERTEX=n_vertex, $
     SCALE=scale, $
     REGISTER_PROPERTIES=register_properties, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Initialise the model

   ok = self->IDLgrModel::Init(DESCRIPTION=description, HIDE=hide, $
                               NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'

   ;; Create child objects

   self.ellipse_atom = obj_new('IDLgrPolyline', /DOUBLE, _STRICT_EXTRA=extra)
   self->Add, self.ellipse_atom

   ;; Set defaults

   self.norm_scale = 0
   self.scale = 1

   self.n_vertex = 49

   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   ;; Pass all remaining arguments to SetProperty. (So why not pass
   ;; them all via extra?)

   self->SetProperty, ELLIPSE_COLORS=ellipse_colors, $
      DATAX=datax, DATAY=datay, DATAZ=dataz, $
      DATA_SMA=data_sma, DATA_ECC=data_ecc, DATA_INC=data_inc, $
      NORM_SCALE=norm_scale, N_VERTEX=n_vertex, $
      SCALE=scale, $
      XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, $
      ZCOORD_CONV=zcoord_conv, _STRICT_EXTRA=extra

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'NAME', NAME='Name', /STRING
      self->RegisterProperty, 'DESCRIPTION', NAME='Description', /STRING
      self->RegisterProperty, 'LINESTYLE', NAME='Line style', /LINESTYLE
      self->RegisterProperty, 'THICK', NAME='Line thickness', /THICKNESS

   endif

   return, 1

end

; MGHgrEllipse::Cleanup
;
pro MGHgrEllipse::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ptr_free, self.ellipse_colors

   ptr_free, self.datax
   ptr_free, self.datay
   ptr_free, self.dataz

   ptr_free, self.data_sma
   ptr_free, self.data_ecc
   ptr_free, self.data_inc

   self->IDLgrModel::Cleanup

end

; MGHgrEllipse::GetProperty
;
pro MGHgrEllipse::GetProperty, $
   DATAX=datax, DATAY=datay, DATAZ=dataz, $
   DATA_SMA=data_sma, DATA_ECC=data_ecc, DATA_INC=data_inc, $
   DESCRIPTION=description, HIDE=hide, NAME=name, $
   NORM_SCALE=norm_scale, N_VERTEX=n_vertex, $
   PARENT=parent, SCALE=scale, $
   XCOORD_CONV=xcoord_conv, $
   YCOORD_CONV=ycoord_conv, $
   ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name, PARENT=parent

   self.ellipse_atom->GetProperty, _STRICT_EXTRA=extra

   if arg_present(datax) then $
        datax = ptr_valid(self.datax) ? *self.datax : 0

   if arg_present(datay) then $
        datay = ptr_valid(self.datay) ? *self.datay : 0

   if arg_present(dataz) then $
        dataz = ptr_valid(self.dataz) ? *self.dataz : 0

   if arg_present(data_sma) then $
        data_sma = ptr_valid(self.data_sma) ? *self.data_sma : 0

   if arg_present(data_ecc) then $
        data_ecc = ptr_valid(self.data_ecc) ? *self.data_ecc : 0

   if arg_present(data_inc) then $
        data_inc = ptr_valid(self.data_inc) ? *self.data_inc : 0

   n_vertex = self.n_vertex

   norm_scale = self.norm_scale

   scale = self.scale

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

end

; MGHgrEllipse::SetProperty
;
pro MGHgrEllipse::SetProperty, $
     ELLIPSE_COLORS=ellipse_colors, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, $
     DATA_SMA=data_sma, DATA_ECC=data_ecc, DATA_INC=data_inc, $
     DESCRIPTION=description, HIDE=hide, NAME=name, $
     NORM_SCALE=norm_scale, SCALE=scale, $
     N_VERTEX=n_vertex, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.ellipse_atom->SetProperty, _STRICT_EXTRA=extra

   recalc = 0B

   if n_elements(ellipse_colors) gt 0 then begin
      recalc = 1B
      ptr_free, self.ellipse_colors
      self.ellipse_colors = ptr_new(ellipse_colors)
   endif

   if n_elements(datax) gt 0 then begin
      recalc = 1B
      ptr_free, self.datax
      self.datax = ptr_new(datax)
   endif

   if n_elements(datay) gt 0 then begin
      recalc = 1B
      ptr_free, self.datay
      self.datay = ptr_new(datay)
   endif

   if n_elements(dataz) gt 0 then begin
      recalc = 1B
      ptr_free, self.dataz
      self.dataz = ptr_new(dataz)
   endif

   if n_elements(data_sma) gt 0 then begin
      recalc = 1B
      ptr_free, self.data_sma
      self.data_sma = ptr_new(data_sma)
   endif

   if n_elements(data_ecc) gt 0 then begin
      recalc = 1B
      ptr_free, self.data_ecc
      self.data_ecc = ptr_new(data_ecc)
   endif

   if n_elements(data_inc) gt 0 then begin
      recalc = 1B
      ptr_free, self.data_inc
      self.data_inc = ptr_new(data_inc)
   endif

   if n_elements(norm_scale) gt 0 then begin
      recalc = 1B
      case n_elements(norm_scale) of
         1: self.norm_scale = norm_scale[0]   ;;; Assign single value to both elements
         else: self.norm_scale = norm_scale   ;;; Assign vector to vector
      endcase
   endif

   if n_elements(scale) gt 0 then begin
      recalc = 1B
      case n_elements(scale) of
         1: self.scale = scale[0]   ;;; Assign single value to all 3 elements
         else: self.scale = scale   ;;; Assign vector to vector
      endcase
   endif

   if n_elements(n_vertex) gt 0 then begin
     recalc = 1B
     self.n_vertex = n_vertex
   endif

   if n_elements(xcoord_conv) gt 0 then begin
      recalc = 1B
      self.xcoord_conv = xcoord_conv
   endif

   if n_elements(ycoord_conv) gt 0 then begin
      recalc = 1B
      self.ycoord_conv = ycoord_conv
   endif

   if n_elements(zcoord_conv) gt 0 then begin
      recalc = 1B
      self.zcoord_conv = zcoord_conv
   endif

   if recalc then self->CalculateDimensions

end

; MGHgrEllipse::CalculateDimensions
;
pro MGHgrEllipse::CalculateDimensions

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Get data and/or provide defaults.

   if ptr_valid(self.datax) then datax = *self.datax
   if ptr_valid(self.datay) then datay = *self.datay
   if ptr_valid(self.dataz) then dataz = *self.dataz

   if ptr_valid(self.data_sma) then data_sma = *self.data_sma
   if ptr_valid(self.data_ecc) then data_ecc = *self.data_ecc
   if ptr_valid(self.data_inc) then data_inc = *self.data_inc

   ;; Calculate number of ellipses

   n_ellipse = $
      n_elements(datax) > n_elements(datay) > n_elements(dataz) > $
      n_elements(data_sma) > n_elements(data_ecc) > n_elements(data_inc)

   ;; Provide default values

   if n_elements(datax) eq 0 then datax = replicate(0, n_ellipse)
   if n_elements(datay) eq 0 then datay = replicate(0, n_ellipse)
   if n_elements(dataz) eq 0 then dataz = replicate(0, n_ellipse)

   if n_elements(data_sma) eq 0 then data_sma = replicate(0, n_ellipse)
   if n_elements(data_ecc) eq 0 then data_ecc = replicate(0, n_ellipse)
   if n_elements(data_inc) eq 0 then data_inc = replicate(0, n_ellipse)

   ;; Check data are conformal

   if n_elements(datax) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'datax'
   if n_elements(datay) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'datay'
   if n_elements(dataz) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'dataz'

   if n_elements(data_sma) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_sma'
   if n_elements(data_ecc) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_ecc'
   if n_elements(data_inc) ne n_ellipse then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_inc'

   ;; Calculate velocity scale in data coordinates

   data_scale = self.scale
   if self.norm_scale[0] then data_scale[0] /= self.xcoord_conv[1]
   if self.norm_scale[1] then data_scale[1] /= self.ycoord_conv[1]

   ;; Determine which ellipses have good data

   l_ellipse_good = where(finite(datax) and finite(datay) and finite(dataz) and $
                          finite(data_sma) and finite(data_ecc) and finite(data_inc), n_ellipse_good)

   ;; Create & fill a polyline vertex array for the ellipses

   self->GetProperty, DOUBLE=double, N_VERTEX=n_vertex

   vert = make_array([3,n_vertex,n_ellipse], DOUBLE=double)
   for i_ellipse=0,n_ellipse-1 do begin
      xy = mgh_ellipse(data_sma[i_ellipse], data_ecc[i_ellipse], data_inc[i_ellipse], N_VERTEX=n_vertex)
      vert[0,*,i_ellipse] = datax[i_ellipse] + xy[0,*]*data_scale[0]
      vert[1,*,i_ellipse] = datay[i_ellipse] + xy[1,*]*data_scale[1]
      vert[2,*,i_ellipse] = dataz[i_ellipse]
   endfor

   ;; Handle missing vertex values. An IDLgrPolyline does not permit
   ;; non-finite vertices so set them to 0 (the associated line segments
   ;; will be omitted from the connectivity array.

   vert[where(~finite(vert), /NULL)] = 0

   ;; Specify connections between polyline vertices.

   conn = lonarr((n_vertex+1)*n_ellipse)

   if n_ellipse_good lt n_ellipse then begin
      for i_good=0,n_ellipse_good-1 do begin
         i0 = (n_vertex+1)*i_good
         conn[i0] = n_vertex
         conn[i0+1:i0+n_vertex] = (l_ellipse_good[i_good]*n_vertex)+lindgen(n_vertex)
      endfor
      conn[(n_vertex+1)*n_ellipse_good] = -1 ; Terminate the list of polylines
   endif else begin
      for i_ellipse=0,n_ellipse-1 do begin
         i0 = (n_vertex+1)*i_ellipse
         conn[i0] = n_vertex
         conn[i0+1:i0+n_vertex] = (i_ellipse*n_vertex)+lindgen(n_vertex)
      endfor
   endelse

   ;; Specify vertex colours

   if ptr_valid(self.ellipse_colors) then begin

      ellipse_colors = *(self.ellipse_colors)

      dim_colors = size(ellipse_colors, /DIMENSIONS)
      case size(ellipse_colors, /N_DIMENSIONS) of
         1: begin
            n_colors = dim_colors[0]
            vert_colors = bytarr(n_vertex, n_colors)
            for i_vertex=0,n_vertex-1 do $
               vert_colors[i_vertex,*] = ellipse_colors
            vert_colors = reform(vert_colors, n_vertex*n_colors)
         end
         2: begin
            if dim_colors[0] ne 3 then $
               message, 'The inner dimension of ELLIPSE_COLORS must be 3'
            n_colors = dim_colors[1]
            vert_colors = bytarr(3, n_vertex, n_colors)
            for i_vertex=0,n_vertex-1 do $
               vert_colors[*,i_vertex,*] = ellipse_colors
            vert_colors = reform(vert_colors, [3,n_vertex*n_colors])
         end
      endcase

   endif else begin

      vert_colors = -1

   endelse

   ;; Set up ellipse polyline.

   self.ellipse_atom->SetProperty, DATA=vert, POLYLINES=conn, VERT_COLORS=vert_colors

   mgh_undefine, vert, conn, vert_colors

   ;; Scale & translate the model

   self->IDLgrModel::Reset

   self->IDLgrModel::Scale, $
      self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->IDLgrModel::Translate, $
      self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrEllipse__Define

pro MGHgrEllipse__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrEllipse, inherits IDLgrModel, $
         n_vertex: 0L, $
         ellipse_atom: obj_new(), ellipse_colors: ptr_new(), $
         symbol_atom: obj_new(), scale: dblarr(2), norm_scale: bytarr(2), $
         datax: ptr_new(), datay: ptr_new(), dataz: ptr_new(), $
         data_sma: ptr_new(), data_ecc: ptr_new(), data_inc: ptr_new(), $
         xcoord_conv: dblarr(2), $
         ycoord_conv: dblarr(2), $
         zcoord_conv: dblarr(2)}

end
