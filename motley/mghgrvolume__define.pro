; svn $Id$
;+
; CLASS NAME:
;   MGHgrVolume
;
; PURPOSE:
;   An IDLgrVolume inside a user-friendly (?) wrapper.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   This class inherits from IDLgrModel.
;
; PROPERTIES:
;   The following properties are supported:
;
;       LOCATION (Init,Get,Set)
;           Location of the lower left corner of the rectangle in data units.
;
;       DIMENSIONS (Init,Get,Set)
;           Dimensions of the volume in data units.
;
;       XCOORD_CONV (Init,Get,Set)
;       YCOORD_CONV (Init,Get,Set)
;       ZCOORD_CONV (Init,Get,Set)
;           Coordinate transformations specifying the relationship between
;           normalised & data units.
;
;       XRANGE (Get)
;       YRANGE (Get)
;       ZRANGE (Get)
;           Position of the extremes of the object in data units. ZRANGE is
;           not finalised until the object is drawn.
;
; METHODS:
;   The usual.
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
;   Mark Hadfield, 2004-07:
;     Updated to support property-sheet functionality.
;-

; MGHgrVolume::Init

function MGHgrVolume::Init, vol0, vol1, vol2, vol3, $
     DESCRIPTION=description, DIMENSIONS=dimensions, $
     HIDE=hide, LOCATION=location, NAME=name, $
     REGISTER_PROPERTIES=register_properties, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDLgrModel::Init(DESCRIPTION=description, HIDE=hide, $
                               NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'

   ;; Create child objects

   self.normal_node = obj_new('IDLgrModel')

   case n_params() of
      0: self.volume = obj_new('IDLgrVolume', _EXTRA=extra)
      1: self.volume = obj_new('IDLgrVolume', vol0, _EXTRA=extra)
      2: self.volume = obj_new('IDLgrVolume', vol0, vol1, _EXTRA=extra)
      3: self.volume = obj_new('IDLgrVolume', vol0, vol1, vol2, _EXTRA=extra)
      4: self.volume = obj_new('IDLgrVolume', vol0, vol1, vol2, vol3, _EXTRA=extra)
   endcase

   ;; Set up the object hierarchy

   self->Add, self.normal_node

   self.normal_node->Add, self.volume

   ;; Set defaults for location, dimensions & coordinate conversions.
   ;; Default location & dimensions are calculated from the object's
   ;; [X,Y,Z]RANGE

   self->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

   self.dimensions = [xrange[1]-xrange[0],yrange[1]-yrange[0],zrange[1]-zrange[0]]
   self.location = [xrange[0],yrange[0],zrange[0]]
   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   ;; Set location, dimensions & coordinate conversions, if applicable

   self->SetProperty, $
        DIMENSIONS=dimensions, LOCATION=location, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   ;; Register properties

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'NAME', NAME='Name', /STRING
      self->RegisterProperty, 'DESCRIPTION', NAME='Description', /STRING
      self->RegisterProperty, 'HIDE', NAME='Show', ENUMLIST=['True','False']
      self->RegisterProperty, 'AMBIENT', NAME='Ambient Color', /COLOR
      self->RegisterProperty, 'COMPOSITE_FUNCTION', NAME='Composite', $
           ENUMLIST=['Alpha blending','Max intensity proj','Alpha sum','Average intensity']
      self->RegisterProperty, 'INTERPOLATE', NAME='Interpolation', $
           ENUMLIST=['Nearest neighbor','Trilinear']

   end

   return, 1

END

; MGHgrVolume::CalculateDimensions
;
pro MGHgrVolume::CalculateDimensions

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

    self.volume->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

    if xrange[1] le xrange[0] then xrange[1] = xrange[0] + 1
    if yrange[1] le yrange[0] then yrange[1] = yrange[0] + 1
    if zrange[1] le zrange[0] then zrange[1] = zrange[0] + 1

    self.normal_node->Reset

    self.normal_node->Scale, self.dimensions[0]/(xrange[1]-xrange[0]), self.dimensions[1]/(yrange[1]-yrange[0]), self.dimensions[2]/(zrange[1]-zrange[0])

    self.normal_node->Translate, self.location[0]-xrange[0], self.location[1]-yrange[0], self.location[2]-zrange[0]

    self->Reset

    self->Scale, self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

    self->Translate, self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end


; MGHgrVolume::SetProperty
;
PRO MGHgrVolume::SetProperty, $
     DESCRIPTION=description, DIMENSIONS=dimensions, $
     HIDE=hide, LOCATION=location, NAME=name, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::SetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   recalc = 0B

   if n_elements(dimensions) gt 0 then begin
      self.dimensions = dimensions
      recalc = 1B
   endif

   if n_elements(location) gt 0 then begin
      self.location = location
      recalc = 1B
   endif

   if n_elements(xcoord_conv) gt 0 then begin
      self.xcoord_conv = xcoord_conv
      recalc = 1B
   endif

   if n_elements(ycoord_conv) gt 0 then begin
      self.ycoord_conv = ycoord_conv
      recalc = 1B
   endif

   if n_elements(zcoord_conv) gt 0 then begin
      self.zcoord_conv = zcoord_conv
      recalc = 1B
   endif

   self.volume->SetProperty, _STRICT_EXTRA=extra

   if recalc then self->CalculateDimensions

end


; MGHgrVolume::GetProperty
;
pro MGHgrVolume::GetProperty, $
     DESCRIPTION=description, DIMENSIONS=dimensions, HIDE=hide, $
     LOCATION=location, NAME=name, PARENT=parent, $
     XCOORD_CONV=xcoord_conv, XRANGE=xrange, $
     YCOORD_CONV=ycoord_conv, YRANGE=yrange, $
     ZCOORD_CONV=zcoord_conv, ZRANGE=zrange, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name, PARENT=parent

   self.volume->GetProperty, _STRICT_EXTRA=extra

   dimensions = self.dimensions

   location = self.location

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   if arg_present(xrange) || arg_present(yrange) || arg_present(zrange) then begin

      self.volume->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

      ;; Why not use the [x,y,z]coord_conv properties here??
      self.normal_node->GetProperty, TRANSFORM = normal_transform
      xrange = xrange * normal_transform[0,0] + normal_transform[3,0]
      yrange = yrange * normal_transform[1,1] + normal_transform[3,1]
      zrange = zrange * normal_transform[2,2] + normal_transform[3,2]

   endif

end


; MGHgrVolume__Define

pro MGHgrVolume__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrVolume, inherits IDLgrModel, $
         normal_node: obj_new(), volume: obj_new(), $
         dimensions: dblarr(3), location: dblarr(3), $
         xcoord_conv: dblarr(2), ycoord_conv: dblarr(2), $
         zcoord_conv: dblarr(2)}

end


