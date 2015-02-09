; svn $Id$
;+
; NAME:
;   MGHgrLegend
;
; PURPOSE:
;   This class inherits IDLgrLegend and adds a LOCATION property
;   (which specifies the .
;   It also applies different defaults for a few properties.
;
; CATEGORY:
;   Object graphics.
;
; PROPERTIES:
;   In addition to those properties supported by IDLgrLegend:
;
;     LOCATION (Init, Get, Set)
;       Location of bottom left corner in data units.
;
;     [X,Y,Z]COORD_CONV (Init, Get, Set)
;       The usual.
;
;   The following properties of IDLgrLegend have different default
;   values:
;
;     BORDER_GAP
;       Default 0.2
;
;     GAP
;       Default 0.2
;
;     GLYPH_WIDTH
;       Default 2.5
;
; EXAMPLE:
;   See MGH_EXAMPLE_LEGEND.
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
;   Mark Hadfield, 1998-02:
;     Written.
;   Mark Hadfield, 2000-08:
;     Updated for IDL2 syntax. Cleared out a lot of extraneous
;     defaults from Init--were these originally put in to work
;     around bugs in an IDL beta?
;   Mark Hadfield, 2001-07:
;     Minor changes.
;   Mark Hadfield, 2003-05:
;     Various changes made in upgrading to IDL 6.0, including
;     setting default value of DEPTH_TEST_DISABLE to 1, so that
;     the legend will be drawn over other graphic objects.
;-

function MGHgrLegend::Init, LOCATION=location, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ok = self->IDLgrLegend::Init(BORDER_GAP=0.2, GAP=0.2 , GLYPH_WIDTH=2.5, $
                                DEPTH_TEST_DISABLE=1, _STRICT_EXTRA=extra)
   if ~ ok then message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrLegend'

   self.location = 0
   self.xcoord_conv = [0,1]
   self.ycoord_conv = [0,1]
   self.xcoord_conv = [0,1]

   self->SetProperty, LOCATION=location, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   return, 1

end

pro MGHgrLegend::GetProperty, LOCATION=location, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   location = self.location
   xcoord_conv = self.xcoord_conv
   ycoord_conv = self.ycoord_conv
   zcoord_conv = self.zcoord_conv

   self->IDLgrLegend::GetProperty, _STRICT_EXTRA=extra

end

pro MGHgrLegend::SetProperty, LOCATION=location, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(location) gt 0 then self.location = location

   if n_elements(xcoord_conv) gt 0 then self.xcoord_conv = xcoord_conv
   if n_elements(ycoord_conv) gt 0 then self.ycoord_conv = ycoord_conv
   if n_elements(zcoord_conv) gt 0 then self.zcoord_conv = zcoord_conv

   xc = [self.xcoord_conv[0] + self.location[0]*self.xcoord_conv[1], 1.]
   yc = [self.ycoord_conv[0] + self.location[1]*self.ycoord_conv[1], 1.]
   zc = [self.zcoord_conv[0] + self.location[2]*self.zcoord_conv[1], 1.]

   self->IDLgrLegend::SetProperty, $
        XCOORD_CONV=xc, YCOORD_CONV=yc, ZCOORD_CONV=zc, _STRICT_EXTRA=extra

end

pro MGHgrLegend__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHgrLegend, inherits IDLgrLegend, location: dblarr(3), $
                 xcoord_conv: dblarr(2), ycoord_conv: dblarr(2), zcoord_conv: dblarr(2)}

end

