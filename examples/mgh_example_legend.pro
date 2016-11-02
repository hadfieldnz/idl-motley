;+
; NAME:
;   MGH_EXAMPLE_LEGEND
;
; PURPOSE:
;   Example of MGHgrLegend object.
;
;###########################################################################
; Copyright (c) 2001-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-02:
;     Written.
;-
pro mgh_example_legend, option

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(option) eq 0 then option = 0

  ograph = obj_new('MGHgrGraph2D', ASPECT=0.9, NAME='Example graph with legend')

  ograph->NewFont

  ograph->NewMask

  ograph->NewTitle

  ograph->NewAxis, DIRECTION=0, RANGE=[0,10]
  ograph->NewAxis, DIRECTION=1, RANGE=[1,9]

  ograph->NewSymbol, CLASS='MGHgrSymbol', 0, $
    FILL=0, COLOR=mgh_color('blue'), RESULT=osym0
  ograph->NewSymbol, CLASS='MGHgrSymbol', 0, $
    FILL=1, COLOR=mgh_color('red'), RESULT=osym1

  ograph->NewAtom, 'IDLgrPlot', $
    DATAX=findgen(11), DATAY=findgen(11), SYMBOL=osym0
  ograph->NewAtom, 'IDLgrPlot', $
    DATAX=1+findgen(10), DATAY=findgen(10), LINE=1, SYMBOL=osym1

  ;; For option = 0 the legend is scaled to the axes, for option = 1
  ;; it is not.  I tried it both ways because I expected that the
  ;; scaling would affect the symbol sizes, so that in the latter
  ;; case it would be necessary to generate different symbols for the
  ;; legend. This turns out not to be true because the legend object
  ;; resets the size of its symbols and reverses the change
  ;; afterwards every time it is drawn.

  case option of

    0: begin
      ograph->NewAtom, 'MGHgrLegend', FONT=ograph->GetFont(), $
        GLYPH_WIDTH=5, /SHOW_OUTLINE, BORDER_GAP=0.5, LOCATION=[4,8], $
        ITEM_NAME=['A','B'], ITEM_LINESTYLE=[0,1], ITEM_OBJECT=[osym0, osym1], $
        /DEPTH_TEST_DISABLE
    end
    1: begin
      ograph->NewAtom, 'MGHgrLegend', FONT=ograph->GetFont(), $
        GLYPH_WIDTH=5, /SHOW_OUTLINE, BORDER_GAP=0.5, XAXIS=0, YAXIS=0, $
        LOCATION=ograph->NormPosition([4,8]), $
        ITEM_NAME=['A','B'], ITEM_LINESTYLE=[0,1], ITEM_OBJECT=[osym0, osym1]
    end

  endcase

  mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph

end

