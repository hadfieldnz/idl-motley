;+
; NAME:
;   MGH_EXAMPLE_PLOT
;
; PURPOSE:
;   A simple line plot implemented various ways.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;   Mark Hadfield, 2013-10:
;     Updated.
;-
pro mgh_example_plot, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   ;; The data

   x = findgen(21) & y = x^2

   case option of

      0: begin

         ;; Using MGH_Plot object

         mgh_new, 'mgh_plot', x, y

      end

      1: begin

         ;; Using MGH_Plot object, dress it up a bit with colours, symbols and axis titles

         mgh_new, 'mgh_plot', x, y, $
            PLOT_PROPERTIES={color: mgh_color('blue')}, $
            SYMBOL_PROPERTIES={style: 1, fill: 1B, color: mgh_color('red')}, $
            XAXIS_PROPERTIES={title: 'X'}, $
            YAXIS_PROPERTIES={title: 'Y'}

      end

      2: begin

         ;; Generate the MGH_Plot object first, then add the plot
         ;; object.

         mgh_new, 'mgh_plot', RESULT=oplt, $
            XRANGE=mgh_minmax(x), YRANGE=mgh_minmax(y), $
            XAXIS_PROPERTIES={title: 'X'}, $
            YAXIS_PROPERTIES={title: 'Y'}

         oplt->NewPlot, x, y, $
            PLOT_PROPERTIES={color: mgh_color('blue')}, $
            SYMBOL_PROPERTIES={style: 0, fill: 1B, color: mgh_color('red')}

      end

      3: begin

         ;; The same plot is available via the MGH_Plot object's
         ;; EXAMPLE keyword.

         mgh_new, 'mgh_plot', /EXAMPLE

      end

      4: begin

         ;; Same again, with MGHgrGraph2D and MGH_Window objects.  It
         ;; looks the same but code is more complicated.

         ograph = obj_new('MGHgrGraph2D', NAME='X-Y line plot')

         ograph->NewMask

         ograph->NewFont

         ograph->NewAxis, DIRECTION=0, RANGE=mgh_minmax(x), TITLE='X', /EXTEND
         ograph->NewAxis, DIRECTION=1, RANGE=mgh_minmax(y), TITLE='Y', /EXTEND

         ograph->NewBackground

         ograph->NewSymbol, 0, /FILL, COLOR=mgh_color('red'), RESULT=osym

         ograph->NewAtom, 'IDLgrPlot', X, Y, COLOR=mgh_color('blue'), SYMBOL=osym

         ograph->NewTitle

         mgh_new, 'MGH_Window', ograph, RENDERER=1, MOUSE_ACTION=['Zoom XY','Pick','Context']

      end

   endcase

end
