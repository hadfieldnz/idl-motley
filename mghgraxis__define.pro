;+
; CLASS NAME:
;   MGHgrAxis
;
; PURPOSE:
;   An MGHgrAxis is an axis specialised for use by objects of the
;   MGHgrGraph class and its subclasses. The class is based on the
;   IDLgrAxis, but with several differences:
;
;     - The TITLE and TICKTEXT properties are strings. Behind the
;       scenes, corresponding IDLgrText objects are created
;       and modified as necessary.
;
;     - The following properties are passed to the axis's title and
;       tick-text objects: ENABLE_FORMATTING (default 1), FONT and
;       RECOMPUTE_DIMENSIONS (default 2). These properties are applied
;       to *both* objects. (This loses a lot of generality, but it also
;       simplifies the interface & coding.)
;
;     - A new property, NORM_RANGE, specifies the end points of the
;       axis in normal coordinates. When the axis is changed in a way
;       that affects its range in data coordinates, the
;       coordinate conversion is changed to keep the normalised range
;       constant. The [X,Y,Z]COORD_CONV properties are retained but
;       are read-only.
;
;     - It can participate in master-slave relationships (see below).
;
; MASTER-SLAVE RELATIONSHIPS
;   An MGHgrAxis can participate in master-slave relationships with
;   axes, atoms and symbols. When changes are made that affect the
;   scaling and/or position of a master axis, it passes on those
;   changes to its slaves.
;
;   In relationships with atoms and symbols, an MGHgrAxis is always
;   a master. For atoms it passes on changes in the relevant
;   [X,Y,Z]COORD_CONV property. For symbols it adjusts the relevant
;   component of SIZE so as to preserve the normalised size of the
;   symbol. There are no restrictions on the class of the atoms or
;   symbols, provided they support the required properties.
;
;   The master-slave relationship between axes is intended to support
;   situations where there are two more-or-less identical axes on a
;   graph. Both parties in such a relationship must be instances of
;   MGHgrAxis and there are various restrictions, e.g. a slave axis
;   may not itself have slaves (of any sort) and a slave axis cannot
;   have two masters. These rules are enforced to keep dependencies
;   very simple (there being no good reason to allow complicated ones)
;   and avoid circular dependencies and other subtle effects that
;   depend on the order in which changes are passed on.
;
;   Each MGHgrAxis has a property called MS_STATUS; it is an integer
;   that can take three values: -1 (I am a slave), 1 (I am a master),
;   0 (I am neither). The MS_STATUS property is used to enforce the
;   above restrictions on the master-slave relationships. It can only
;   be acessed via by the axis itself, or via the FriendGetProperty &
;   FriendSetProperty methods. When these methods are called an object
;   reference must be supplied and it must refer to an MGHgrAxis
;   object. This provides a barrier (though a very weak one) to
;   setting the property inappropriately.
;
;   A slave axis cannot have more than one master but an atom or
;   symbol can. Normally each atom or symbol will have 2 or 3 masters,
;   one each for the X, Y and (maybe) Z directions. It would not make
;   sense for an atom or symbol to have two masters with the same
;   direction, but no attempt is made to test for this state (because
;   doing so would require code in every atom & symbol class).
;
; BACKGROUND:
;   The central concept behind the MGHgrGraph class is that the axes
;   in a graph define coordinate conversions, which are then adopted by
;   atoms and symbols as they are added to the graph (or in the case of
;   animations, fitted to the graph and added or removed during playback).
;   The MGHgrAxis class takes this concept a step further in that
;   axes keep references to the objects (slaves) that have been fitted
;   to them and update their slaves if any of the axis's relevant
;   properties is changed.
;
; PROPERTIES:
;   In addition to the properties inherited from MGHgrAxis:
;
;     ATOM_RANGE (Get)
;       This keyword to GEtProperty retruns the envelope of the slave
;       atoms' XRANGE, YRANGE or ZRANGE properties (depending on the
;       axis direction. Note that this property may be undefined or
;       unchanged on output from GetProperty, if the axis has no slave
;       atoms, or if none of the slave atoms supports the required
;       RANGE property.
;
;###########################################################################
; Copyright (c) 2000-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-05:
;     Written.
;   Mark Hadfield, 2000-08:
;     Revisited and generally revised
;   Mark Hadfield, 2001-07:
;     Keyword inheritance updated for IDL 5.5.
;   Mark Hadfield, 2004-07:
;     The MGHgrAxis class incorporates master-slave functionality from the
;     MGHgrMSaxis class, now obsolete.
;   Mark Hadfield, 2006-03:
;     Fixed a long-standing bug: initialisation fails when no font is specified.
;-
function MGHgrAxis::Init, $
     ALPHA_CHANNEL=alpha_channel, $
     AM_PM=am_pm, CLIP_PLANES=clip_planes, COLOR=color, DAYS_OF_WEEK=days_of_week, $
     DEPTH_TEST_DISABLE=depth_test_disable, DEPTH_TEST_FUNCTION=depth_test_function, $
     DEPTH_WRITE_DISABLE=depth_write_disable, $
     DESCRIPTION=description, $
     DIRECTION=direction, ENABLE_FORMATTING=enable_formatting, $
     EXACT=exact, EXTEND=extend, FONT=font, $
     GRIDSTYLE=gridstyle, HIDE=hide, LOCATION=location, LOG=log, $
     MAJOR=major, MINOR=minor, MONTHS=months, NAME=name, NORM_RANGE=norm_range, $
     NOTEXT=notext, PALETTE=palette, RANGE=range, $
     REGISTER_PROPERTIES=register_properties, $
     RECOMPUTE_DIMENSIONS=recompute_dimensions, $
     SUBTICKLEN=subticklen, TEXTALIGNMENTS=textalignments, TEXTBASELINE=textbaseline, $
     TEXTPOS=textpos, TEXTUPDIR=textupdir, THICK=thick, $
     TICKDIR=tickdir, TICKFORMAT=tickformat, TICKFRMTDATA=tickfrmtdata, $
     TICKINTERVAL=tickinterval, TICKLAYOUT=ticklayout, TICKLEN=ticklen, $
     TICKTEXT=ticktext, TICKUNITS=tickunits, TICKVALUES=tickvalues, $
     TITLE=title, USE_TEXT_COLOR=use_text_color

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.axes = obj_new('MGH_Container', DESTROY=0)

   self.atoms = obj_new('MGH_Container', DESTROY=0)

   self.symbols = obj_new('MGH_Container', DESTROY=0)

   self.disposal = obj_new('MGH_Container', DESTROY=1)

   self.ms_status = 0

   if n_elements(font) eq 1 && obj_valid(font) then self.font = font

   self.recompute_dimensions = $
        n_elements(recompute_dimensions) gt 0 ? recompute_dimensions : 2

   self.enable_formatting = $
        n_elements(enable_formatting) gt 0 ? enable_formatting : 1

   self.norm_range = $
        n_elements(norm_range) gt 0 ? norm_range : [0,1]

   ;; Create a title object

   otitle = obj_new('IDLgrText', FONT=self.font, $
                    ENABLE_FORMATTING=self.enable_formatting, $
                    RECOMPUTE_DIMENSIONS=self.recompute_dimensions)
   if n_elements(title) gt 0 then otitle->SetProperty, STRINGS=title
   self.disposal->Add, otitle

   ;; If a TICKTEXT string has been specified, create a tick-text
   ;; object. Otherwise supply an empty object reference to
   ;; IDLgrAxis::Init and it will create an object automatically

   oticktext = obj_new()
   if n_elements(ticktext) gt 0 then begin
      oticktext = obj_new('IDLgrText', ticktext)
      self.disposal->Add, oticktext
   endif

   ;; Wish me luck

   ok = self->IDLgrAxis::Init(ALPHA_CHANNEL=alpha_channel, $
                              AM_PM=am_pm, CLIP_PLANES=clip_planes, COLOR=color, $
                              DAYS_OF_WEEK=days_of_week, $
                              DEPTH_TEST_DISABLE=depth_test_disable, $
                              DEPTH_TEST_FUNCTION=depth_test_function, $
                              DEPTH_WRITE_DISABLE=depth_write_disable, $
                              DESCRIPTION=description, $
                              DIRECTION=direction, EXACT=exact, EXTEND=extend, $
                              GRIDSTYLE=gridstyle, HIDE=hide, LOCATION=location, $
                              LOG=log, MAJOR=major, MINOR=minor, MONTHS=months, $
                              NAME=name, NOTEXT=notext, PALETTE=palette, RANGE=range, $
                              REGISTER_PROPERTIES=register_properties, $
                              SUBTICKLEN=subticklen, TEXTALIGNMENTS=textalignments, $
                              TEXTBASELINE=textbaseline, TEXTPOS=textpos, $
                              TEXTUPDIR=textupdir, THICK=thick, TICKDIR=tickdir, $
                              TICKFORMAT=tickformat, TICKFRMTDATA=tickfrmtdata, $
                              TICKINTERVAL=tickinterval, TICKLAYOUT=ticklayout, $
                              TICKLEN=ticklen, TICKTEXT=oticktext, $
                              TICKUNITS=tickunits, TICKVALUES=tickvalues, $
                              TITLE=otitle, USE_TEXT_COLOR=use_text_color)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrAxis'

   ;; Rescale to normalised range.

   self->IDLgrAxis::GetProperty, CRANGE=crange, DIRECTION=direction

   case direction of
      0: begin
         self->IDLgrAxis::SetProperty, $
              XCOORD_CONV=mgh_norm_coord(crange, self.norm_range)
      end
      1: begin
         self->IDLgrAxis::SetProperty, $
              YCOORD_CONV=mgh_norm_coord(crange, self.norm_range)
      end
      2: begin
         self->IDLgrAxis::SetProperty, $
              ZCOORD_CONV=mgh_norm_coord(crange, self.norm_range)
      end
   endcase

   ;; If a tick-text object was not created above, then it will have
   ;; been created by IDLgrAxis::Init. Set required properties now.

   if n_elements(ticktext) eq 0 then begin
      self->IDLgrAxis::GetProperty, TICKTEXT=oticktext
      if n_elements(oticktext) gt 1 then $
           message, 'Who ordered all these tick-text objects?'
      if obj_valid(self.font) then $
           oticktext->SetProperty, FONT=self.font
      oticktext->SetProperty, $
           ENABLE_FORMATTING=self.enable_formatting, $
           RECOMPUTE_DIMENSIONS=self.recompute_dimensions
   end

   ;; Register some more properties

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'RNG0', NAME='Range min', /FLOAT
      self->RegisterProperty, 'RNG1', NAME='Range max', /FLOAT
      self->RegisterProperty, 'TITLE', NAME='Title', /STRING

   endif

   return, 1

end

; MGHgrAxis::Cleanup
;
pro MGHgrAxis::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Don't destroy the font!

   obj_destroy, self.axes
   obj_destroy, self.atoms
   obj_destroy, self.symbols
   obj_destroy, self.disposal

   self->IDLgrAxis::Cleanup

end


; MGHgrAxis::GetProperty
;
pro MGHgrAxis::GetProperty, $
     ATOM_RANGE=atom_range, DIRECTION=direction, $
     FONT=font, NORM_RANGE=norm_range, OTICKTEXT=oticktext, OTITLE=otitle, RANGE=range, $
     RNG0=rng0, RNG1=rng1, TICKTEXT=ticktext, TITLE=title, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->IDLgrAxis::GetProperty, $
        DIRECTION=direction, TICKTEXT=oticktext, TITLE=otitle, RANGE=range, _STRICT_EXTRA=extra

   rng0 = range[0]
   rng1 = range[1]

   if arg_present(ticktext) then begin
      oticktext->GetProperty, STRINGS=ticktext
      if size(ticktext, /TYPE) ne 7 then ticktext = ''
   endif

   if arg_present(title) then begin
      otitle->GetProperty, STRINGS=title
      if size(title, /TYPE) ne 7 then title = ''
      title = title[0]
   endif

   norm_range = self.norm_range

   font = self.font

   if arg_present(atom_range) && (self.ms_status gt 0) then begin

      slave_atoms = self->GetSlave(/ALL, COUNT=n_slave_atoms)

      for i=0,n_slave_atoms-1 do begin
         slave = slave_atoms[i]
         if obj_valid(slave) then begin
            case direction of
               0: slave->GetProperty, XRANGE=slave_range
               1: slave->GetProperty, YRANGE=slave_range
               2: slave->GetProperty, ZRANGE=slave_range
            endcase
            ;; Is it possible for slave_range to be undefined here?
            ;; If it is, enclose the following in an IF block.
            atom_range = n_elements(atom_range) eq 0 $
                         ? slave_range $
                         : [atom_range[0] < slave_range[0], $
                            atom_range[1] > slave_range[1]]
         endif
      endfor

   endif

end

; MGHgrAxis::SetProperty
;
pro MGHgrAxis::SetProperty, $
     ALPHA_CHANNEL=alpha_channel, $
     AM_PM=am_pm, CLIP_PLANES=clip_planes, COLOR=color, DAYS_OF_WEEK=days_of_week, $
     DEPTH_TEST_DISABLE=depth_test_disable, $
     DEPTH_TEST_FUNCTION=depth_test_function, $
     DEPTH_WRITE_DISABLE=depth_write_disable, DESCRIPTION=description, $
     DIRECTION=direction, ENABLE_FORMATTING=enable_formatting, $
     EXACT=exact, EXTEND=extend, FONT=font, $
     GRIDSTYLE=gridstyle, HIDE=hide, LOCATION=location, LOG=log, $
     MAJOR=major, MINOR=minor, MONTHS=months, NAME=name, NORM_RANGE=norm_range, $
     NOTEXT=notext, PALETTE=palette, RANGE=range, RNG0=rng0, RNG1=rng1, $
     RECOMPUTE_DIMENSIONS=recompute_dimensions, $
     SUBTICKLEN=subticklen, TEXTALIGNMENTS=textalignments, TEXTBASELINE=textbaseline, $
     TEXTPOS=textpos, TEXTUPDIR=textupdir, THICK=thick, $
     TICKDIR=tickdir, TICKFORMAT=tickformat, TICKFRMTDATA=tickfrmtdata, $
     TICKINTERVAL=tickinterval, TICKLAYOUT=ticklayout, TICKLEN=ticklen, $
     TICKTEXT=ticktext, TICKUNITS=tickunits, TICKVALUES=tickvalues, $
     TITLE=title, USE_TEXT_COLOR=use_text_color

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(direction) gt 0 && self.ms_status ne 0 then $
        message, 'Cannot set DIRECTION for a master or slave axis'

   ;; Set axis properties

   if n_elements(enable_formatting) gt 0 then begin
      self.enable_formatting = enable_formatting
      self->IDLgrAxis::GetProperty, TICKTEXT=oticktext, TITLE=otitle
      otitle->SetProperty, ENABLE_FORMATTING=self.enable_formatting
      oticktext->SetProperty, ENABLE_FORMATTING=self.enable_formatting
   endif

   if n_elements(font) gt 0 then begin
      self.font = font
      self->IDLgrAxis::GetProperty, TICKTEXT=oticktext, TITLE=otitle
      otitle->SetProperty, FONT=self.font
      oticktext->SetProperty, FONT=self.font
   endif

   if n_elements(norm_range) gt 0 then $
        self.norm_range = norm_range

   if n_elements(recompute_dimensions) gt 0 then begin
      self.recompute_dimensions = recompute_dimensions
      self->IDLgrAxis::GetProperty, TICKTEXT=oticktext, TITLE=otitle
      otitle->SetProperty, recompute_dimensions=self.recompute_dimensions
      oticktext->SetProperty, recompute_dimensions=self.recompute_dimensions
   endif


   if n_elements(rng0) gt 0 || n_elements(rng1) gt 0 then begin
      if n_elements(range) eq 0 then self->GetProperty, RANGE=range
      if n_elements(rng0) gt 0 then range[0] = rng0
      if n_elements(rng1) gt 0 then range[1] = rng1
   endif

   if n_elements(ticktext) gt 0 then begin
      self->IDLgrAxis::GetProperty, TICKTEXT=oticktext
      oticktext->SetProperty, STRINGS=ticktext
   endif

   if n_elements(title) gt 0 then begin
      self->IDLgrAxis::GetProperty, TITLE=otitle
      otitle->SetProperty, STRINGS=title[0]
   endif

   self->IDLgrAxis::SetProperty, $
        ALPHA_CHANNEL=alpha_channel, $
        AM_PM=am_pm, CLIP_PLANES=clip_planes, COLOR=color, DAYS_OF_WEEK=days_of_week, $
        DEPTH_TEST_DISABLE=depth_test_disable, $
        DEPTH_TEST_FUNCTION=depth_test_function, $
        DEPTH_WRITE_DISABLE=depth_write_disable, DESCRIPTION=description, $
        DIRECTION=direction, EXACT=exact, EXTEND=extend, $
        GRIDSTYLE=gridstyle, HIDE=hide, LOCATION=location, LOG=log, $
        MAJOR=major, MINOR=minor, MONTHS=months, NAME=name, $
        NOTEXT=notext, PALETTE=palette, RANGE=range, $
        SUBTICKLEN=subticklen, TEXTALIGNMENTS=textalignments, TEXTBASELINE=textbaseline, $
        TEXTPOS=textpos, TEXTUPDIR=textupdir, THICK=thick, $
        TICKDIR=tickdir, TICKFORMAT=tickformat, TICKFRMTDATA=tickfrmtdata, $
        TICKINTERVAL=tickinterval, TICKLAYOUT=ticklayout, TICKLEN=ticklen, $
        TICKUNITS=tickunits, TICKVALUES=tickvalues, $
        USE_TEXT_COLOR=use_text_color

   ;; Rescale

   self->GetProperty, CRANGE=crange, DIRECTION=direction

   coord_conv = mgh_norm_coord(crange, self.norm_range)

   case direction of
      0: begin
         self->IDLgrAxis::SetProperty, $
              XCOORD_CONV=coord_conv, YCOORD_CONV=[0,1], ZCOORD_CONV=[0,1]
      end
      1: begin
         self->IDLgrAxis::SetProperty, $
              XCOORD_CONV=[0,1], YCOORD_CONV=coord_conv, ZCOORD_CONV=[0,1]
      end
      2: begin
         self->IDLgrAxis::SetProperty, $
              XCOORD_CONV=[0,1], YCOORD_CONV=[0,1], ZCOORD_CONV=coord_conv
      end
   endcase

   ;; If not a master axis, then return

   if self.ms_status le 0 then return

   ;; Get coordinate conversion data to pass on to symbol & atom slaves

   self->GetProperty, $
        XCOORD_CONV=xcoord_conv, YCOORD_CONV=ycoord_conv, ZCOORD_CONV=zcoord_conv

   ;; Pass on relevant properties to slave axes.

   slave_axes = self->GetSlave(/AXIS, /ALL, COUNT=n_slave_axes)

   for i=0,n_slave_axes-1 do begin

      slave = slave_axes[i]

      if obj_valid(slave) then begin

         slave->SetProperty, $
              EXACT=exact, EXTEND=extend, LOG=log, MAJOR=major, $
              NORM_RANGE=self.norm_range, RANGE=range, $
              TICKINTERVAL=tickinterval, TICKUNITS=tickunits, $
              TICKVALUES=tickvalues

         ;; Check that the slave still matches the master and raise an
         ;; error if it doesn't.

         slave->GetProperty, $
              DIRECTION=slave_direction, CRANGE=slave_crange, $
              NORM_RANGE=slave_norm_range

         if direction ne slave_direction then begin
            message, 'Slave axis DIRECTION does not match master. ' + $
                     'Please consult program author for advice.'
         endif

         if ~ array_equal(crange, slave_crange) then begin
            message, 'Slave axis CRANGE does not match master. ' + $
                     'Please consult program author for advice.'
         endif

         if ~ array_equal(self.norm_range, slave_norm_range) then begin
            message, 'Slave axis NORM_RANGE does not match master. ' + $
                     'Please consult program author for advice.'
         endif

      endif

   endfor

   ;; Pass on relevant coordinate conversion to symbol slaves.

   slave_symbols = self->GetSlave(/SYMBOL, /ALL, COUNT=n_slave_symbols)

   for i=0,n_slave_symbols-1 do begin

      slave = slave_symbols[i]

      if obj_valid(slave) then begin
         case direction of
            0: slave->SetProperty, XSCALE=xcoord_conv[1]
            1: slave->SetProperty, YSCALE=ycoord_conv[1]
            2: slave->SetProperty, ZSCALE=zcoord_conv[1]
         endcase
      endif

   endfor

   ;; Pass on relevant coordinate conversion to atom slaves.

   for pos=0,self->CountSlave()-1 do begin

      slave = self->GetSlave(POSITION=pos)

      if obj_valid(slave) then begin
         case direction of
            0: slave->SetProperty, XCOORD_CONV=xcoord_conv
            1: slave->SetProperty, YCOORD_CONV=ycoord_conv
            2: slave->SetProperty, ZCOORD_CONV=zcoord_conv
         endcase
      endif

   endfor

end


; MGHgrAxis::FriendGetProperty
;
pro MGHgrAxis::FriendGetProperty, caller, MS_STATUS=ms_status

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(caller) then $
        message, 'Caller has not identified itself'

   if ~ obj_isa(caller, 'MGHgrAxis') then $
        message, 'Caller is not an MGHgrAxis'

   ms_status = self.ms_status

end

; MGHgrAxis::FriendSetProperty
;
pro MGHgrAxis::FriendSetProperty, caller, MS_STATUS=ms_status

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ obj_valid(caller) then $
        message, 'Caller has not identified itself'

   if ~ obj_isa(caller, 'MGHgrAxis') then $
        message, 'Caller is not an MGHgrAxis'

   if n_elements(ms_status) gt 0 then $
        self.ms_status = fix(ms_status gt 0) - fix(ms_status lt 0)

end

; MGHgrAxis::AddSlave
;
;   Add a slave. If an axis then various restrictions are imposed
;
pro MGHgrAxis::AddSlave, object, AXIS=axis, SYMBOL=symbol

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.ms_status lt 0 then $
        message, 'I am already a slave axis so cannot take on slaves.'

   ;; Set this axis's status to "master" as soon as its AddSlave
   ;; method is called.

   self.ms_status = 1

   if keyword_set(axis) then begin

      container = self.axes

      self->GetProperty, DIRECTION=direction, CRANGE=crange, $
           NORM_RANGE=norm_range

      for i=0,n_elements(object)-1 do begin

         spos = string(i, FORMAT='(I0)')

         if ~ obj_valid(object[i]) then $
              message, 'Invalid object at position '+spos

         if ~ obj_isa(object[i],'MGHgrAxis') then begin
            message, 'The object at position '+spos+ ' is not an MGHgrAxis.'
         endif

         object[i]->FriendGetProperty, self, MS_STATUS=slave_ms_status
         case slave_ms_status of
            -1: begin
               message, 'Cannot add the axis at position '+spos+ $
                        ' because it is already a slave.'
            end
            0:
            1: begin
               message, 'Cannot add the axis at position '+spos+ $
                        ' because it is a master.'
            end
         endcase

         object[i]->GetProperty, DIRECTION=slave_direction, $
              CRANGE=slave_crange, NORM_RANGE=slave_norm_range

         if slave_direction ne direction then begin
            message, 'Cannot add the axis at position '+spos+ $
                     ' because its DIRECTION does not match.'
         endif

         if ~ array_equal(slave_crange, crange) gt 0 then begin
            message, 'Cannot add the axis at position '+spos+ $
                     ' because its CRANGE does not match.'
         endif

         if ~ array_equal(slave_norm_range, norm_range) gt 0 then begin
            message, 'Cannot add the axis at position '+spos+ $
                     ' because its NORM_RANGE does not match.'
         endif

         object[i]->FriendSetProperty, self, MS_STATUS=-1

         container->Add, object[i]

      endfor

   endif else begin

      case keyword_set(symbol) of
         0: container = self.atoms
         1: container = self.symbols
      endcase

      for i=0,n_elements(object)-1 do begin

         spos = string(i, FORMAT='(I0)')

         if ~ obj_valid(object[i]) then $
              message, 'Invalid object at position '+spos

         container->Add, object[i]

      endfor

   endelse

end

; MGHgrAxis::CountSlave
;
FUNCTION MGHgrAxis::CountSlave, AXIS=axis, SYMBOL=symbol

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1 of
      keyword_set(axis): container = self.axes
      keyword_set(symbol): container = self.symbols
      else: container = self.atoms
   endcase

   return, container->Count()

END

; MGHgrAxis::FitToAtoms
;
pro MGHgrAxis::FitToAtoms

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, ATOM_RANGE=atom_range

   self->SetProperty, RANGE=atom_range

end

; MGHgrAxis::GetSlave
;
FUNCTION MGHgrAxis::GetSlave, $
     AXIS=axis, COUNT=count, SYMBOL=symbol, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1 of
      keyword_set(axis): $
           container = self.axes
      keyword_set(symbol): $
           container = self.symbols
      else: $
           container = self.atoms
   endcase

   return, container->Get(COUNT=count, _STRICT_EXTRA=extra)

END

; MGHgrAxis::IsContainedSlave
;
FUNCTION MGHgrAxis::IsContainedSlave, object, $
     AXIS=axis, SYMBOL=symbol

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1B of
      keyword_set(axis): $
           container = self.axes
      keyword_set(symbol): $
           container = self.symbols
      else: $
           container = self.atoms
   endcase

   return, container->IsContained(object)

END

pro MGHgrAxis__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrAxis, inherits IDLgrAxis, inherits IDL_Object, $
         ms_status: 0S, norm_range: dblarr(2), $
         enable_formatting: 0B, $
         recompute_dimensions: 0B, $
         font: obj_new(), disposal: obj_new(), $
         axes: obj_new(), atoms: obj_new(), symbols: obj_new()}

end

