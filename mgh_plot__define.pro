;+
; CLASS NAME:
;   MGH_Plot
;
; PURPOSE:
;   This class implements a line plot. It inherits from MGH_Window,
;   adding code in the Init method to produce and IDLgrPlot object.
;
; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'MGH_Plot', findgen(11)
;
; POSITIONAL PARAMETERS:
;   The Init method accepts up to 3 positional parameters. It passes
;   them to the IDLgrPlot object.
;
; KEYWORD PARAMETERS:
;   The Init method accepts the following keyword parameters. All
;   other keywords are passed to the Init method of the superclass
;   (MGH_Window):
;
;     FONT_PROPERTIES (input, structure)
;       A structure containing keywords to be passed to the graph's
;       default-font object.
;
;     GRAPH_PROPERTIES (input, structure)
;       A structure containing keywords to be passed to the graph.
;
;     MASK_PROPERTIES (input, structure)
;       A structure containing keywords to be passed to the graph's
;       clipping mask.
;
;     PLOT_PROPERTIES (input, structure)
;       A structure containing keywords to be passed to the line plot.
;
;     SYMBOL_PROPERTIES (input, structure)
;       A structure containing keywords to be passed to the line
;       plot's symbol. This keyword breaks the convention set by other
;       *_PROPERTIES keywords in that a symbol is created *only* if
;       the keyword is supplied.
;
;     XAXIS_PROPERTIES (input, structure)
;     YAXIS_PROPERTIES (input, structure)
;       Structures containing keywords to be passed to the X/Y axis
;
;     XRANGE (input, 2-element numeric vector)
;     YRANGE (input, 2-element numeric vector)
;       Default values are calculated from data (if any) passed to the
;       line plot.
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
;   Mark Hadfield, 2002-06:
;     Most of the functionality in the old MGH_Plot class has now been
;     moved to the new MGH_Window class. The MGH_Plot class now
;     inherits from MGH_Window and adds functionality in the Init
;     method to draw a line-plot object.
;-

; MGH_Plot::Init
;
function MGH_Plot::Init, P1, P2, $
     EXAMPLE=example, $
     FONT_PROPERTIES=font_properties, $
     GRAPH_PROPERTIES=graph_properties, $
     MASK_PROPERTIES=mask_properties, $
     PLOT_PROPERTIES=plot_properties, $
     SYMBOL_PROPERTIES=symbol_properties, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, $
     XRANGE=xrange, YRANGE=yrange, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(example) then begin

      if n_elements(p1) eq 0 then p1 = findgen(21)
      if n_elements(p2) eq 0 then p2 = p1*p1

      if n_elements(plot_properties) eq 0 then $
           plot_properties = {color: mgh_color('blue')}

      if n_elements(symbol_properties) eq 0 then $
           symbol_properties = {class: 'MGHgrSymbol', style: 0, fill: 1B, $
                                color: mgh_color('red')}

      if n_elements(xaxis_properties) eq 0 then $
           xaxis_properties = {title: 'X'}

      if n_elements(yaxis_properties) eq 0 then $
           yaxis_properties = {title: 'Y'}

   endif

   ;; Interpret X & Y data

   do_plot = n_elements(p1) gt 0

   if do_plot then begin

      case 1 of
         n_elements(p2) eq 0: begin
            datax = lindgen(n_elements(P1))
            datay = P1
         end
         else: begin
            datax = P1
            datay = P2
         end
      endcase

   endif

   ;; Determine axis ranges

   if n_elements(xrange) eq 0 &&  n_elements(datax) gt 0 then $
        xrange = mgh_minmax(datax, /NAN)

   if n_elements(yrange) eq 0 && n_elements(datay) gt 0 then $
        yrange = mgh_minmax(datay, /NAN)

   if n_elements(xrange) eq 0 then xrange = [-1,1]
   if n_elements(yrange) eq 0 then yrange = [-1,1]

   if xrange[0] eq xrange[1] then xrange += [-1,1]
   if yrange[0] eq yrange[1] then yrange += [-1,1]

   ;; Create the graph.

   mgh_new, 'MGHgrGraph2D', NAME='X-Y line plot', $
            /REGISTER_PROPERTIES, _STRICT_EXTRA=graph_properties, RESULT=ograph

   ograph->NewMask, /REGISTER_PROPERTIES, _STRICT_EXTRA=mask_properties

   ograph->NewFont, _STRICT_EXTRA=font_properties

   ;; Create axes.

   ograph->NewAxis, 0, RESULT=xaxis, /EXTEND, RANGE=xrange, $
                    /REGISTER_PROPERTIES, _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, 1, RESULT=yaxis, /EXTEND, RANGE=yrange, $
                    /REGISTER_PROPERTIES, _STRICT_EXTRA=yaxis_properties

   ;; Add background

   ograph->NewBackground, /REGISTER_PROPERTIES

   ;; Create symbol

   if n_elements(symbol_properties) gt 0 then $
        ograph->NewSymbol, _STRICT_EXTRA=symbol_properties, RESULT=symbol

   ;; Draw the line plot

   if do_plot then begin
      ograph->NewAtom, 'IDLgrPlot', DATAX=datax, DATAY=datay, $
                       SYMBOL=symbol, /REGISTER_PROPERTIES, _STRICT_EXTRA=plot_properties
   endif

   ;; Initialise MGH_Window. MOUSE_ACTION default is changed to
   ;; appropriate ones for a 2D plot.

   mouse_action = ['Zoom XY','Pick','Context']

   ok = self->MGH_Window::Init(ograph, CHANGEABLE=0, MOUSE_ACTION=mouse_action, $
                               _STRICT_EXTRA=extra)

   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Window'

   ;; Finalise.

   self->Finalize, 'MGH_Plot'

   return, 1

end

; MGH_Plot::GetProperty
;
pro MGH_Plot::GetProperty, $
     ALL=all, DELTAZ=deltaz, GRAPHICS_TREE=graphics_tree, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::GetProperty, $
        ALL=all, GRAPHICS_TREE=graphics_tree, _STRICT_EXTRA=extra

   graphics_tree->GetProperty, DELTAZ=deltaz

   if arg_present(all) then $
        all = create_struct(all, 'deltaz', deltaz)

end


; MGH_Plot::NewPlot
;
pro MGH_Plot::NewPlot, P1, P2, $
     PLOT_PROPERTIES=plot_properties, $
     SYMBOL_PROPERTIES=symbol_properties, UPDATE=update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(update) eq 0 then update = 1B

   self->GetProperty, GRAPHICS_TREE=ograph

   if n_elements(symbol_properties) gt 0 then $
        ograph->NewSymbol, _STRICT_EXTRA=symbol_properties, RESULT=symbol

   case n_params() of
      0: begin
         ograph->NewAtom, 'IDLgrPlot', $
              SYMBOL=symbol, _STRICT_EXTRA=plot_properties
      end
      1: begin
         ograph->NewAtom, 'IDLgrPlot', P1, $
              SYMBOL=symbol, _STRICT_EXTRA=plot_properties
      end
      2: begin
         ograph->NewAtom, 'IDLgrPlot', P1, P2, $
              SYMBOL=symbol, _STRICT_EXTRA=plot_properties
      end
   endcase

   if keyword_set(update) then self->Update

end

; MGH_Plot__Define

pro MGH_Plot__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Plot, inherits MGH_Window}

end
