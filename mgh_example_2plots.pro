 ;+
; NAME:
;   MGH_EXAMPLE_2PLOTS
;
; PURPOSE:
;   Object graphics example: 2 line plots side by side.
;
;###########################################################################
; Copyright (c) 2000-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;-
pro mgh_example_2plots, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   ;; Two line plots side-by-side, depending on the value of option:
   ;;
   ;;   0  One graph object with two panes
   ;;   1  A viewgroup containing 2 separate graph objects
   ;;   2  A scene containing 2 separate graph objects

   x = 0.1*findgen(11)  &  y = x^2  &  z = sqrt(x)

   case 1 of

      option eq 0: begin

         ;; Option 0: One graph object with two panes

         ograph = obj_new('MGHgrGraph2D', NAME='A graph with two panes', ASPECT=0.5)

         spacing = 0.03

         ;; Add two panes, specifying for each a bounding rectangle, a
         ;; set of axes and a line plot. By default each plot is
         ;; associated with the x & y axes most recently added to the
         ;; graph

         ;; First pane

         rect = ograph->Rect([0,0,0.5-spacing,1])

         ograph->NewAxis, 0, RANGE=mgh_minmax(x), RECT=rect
         ograph->NewAxis, 1, RANGE=mgh_minmax(y), RECT=rect

         ograph->NewAtom, 'IDLgrPlot', DATAX=x, DATAY=y

         ;; Second pane. We need to specify the x & y axes here when
         ;; creating the plot object, otherwise the NewAtom method
         ;; will search for the first ones in the model. Note that
         ;; MGHgrGraph2D::NewAxis returns a two-element vector by
         ;; default, and it is permissible to pass this to NewAtom
         ;; (which ignores all but the first element).

         rect = ograph->Rect([0.5+spacing,0,0.5-spacing,1])

         ograph->NewAxis, 0, RANGE=mgh_minmax(x), RECT=rect, RESULT=xaxis
         ograph->NewAxis, 1, RANGE=mgh_minmax(z), RECT=rect, RESULT=yaxis, /NOTEXT

         ograph->NewAtom, 'IDLgrPlot', DATAX=x, DATAY=z, XAXIS=xaxis, YAXIS=yaxis

         mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph

      end

      option eq 1 || option eq 2: begin

         ;; Options 1 & 2: Two separate graph objects in a viewgroup
         ;; or scene

         case option of
            1: ogroup = obj_new('IDLgrViewgroup', NAME='Two graphs in a viewgroup')
            2: ogroup = obj_new('IDLgrScene', NAME='Two graphs in a scene')
         endcase

         ograph = objarr(2)
         
         mgh_graph_default, SCALE=default_scale
         
         for i=0,n_elements(ograph)-1 do begin

            ograph[i] = obj_new('MGHgrGraph2D', ASPECT=1.1, SCALE=0.7*default_scale)

            ograph[i]->NewMask

            case i of

               0: begin
                  ograph[i]->SetProperty, NAME='Left-hand graph'
                  ograph[i]->NewAxis, DIRECTION=0, RANGE=mgh_minmax(x)
                  ograph[i]->NewAxis, DIRECTION=1, RANGE=mgh_minmax(y)
                  ograph[i]->NewAtom, 'IDLgrPlot', DATAX=x, DATAY=y
                  ograph[i]->GetProperty, XMARGIN=xmargin  &  xmargin[1] = 0.05
                  ograph[i]->SetProperty, XMARGIN=xmargin
               end

               1: begin
                  ograph[i]->SetProperty, NAME='Right-hand graph'
                  ograph[i]->NewAxis, DIRECTION=0, RANGE=mgh_minmax(x)
                  ograph[i]->NewAxis, DIRECTION=1, RANGE=mgh_minmax(z), /NOTEXT
                  ograph[i]->NewAtom, 'IDLgrPlot', DATAX=x, DATAY=z
                  ograph[i]->GetProperty, XMARGIN=xmargin  &  xmargin[0] = 0.05
                  ograph[i]->SetProperty, XMARGIN=xmargin
               end

            endcase

         endfor

         ogroup->Add, ograph

         ograph[0]->GetProperty, DIMENSIONS=dim
         ograph[1]->SetProperty, LOCATION=[dim[0],0]

         mgh_new, 'MGH_Window', GRAPHICS_TREE=ogroup

      end

   endcase

end

