; svn $Id$
;+
; CLASS NAME:
;
;   MGHgrLegoSurface
;
; PURPOSE:
;
;   A surface class that acts sanely when the STYLE property is set to
;   one of the Lego values (5 or 6).
;
; PROPERTIES:
;
;   This class supports all the properties of MGHgrSurface, with a few
;   differences in the behaviour of the DATAX, DATAY, DATAZ and STYLE
;   properties.
;
;     - For lego surfaces (STYLE equals 5 or 6), DATAZ is dimensioned
;       according to the number of visible cells, not the the number
;       of vertices. DATAX and DATAY still specify vertex positions
;       and are dimensioned according to the number of vertices. Thus
;       for a lego surface with m x n vertices, DATAX is
;       dimensioned [m] or [m,n], DATAY is dimensioned [n] or [m,n]
;       and DATAZ is dimensioned [m-1,n-1].
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
;   Mark Hadfield, 2002-07:
;     Written.
;-

; MGHgrLegoSurface::Init

function MGHgrLegoSurface::Init, z, x, y, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Initialise with no geometric or style data

   ok = self->MGHgrSurface::Init(_STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGHgrSurface'

   ;; Specify geometric data. Defaults depend on style.

   if n_elements(style) eq 0 then style = 1

   if n_elements(datax) eq 0 then if n_elements(x) gt 0 then datax = x
   if n_elements(datay) eq 0 then if n_elements(y) gt 0 then datay = y
   if n_elements(dataz) eq 0 then if n_elements(z) gt 0 then dataz = z

   if n_elements(dataz) gt 0 then begin

      if size(dataz, /N_DIMENSIONS) ne 2 then $
           message, 'DATAZ must be a 2-dimensional array'

      dims = size(dataz, /DIMENSIONS)

      lego = style ge 5

      if n_elements(datax) eq 0 then $
           datax = mgh_stagger(findgen(dims[0]), DELTA=lego)

      if n_elements(datay) eq 0 then $
           datay = mgh_stagger(findgen(dims[1]), DELTA=lego)

   endif

   self->SetProperty, DATAX=datax, DATAY=datay, DATAZ=dataz, STYLE=style

   return, 1

end

; MGHgrLegoSurface::SetProperty
;
pro MGHgrLegoSurface::SetProperty, DATAZ=dataz, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; The Restyle method sets the style; if this changes the legosity
   ;; of the surface then it also changes any existing geometry data
   ;; so as to preserve the number and position of the DATAZ points.
   ;; These changes may be overriden below if any geometry data have
   ;; been specified in the call to SetProperty, however the
   ;; inefficiency is insignificant and writing it this way makes the
   ;; code simpler.

   if n_elements(style) gt 0 then self->Restyle, style

   self->GetProperty, STYLE=style

   case style ge 5 of

      0: begin

         self->MGHgrSurface::SetProperty, DATAZ=dataz, _STRICT_EXTRA=extra

      end

      1: begin

         if n_elements(dataz) gt 0 then begin
            dims = size(dataz, /DIMENSIONS)
            if n_elements(dims) ne 2 then $
                 message, 'DATAZ must be a 2-dimensional array'
            ndataz = make_array(VALUE=0*dataz[0], DIMENSION=dims+1)
            ndataz[0,0] = dataz
         endif

         self->MGHgrSurface::SetProperty, DATAZ=ndataz, _STRICT_EXTRA=extra

      end

   endcase



end

; MGHgrLegoSurface::GetProperty
;
pro MGHgrLegoSurface::GetProperty, DATAX=datax, DATAY=datay, DATAZ=dataz, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGHgrSurface::GetProperty, _STRICT_EXTRA=extra

   if arg_present(datax) or arg_present(datay) or arg_present(dataz) then begin

      self->MGHgrSurface::GetProperty, DATAX=datax, DATAY=datay, DATAZ=dataz

      dims = size(dataz, /DIMENSIONS)

      if n_elements(dims) eq 2 and self.style ge 5 then $
           dataz = dataz[0:dims[0]-2,0:dims[1]-2]

   endif

end

; MGHgrLegoSurface::ReStyle
;
pro MGHgrLegoSurface::Restyle, style

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Restyle has been called by a SetProperty method and itself calls
   ;; SetProperty methods. Be careful careful about which class's
   ;; SetProperty methods we call to avoid infinite recursion.

   ostyle = self.style
   nstyle = n_elements(style) gt 0 ? style : ostyle

   olego = ostyle ge 5
   nlego = nstyle ge 5

   case nlego ne olego of

      0: self->MGHgrSurface::SetProperty, STYLE=nstyle

      1: begin

         self->GetProperty, DATAX=datax, DATAY=datay, DATAZ=dataz

         self->MGHgrSurface::SetProperty, STYLE=nstyle

         if size(datax, /N_DIMENSIONS) eq 2 then begin

            self->SetProperty, $
                 DATAX=mgh_stagger(datax, DELTA=fix(nlego)-fix(olego)), $
                 DATAY=mgh_stagger(datay, DELTA=fix(nlego)-fix(olego)), $
                 DATAZ=dataz

         endif
      end

   endcase

end

; MGHgrLegoSurface__Define

PRO MGHgrLegoSurface__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHgrLegoSurface, inherits MGHgrSurface}

end

