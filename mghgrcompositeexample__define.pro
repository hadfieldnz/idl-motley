; svn $Id$
;+
; CLASS NAME:
;   MGHgrCompositeExample
;
; PURPOSE:
;   This class was written as a prototype for a typical composite graphics
;   object. It implements a grey rectangle with a black outline. It has
;   properties LOCATION and DIMENSIONS. It has no practical use.
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
;     DELTAZ (Init,Get,Set)
;       Vertical spacing in normalised units between the rectangle and the
;       outline, needed to ensure the outline is visible. If this property is
;       not set, then the spacing is set at draw time, based on the view's
;       ZCLIP property--the value is 2*(ZCLIP[0] - ZCLIP[1])/65536, which
;       for the default ZCLIP is 6.1E-5. DELTAZ should only need to be
;       set explicitly if the object or its parent is transformed before
;       drawing.
;
;     LOCATION (Init,Get,Set)
;       Location of the lower left corner of the rectangle in data units.
;
;     DIMENSIONS (Init,Get,Set)
;       Horizontal & vertical dimensions of the rectangle in data units.
;
;     XCOORD_CONV (Init,Get,Set)
;     YCOORD_CONV (Init,Get,Set)
;     ZCOORD_CONV (Init,Get,Set)
;       Coordinate transformations specifying the relationship between
;       normalised & data units.
;
;     XRANGE (Get)
;     YRANGE (Get)
;     ZRANGE (Get)
;       Position of the extremes of the object in data units. ZRANGE is
;       not finalised until the object is drawn.
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
;   Mark Hadfield, 2004-03:
;     Overhauled keyword handling and updated for IDL 6.0.
;   Mark Hadfield, 2004-07:
;     Added support for property registration.
;-

; MGHgrCompositeExample::Init

FUNCTION MGHgrCompositeExample::Init, $
     ALPHA_CHANNEL, COLOR=color, DELTAZ=deltaz, DESCRIPTION=description, $
     DIMENSIONS=dimensions, HIDE=hide, LOCATION=location, NAME=name, $
     REGISTER_PROPERTIES=register_properties, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDLgrModel::Init(DESCRIPTION=description, HIDE=hide, $
                               NAME=name, /SELECT_TARGET)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrModel'


   ;; Create child objects

   if n_elements(color) eq 0 then color = [190,190,190]

   self.normal_node = OBJ_NEW('IDLgrModel')

   self.rectangle = obj_new('IDLgrPolygon', [0,1,1,0], [0,0,1,1], $
                            ALPHA_CHANNEL=alpha_channel, COLOR=color)

   self.outline = obj_new('IDLgrPolyline', [0,1,1,0,0], [0,0,1,1,0], intarr(5), $
                          COLOR=[0,0,0])

   ;; Set up the object hierarchy

   self->Add, self.normal_node

   self.normal_node->Add, self.rectangle

   self.normal_node->Add, self.outline

   self.deltaz = !values.f_nan
   self.dimensions = [1,1]
   self.location = [0,0,0]
   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.zcoord_conv = [0,1]

   self->SetProperty, $
        DELTAZ=deltaz, DIMENSIONS=dimensions, LOCATION=location, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'NAME', NAME='Name', /STRING
      self->RegisterProperty, 'DESCRIPTION', NAME='Description', /STRING
      self->RegisterProperty, 'HIDE', NAME='Show', ENUMLIST=['True','False']
      self->RegisterProperty, 'COLOR', NAME='Color', /COLOR
      self->RegisterProperty, 'ALPHA_CHANNEL', NAME='Opacity', /FLOAT, $
          VALID_RANGE=[0D0,1D0,0.05D0]

   endif

   return, 1

end

; MGHgrCompositeExample::SetProperty
;
pro MGHgrCompositeExample::SetProperty, $
     ALPHA_CHANNEL=alpha_channel, COLOR=color, DELTAZ=deltaz, $
     DESCRIPTION=description, DIMENSIONS=dimensions, HIDE=hide, $
     LOCATION=location, NAME=name, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::SetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.rectangle->SetProperty, $
        ALPHA_CHANNEL=alpha_channel, COLOR=color

   if n_elements(deltaz) eq 1 then self.deltaz = deltaz

   if n_elements(dimensions) eq 2 then begin
      self.dimensions = dimensions
      recalc = 1B
   endif

   nloc = n_elements(location)
   if nloc ge 2 then begin
      self.location[0:nloc-1] = location
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

   if keyword_set(recalc) then self->CalculateDimensions

end


; MGHgrCompositeExample::GetProperty
;
PRO MGHgrCompositeExample::GetProperty, $
     ALPHA_CHANNEL=alpha_channel, COLOR=color, DELTAZ=deltaz, DESCRIPTION=description, DIMENSIONS=dimensions, $
     HIDE=hide, LOCATION=location, NAME=name, $
     XCOORD_CONV=xcoord_conv, XRANGE=xrange, $
     YCOORD_CONV=ycoord_conv, YRANGE=yrange, $
     ZCOORD_CONV=zcoord_conv, ZRANGE=zrange

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   deltaz = self.deltaz

   dimensions = self.dimensions

   location = self.location

   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   self->IDLgrModel::GetProperty, $
        DESCRIPTION=description, HIDE=hide, NAME=name

   self.rectangle->GetProperty, $
        ALPHA_CHANNEL=alpha_channel, COLOR=color, $
        XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

   self.outline->GetProperty, $
        XRANGE=outline_xrange, YRANGE=outline_yrange, ZRANGE=outline_zrange

   xrange[0] = xrange[0] < outline_xrange[0]
   xrange[1] = xrange[1] > outline_xrange[1]

   yrange[0] = yrange[0] < outline_yrange[0]
   yrange[1] = yrange[1] > outline_yrange[1]

   zrange[0] = zrange[0] < outline_zrange[0]
   zrange[1] = zrange[1] > outline_zrange[1]

   self.normal_node->GetProperty, TRANSFORM = normal_transform
   xrange = xrange * normal_transform[0,0] + normal_transform[3,0]
   yrange = yrange * normal_transform[1,1] + normal_transform[3,1]
   zrange = zrange * normal_transform[2,2] + normal_transform[3,2]

end


PRO MGHgrCompositeExample::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrModel::Cleanup

end

; MGHgrCompositeExample::CalculateDimensions
;
pro MGHgrCompositeExample::CalculateDimensions

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.normal_node->Reset

   self.normal_node->Scale, self.dimensions[0], self.dimensions[1], 1

   self.normal_node->Translate, self.location[0], self.location[1], self.location[2]

   self->Reset

   self->Scale, self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

   self->Translate, self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end

; MGHgrCompositeExample::Draw
;
;   An atom or model's Draw method is called by a destination device when its
;   own Draw method is called. Here we intercept the call and take the oportunity
;   to set the vertical spacing between the rectangle and the outline.
;
pro MGHgrCompositeExample::Draw, oSrcDest, oView

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case finite(self.deltaz) of
      0B: begin
         oView->GetProperty, ZCLIP=zclip
         deltaz = 2.D0*(double(zclip[0]) - double(zclip[1]))/65536.D0
      end
      1B: begin
         deltaz = self.deltaz
      end
   endcase

   self.outline->GetProperty, DATA=data

   data[2,*] = deltaz/self.zcoord_conv[1]

   self.outline->SetProperty, DATA=data

   self->IDLgrModel::Draw, oSrcDest, oView

end

; MGHgrCompositeExample__Define

pro MGHgrCompositeExample__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrCompositeExample, inherits IDLgrModel, $
         normal_node: obj_new(), rectangle: obj_new(), location: dblarr(3), $
         outline: obj_new(), deltaz: 0., dimensions: dblarr(2), $
         xcoord_conv: dblarr(2), ycoord_conv: dblarr(2), zcoord_conv: dblarr(2)}

end


