;+
; CLASS NAME:
;   MGHgrGraph2D
;
; PURPOSE:
;   This class implements a 2D graph with a plot area and space for
;   axes & annotations. It includes several methods for adding axes,
;   plots, and other graphics atoms & models. Most of this
;   functionality is inherited from the superclass, MGHgrGraph, but
;   the MGHgrGraph2D knows where to put its X & Y axes and how to
;   scale them.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   MGHgrGraph.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported in addition to those inherited
;   from MGHgrGraph:
;
;     ALL (Get)
;       This property wraps the object's other properties in a structure.
;
;     ASPECT (Init)
;       A floating point number specifying the ratio between height and
;       width of the plot rectangle (ie. PLOT_RECT[3]/PLOT_RECT[2]). It
;       is used only if PLOT_RECT is not specified.
;
;     PLOT_RECT (Init, Get, Set)
;       This is a 4-element vector, similar in layout to
;       VIEWPLANE_RECT, specifying the location and dimensions in
;       normalised coordinates of the "plot rectangle". By default
;       axes and plots are drawn around, and plots in, the plot
;       rectangle.
;
;     XMARGIN, YMARGIN (Init, Get, Set)
;       2-element vectors specifying the width, in normalised
;       coordinates, of the margins between the plot and viewplane
;       rectanges. Defaults are XMARGIN = [0.375,0.15] and YMARGIN =
;       [0.30,0.225].
;
; METHODS:
;   (under construction)
;
;###########################################################################
; Copyright (c) 2000-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-08:
;     - Replaced existing classes MGHgrView, MGHgrGraph,
;       MGHgrFixedGraph & MGHgrGraph3D with MGHgrGraph (similar to the
;       old MGHgrView), MGHgrGraph2D (merges the old MGHgrGraph &
;       MGHgrFixedGraph) and MGHgrGraph3D (similar to the old class of
;       the same name but much of the logic has been moved to the
;       superclass MGHgrGraph).
;     - Moved auto-scaling of DIMENSIONS based on VIEWPLANE_RECT to
;       MGHgrGraph.
;     - XMARGIN and YMARGIN are no longer stored in the class
;       structure but are calculated as needed from VIEWPLANE_RECT and
;       PLOT_RECT.
;     - Removed the NewText method from this class (which therefore
;       now inherits MGHgrGraph::NewText unchanged). The functionality
;       previously provided by the TITLE keyword to NewText is now in
;       a separate method called NewTitle. The NewTitle method
;       requires its "text class" to have an interface very similar to
;       IDLgrText, whereas the NewText method can be used with any
;       graphics atom class that supports a FONT property and takes up
;       to 1 positional parameter in its Init method.
;     - Added REVERSE keyword to NewAxis to support creation of
;       reverse-direction axes. Doesn't work properly for axis titles,
;       or for Z axes because of a bug in IDL 5.4 beta.
;     - The NewBackground method now creates an MGHgrBackground, which
;       has some properties that make it espacially suitable for this role.
;   Mark Hadfield, 2001-11:
;     - Updated for IDL 5.5.
;     - Added support for ALL property.
;   Mark Hadfield, 2008-08:
;     - The NewColorBar method now calls the method of the same name
;       from the superclass, MGHgrGraph, and has been simplified
;       accordingly.
;   Mark Hadfield, 2011-08:
;     - Added the TICK_ORIENTATION property.
;-

; MGHgrGraph2D::Init

function MGHgrGraph2D::Init, $
     ASPECT=aspect, DIMENSIONS=dimensions, EXAMPLE=example, $
     PLOT_RECT=plot_rect, TICK_ORIENTATION=tick_orientation, $
     XMARGIN=xmargin, YMARGIN=ymargin, $
     VIEWPLANE_RECT=viewplane_rect, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Create a graph with one model.

   ok = self->MGHgrGraph::Init(N_MODELS=1, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGHgrGraph'

   ;; The remainder of the Init method deals with sizing & layout.

   ;; We calculate various quantitities and eventually pass them to
   ;; SetProperty which sorts enerything out. Default values are
   ;; needed for everything except DIMENSIONS and VIEWPLANE_RECT which
   ;; if missing will be calculated based on PLOT_RECT, XMARGIN and
   ;; YMARGIN.

   if n_elements(tick_orientation) eq 0 then tick_orientation = 0B

   ;; All calculations are based on a default plot rectangle size of 1.5.
   ;; This has been chosen so that, allowing for the margins, the viewplane
   ;; dimensions will be *roughly* equal to the default for
   ;; and IDLgrView or MGHgrGraph, i.e. 2 x 2.

   psize = 1.5

   if n_elements(xmargin) eq 0 then xmargin = [0.25,0.10]*psize
   if n_elements(ymargin) eq 0 then ymargin = [0.20,0.15]*psize

   if n_elements(plot_rect) eq 0 then begin

      ;; The default plot rectangle is a square. The ASPECT keyword
      ;; determines the height/width ratio. Height (ysize) and width
      ;; (xsize) are varied in such a way that sqrt(xsize*ysize) stays
      ;; constant up to a point where either xsize or ysize is
      ;; clipped.

      ;; Set default for ASPECT & check value is valid.

      if n_elements(aspect) eq 0 then aspect = 1.

      if ~ finite(aspect) then message, 'Aspect ratio is not finite'

      if aspect le 0 then message, 'Aspect ratio is not positive'

      ;; Calculate X & Y sizes

      ysize = psize * (sqrt(aspect) < 1.6)
      xsize = (ysize/aspect) < (1.6*psize)
      ysize = xsize*aspect

      ;; Plot rectangle is centred on [0,0]

      plot_rect = [-0.5*xsize,-0.5*ysize,xsize,ysize]

   endif

   ;; Let SetProperty sort out all the layout info.

   self->SetProperty, DIMENSIONS=dimensions, PLOT_RECT=plot_rect, $
        TICK_ORIENTATION=tick_orientation, VIEWPLANE_RECT=viewplane_rect, $
        XMARGIN=xmargin, YMARGIN=ymargin

   ;; Example graph

   if keyword_set(example) then begin

      x = findgen(11) & y = x^2

      self->SetProperty, NAME='Example 2D graph - line plot with symbols'

      self->NewFont, SIZE=10

      self->NewAxis, 0, RANGE=mgh_minmax(x), TITLE='X', /EXTEND
      self->NewAxis, 1, RANGE=mgh_minmax(y), TITLE='Y', /EXTEND

      self->NewBackground
      self->NewSymbol, CLASS='MGHgrSymbol', 0, /FILL, COLOR=mgh_color('red')

      self->NewAtom, 'IDLgrPlot', X, Y, COLOR=mgh_color('blue'), $
           SYMBOL=self->GetSymbol()

   endif

   return, 1

end

; MGHgrGraph2D::GetProperty
;
pro MGHgrGraph2D::GetProperty, ALL=all, $
     PLOT_RECT=plot_rect, TICK_ORIENTATION=tick_orientation, $
     XMARGIN=xmargin, YMARGIN=ymargin, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->MGHgrGraph::GetProperty, ALL=all, _STRICT_EXTRA=extra

   plot_rect = self.plot_rect

   tick_orientation = self.tick_orientation

   xmargin = $
        [plot_rect[0]-all.viewplane_rect[0], $
         all.viewplane_rect[0]+all.viewplane_rect[2]-plot_rect[0]-plot_rect[2]]

   ymargin = $
        [plot_rect[1]-all.viewplane_rect[1], $
         all.viewplane_rect[1]+all.viewplane_rect[3]-plot_rect[1]-plot_rect[3]]

   if arg_present(all) then $
        all = create_struct(all, 'plot_rect', plot_rect, $
                            'xmargin', xmargin, 'ymargin', ymargin)

end

; MGHgrGraph2D::SetProperty
;
pro MGHgrGraph2D::SetProperty, PLOT_RECT=plot_rect, $
     TICK_ORIENTATION=tick_orientation, VIEWPLANE_RECT=viewplane_rect, $
     XMARGIN=xmargin, YMARGIN=ymargin, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   recalc_size = 0B

   if n_elements(plot_rect) gt 0 then begin
      recalc_size = 1B
      self.plot_rect = plot_rect
   endif

   if n_elements(tick_orientation) gt 0 then self.tick_orientation = tick_orientation

   if n_elements(viewplane_rect) gt 0 then recalc_size = 1B

   if n_elements(xmargin) gt 0 then recalc_size = 1B

   if n_elements(ymargin) gt 0 then recalc_size = 1B

   if recalc_size then begin

      if n_elements(viewplane_rect) eq 0 then begin
         if n_elements(xmargin) eq 0 then self->GetProperty, XMARGIN=xmargin
         if n_elements(ymargin) eq 0 then self->GetProperty, YMARGIN=ymargin
         viewplane_rect = $
              [self.plot_rect[0] - xmargin[0], $
               self.plot_rect[1] - ymargin[0], $
               self.plot_rect[2] + xmargin[0]+xmargin[1], $
               self.plot_rect[3] + ymargin[0]+ymargin[1]]
      endif

      self->MGHgrGraph::SetProperty, VIEWPLANE_RECT=viewplane_rect

   endif

   self->MGHgrGraph::SetProperty, _STRICT_EXTRA=extra

end


; MGHgrGraph2D::Cleanup
;
pro MGHgrGraph2D::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->MGHgrGraph::Cleanup

end

; MGHgrGraph2D::NewAxis (Function & Procedure)
;
;   Create an axis with the appropriate scaling, add it to the plot
;   and return the object reference. This method extends
;   MGHgrGraph::NewAxis in that (by default) it creates X & Y axes
;   in pairs at the left & right or bottom & top of the plot rectangle.
;   Z axes can also be created but are not fitted to the plot rectangle.
;
function MGHgrGraph2D::NewAxis, dir, $
     DIRECTION=direction, LOCATION=location, $
     MIRROR=mirror, NORM_RANGE=norm_range, $
     NOTEXT=notext, RECT=rect, $
     REVERSE_RANGE=reverse_range, $
     TEXTBASELINE=textbaseline, TEXTPOS=textpos, $
     TEXTUPDIR=textupdir, TICKDIR=tickdir, $
     _REF_EXTRA=extra

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  if n_elements(direction) eq 0 then begin
    direction = n_elements(dir) gt 0 ? dir : 0
  endif
  
  if direction eq 2 then begin
  
    ;; If creating a vertical axis just pass everything to
    ;; MGHgrGraph::NewAxis (ignoring REVERSE_RANGE keyword).
    
    axis = self->MGHgrGraph::NewAxis(DIRECTION=direction, LOCATION=location, $
                                     NORM_RANGE=norm_range, NOTEXT=notext, $
                                     TEXTBASELINE=textbaseline, TEXTPOS=textpos, $
                                     TEXTUPDIR=textupdir, TICKDIR=tickdir, $
                                     _STRICT_EXTRA=extra)
    return, axis
    
  endif
  
  ;; By default horizontal axes are created in pairs at the edges of
  ;; the plot rectangle
  
  self->GetProperty, DELTAZ=deltaz
  
  if n_elements(rect) eq 0 then self->GetProperty, PLOT_RECT=rect
  
  if n_elements(mirror) eq 0 then mirror = [0,1]
  
  if n_elements(reverse_range) eq 0 then reverse_range = 0
  
  if n_elements(norm_range) eq 0 then begin
    case reverse_range of
      0: norm_range = [rect[direction],rect[direction]+rect[direction+2]]
      1: norm_range = [rect[direction]+rect[direction+2],rect[direction]]
    endcase
  endif
  
  if n_elements(textbaseline) eq 0 then begin
    textbaseline = [1,0,0]
    if reverse_range then if direction eq 0 then $
      textbaseline = - textbaseline
  endif
  
  if n_elements(textupdir) eq 0 then begin
    textupdir = [0,1,0]
    if reverse_range then if direction eq 1 then textupdir = - textupdir
  endif
  
  n_mirror = n_elements(mirror)
  
  axes = n_mirror gt 0 ? objarr(n_mirror) : obj_new()
  
  for i=0,n_mirror-1 do begin
  
    case mirror[i] of

      0: begin
        my_location = n_elements(location) gt 0 ? location : [ rect[0:1], 2*deltaz ]
        my_notext = n_elements(notext) gt 0 ? notext : 0
        my_tickdir = n_elements(tickdir) gt 0 ? tickdir : (1-self.tick_orientation)
        my_textpos = n_elements(textpos) gt 0 ? textpos : 0
      end
      
      1: begin
        my_location = n_elements(location) gt 0 ? location : [ rect[0:1]+rect[2:3], 2*deltaz ]
        my_notext = n_elements(notext) gt 0 ? notext : 1
        my_tickdir = n_elements(tickdir) gt 0 ? tickdir : self.tick_orientation
        my_textpos = n_elements(textpos) gt 0 ? textpos : 1
      end
      
    endcase
    
    axes[i] = self->MGHgrGraph::NewAxis(DIRECTION=direction, LOCATION=my_location, $
                                        NORM_RANGE=norm_range, NOTEXT=my_notext, $
                                        TEXTBASELINE=textbaseline, $
                                        TEXTUPDIR=textupdir, TICKDIR=my_tickdir, $
                                        TEXTPOS=my_textpos, _STRICT_EXTRA=extra)
      
  endfor
  
  for i=1,n_elements(axes)-1 do axes[0]->AddSlave, axes[i], /AXIS
    
  return, axes

end

; MGHgrGraph2D::NewBackground
;
;   Draw a rectangle immediately in front of the rear clipping plane,
;   to provide a selection target and maybe for cosmetic ressons.
;   The rectangle picks up its size & scaling from axes in the same way as other atoms.

function MGHgrGraph2D::NewBackground, $
     MODEL=model, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, XRANGE=xrange, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, YRANGE=yrange, $
     ZVALUE=zvalue, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->GetScaling, MODEL=model, XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv

   if n_elements(xrange) ne 2 then begin
      case obj_valid(xaxis[0]) of
         0B: xrange = [0,1]
         1B: xaxis[0]->GetProperty, CRANGE=xrange
      endcase
   end

   if n_elements(yrange) ne 2 then begin
      case obj_valid(yaxis[0]) of
         0B: yrange = [0,1]
         1B: yaxis[0]->GetProperty, CRANGE=yrange
      endcase
   end

   ;; Specify default for ZVALUE. It appears to be necessary to
   ;; position the polygon well in front of the rear clipping plane
   ;; for data picking to work properly. The following spacing
   ;; (5*deltaz) works on the Win32 hardware & software renderers.

   if n_elements(zvalue) ne 1 then begin
      self->GetProperty, ZCLIP=zclip, DELTAZ=deltaz
      zvalue = zclip[1]+5*deltaz
   endif

   ;; Default color is same as the view's background

   self->GetProperty, COLOR=color

   ;; Create atom & return reference

   return, self->NewAtom('MGHgrBackground', $
                         xrange[[0,1,1,0]], yrange[[0,0,1,1]], $
                         replicate(zvalue,4), MODEL=model, $
                         XAXIS=xaxis, XCOORD=xcoord_conv, $
                         YAXIS=yaxis , YCOORD=ycoord_conv, $
                         ZCOORD=[0,1], COLOR=color, NAME='Background', $
                         _STRICT_EXTRA=extra)

end


; MGHgrGraph2D::NewColorBar
;
;   Draw a colour bar with locations and dimensions specified in
;   normalised coordinates.
;
function MGHgrGraph2D::NewColorBar, $
     DIMENSIONS=dimensions, LOCATION=location, VERTICAL=vertical, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, DELTAZ=deltaz, PLOT_RECT=prect

   if n_elements(vertical) eq 0 then vertical = 1B
   
   if keyword_set(vertical) then begin
      if n_elements(dimensions) eq 0 then $
           dimensions = [0.08,0.7*prect[3]]
      if n_elements(location) eq 0 then $
           location = $
                [prect[0]+prect[2]+self.ticklen+0.05, $
                 prect[1]+0.5*prect[3]-0.5*dimensions[1], $
                 2*deltaz]
   endif else begin
      if n_elements(dimensions) eq 0 then $
           dimensions = [0.7*prect[2],0.08]
      if n_elements(location) eq 0 then $
           location = $
                [prect[0]+0.5*prect[2]-0.5*dimensions[0], $
                 prect[1]-self.ticklen-0.15, $
                 2*deltaz]
   endelse

   ;; Create & return
   
   result = self->MGHgrGraph::NewColorBar(DIMENSIONS=dimensions, LOCATION=location, $
                                          VERTICAL=vertical, _STRICT_EXTRA=extra)
                                      
   return, result                                      
   
end

; MGHgrGraph2D::NewMask (Function & Procedure)
;
;   Draw a polygon close in front of the viewplane, masking the area
;   outside the plot rectangle (or other specified rectangle). Objects
;   drawn behind this will be obscured.
;
function MGHgrGraph2D::NewMask, COLOR=color, NAME=name, RECT=rect, $
     ZVALUE=zvalue, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->GetProperty, DELTAZ=deltaz

   if n_elements(zvalue) ne 1 then zvalue = deltaz

   if n_elements(color) eq 0 then self->GetProperty, COLOR=color

   if n_elements(name) eq 0 then name = 'Mask'

   if n_elements(rect) eq 0 then self->GetProperty, PLOT_RECT=rect

   self->GetProperty, VIEWPLANE_RECT=vrect

   ;; Calculate X & Y positions of the inside corners of the mask.

   xr = [rect[0],rect[0]+rect[2]]
   yr = [rect[1],rect[1]+rect[3]]

   ;; Calculate X & Y positions of the outside corners of the mask Add
   ;; plenty of additional space to make the observer can't peak
   ;; around the edge of the mask

   xv = [vrect[0],vrect[0]+vrect[2]] + [-10,10]*rect[2]
   yv = [vrect[1],vrect[1]+vrect[3]] + [-10,10]*rect[3]

   ;; Just to be clever we use a Tessellator object to construct the
   ;; mask polygons

   tess = obj_new('IDLgrTessellator')
   tess->AddPolygon, xv[[0,1,1,0]], yv[[0,0,1,1]], replicate(zvalue,4)
   ;; INTERIOR keyword is unnecessary (and results in warning message)
   ;; for IDL 5.6 and later
   tess->AddPolygon, xr[[0,1,1,0]], yr[[0,0,1,1]], replicate(zvalue,4)
   if ~ tess->Tessellate(vert, conn) then $
        message, 'Tessellation failed.'
   obj_destroy, tess

   ;; Call NewAtom to create the polygon. X, Y & Z coordinate
   ;; conversions are specified explicitly, so will not be read from
   ;; axes.

   return, self->NewAtom('IDLgrPolygon', COLOR=color, DATA=vert, NAME=name, $
                         POLYGONS=conn, XAXIS=0, YAXIS=0, ZAXIS=0, $
                         _STRICT_EXTRA=extra)

end

; MGHgrGraph2D::NewTitle
;
function MGHgrGraph2D::NewTitle, P1, $
     LOCATIONS=locations, RECT=rect, STRINGS=strings, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->GetProperty, $
        DELTAZ=deltaz, PLOT_RECT=plot_rect, TICKLEN=ticklen

   ;; Default location is above the top edge of the rectangle,
   ;; 2*DELtAZ above the viewplane.

   if n_elements(rect) eq 0 then rect = plot_rect

   if n_elements(locations) eq 0 then $
        locations = [rect[0] + 0.5*rect[2], $
                     rect[1] + 1.0*rect[3] + 0.5*ticklen + 0.05]

   if n_elements(locations) eq 2 then locations = [locations, 4*deltaz]

   ;; Default text is object NAME

   if n_elements(strings) eq 0 then begin
      case n_elements(p1) gt 0 of
         0B: self->GetProperty, NAME=strings
         1B: strings = p1
      endcase
   endif

   ;; Generate & return atom. Location is unscaled.

   return, $
        self->NewText(XAXIS=0, YAXIS=0, ZAXIS=0, ALIGNMENT=0.5, $
                      LOCATIONS=locations, NAME='Title', STRINGS=strings, $
                      VERTICAL_ALIGNMENT=0.0, _STRICT_EXTRA=extra )

end

; MGHgrGraph2D::Rect
;
; This function returns a 4-element vector specifying a rectangular
; area of the graph, given an input vector specifying the rectangle in
; "fractional coordinates" (i.e. bottom left-hand corner of the plot
; rectangle is [0,0], top right-hand corner is [1,1]). The result has
; the same form as VIEWPLANE_RECT & PLOT_RECT properties, i.e. [x
; offset, y offset, w width, y width].
;
function MGHgrGraph2D::Rect, nrect

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(nrect) eq 0 then nrect = [0,0,1,1]

   if n_elements(nrect) ne 4 then $
        message, 'The argument, if supplied, must be a 4-element numeric vector'

   self->GetProperty, PLOT_RECT=prect

   return, [ prect[0] + nrect[0]*prect[2], $
             prect[1] + nrect[1]*prect[3], $
             nrect[2]*prect[2], $
             nrect[3]*prect[3] ]

end

; Procedure forms for the "New..." functions. We only need to include
; the ones not inherited from MGHgrGraph

pro MGHgrGraph2D::NewBackground, RESULT=result, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   result = self->NewBackground( _STRICT_EXTRA=extra )

end

pro MGHgrGraph2D::NewMask, RESULT=result, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = self->NewMask(_STRICT_EXTRA=extra)

end

pro MGHgrGraph2D::NewTitle, P1, RESULT=result, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   case n_params() of
      0: result = self->NewTitle( _STRICT_EXTRA=extra )
      1: result = self->NewTitle(P1, _STRICT_EXTRA=extra )
   endcase

end


; MGHgrGraph2D__Define

pro MGHgrGraph2D__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   struct_hide, $
        {MGHgrGraph2D, inherits MGHgrGraph, $
         plot_rect: fltarr(4), tick_orientation: 0B}

end


