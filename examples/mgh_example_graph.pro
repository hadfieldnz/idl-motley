; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_GRAPH
;
; PURPOSE:
;   An example to demonstrate an MGHgrGraph and its facilities for
;   handling of axes, symbols, fonts and for adding and scaling
;   graphics atoms.
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
;   Mark Hadfield, 2001-02:
;     Written.
;   Mark Hadfield, 2004-03:
;     Updated for IDL 6.0.
;-


pro mgh_example_graph, USE_AXES=use_axes

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(use_axes) eq 0 then use_axes = 1B

   ;; Create some data

   x = findgen(11)
   y = x*x

   ;; Create the view

   ograph = obj_new('MGHgrGraph')

   ;; Attach a font. This is added to a container & will be destroyed
   ;; with the view

   ograph->NewFont, SIZE=12

   case use_axes of

      0: begin

         ograph->SetProperty, NAME='MGHgrGraph example without axes'

         ;; Calculate x & y scaling needed to map the data range to the normalised
         ;; range [-0.6,0.6]

         xcoord = mgh_norm_coord(mgh_minmax(x), [-0.6,0.6])
         ycoord = mgh_norm_coord(mgh_minmax(y), [-0.6,0.6])

         ;; Attach a symbol. Like the font this is added to a
         ;; container & will be destroyed with the view. The symbol
         ;; should be given the same scaling as the atom that uses it.

         ograph->NewSymbol, CLASS='MGHgrSymbol', 0, /FILL, COLOR=mgh_color('red'), $
              XCOORD=xcoord, YCOORD=ycoord

         ;; Add a line plot object using the symbol

         ograph->NewAtom, 'IDLgrPlot', x, y, SYMBOL=ograph->GetSymbol(), $
              XCOORD=xcoord, YCOORD=ycoord

         ;; Add a text object using the font. Leave this unscaled.

         ograph->NewAtom, 'IDLgrText', 'MGHgrGraph example', FONT=ograph->GetFont(), $
              ALIGN=0.5, LOCATIONS=[0,0.8], RECOMPUTE=2

      end

      1: begin

         ograph->SetProperty, NAME='MGHgrGraph example with axes'

         ;; Add a pair of axes, specifying LOCATION (a point through
         ;; which the axes pass) and the NORM_RANGE (axis end-points
         ;; in normalised coordinates in tha along-axis direction).
         ;; The axis is scaled (in the along-axis direction only) to
         ;; fit into NORM_RANGE.

         ograph->NewAxis, DIRECTION=0, RANGE=mgh_minmax(x), $
              LOCATION=[0,-0.8], NORM_RANGE=[-0.6,0.6]
         ograph->NewAxis, DIRECTION=1, RANGE=mgh_minmax(y), $
              LOCATION=[-0.8,0], NORM_RANGE=[-0.6,0.6]

         ;; Attach a symbol. Like the font this is added to a
         ;; container & will be destroyed with the view. The symbol,
         ;; like other atoms, picks up its scaling from the axes so
         ;; should be added after the axes.

         ograph->NewSymbol, CLASS='MGHgrSymbol', 0, /FILL, COLOR=mgh_color('red')

         ;; Add a line plot object using the symbol

         ograph->NewAtom, 'IDLgrPlot', x, y, SYMBOL=ograph->GetSymbol()

         ;; Add a text object using the font. Just for fun, we give the location in
         ;; normalised coordinates and specify XAXIS=0, YAXIS=0 to suppress automatic
         ;; axis scaling.

         ograph->NewAtom, 'IDLgrText', 'MGHgrGraph example', $
              FONT=ograph->GetFont(), ALIGN=0.5, $
              XAXIS=0, YAXIS=0, LOCATIONS=[0,0.8], RECOMPUTE=2

      end

   endcase

   ;; Display the view in an MGH_Window object.

   mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph

end
