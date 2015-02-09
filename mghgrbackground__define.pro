; svn $Id$
;+
; CLASS NAME:
;   MGHgrBackground
;
; PURPOSE:
;   This class is just an IDLgrPolygon with a couple of changes that
;   make it suitable to be the background (selection target) in an
;   MGHgrGraph:
;
;     - The GetProperty keywords XRANGE, YRANGE and ZRANGE return
;       undefined values. This means that the background object is
;       ignored when fitting axes around atoms.
;
;     - The DEPTH_WRITE_DISABLE property is set to 1 to allow this
;       pbject to be overdrawn.
;
;     - If the SetProperty keywords XCOORD_CONV, YCOORD_CONV or
;       ZCOORD_CONV are invoked (and the DATA keyword is not) then the
;       DATA array is adjusted to maintain a constant position in
;       normalised coordinates.
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
;   Mark Hadfield, 2000-08:
;     Written.
;   Mark Hadfield, 2003-06:
;     Updated for IDL 6.0: Init method added, setting the default value of
;     DEPTH_WRITE_DISABLE to 1.
;-

function MGHgrBackground::Init, P1, P2, P3, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: ok = self->IDLgrPolygon::Init(DEPTH_WRITE_DISABLE=1, _STRICT_EXTRA=extra)
      1: ok = self->IDLgrPolygon::Init(P1, DEPTH_WRITE_DISABLE=1, _STRICT_EXTRA=extra)
      2: ok = self->IDLgrPolygon::Init(P1, P2, DEPTH_WRITE_DISABLE=1, _STRICT_EXTRA=extra)
      3: ok = self->IDLgrPolygon::Init(P1, P2, P3, DEPTH_WRITE_DISABLE=1, _STRICT_EXTRA=extra)
   endcase

   if ~ ok then message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrPolygon'

   return, 1

end

; MGHgrBackground::GetProperty
;
pro MGHgrBackground::GetProperty, $
     XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   self->IDLgrPolygon::GetProperty, _STRICT_EXTRA=extra

end

; MGHgrBackground::SetProperty
;
pro MGHgrBackground::SetProperty, $
     XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   bx = n_elements(xcoord_conv) gt 0
   by = n_elements(ycoord_conv) gt 0
   bz = n_elements(zcoord_conv) gt 0

   if bx || by || bz then begin

      self->GetProperty, DATA=data

      dims = size(data, /DIMENSIONS)

      if dims[0] gt 0 then begin

         if bx then begin
            self->GetProperty, XCOORD_CONV=xcoord_old
            norm = xcoord_old[0] + data[0,*]*xcoord_old[1]
            data[0,*] = (norm-xcoord_conv[0])/xcoord_conv[1]
         endif

         if by then begin
            self->GetProperty, YCOORD_CONV=ycoord_old
            norm = ycoord_old[0] + data[1,*]*ycoord_old[1]
            data[1,*] = (norm-ycoord_conv[0])/ycoord_conv[1]
         endif

         if bz then if dims[0] eq 3 then begin
            self->GetProperty, ZCOORD_CONV=zcoord_old
            norm = zcoord_old[0] + data[2,*]*zcoord_old[1]
            data[2,*] = (norm-zcoord_conv[0])/zcoord_conv[1]
         endif

         self->SetProperty, DATA=data

      endif

   endif

   ;; Pass on all other properties. Note that if the DATA keyword has been
   ;; specified it will be passed to IDLgrPolygon::SetProperty here and
   ;; will override the changes above. This is the intended behaviour.

   self->IDLgrPolygon::SetProperty, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
        _STRICT_EXTRA=extra

end

; MGHgrBackground__Define

pro MGHgrBackground__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHgrBackground, inherits IDLgrPolygon}

end

