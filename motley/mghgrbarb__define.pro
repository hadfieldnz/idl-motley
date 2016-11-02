;+
; NAME:
;   MGHgrBarb
;
; PURPOSE:
;   This class implements a set of wind/current barbs by joining up the
;   appropriate vertices in a single IDLgrPolyline.
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
;     BARB_COLORS (Init)
;       A vector of indexed or RGB colours (ie an [n] or [3,n] byte
;       array) specifying the colour of each barb.
;
;     DATAU, DATAV, DATAW (Init)
;       These specify the displacement of the tip of each barb from
;       its base in the x, y & z directions respectively. Optional,
;       default = 0.
;
;     DATAX, DATAY, DATAZ (Init)
;       Each of these  is a scalar or vector specifying the location
;       of the base of each barb. Optional, default = 0.
;
;     NORM_SCALE (Init, Get, Set)
;       A 3-element boolean vector specifying how the SCALE property is to
;       be interpreted for each direction. If NORM_SCALE is true for a
;       given direction, then the corresponding SCALE is interpreted
;       as a length in normalised coordinates, otherwise it is
;       interpreted as a length in data coordinates (the same ones as used
;       for DATA[X,Y,Z]).
;
;     SCALE (Init, Get, Set)
;       A 3-element double-precision vector specifying the length of a
;       unit velocity vector. This property can be (and often will be)
;       passed to Init or GetProperty as a scalar. Default is [1,1,1].
;
; TO DO:
;   - Direct appropriate keywords (e.g. HIDE) to the model rather than
;     the atom.
;   - Separate colour recalculation from dimension recalculation--you don't
;     really need to recalculate all the dimensions when the colour is changed.
;   - Sort out arrow head shape for anisotropic data coordinates.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1998-02:
;     Written as MGHgrBarb.
;   Mark Hadfield, 1999-05:
;     Added DATAZ & BARB_COLORS.
;   Mark Hadfield, 2000-07:
;     Substantially rewritten. The meaning of the SCALE keyword has
;     changed so that it is more logical and extensible to the Z
;     dimension--this is NOT BACKWARD-COMPATIBLE. Changed from a
;     subclass of IDLgrPolyline to a subclass of IDLgrModel (with
;     SELECT_TARGET set) in preparation for supporting symbols. Added
;     DATAW property for full 3D support.
;   Mark Hadfield, 2001-07:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2004-07:
;     - Renamed MGHgrBarb.
;     - Handling of scaling changed: the default is now to scale in data
;       coordinates and the NORM_SCALE keyword has been added to support
;       the original normalised scaling.
;   Mark Hadfield, 2007-09:
;     - Fixed bug: single precision calculations used in CalculateDimensions
;       methods when the object's DOUBLE property is set.
;     - Changed default value of DOUBLE property to 1.
;   Mark Hadfield, 2013-10:
;     - Implemented arrow heads. (Actually, the heads should be called "barbs" and
;       the shafts that I call barbs should be called "shafts".)
;   Mark Hadfield, 2016-01:
;     A couple of improvements to the CalculateDimensions method, made when developing the
;     same method for the new MGHgrEllipse class:
;     - Tweaked the code for laying out barb vertices: it should produce the same results
;       as before but it's a bit easier to follow.
;     - Made the code for providing default values more robust.
;   Mark Hadfield, 2016-04:
;     Added the HEAD_EXPONENT property, used along with HEAD_SIZE to control the size of
;     the arrow heads.
;-
function MGHgrBarb::Init, $
     BARB_COLORS=barb_colors, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, $
     DATAU=datau, DATAV=datav, DATAW=dataw, $
     DESCRIPTION=description, HIDE=hide, NAME=name, $
     NORM_SCALE=norm_scale, $
     REGISTER_PROPERTIES=register_properties, $
     HEAD_SIZE=head_size, HEAD_EXPONENT=head_exponent, SHOW_HEAD=show_head, $
     SCALE=scale, SYMBOL=symbol, $
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

   self.barb_atom = obj_new('IDLgrPolyline', /DOUBLE, _STRICT_EXTRA=extra)
   self->Add, self.barb_atom

   self.head_atom = obj_new('IDLgrPolyline', /DOUBLE, _STRICT_EXTRA=extra)
   self->Add, self.head_atom

   self.symbol_atom = obj_new('IDLgrPolyline', LINESTYLE=6)
   self->Add, self.symbol_atom

   ;; Set defaults

   self.norm_scale = !false

   self.scale = 1.0

   self.show_head = !false
   self.head_size = 0.3
   self.head_exponent = 1.0

   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   ;; Pass all remaining arguments to SetProperty. (So why not pass
   ;; them all via extra?)

   self->SetProperty, BARB_COLORS=barb_colors, $
        DATAU=datau, DATAV=datav, DATAW=dataw, $
        DATAX=datax, DATAY=datay, DATAZ=dataz, $
        NORM_SCALE=norm_scale, SCALE=scale, SYMBOL=symbol, $
        HEAD_SIZE=head_size, HEAD_EXPONENT=head_exponent, SHOW_HEAD=show_head, $
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

; MGHgrBarb::Cleanup
;
pro MGHgrBarb::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   ptr_free, self.barb_colors

   ptr_free, self.datax
   ptr_free, self.datay
   ptr_free, self.dataz

   ptr_free, self.datau
   ptr_free, self.datav
   ptr_free, self.dataw

   self->IDLgrModel::Cleanup

end

; MGHgrBarb::GetProperty
;
pro MGHgrBarb::GetProperty, $
     DATAU=datau, DATAV=datav, DATAW=dataw, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, $
     DESCRIPTION=description, HIDE=hide, NAME=name, $
     NORM_SCALE=norm_scale, $
     PARENT=parent, SCALE=scale, SYMBOL=symbol, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name, PARENT=parent

   self.barb_atom->GetProperty, _STRICT_EXTRA=extra

   if arg_present(datax) then $
        datax = ptr_valid(self.datax) ? *self.datax : 0

   if arg_present(datay) then $
        datay = ptr_valid(self.datay) ? *self.datay : 0

   if arg_present(dataz) then $
        dataz = ptr_valid(self.dataz) ? *self.dataz : 0

   if arg_present(datau) then $
        datau = ptr_valid(self.datau) ? *self.datau : 0

   if arg_present(datav) then $
        datav = ptr_valid(self.datav) ? *self.datav : 0

   if arg_present(dataw) then $
        dataw = ptr_valid(self.dataw) ? *self.dataw : 0

   norm_scale = self.norm_scale

   scale = self.scale

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   if arg_present(symbol) then self.symbol_atom->GetProperty, SYMBOL=symbol

end

; MGHgrBarb::SetProperty
;
pro MGHgrBarb::SetProperty, $
     BARB_COLORS=barb_colors, $
     DATAU=datau, DATAV=datav, DATAW=dataw, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, $
     DESCRIPTION=description, HIDE=hide, NAME=name, $
     NORM_SCALE=norm_scale, SCALE=scale, SYMBOL=symbol, $
     HEAD_SIZE=head_size, HEAD_EXPONENT=head_exponent, SHOW_HEAD=show_head, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.barb_atom->SetProperty, _STRICT_EXTRA=extra

   recalc = !false

   if n_elements(barb_colors) gt 0 then begin
      recalc = !true
      ptr_free, self.barb_colors
      self.barb_colors = ptr_new(barb_colors)
   endif

   if n_elements(datax) gt 0 then begin
      recalc = !true
      ptr_free, self.datax
      self.datax = ptr_new(datax)
   endif

   if n_elements(datay) gt 0 then begin
      recalc = !true
      ptr_free, self.datay
      self.datay = ptr_new(datay)
   endif

   if n_elements(dataz) gt 0 then begin
      recalc = !true
      ptr_free, self.dataz
      self.dataz = ptr_new(dataz)
   endif

   if n_elements(datau) gt 0 then begin
      recalc = !true
      ptr_free, self.datau
      self.datau = ptr_new(datau)
   endif

   if n_elements(datav) gt 0 then begin
      recalc = !true
      ptr_free, self.datav
      self.datav = ptr_new(datav)
   endif

   if n_elements(dataw) gt 0 then begin
      recalc = !true
      ptr_free, self.dataw
      self.dataw = ptr_new(dataw)
   endif

   if n_elements(norm_scale) gt 0 then begin
      recalc = !true
      if n_elements(norm_scale) eq 1 then begin
         self.norm_scale = norm_scale[0]   ;;; Assign single value to all 3 elements
      endif else begin
         self.norm_scale = norm_scale   ;;; Assign vector to vector
      endelse
   endif

   if n_elements(scale) gt 0 then begin
      recalc = !true
      if n_elements(scale) eq 1 then begin
         self.scale = scale[0]   ;;; Assign single value to all 3 elements
      endif else begin
         self.scale = scale   ;;; Assign vector to vector
      endelse
   endif

   if n_elements(symbol) gt 0 then begin
      recalc = !true
      self.symbol_atom->SetProperty, SYMBOL=symbol
   endif

   if n_elements(head_size) gt 0 then begin
     recalc = !true
     self.head_size = head_size
   endif

   if n_elements(head_exponent) gt 0 then begin
      recalc = !true
      self.head_exponent = head_exponent
   endif

   if n_elements(show_head) gt 0 then begin
     recalc = !true
     self.show_head = show_head
   endif

   if n_elements(xcoord_conv) gt 0 then begin
      recalc = !true
      self.xcoord_conv = xcoord_conv
   endif

   if n_elements(ycoord_conv) gt 0 then begin
      recalc = !true
      self.ycoord_conv = ycoord_conv
   endif

   if n_elements(zcoord_conv) gt 0 then begin
      recalc = !true
      self.zcoord_conv = zcoord_conv
   endif

   if recalc then self->CalculateDimensions

end

; MGHgrBarb::CalculateDimensions
;
pro MGHgrBarb::CalculateDimensions

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Get data and/or provide defaults.

   if ptr_valid(self.datax) then datax = *self.datax
   if ptr_valid(self.datay) then datay = *self.datay
   if ptr_valid(self.dataz) then dataz = *self.dataz

   if ptr_valid(self.datau) then datau = *self.datau
   if ptr_valid(self.datav) then datav = *self.datav
   if ptr_valid(self.dataw) then dataw = *self.dataw

   ;; Calculate number of barbs

   n_barb = $
      n_elements(datax) > n_elements(datay) > n_elements(dataz) > $
      n_elements(datau) > n_elements(datav) > n_elements(dataw)

   ;; Provide default values

   use_z = n_elements(dataz) gt 0 || n_elements(dataw) gt 0

   if n_elements(datax) eq 0 then datax = replicate(0, n_barb)
   if n_elements(datay) eq 0 then datay = replicate(0, n_barb)

   if n_elements(datau) eq 0 then datau = replicate(0, n_barb)
   if n_elements(datav) eq 0 then datav = replicate(0, n_barb)

   if use_z then begin
      if n_elements(dataz) eq 0 then dataz = replicate(0, n_barb)
      if n_elements(dataw) eq 0 then dataw = replicate(0, n_barb)
   endif

   ;; Determine which barbs have good data

   if use_z then begin
      l_barb_good = where(finite(datax) and finite(datay) and finite(dataz) and $
         finite(datau) and finite(datav) and finite(dataw), n_barb_good)
   endif else begin
      l_barb_good = where(finite(datax) and finite(datay) and $
         finite(datau) and finite(datav), n_barb_good)
   endelse

   ;; Calculate velocity scale in data coordinates

   data_scale = self.scale
   if self.norm_scale[0] then data_scale[0] /= self.xcoord_conv[1]
   if self.norm_scale[1] then data_scale[1] /= self.ycoord_conv[1]
   if self.norm_scale[2] then data_scale[2] /= self.zcoord_conv[1]

   ;; Create & fill a polyline vertex array for the barbs

   self->GetProperty, DOUBLE=double

   if use_z then begin
      vert = make_array(3, 2*n_barb, DOUBLE=double)
      vert[0,2*lindgen(n_barb)] = datax
      vert[1,2*lindgen(n_barb)] = datay
      vert[2,2*lindgen(n_barb)] = dataz
      vert[0,2*lindgen(n_barb)+1] = datax + datau*data_scale[0]
      vert[1,2*lindgen(n_barb)+1] = datay + datav*data_scale[1]
      vert[2,2*lindgen(n_barb)+1] = dataz + dataw*data_scale[1]
   endif else begin
      vert = make_array(2, 2*n_barb, DOUBLE=double)
      vert[0,2*lindgen(n_barb)] = datax
      vert[1,2*lindgen(n_barb)] = datay
      vert[0,2*lindgen(n_barb)+1] = datax + datau*data_scale[0]
      vert[1,2*lindgen(n_barb)+1] = datay + datav*data_scale[1]
   endelse

   ;; Handle missing vertex values. An IDLgrPolyline does not permit
   ;; non-finite vertices so set them to 0 (the associated line segments
   ;; will be omitted from the connectivity array).

   vert[where(~ finite(vert), /NULL)] = 0

   ;; Specify connections between polyline vertices.

   conn = lonarr(3*n_barb)

   if n_barb_good lt n_barb then begin
      for g=0,n_barb_good-1 do begin
         i = l_barb_good[g]
         conn[3*g]   = 2
         conn[3*g+1] = 2*i
         conn[3*g+2] = 2*i+1
      endfor
      conn[3*n_barb_good] = -1 ; Terminate the list of polylines
   endif else begin
      conn[3*lindgen(n_barb)  ] = 2
      conn[3*lindgen(n_barb)+1] = 2*lindgen(n_barb)
      conn[3*lindgen(n_barb)+2] = 2*lindgen(n_barb)+1
   endelse

   ;; Specify vertex colours

   if ptr_valid(self.barb_colors) then begin

      barb_colors = *(self.barb_colors)

      dims = size(barb_colors, /DIMENSIONS)
      case size(barb_colors, /N_DIMENSIONS) of
         1: begin
            vert_colors = bytarr(2, dims[0])
            vert_colors[0,*] = barb_colors
            vert_colors = reform(vert_colors, 2*dims[0])
         end
         2: begin
            if dims[0] ne 3 then $
               message, 'The inner dimension of BARB_COLORS must be 3'
            vert_colors = bytarr(3, 2, dims[1])
            vert_colors[*,0,*] = barb_colors
            vert_colors = reform(vert_colors, 3, 2*dims[1])
         end
      endcase

   endif else begin

      vert_colors = -1

   endelse

   ;; Set up barb polyline.

   self.barb_atom->SetProperty, DATA=vert, POLYLINES=conn, VERT_COLORS=vert_colors

   ;; Set up symbol polyline (if any) using the a subset (0, 2, 4, ...) of
   ;; the barb polyline vertices.  If a symbol is added then deleted, then the
   ;; symbol polyline vertices hang around but they're invisible.

   self.symbol_atom->GetProperty, SYMBOL=symbol

   if n_elements(symbol) gt 0 then $
      self.symbol_atom->SetProperty, DATA=vert[*,2*lindgen(n_barb)]

   mgh_undefine, vert, conn, vert_colors

   ;; Set up the head

   if self.show_head then begin

      ;; Create & fill a polyline vertex array for the head

      ;; Heads are drawn on 3D arrays but are in the xy plane only

      self->GetProperty, DOUBLE=double

      hs = self.head_size
      he = self.head_exponent

      lenu = datau*data_scale[0]
      lenv = datav*data_scale[1]
      if use_z then lenw = dataw*data_scale[2]

      ;; Length and angle of arrows
      len = sqrt(lenu*lenu+lenv*lenv)
      ang = atan(lenv, lenu)

      ;; Angle of head lines (actually I think these are the things
      ;; I should call barbs)
      a1 = 150*!dtor + ang
      a2 = 210*!dtor + ang

      if use_z then begin
         vert = make_array(3, 3*n_barb, DOUBLE=double)
         vert[9*lindgen(n_barb)  ] = datax + lenu + hs*(len^he)*cos(a1)
         vert[9*lindgen(n_barb)+1] = datay + lenv + hs*(len^he)*sin(a1)
         vert[9*lindgen(n_barb)+2] = dataz + lenw
         vert[9*lindgen(n_barb)+3] = datax + lenu
         vert[9*lindgen(n_barb)+4] = datay + lenv
         vert[9*lindgen(n_barb)+5] = dataz + lenw
         vert[9*lindgen(n_barb)+6] = datax + lenu + hs*(len^he)*cos(a2)
         vert[9*lindgen(n_barb)+7] = datay + lenv + hs*(len^he)*sin(a2)
         vert[9*lindgen(n_barb)+8] = dataz + lenw
      endif else begin
         vert = make_array(2, 3*n_barb, DOUBLE=double)
         vert[6*lindgen(n_barb)  ] = datax + lenu + hs*(len^he)*cos(a1)
         vert[6*lindgen(n_barb)+1] = datay + lenv + hs*(len^he)*sin(a1)
         vert[6*lindgen(n_barb)+2] = datax + lenu
         vert[6*lindgen(n_barb)+3] = datay + lenv
         vert[6*lindgen(n_barb)+4] = datax + lenu + hs*(len^he)*cos(a2)
         vert[6*lindgen(n_barb)+5] = datay + lenv + hs*(len^he)*sin(a2)
      endelse

      ;; Handle missing vertex values. An IDLgrPolyline does not permit
      ;; non-finite vertices so set them to 0. The associated line segments
      ;; will be omitted from the connectivity array below.

      vert[where(~ finite(vert), /NULL)] = 0

      ;; Specify connections between polyline vertices.

      conn = lonarr(4*n_barb)

      if n_barb_good lt n_barb then begin
         for g=0,n_barb_good-1 do begin
            i = l_barb_good[g]
            conn[4*g]   = 3
            conn[4*g+1] = 3*i
            conn[4*g+2] = 3*i+1
            conn[4*g+3] = 3*i+2
         endfor
         conn[4*n_barb_good] = -1 ; Terminate the list of polylines
      endif else begin
         conn[4*lindgen(n_barb)  ] = 3
         conn[4*lindgen(n_barb)+1] = 3*lindgen(n_barb)
         conn[4*lindgen(n_barb)+2] = 3*lindgen(n_barb)+1
         conn[4*lindgen(n_barb)+3] = 3*lindgen(n_barb)+2
      endelse

      ;; Specify vertex colours

      if ptr_valid(self.barb_colors) then begin

         barb_colors = *(self.barb_colors)

         dims = size(barb_colors, /DIMENSIONS)
         case size(barb_colors, /N_DIMENSIONS) of
            1: begin
               vert_colors = bytarr(3, dims[0])
               vert_colors[0,*] = barb_colors
               vert_colors[1,*] = barb_colors
               vert_colors = reform(vert_colors, 3*dims[0])
            end
            2: begin
               if dims[0] ne 3 then $
                  message, 'The inner dimension of BARB_COLORS must be 3'
               vert_colors = bytarr(3, 3, dims[1])
               vert_colors[*,0,*] = barb_colors
               vert_colors[*,1,*] = barb_colors
               vert_colors = reform(vert_colors, 3, 3*dims[1])
            end
         endcase

      endif else begin

         vert_colors = -1

      endelse

      ;; Set up head polyline.

      self.head_atom->SetProperty, DATA=vert, POLYLINES=conn, VERT_COLORS=vert_colors

      mgh_undefine, vert, conn, vert_colors

   endif

   ;; Scale & translate the model

   self->IDLgrModel::Reset

   self->IDLgrModel::Scale, $
      self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->IDLgrModel::Translate, $
      self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrBarb__Define

pro MGHgrBarb__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrBarb, inherits IDLgrModel, $
         barb_atom: obj_new(), barb_colors: ptr_new(), $
         head_atom: obj_new(), symbol_atom: obj_new(), $
         scale: dblarr(3), norm_scale: boolarr(3), $
         datax: ptr_new(), datay: ptr_new(), dataz: ptr_new(), $
         datau: ptr_new(), datav: ptr_new(), dataw: ptr_new(), $
         head_size: 0.0, head_exponent: 0.0, show_head: !false, $
         xcoord_conv: dblarr(2), $
         ycoord_conv: dblarr(2), $
         zcoord_conv: dblarr(2)}

end
