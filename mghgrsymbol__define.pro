;+
; CLASS NAME:
;   MGHgrSymbol
;
; PURPOSE:
;   This class implements a symbol in which the size can be specified
;   in normalised coordinates. It provides useful plotting symbols not
;   in the standard IDLgrSymbol definitions.
;
; PROPERTIES:
;   The following properties are supported.
;
;     COLOR (Init, Get, Set)
;       This is passed to the atom encapsulated by the symbol.
;       Note that when an IDLgrSymbol has user-defined data,
;       the symbol's own colour property is ignored, and the
;       colour is not inherited from the graphics atom to which the
;       symbol is attached.
;
;     NORM_SIZE (Init, Get, Set)
;       Symbol size in scaled coordinates. This is a 3-element,
;       double-precision floating point vector, but can (and usually
;       will) be set as a scalar. See notes on symbol-sizing below.
;
;     ROTATABLE (Init, Get, Set)
;       This property has permissible values 0 and 1 & specifies
;       whether the graphics atom that defines the symbol is embedded
;       in an IDlgrModel (which can be rotated) or not. If the Rotate
;       method is called on on a non-rotatable symbol then the symbol
;       is made rotatable--is that cool or what?!
;
;     SIZE (Init, Get, Set)
;       Symbol size in unscaled coordinates. This is the underlying
;       IDLgrSymbol's SIZE property, exposed so that it can be
;       manipulated directly if necessary, eg. by the IDLgrLegend
;       object. See notes on symbol-sizing below.
;
;     STYLE(Init, Get)
;       An integer specifying the type of symbol. Valid values are in
;       the range 0-4.
;
;     XSCALE (Init, Get, Set)
;     YSCALE (Init, Get, Set)
;     ZSCALE (Init, Get, Set)
;       Scaling factor for symbol size in x, y & z directions. See
;       notes on symbold sizing below.
;
; SYMBOL SIZING:
;   The properties relevant to sizing the symbol are NORM_SIZE, SIZE
;   and [X,Y,Z]SCALE. The underlying IDLgrSymbol is resized whenever the
;   SetProperty method is called (and this is always done at initialisation).
;   The rules are:
;
;     - If SIZE is specified, then this value is used. The values of
;       the other properties may be changed and are retained, but they are
;       ignored.
;     - If SIZE is not specified, then the IDLgrSymbol's size is set to
;       self.norm_size/[self.xscale,self.yscale,self.zscale].
;
;   These rather complicated rules are used to support both explicit
;   sizing in data coordinates (eg by IDLgrLegend) and the automatic scaling
;   done by MGHgrGraph and MGHgrAxis objects.
;
;###########################################################################
; Copyright (c) 2000-2011 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-07:
;     Written, base on my earlier MGH_SYMBOL function
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6. I managed to use array stride subscripts in
;     the code for STYLE=2!
;   Mark Hadfield, 2004-07:
;     - Sizing code revised, allowing cleaner code in MGHgrGraph and
;       MGHgrAxis.
;     - IDL 6.0 logical syntax.
;   Mark Hadfield, 2012-10:
;     - THICK keyword now passed to IDLgrPolygon for style 0.
;   Mark Hadfield, 2014-12:
;     - Added ZVALUE keyword, used for vertical positioning.
;-
function MGHgrSymbol::Init, pstyle, $
     COLOR=color, FILL=fill, N_VERTICES=n_vertices, NORM_SIZE=norm_size, $
     ROTATABLE=rotatable, SIZE=size, STYLE=style, THICK=thick, $
     XSCALE=xscale, YSCALE=yscale, ZSCALE=zscale, ZVALUE=zvalue

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(style) eq 0 && n_elements(pstyle) gt 0 then $
        style = pstyle

   self.style = n_elements(style) gt 0 ? style : 0

   self.rotatable = n_elements(rotatable) gt 0 ? self.rotatable : 0

   self.disposal = obj_new('MGH_Container')

   case self.style of

      ;; Circle (strictly an equilateral polygon)
      0: begin
         if n_elements(n_vertices) eq 0 then n_vertices = 10
         if n_elements(zvalue) eq 0 then zvalue = 0
         a = 2.*!pi*findgen(n_vertices)/n_vertices
         x = sin(a)  &  y = cos(a)  &  z = replicate(zvalue, n_vertices)
         self.atom = obj_new('IDLgrPolygon', x, y, z, COLOR=color, THICK=thick, $
                              STYLE=1+keyword_set(fill))
      end

      ;; Annular polygon
      1: begin
         if n_elements(n_vertices) eq 0 then n_vertices = 12
         a = 2.*!pi*findgen(n_vertices)/n_vertices
         x = sin(a)  &  y = cos(a)
         if keyword_set(fill) then begin
            otess = obj_new('IDLgrTessellator')
            otess->AddPolygon, x, y, fltarr(n_vertices)
            otess->AddPolygon, 0.5*x, 0.5*y, fltarr(n_vertices)
            if ~ otess->Tessellate(vert, conn) then $
                 message, 'Tessellation failed.'
            obj_destroy, otess
            self.atom = obj_new('IDLgrPolygon', COLOR=color, DATA=vert, POLY=conn)
         endif else begin
            poly = [n_vertices+1, lindgen(n_vertices+1), $
                    n_vertices+1, n_vertices+1+lindgen(n_vertices+1)]
            self.atom = obj_new('IDLgrPolyline', $
                            [x,x[0],0.5*x,0.5*x[0]], $
                            [y,y[0],0.5*y,0.5*y[0]], $
                            COLOR=color, POLY=poly)
         endelse
      end

      ;; Star
      2: begin
         if n_elements(n_vertices) eq 0 then n_vertices = 5
         x = fltarr(2*n_vertices)
         y = fltarr(2*n_vertices)
         a = 2.*!pi*findgen(n_vertices)/n_vertices
         x[0:*:2] = 1.3*sin(a)
         y[0:*:2] = 1.3*cos(a)
         a = 2.*!pi*(findgen(n_vertices)+0.5)/n_vertices
         x[1:*:2] = 0.6*sin(a)
         y[1:*:2] = 0.6*cos(a)
         if keyword_set(fill) then begin
            otess = obj_new('IDLgrTessellator')
            otess->AddPolygon, x, y, replicate(0.,2*n_vertices)
            if ~ otess->Tessellate(vert, conn) then $
                 message, 'Tessellation failed.'
            obj_destroy, otess
            self.atom = obj_new('IDLgrPolygon', COLOR=color, DATA=vert, POLY=conn)
         endif else begin
            self.atom = obj_new('IDLgrPolyline' , [x,x[0]], [y,y[0]], COLOR=color)
         endelse
      end

      ;; Sphere
      3: begin
         if n_elements(n_vertices) eq 0 then n_vertices = 6
         mesh_obj, 4, vert, conn, replicate(1, n_vertices+1, n_vertices)
         self.atom = obj_new('IDLgrPolygon', COLOR=color, DATA=vert, POLY=conn, $
                         STYLE=1+keyword_set(fill))
      end

      ;; Cylinder
      4: begin
         if n_elements(n_vertices) eq 0 then n_vertices = 10
         mesh_obj, 3, vert, conn, replicate(1, n_vertices+1, 2)
         vert[2,*] = 2*vert[2,*]-1
         self.atom = obj_new('IDLgrPolygon', COLOR=color, DATA=vert, POLY=conn, $
                         STYLE=1+keyword_set(fill))
      end

   endcase
   
   if self.rotatable then begin
      data = obj_new('IDLgrModel')
      data->Add, self.atom
      self.disposal->Add, data
   endif else begin
      data = self.atom
   endelse

   ;; Create the symbol object

   ok = self->IDLgrSymbol::Init(DATA=data, NAME=name, THICK=thick)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrSymbol'

   ;; Pass size information to the SetProperty method

   if n_elements(norm_size) eq 0 then norm_size = 1.D0

   if n_elements(xscale) eq 0 then xscale = 1.D0
   if n_elements(yscale) eq 0 then yscale = 1.D0
   if n_elements(zscale) eq 0 then zscale = 1.D0

   self->SetProperty, $
        NORM_SIZE=norm_size, SIZE=size, XSCALE=xscale, YSCALE=yscale, ZSCALE=zscale

   return, 1

end

; MGHgrSymbol::Cleanup
;
pro MGHgrSymbol::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.atom
   obj_destroy, self.disposal

   self->IDLgrSymbol::Cleanup

end

; MGHgrSymbol::GetProperty
;
pro MGHgrSymbol::GetProperty, $
     COLOR=color, NORM_SIZE=norm_size, ROTATABLE=rotatable, SIZE=size, STYLE=style, $
     XSCALE=xscale, YSCALE=yscale, ZSCALE=zscale

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.atom->GetProperty, COLOR=color

   self->IDLgrSymbol::GetProperty, SIZE=size

   rotatable = self.rotatable

   norm_size = self.norm_size

   style = self.style

   xscale = self.xscale
   yscale = self.yscale
   zscale = self.zscale

end

; MGHgrSymbol::SetProperty
;
pro MGHgrSymbol::SetProperty,$
     COLOR=color, ROTATABLE=rotatable, NORM_SIZE=norm_size, SIZE=size, $
     XSCALE=xscale, YSCALE=yscale, ZSCALE=zscale

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.atom->SetProperty, COLOR=color

   if n_elements(rotatable) gt 0 then begin
      delta = fix(rotatable) - fix(self.rotatable)
      case delta of
         -1: begin
            self->IDLgrSymbol::GetProperty, DATA=omodel
            omodel->Remove, self.atom
            self->IDLgrSymbol::SetProperty, DATA=self.atom
         end
         0:
         1: begin
            omodel = obj_new('IDlgrModel')
            self->IDLgrSymbol::SetProperty, DATA=omodel
            omodel->Add, self.atom
            self.disposal->Add, omodel
         end
      endcase
      self.rotatable = rotatable
   endif

   ;; Recalculate size if appropriate. Note that the following logical
   ;; expression is made simpler with IDL 6.0-style logical-predicate
   ;; values.

   if n_elements(norm_size) || n_elements(size) || $
        n_elements(xscale) || n_elements(yscale) || n_elements(zscale) then begin

      if n_elements(norm_size) gt 0 then $
           self.norm_size = norm_size

      if n_elements(xscale) gt 0 then $
           self.xscale = xscale
      if n_elements(yscale) gt 0 then $
           self.yscale = yscale
      if n_elements(zscale) gt 0 then $
           self.zscale = zscale

      if n_elements(size) eq 0 then $
           size = self.norm_size/[self.xscale,self.yscale,self.zscale]

      self->IDLgrSymbol::SetProperty, SIZE=size

   endif

end

; MGHgrSymbol::Rotate
;
pro MGHgrSymbol::Rotate, p0, p1

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Clever, eh?
   if ~ self.rotatable then self->SetProperty, /ROTATABLE

   self->GetProperty, DATA=data

   data->Rotate, p0, p1

end

; MGHgrSymbol__Define
;
pro MGHgrSymbol__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrSymbol, inherits IDLgrSymbol, $
         atom: obj_new(), disposal: obj_new(), $
         norm_size: dblarr(3), rotatable: 0B, style: 0S, $
         xscale: 0.D0, yscale: 0.D0, zscale: 0.D0}

end

