 ;+
; NAME:
;   MGH_EXAMPLE_SCATTER
;
; PURPOSE:
;   3D scatter plot example.
;
;   For a discussion of the different representations possible for a
;   3D scatter plot in object graphics see:
;
;     http://www.sljus.lu.se/stm/IDL/misc/scatter_surface.txt
;
;   I used this procedure to test relative times for creating & drawing
;   different symbol types. In each case I used STYLE=0 (single polyline
;   with a single symbol object) and N_POINTS=10000. Times for execution
;   of the procedure (IDL 5.3 on Pentium II 400 MHz) were compared for
;   different symbol types:
;
;     IDLgrSymbol with DATA=6 (square):                       0.78 s
;
;     IDLgrSymbol with DATA set to a 4-vertex polyline        1.52 s
;
;     IDLgrSymbol with DATA set to a 16-vertex polyline       1.68 s
;
;     IDLgrSymbol with DATA set to a model containing a
;     4-vertex polyline                                       1.91 s
;
;     IDLgrSymbol with DATA set to a model containing a
;     16-vertex polyline                                      2.08 s
;
;     IDLgrSymbol with DATA set to a 4-vertex polygon         1.72 s
;
;   Conclusions:
;
;     - The simplest user-defined symbols (DATA = a polyline) are about
;     a factor of 2 slower than the built-in symbols.
;
;     - Drawing time increases with the number of vertices in the symbol,
;     but much slower than linearly.
;
;     - Filled symbols (polygons) are 13% slower than unfilled symbols
;     (polylines).
;
;     - The extra indirection involved with embedding the user-defined
;     symbol in a model adds 25% to drawing time
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
;   Mark Hadfield, 2001-06:
;     Written.
;-
pro mgh_example_scatter, style, N_POINTS=n_points

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(style) eq 0 then style = 0

   if n_elements(n_points) eq 0 then n_points = 400

   ograph = obj_new('MGHgrGraph3D', NAME='3D scatter plot')

   ograph->NewTitle

   x = randomn(seed, n_points)
   y = 10*randomn(seed, n_points)
   z = randomn(seed, n_points)

   ograph->NewAxis, DIRECTION=0, RANGE=[-4,4], TITLE='X'
   ograph->NewAxis, DIRECTION=1, RANGE=[-40,40], TITLE='Y'
   ograph->NewAxis, DIRECTION=2, RANGE=[-4,4], TITLE='Z'

   case style of

      0: begin
         ;; A single polyline with invisible lines & a single symbol
         ograph->NewSymbol, 0, COLOR=mgh_color('red'), $
              N_VERTICES=6, RESULT=osym
         ograph->NewAtom, 'IDLgrPolyline', x, y, z, LINESTYLE=6, SYMBOL=osym
      end

      1: begin
         ;; As 0, but symbols are coloured with the polyline's VERT_COLORS property.
         ograph->NewPalette, 5, RESULT=opal
         ograph->NewSymbol, CLASS='mghgrsymbol', 0, N_VERTICES=6, RESULT=osym
         ograph->NewAtom, 'IDLgrPolyline', x, y, z, $
              LINESTYLE=6, SYMBOL=osym, PALETTE=opal, VERT_COLORS=bindgen(n_elements(z))
      end

      2: begin
         ;; The cloud of points is represented by a text object.
         ograph->NewFont, SIZE=8, NAME='Hershey*3', RESULT=symfont
         ograph->NewText, replicate('+', n_points), COLOR=mgh_color('red'), $
              LOCATIONS=transpose([[x],[y],[z]]), ALIGN=0.5, $
              VERTICAL_ALIGN=0.5, FONT=symfont, /ONGLASS
      end

   endcase

   mgh_new, 'MGH_Window', ograph, MOUSE_ACTION=['Rotate','Pick','Context']

end


