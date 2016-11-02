;+
; CLASS NAME:
;   MGHgrGraph
;
; PURPOSE:
;   An MGHgrGraph is an IDLgrView with extra facilities that make it
;   useful as a container for general-purpose scientific graphs. These
;   include:
;
;     - Containers to hold resources (fonts, symbols, palettes)
;       required by graphics atoms.
;     - Methods to create axes and fit them to the view dimensions.
;     - Methods to create or add graphics atoms and scale them to the
;       axes.
;     - By default, there is a fixed relationship between the
;       viewplane dimensions in normalised and physical
;       coordinates. (This means that you can assume that a graphics
;       atom that is "square" in normalised coordinates will be square
;       on the destination device.)
;
;   An MGHgrGraph does not assume anything in particular about the
;   layout of the graph. The default axis location and length (centred
;   in the viewplane with length 1 in normalised coordinates) makes
;   sure that the axes will be seen but will need to be modified for
;   actual graphs. Thus this class be useful mainly for "free-form"
;   graphs; for most purposes it be used via a subclass such as
;   MGHgrGraph2D or MGHgrGraph3D.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   IDLgrView.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported in addition to those inherited
;   from IDLgrView:
;
;     ALL (Get)
;       This property wraps the object's other properties in a structure.
;
;     DELTAZ (Get)
;       This is a real number specifying the minimum spacing, in
;       normalised coordinates, needed in the Z direction to ensure
;       that graphic atoms overlap cleanly. The value is calculated
;       from the ZCLIP property (inherited from IDLgrView).
;
;     DIMENSIONS (Init, Get, Set)
;       As IDLgrView, but by default an MGHgrGraph object is created
;       with explicit dimensions calculated from the VIEWPLANE_RECT
;       and SCALE properties. Thereafter, if the VIEWPLANE_RECT is
;       altered then DIMENSIONS are also altered so as to preserve
;       SCALE.
;
;     FONTSIZE (Init, Get, Set)
;       The default size in points for font objects created by the
;       NewFont method. The default value is determined by
;       MGH_GRAPH_DEFAULT.
;
;     N_MODELS (Init, Get)
;       The number of IDLgrModel objects directly attached to the
;       graph.
;
;     SCALE (Init, Get, Set)
;       This is a 2-element vector specifying the size in physical
;       dimensions of a unit square on the viewplane. The GetProperty
;       method always returns a 2-element vector for SCALE, but in
;       calls to Init and SetProperty it should normally be specified
;       as a scalar, indicating that the scale is the same in X & Y
;       dimensions. The default value of SCALE depends on the UNITS
;       property: for UNITS = 2 it is 7.5 cm. A SCALE of 0 or [0,0]
;       indicates that the graph's dimensions are not specified
;       explicitly (i.e. UNITS = 3 or DIMENSIONS = [0,0]).
;
;     SYMSIZE (Init, Get, Set)
;       The default size in normalised coordinates for symbols created
;       by the NewSymbol method. Default value is 0.02D0.
;
;     TICKLEN (Init, Get, Set)
;       The default tickmark length in normalised coordinates for axes
;       created by the NewAxis method. Default value is 0.03.
;
;     UNITS (Init, Get, Set)
;       As IDLgrView, but default is 2 (dimensions specified in cm).
;
; METHODS:
;   Most of the methods that create new objects can be called as
;   functions (returning the object reference(s)) or procedures
;   (references discarded).
;
;     NewFont
;       Create a new font object and add it to a container attached to
;       the view. Fonts can be retrieved with the GetFont method and
;       are destroyed with the view. Several of the methods below use
;       the first font in the container when creating text objects.
;
;     AddFont
;       Like NewFont, but use an existing font. Obsolete.
;
;     GetFont
;       Retrieve object references from the fonts container. Similar
;       syntax to IDL_Container::Get.
;
;     NewSymbol
;       Create a new symbol object and add it to a container attached
;       to the view. Symbols can be retrieved with the GetSymbol
;       method and are destroyed with the view. The default symbol
;       size, taken from the SYMSIZE property, can be overriden via
;       the SIZE keyword.
;
;     GetSymbol
;       Retrieve object references from the symbols container. Similar
;       syntax to IDL_Container::Get.
;
;     Dispose
;       Add an object (eg a palette) to a container for disposal with
;       the graph.
;
;     NewAtom
;       Create a graphics atom (or atom-like object) and add it to the
;       graph. NewAtom is either invoked directly or via a wrapper
;       method (below); it takes care of associating the new object
;       with the right model & axes. The object type is specified via
;       the first parameter & NewAtom can accept up to 3 further
;       positional parameters, which are passed to the object's Init
;       method.
;
;     AddAtom
;       Take an existing graphics atom, add it to the graph and
;       associate it with the right model & axes. This is not used as
;       often as NewAtom, but is appropriate, for example, when the
;       size of a graphics atom will not be known until after it is
;       created.
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
;     - Replaced existing classes MGHgrView, MGHgrGraph,
;       MGHgrFixedGraph & MGHgrGraph3D with MGHgrGraph (similar to the
;       old MGHgrView), MGHgrGraph2D (merges the old MGHgrGraph &
;       MGHgrFixedGraph) and MGHgrGraph3D (similar to the old class of
;       the same name but much of the logic has been moved to the
;       superclass MGHgrGraph).
;     - Added a facility for graphs to use master-slave axes, enabled
;       by the property USE_MSAXIS, which defaults to 0. In sorting
;       this out I introduced a significant backward-incompatible
;       change: the GetScaling method picks up its scaling from the
;       first suitable axis it finds, not the last. The new convention
;       makes the implementation of master-slave graphs much simpler
;       and more logical, but the preparation of multi-scaled graphs
;       becomes less convenient.
;   Mark Hadfield, 2001-01:
;     - NewText method now sets the text object's RECOMPUTE_DIMENSIONS
;       property to 2 by default.
;   Mark Hadfield, 2001-05:
;     - Models created by the view are now instances of
;       MGHgrModel. Each MGHgrModel keeps track of the axes that have
;       been added to it, which this allows the MGHgrGraph code to be
;       simpler.
;   Mark Hadfield, 2002-06:
;     - Default value for USE_MSAXIS changed from 0 to 1.
;   Mark Hadfield, 2004-05:
;     - Revised GetScaling code, removing calls to MGH_GET_PROPERTY.
;   Mark Hadfield, 2004-07:
;     - The NewAtom method now sets the REGISTER_PROPERTY keyword by
;       default for all atoms.
;     - Modified to accommodate the changes in the axis classes.
;       Property USE_MSAXIS is no longer supported; master-slave
;       behaviour can be suppressed in various methods by setting
;       SLAVE to 0.
;   Mark Hadfield, 2005-09:
;     - Default scale (in cm) increased from 6 to 9.
;   Mark Hadfield, 2006-08:
;     - Default scale (in cm) decreased from 9 to 8 to suit my new
;       monitor better.
;   Mark Hadfield, 2007-08:
;     - Generalised NormPosition method so it accepts [2,n] or [3,n]
;       arrays as input. DataPosition method should also be (but hasn't
;       been) generalised in this way.
;   Mark Hadfield, 2008-08:
;     - Added a NewColorBar method (function and procedure). The
;       method of the same name in the MGHgrGraph2D class, now calls
;       this one.
;   Mark Hadfield, 2009-04:
;     A couple of changes have been made to accommodate the change in
;     IDLgrWindow resolution in IDL version 7.1. (The value was queried
;     from the OS but is now set to a fixed 72 dpi). Code to set the default
;     SCALE property is now version-dependent and a FONTSIZE property has
;     been added, with a version-dependent default value.
;   Mark Hadfield, 2010-11:
;     The change in IDLgrWindow resolution (see previous entry) has been
;     reversed in IDL 8.0.1; the default values of the SCALE and FONTSIZE
;     (which are set by routine MGH_GRAPH_DEFAULT) have been altered
;     accordingly.
;-
;+
; METHOD NAME:
;       MGHgrGraph::GetScaling (Procedure)
;
; PURPOSE:
;   This procedure-type method is the heart of the MGHgrGraph class,
;   but is seldom called from outside. Based on its keyword arguments
;   it establishes the model to which new atoms are to be added, the
;   axes to which they are to be scaled (and maybe tied as slaves) and
;   the coordinate conversions. It passes this information to various
;   methods, notably NewAtom, which use this information as necessary.
;
; POSITIONAL PARAMETERS:
;   None.
;
; KEYWORD PARAMETERS:
;   All keywords can be used for input and output. Most of the time
;   the method will be called with all keywords present & set to
;   undefined, named variables, but any & all keywords can be set on
;   input to override the defaults.
;
;   MODEL
;     The model to which new atoms are to be added and in which to
;     search for axes. Default is the first model in the graph.
;
;   [X,Y,Z]AXIS
;     The axis from which [X,Y,Z] coordinate conversions are to be
;     taken. Default is the first axis of the required DIRECTION in
;     the model. Set this to a non-object value (e.g. -1) to prevent
;     searching for the axis. It is permissible and (sometimes
;     convenient) to set this keyword to an array.
;
;   [X,Y,Z]COORD_CONV
;     The [X,Y,Z] coordinate conversions. Default is taken from the
;     corresponding [X,Y,Z]AXIS; if this is not an object it is
;     [0,1].
;-

; MGHgrGraph::Init

function MGHgrGraph::Init, $
     DIMENSIONS=dimensions, FONTSIZE=fontsize, $
     N_MODELS=n_models, NAME=name, $
     REGISTER_PROPERTIES=register_properties, $
     SCALE=scale, SYMSIZE=symsize, TICKLEN=ticklen, $
     UNITS=units, VIEWPLANE_RECT=viewplane_rect, $
     _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Initialise containers for resources needed by the graph

   self.fonts = obj_new('IDL_Container')
   self.palettes = obj_new('IDL_Container')
   self.symbols = obj_new('IDL_Container')

   ;; Get defaults from MGH_GRAPH_DEFAULT

   mgh_graph_default, $
        DIMENSIONS=dimensions, FONTSIZE=fontsize, $
        SCALE=scale, SYMSIZE=symsize, TICKLEN=ticklen, $
        UNITS=units

   ;; The DISPOSAL container will hold miscellaneous items marked for
   ;; deletion.

   self.disposal = obj_new('IDL_Container')

   ;; Properties are registered by default

   if n_elements(register_properties) eq 0 then $
        register_properties = 1B

   ;; Create the view

   ok = self->IDLgrView::Init(/DOUBLE, REGISTER_PROPERTIES=register_properties, $
                              _STRICT_EXTRA=_extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrView'

   ;; Add models to the view.

   if n_elements(n_models) eq 0 then n_models = 1
   for i=0,n_models-1 do self->Add, obj_new('MGHgrModel', NAME='Model '+strtrim(i, 2))

   ;; Let SetProperty sort everything out

   self->SetProperty, $
        DIMENSIONS=dimensions, FONTSIZE=fontsize, NAME=name, $
        SCALE=scale, SYMSIZE=symsize, TICKLEN=ticklen, $
        UNITS=units, VIEWPLANE_RECT=viewplane_rect

   ;; Register some properties

   if keyword_set(register_properties) then begin

      ;; Bugger can't register SCALE. It's returned by GetProperty as a 2-element
      ;; vector!
;     self->RegisterProperty, 'SCALE', /FLOAT, DESCRIPTION='Scale (normal/device)'

   endif

   ;; Initialisation is successful!

   return, 1

END

; MGHgrGraph::Cleanup
;
pro MGHgrGraph::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.fonts
   obj_destroy, self.palettes
   obj_destroy, self.symbols
   obj_destroy, self.disposal

   self->IDLgrView::Cleanup

end

; MGHgrGraph::GetProperty
;
pro MGHgrGraph::GetProperty, $
     ALL=all, DELTAZ=deltaz, FONTSIZE=fontsize, N_MODELS=n_models, SCALE=scale, $
     SYMSIZE=symsize, TICKLEN=ticklen, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrView::GetProperty, ALL=all, _STRICT_EXTRA=_extra

   ;; DELTAZ is calculated from the front-rear limits of the view
   ;; divided by 2^16. I've allowed another factor of two because some
   ;; renderers (e.g. the Win32 hardware renderer) require it for
   ;; clean separation.
   ;; NB 2004-07-12: I've made DELTAZ a larger, rounder number so it
   ;; looks nicer in property-sheet widgets

   deltaz = 1.D-4*(double(all.zclip[0]) - double(all.zclip[1]))

   n_models = self->Count()

   scale = (all.units eq 3) $
           ? [0,0] : all.dimensions/all.viewplane_rect[2:3]

   fontsize = self.fontsize

   symsize = self.symsize

   ticklen = self.ticklen

   if arg_present(all) then begin
      all = create_struct(all, 'deltaz', deltaz, 'fontsize', fontsize, $
                          'n_models', n_models, 'scale', scale , $
                          'symsize', symsize, 'ticklen', ticklen)
   endif

end

; MGHgrGraph::SetProperty
;
pro MGHgrGraph::SetProperty, $
     DIMENSIONS=dimensions, FONTSIZE=fontsize, SCALE=scale, $
     SYMSIZE=symsize, TICKLEN=ticklen, UNITS=units, $
     VIEWPLANE_RECT=viewplane_rect, $
     _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrView::SetProperty, _STRICT_EXTRA=_extra

   if n_elements(fontsize) gt 0 then self.fontsize = fontsize

   if n_elements(symsize) gt 0 then begin
      case n_elements(symsize) of
         1: self.symsize = symsize[0]
         2: self.symsize[0:1] = symsize
         3: self.symsize = symsize
      endcase
   endif

   if n_elements(ticklen) gt 0 then self.ticklen = ticklen

   ;; The following properties are related to layout and size.  If any
   ;; of them has been specified then if the graph has explicit
   ;; dimensions (i.e. a non-zero SCALE property) we alter dimensions
   ;; to preserve the scale.

   recalc_size = 0B

   if n_elements(dimensions) gt 0 then recalc_size = 1B

   if n_elements(scale) gt 0 then recalc_size = 1B

   if n_elements(units) gt 0 then recalc_size = 1B

   if n_elements(viewplane_rect) gt 0 then recalc_size = 1B

   if recalc_size then begin

      if n_elements(dimensions) eq 0 then begin
         if n_elements(scale) eq 0 then $
              self->GetProperty, SCALE=scale
         if n_elements(viewplane_rect) eq 0 then $
              self->GetProperty, VIEWPLANE_RECT=viewplane_rect
         if product(scale) gt 0 then $
              dimensions = scale*viewplane_rect[2:3]
      endif

      self->IDLgrView::SetProperty, $
           UNITS=units, VIEWPLANE_RECT=viewplane_rect, DIMENSIONS=dimensions

   endif

end

; MGHgrGraph::AddAtom (Procedure)
;
;   Add one or more existing atoms to the graph and apply X, Y & Z
;   coordinate conversions.
;
pro MGHgrGraph::AddAtom, atom, $
     MODEL=model, $
     POSITION=position, $
     XAXIS=xaxis, $
     YAXIS=yaxis, ZAXIS=zaxis, $
     XCOORD_CONV=xcoord_conv, $
     YCOORD_CONV=ycoord_conv, $
     ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->FitAtom, atom, $
        MODEL=model, $
        XAXIS=xaxis, $
        YAXIS=yaxis, $
        ZAXIS=zaxis, $
        XCOORD_CONV=xcoord_conv, $
        YCOORD_CONV=ycoord_conv, $
        ZCOORD_CONV=zcoord_conv

   for i=0,n_elements(atom)-1 do $
        model->Add, atom[i], POSITION=position

end

; MGHgrGraph::AddPalette (Procedure)
;
;   Add one or more objects to the graph's palettes container.
;
pro MGHgrGraph::AddPalette, palette, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(palette)-1 do $
        if obj_valid(palette[i]) && obj_isa(palette[i],'IDLgrPalette') then $
             self.palettes->Add, palette[i], _STRICT_EXTRA=_extra

end

; MGHgrGraph::AddSymbol (Procedure)
;
;   Add one or more existing symbol objects to the graph's symbols
;   container and apply X, Y & Z coordinate conversions.
;
pro MGHgrGraph::AddSymbol, symbol, $
     MODEL=model, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->FitSymbol, symbol, $
        MODEL=model, $
        XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
        ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   for i=0,n_elements(symbol)-1 do self.symbols->Add, symbol[i]

end

; MGHgrGraph::DataPosition
;
;   Given a position (2 or 3-element vector) in normalised
;   coordinates, this function returns the position in data
;   coordinates,
function MGHgrGraph::DataPosition, norm_position, $
     MODEL=model, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetScaling, MODEL=model, $
        XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
        ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   case n_elements(norm_position) of
      2: begin
         return, [(norm_position[0]-xcoord_conv[0])/xcoord_conv[1], $
                  (norm_position[1]-ycoord_conv[0])/ycoord_conv[1]]
      end
      3: begin
         return, [(norm_position[0]-xcoord_conv[0])/xcoord_conv[1], $
                  (norm_position[1]-ycoord_conv[0])/ycoord_conv[1], $
                  (norm_position[2]-zcoord_conv[0])/zcoord_conv[1]]
      end
   endcase

end

; MGHgrGraph::Dispose (Procedure)
;
;   Add one or more objects to the graph's disposal container.
;
pro MGHgrGraph::Dispose, obj

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(obj)-1 do begin
      if obj_valid(obj[i]) then self.disposal->Add, obj[i]
   endfor

end

; MGHgrGraph::FitAtom (Procedure)
;
;   Fit one or more existing atoms to the graph axes.
;
pro MGHgrGraph::FitAtom, atom, $
     MODEL=model, SLAVE=slave, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(slave) eq 0 then slave = 1B

   self->GetScaling, MODEL=model, $
        XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
        ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   for i=0,n_elements(atom)-1 do begin
      atom[i]->SetProperty, XCOORD_CONV=xcoord_conv, $
           YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv
   end

   if keyword_set(slave) then begin

      if (n_elements(xaxis) gt 0) && obj_valid(xaxis[0]) then $
           xaxis[0]->AddSlave, atom

      if (n_elements(yaxis) gt 0) && obj_valid(yaxis[0]) then $
           yaxis[0]->AddSlave, atom

      if (n_elements(zaxis) gt 0) && obj_valid(zaxis[0]) then $
           zaxis[0]->AddSlave, atom

   endif

end

; MGHgrGraph::FitSymbol (Procedure)
;
;   Fit one or more existing symbol objects to the graph axes.
;
pro MGHgrGraph::FitSymbol, symbol, $
     MODEL=model, SLAVE=slave, $
     XAXIS=xaxis, YAXIS=yaxis, ZAXIS=zaxis

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(slave) eq 0 then slave = 1B

   for i=0,n_elements(symbol)-1 do $
      symbol[i]->SetProperty, NORM_SIZE=self.symsize

   if keyword_set(slave) then begin

   self->GetScaling, MODEL=model, $
        XAXIS=xaxis, YAXIS=yaxis, ZAXIS=zaxis

      if n_elements(xaxis) gt 0 && obj_valid(xaxis[0]) then $
           xaxis[0]->AddSlave, symbol, /SYMBOL

      if n_elements(yaxis) gt 0 && obj_valid(yaxis[0]) then $
           yaxis[0]->AddSlave, symbol, /SYMBOL

      if n_elements(zaxis) gt 0 && obj_valid(zaxis[0]) then $
           zaxis[0]->AddSlave, symbol, /SYMBOL

   endif

end

; MGHgrGraph::GetAtom (Function)
;
;   Return object references to atoms in the graph, with various
;   filters.
;
function MGHgrGraph::GetAtom, ALL=all, COUNT=count, ISA=isa, MODEL=model, $
     NAME=name, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; We will look for atoms only in the specified model. Default is the first
   ;; model in the graph.

   if n_elements(model) eq 0 then model = self->Get()

   atoms = model->Get( /ALL, COUNT=count )

   if count eq 0 then return, obj_new()

   ;; Filter the list with the ISA criterion
   if n_elements(isa) eq 1 then begin
      isas = mgh_reproduce(0,atoms)
      for i=0,n_elements(isas)-1 do isas[i] = obj_isa(atoms[i], isa)
      match = where(isas,count)
      if count eq 0 then return, obj_new()
      atoms = atoms[match]
   endif

   ;; Filter the list of by NAME (case-insensitive)
   if n_elements(name) eq 1 then begin
      names = mgh_reproduce('',atoms)
      for i=0,n_elements(names)-1 do begin
         atoms[i]->GetProperty, NAME=n
         names[i] = n
      endfor
      match = where(strlowcase(names) eq strlowcase(name),count)
      if count eq 0 then return, obj_new()
      atoms = atoms[match]
   endif

   ;; Return a list of atoms or a single one, depending on the
   ;; ALL and POSITION keywords.

   case 1B of
      keyword_set(all): begin
         return, atoms
      end
      n_elements(position) gt 0: begin
         if max(position) ge count || min(position) lt 0 then $
              message, 'Position value out of range'
         count = n_elements(position)
         return, atoms[position]
      end
      else: begin
         count = 1
         return, atoms[0]
      endelse
   endcase

end


; MGHgrGraph::GetAxis (Function)
;
;   Return object references to axes in the view.
;   They can be selected by DIRECTION and/or NAME.
;
function MGHgrGraph::GetAxis, COUNT=count, MODEL=model, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Look for axes in the specified model. Default is the first one
   ;; in the graph.

   if n_elements(model) eq 0 then model = self->Get()

   return, model->GetAxis(COUNT=count, _STRICT_EXTRA=_extra)

end

; MGHgrGraph::GetFont (Function)
;
;   Return references to objects in the fonts container.
;   They can be selected by NAME.
;
function MGHgrGraph::GetFont, NAME=name, POSITION=position, ALL=all, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   fonts = self.fonts->Get(/ALL, COUNT=count)

   if count eq 0 then return, -1

   ;; Filter the list of fonts by NAME (case-insensitive)

   if n_elements(name) eq 1 then begin

      names = mgh_reproduce('',fonts)

      for i=0,n_elements(names)-1 do begin
         fonts[i]->GetProperty, NAME=n
         names[i] = n
      endfor

      match = where(strcmp(name, names, /FOLD), count)

      if count eq 0 then return, -1

      fonts = fonts[match]

   endif

   ;; Return a list of fonts or a single one, depending on the
   ;; ALL and POSITION keywords.

   if keyword_set(all) then return, fonts

   case n_elements(position) gt 0 of

      0: begin
         count = 1
         return, fonts[0]
      end

      1: begin
         if (max(position) ge count) || (min(position) lt 0) then $
              message, 'Position value out of range'
         count = n_elements(position)
         return, fonts[position]
      end

   endcase

end

; MGHgrGraph::GetPalette (Function)
;
;   Return references to objects in the palettes container.
;   They can be selected by NAME.
;
function MGHgrGraph::GetPalette, NAME=name, POSITION=position, ALL=all, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   palettes = self.palettes->Get(/ALL, COUNT=count)

   if count eq 0 then return, -1

   ;; Filter the list of fonts by NAME (case-insensitive)

   if n_elements(name) eq 1 then begin

      names = mgh_reproduce('',fonts)

      for i=0,n_elements(names)-1 do begin
         palettes[i]->GetProperty, NAME=n
         names[i] = n
      endfor

      match = where(strcmp(name, names, /FOLD_CASE), count)

      if count eq 0 then return, -1

      palettes = palettes[match]

   endif

   ;; Return a list of fonts or a single one, depending on the
   ;; ALL and POSITION keywords.

   if keyword_set(all) then return, palettes

   case n_elements(position) gt 0 of

      0: begin
         count = 1
         return, palettes[0]
      end

      1: begin
         if max(position) ge count || min(position) lt 0 then $
              message, 'Position value out of range'
         count = n_elements(position)
         return, palettes[position]
      end

   endcase

end

; MGHgrGraph::GetScaling
;
;   For an atom that is to be added to the graph, establish the model to which
;   it is to be added, the axes (if any) with which it is associated, and the
;   x & y & z coordinate conversions.
;
pro MGHgrGraph::GetScaling, $
     MODEL=model, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   if n_elements(model) eq 0 then model = self->Get()

   if n_elements(xaxis) eq 0 then $
        xaxis = self->GetAxis(MODEL=model, DIRECTION=0)

   if n_elements(yaxis) eq 0 then $
        yaxis = self->GetAxis(MODEL=model, DIRECTION=1)

   if n_elements(zaxis) eq 0 then $
        zaxis = self->GetAxis(MODEL=model, DIRECTION=2)

   if n_elements(xcoord_conv) eq 0 then begin
      case n_elements(xaxis) gt 0 && obj_valid(xaxis[0]) of
         0B: xcoord_conv = [0,1]
         1B: xaxis[0]->GetProperty, XCOORD_CONV=xcoord_conv
      endcase
   endif

   if n_elements(ycoord_conv) eq 0 then begin
      case n_elements(yaxis) gt 0 && obj_valid(yaxis[0]) of
         0B: ycoord_conv = [0,1]
         1B: yaxis[0]->GetProperty, YCOORD_CONV=ycoord_conv
      endcase
   endif

   if n_elements(zcoord_conv) eq 0 then begin
      case n_elements(zaxis) gt 0 && obj_valid(zaxis[0]) of
         0B: zcoord_conv = [0,1]
         1B: zaxis[0]->GetProperty, ZCOORD_CONV=zcoord_conv
      endcase
   endif

end


; MGHgrGraph::GetSymbol (Function)
;
;   Return references to objects in the symbols container.
;
function MGHgrGraph::GetSymbol, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.symbols->Get(_STRICT_EXTRA=_extra)

end

; MGHgrGraph::NewAtom (Function & Procedure)
;
;   Add a new graphics atom to the plot. Defaults for the scaling and the model
;   to which it is to be added are supplied by the GetScaling method.
;
function MGHgrGraph::NewAtom, class, p1, p2, p3, $
     ADD=add, MODEL=model, POSITION=position, SLAVE=slave, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(class, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'class'

   if n_elements(class) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'class'

   if n_elements(add) eq 0 then add = 1B

   if n_elements(slave) eq 0 then slave = 1B

   self->GetScaling, MODEL=model, $
        XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
        ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   case n_params() of
      1: atom = obj_new(class, /REGISTER_PROPERTIES, XCOORD_CONV=xcoord_conv, $
                        YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
                        _STRICT_EXTRA=_extra)
      2: atom = obj_new(class, p1, /REGISTER_PROPERTIES, XCOORD_CONV=xcoord_conv, $
                        YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
                        _STRICT_EXTRA=_extra)
      3: atom = obj_new(class, p1, p2, /REGISTER_PROPERTIES, XCOORD_CONV=xcoord_conv, $
                        YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
                        _STRICT_EXTRA=_extra)
      4: atom = obj_new(class, p1, p2, p3, /REGISTER_PROPERTIES, XCOORD_CONV=xcoord_conv, $
                        YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv, $
                        _STRICT_EXTRA=_extra)
   endcase

   if ~ obj_valid(atom) then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_OBJREF_BAD', string(atom, /PRINT)

   if keyword_set(add) then $
        model->Add, atom, POSITION=position

   if keyword_set(slave) then begin

      if (n_elements(xaxis) gt 0) && obj_valid(xaxis[0]) then $
           xaxis[0]->AddSlave, atom

      if (n_elements(yaxis) gt 0) && obj_valid(yaxis[0]) then $
           yaxis[0]->AddSlave, atom

      if (n_elements(zaxis) gt 0) && obj_valid(zaxis[0]) then $
           zaxis[0]->AddSlave, atom

   endif

   return, atom

end

; MGHgrGraph::NewAxis (Function & Procedure)
;
;   Create an axis, add it to the view and return the object reference.
;   If a font is available (either as a keyword argument, or attached
;   to the view) then apply it to the title and ticktext objects.
;
;   By default the axis is not scaled. It is expected that this method
;   will be extended in subclasses to specify locations and apply scaling
;   automatically
;
function MGHgrGraph::NewAxis, dir, $
     CLASS=class, DIRECTION=direction, $
     MODEL=model, NAME=name, NORM_RANGE=norm_range, $
     REVERSE_RANGE=reverse_range, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Set defaults

   if n_elements(model) eq 0 then $
        model = self->Get()

   if n_elements(class) eq 0 then $
        class = 'MGHgrAxis'

   if n_elements(direction) eq 0 then $
        direction = n_elements(dir) gt 0 ? dir : 0

   if n_elements(name) eq 0 then $
        name = (['X','Y','Z'])[direction] + ' axis'

   if n_elements(reverse_range) eq 0 then reverse_range = 0

   if n_elements(norm_range) eq 0 then begin
      case reverse_range of
         0: norm_range = [-0.5,0.5]
         1: norm_range = [0.5,-0.5]
      endcase
   endif

   ;; Default handling of reversed axes is somewhat intricate. Reversed
   ;; Z axes are not displayed correctly because of a bug in IDLgrAxis

   textbaseline = [1,0,0]
   if reverse_range && (direction eq 0) then textbaseline *= -1

   textupdir = direction eq 2 ? [0,0,1] : [0,1,0]
   if reverse_range && (direction ge 1) then textupdir *= -1

   ;; Create the axis.

   oaxis = obj_new(class, DIRECTION=direction, FONT=self->GetFont(), $
                   NAME=name, NORM_RANGE=norm_range, /REGISTER_PROPERTIES, $
                   TEXTBASELINE=textbaseline, $
                   TEXTUPDIR=textupdir, TICKLEN=self.ticklen, _STRICT_EXTRA=_extra)

   ;; Add it to the model's graphics container and its axis container.

   model->Add, oaxis
   model->AddAxis, oaxis

   ;; Return the object reference

   return, oaxis

end

; MGHgrGraph::NewColorBar
;
;   Draw a colour bar with locations and dimensions specified in
;   normalised coordinates.
;
function MGHgrGraph::NewColorBar, $
     CLASS=class, DIMENSIONS=dimensions, FONT=font, $
     LOCATION=location, VERTICAL=vertical, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, DELTAZ=deltaz

   if n_elements(class) eq 0 then class = 'MGHgrColorBar'

   if n_elements(vertical) eq 0 then vertical = 1B

   if n_elements(font) eq 0 then font = self->GetFont()

   if keyword_set(vertical) then begin
      if n_elements(dimensions) eq 0 then $
           dimensions = [0.5,1.6]
      if n_elements(location) eq 0 then $
           location = [-0.25,-0.8,2*deltaz]
   endif else begin
      if n_elements(dimensions) eq 0 then $
           dimensions = [1.6,0.5]
      if n_elements(location) eq 0 then $
           location = [-0.8,-0.25,2*deltaz]
   endelse

   ;; Create & return

   return, self->NewAtom(class, DIMENSIONS=dimensions, FONT=font, $
                         LOCATION=location, SHOW_AXIS=vertical+1, $
                         VERTICAL=vertical, XAXIS=0, YAXIS=0, ZAXIS=0, $
                         _STRICT_EXTRA=extra)

end

; MGHgrGraph::NewFont
;
;   Create a new font object, add it to the FONTS container.
;   A reference to the font.object is returned via the return value (function
;   form) or RESULT keyword (procedure form).

function MGHgrGraph::NewFont, P1, CLASS=class, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(class) eq 0 then class = 'IDLgrFont'

   case n_params() of
      0: result = obj_new(class, SIZE=self.fontsize, _STRICT_EXTRA=_extra)
      1: result = obj_new(class, SIZE=self.fontsize, P1, _STRICT_EXTRA=_extra)
   endcase

   self.fonts->Add, result

   return, result

end

; MGHgrGraph::NewPalette
;
function MGHgrGraph::NewPalette, P1, P2, P3, CLASS=class, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(class) eq 0 then class = 'MGHgrPalette'

   case n_params() of
      0: result = obj_new(class, _STRICT_EXTRA=_extra)
      1: result = obj_new(class, P1, _STRICT_EXTRA=_extra)
      2: result = obj_new(class, P1, P2, _STRICT_EXTRA=_extra)
      3: result = obj_new(class, P1, P2, P3, _STRICT_EXTRA=_extra)
   endcase

   self.palettes->Add, result

   return, result

end

; MGHgrGraph::NewSymbol (Function & Procedure)
;
;   Create a new symbol object & add it to the SYMBOLS container.

function MGHgrGraph::NewSymbol, p1, $
     CLASS=class, MODEL=model, SLAVE=slave, NORM_SIZE=norm_size, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv, $
     _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(class) eq 0 then class = 'MGHgrSymbol'

   if n_elements(norm_size) eq 0 then norm_size = self.symsize

   if n_elements(slave) eq 0 then slave = 1B

   ;; Get scaling info

   self->GetScaling, MODEL=model, $
        XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
        ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   ;; Create symbol and add to container.

   case n_params() of
      0: symbol = obj_new(class, NORM_SIZE=norm_size, XSCALE=xcoord_conv[1], $
                          YSCALE=ycoord_conv[1], ZSCALE=zcoord_conv[1], $
                          _STRICT_EXTRA=_extra)
      1: symbol = obj_new(class, p1, NORM_SIZE=norm_size, XSCALE=xcoord_conv[1], $
                          YSCALE=ycoord_conv[1], ZSCALE=zcoord_conv[1], $
                          _STRICT_EXTRA=_extra)
   endcase

   self.symbols->Add, symbol

   ;; Associate with master axis

   if keyword_set(slave) then begin

      if n_elements(xaxis) gt 0 && obj_valid(xaxis[0]) then $
           xaxis[0]->AddSlave, symbol, /SYMBOL
      if n_elements(yaxis) gt 0 && obj_valid(yaxis[0]) then $
           yaxis[0]->AddSlave, symbol, /SYMBOL
      if n_elements(zaxis) gt 0 && obj_valid(zaxis[0]) then $
           zaxis[0]->AddSlave, symbol, /SYMBOL

   endif

   return, symbol

end

; MGHgrGraph::NewText (Function & Procedure)
;
function MGHgrGraph::NewText, P1, CLASS=class, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Defaults for arguments

   if n_elements(class) eq 0 then class = 'IDLgrText'

   ;; Default font

   font = self->GetFont(COUNT=n_font)
   if n_font eq 0 then font = obj_new()

   ;; Create text atom

   case n_params() of
      0: begin
         return, self->NewAtom(class, FONT=font, $
                               RECOMPUTE_DIMENSIONS=2, _STRICT_EXTRA=_extra )
      end
      1: begin
         return, self->NewAtom(class, P1, FONT=font, $
                               RECOMPUTE_DIMENSIONS=2, _STRICT_EXTRA=_extra )
      end
   endcase

end

; MGHgrGraph::NormPosition
;
;   Given an array of positions (dimensioned [2,n] or [3,n]) in data
;   coordinates, this function returns the corresponding positions in
;   normalised coordinates.
;
function MGHgrGraph::NormPosition, data_position, $
     MODEL=model, $
     XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
     YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
     ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetScaling, MODEL=model, $
        XAXIS=xaxis, XCOORD_CONV=xcoord_conv, $
        YAXIS=yaxis, YCOORD_CONV=ycoord_conv, $
        ZAXIS=zaxis, ZCOORD_CONV=zcoord_conv

   if size(data_position, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'data_position'

   n_dim = size(data_position, /N_DIMENSIONS)
   dim = size(data_position, /DIMENSIONS)

   if n_dim lt 1 || n_dim gt 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_position'

   if dim[0] lt 2 || dim[0] gt 3 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgdimsize', 'data_position'

   result = make_array(dim, VALUE=0D)

   m = dim[0]
   n = (n_dim eq 2) ? dim[1] : 1

   case m of
      2: begin
         a = [xcoord_conv[0],ycoord_conv[0]]
         b = [xcoord_conv[1],ycoord_conv[1]]
      end
      3: begin
         a = [xcoord_conv[0],ycoord_conv[0],zcoord_conv[0]]
         b = [xcoord_conv[1],ycoord_conv[1],zcoord_conv[1]]
      end
   endcase

   for i=0,n-1 do $
         result[*,i] = a + b*data_position[*,i]

   return, result

end

; Procedure forms for the "New..." functions.
;
; Extra keywords are passed by value to ensure that precedence
; of inherited keywords is correct.

pro MGHgrGraph::NewAtom, P1, P2, P3, P4, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewAtom( _STRICT_EXTRA=_extra )
      1: result = self->NewAtom( P1, _STRICT_EXTRA=_extra )
      2: result = self->NewAtom( P1, P2, _STRICT_EXTRA=_extra )
      3: result = self->NewAtom( P1, P2, P3, _STRICT_EXTRA=_extra )
      4: result = self->NewAtom( P1, P2, P3, P4, _STRICT_EXTRA=_extra )
   endcase

end

pro MGHgrGraph::NewAxis, P1, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewAxis(_STRICT_EXTRA=_extra)
      1: result = self->NewAxis(P1, _STRICT_EXTRA=_extra)
   endcase

end

pro MGHgrGraph::NewColorBar, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = self->NewColorBar(_STRICT_EXTRA=_extra)

end

pro MGHgrGraph::NewFont, P1, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewFont(_STRICT_EXTRA=_extra)
      1: result = self->NewFont(P1, _STRICT_EXTRA=_extra)
   endcase

end

pro MGHgrGraph::NewPalette, P1, P2, P3, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewPalette(_STRICT_EXTRA=_extra)
      1: result = self->NewPalette(P1, _STRICT_EXTRA=_extra)
      2: result = self->NewPalette(P1, P2, _STRICT_EXTRA=_extra)
      3: result = self->NewPalette(P1, P2, P3, _STRICT_EXTRA=_extra)
   endcase

end

pro MGHgrGraph::NewSymbol, p1, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewSymbol(_STRICT_EXTRA=_extra)
      1: result = self->NewSymbol(p1, _STRICT_EXTRA=_extra)
   endcase

end

pro MGHgrGraph::NewText, P1, RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case n_params() of
      0: result = self->NewText(_STRICT_EXTRA=_extra)
      1: result = self->NewText(P1, _STRICT_EXTRA=_extra)
   endcase

end

; MGHgrGraph__Define

pro MGHgrGraph__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrGraph, inherits IDLgrView, inherits IDL_Object, $
         fonts: obj_new(), $
         palettes: obj_new(), symbols: obj_new(), $
         disposal: obj_new(), symsize: dblarr(3), $
         fontsize: 0.0, ticklen: 0.0D}

end
