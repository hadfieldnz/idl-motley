;+
; NAME:
;   MGH_EXAMPLE_PALETTE
;
; PURPOSE:
;   Generate & display various palettes.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-12:
;     Written.
;-
pro mgh_example_palette, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(option) eq 0 then option = 0

   ograph = obj_new('MGHgrGraph', NAME='Palette example')

   ograph->NewFont, SIZE=10

   case option of

      0: begin
         ;; Colour table retrieved from user colour table file by index.
         table = mgh_get_ct(2)
      end

      1: begin
         ;; Colour table retrieved from system colour table file by name.
         table = mgh_get_ct('Prism', /SYSTEM)
      end

      2: begin
         ;; Colour table constructed using specified points
         indices = [0,25,76,127,178,230,255]
         colors =  ['(0,30,127)','blue','yellow','red','green','(200,0,200)','(0,127,30)']
         table = mgh_make_ct(indices, colors)
      end

   endcase

   ograph->NewPalette, RESULT=opal, TABLE=table

   ograph->NewAtom, 'MGHgrColorBar', PALETTE=opal, VERTICAL=0, RESULT=obar

   obar->GetProperty, XRANGE=xrange, YRANGE=yrange

   ograph->SetProperty, $
        VIEWPLANE_RECT=[xrange[0],yrange[0],xrange[1]-xrange[0], $
                        yrange[1]-yrange[0]]+[-0.1,-0.2,0.2,0.3]

   mgh_new, 'MGH_Window', ograph, RESULT=owin

end

