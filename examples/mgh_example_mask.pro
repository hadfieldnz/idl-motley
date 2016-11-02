;+
; NAME:
;   MGH_EXAMPLE_MASK
;
; PURPOSE:
;   A graph with a few lines & text labels illustrating masking
;   (visibility control) by vertical positioning.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;   Mark Hadfield, 2003-05:
;     Added an example text object showing the effect of
;     DEPTH_TEST_DISABLE.
;-
pro mgh_example_mask, DOUBLE=double

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   ograph = obj_new('MGHgrGraph2D', NAME='Example graph illustrating masking', $
                    DOUBLE=double)

   ;; Specify the default font

   ograph->NewFont, SIZE=12

   ;; Get the DELTAZ property. We will use this to control visibility
   ;; of overlapping objects

   ograph->GetProperty, DELTAZ=deltaz

   ;; Add a title. By default, the NewTitle method locates the text
   ;; object at the top of the plot, above the mask polygon (added
   ;; later)

   ograph->NewTitle, 'Masking example'

   ;; Create axes. The X axis objects are returned so they can be
   ;; further modified.

   ograph->NewAxis, DIRECTION=0, RANGE=[0,10], TITLE='X axis'
   ograph->NewAxis, DIRECTION=1, RANGE=[1,9], TITLE='Y!U2!N axis'

   ;; Draw the masking polygon around the axes & a background polygon
   ;; as a selection target.

   ograph->NewMask
   ograph->NewBackground

   ;; Add a graphic atom. New graphics atoms by default pick up their
   ;; scaling from the x & y axes.

   ograph->NewAtom, 'IDLgrPlot', DATAX=findgen(11), DATAY=findgen(11), THICK=2

   ;; This line is below the mask polygon so will be clipped

   ograph->NewAtom, 'IDLgrPlot', DATAX=findgen(11), DATAY=findgen(11)+2, THICK=2

   ;; This line is above the mask polygon so will not be clipped

   ograph->NewAtom, 'IDLgrPlot', DATAX=findgen(13), DATAY=findgen(13)-2, $
        THICK=2, /USE_ZVALUE, ZVALUE=2*deltaz

   ;; Text above the mask polygon

   ograph->NewText, 'Some text !Uabove!N the mask', $
        ALIGNMENT=1, LOCATION=[11,3,2*deltaz], /ENABLE_FORMATTING

   ;; Text below the mask polygon

   ograph->NewText, 'Some text !Dbelow!N the mask', $
        ALIGNMENT=1, LOCATION=[11,2,0], /ENABLE_FORMATTING

   ;; Text below the mask polygon with DEPTH_TEST_DISABLE set

   ograph->NewText, 'Text !Dbelow!N with DEPTH_TEST_DISABLE set', $
        ALIGNMENT=1, LOCATION=[10.5,1,0], /ENABLE_FORMATTING, /DEPTH_TEST_DISABLE

   mgh_new, 'MGH_Window', ograph

end

