;+
; CLASS NAME:
;   MGHgrGLaxis
;
; PURPOSE:
;   This class implements an axis with optional labelling in the gaps
;   between the major tick marks ("GL" = gaps labelled).
;
;   An MGHgrGLaxis intercepts calls to the superclass's Draw method,
;   at which point it fiddles around to put the gap labels in the
;   right places & hide the tick labels. So it is called every time
;   the axis is drawn (which is more often than you might think)
;   nevertheless the run-time penalty does not seem to be
;   significant. Subclassing Draw is necessary because some of the
;   information needed to draw the gap labels is not known until draw
;   time.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   MGHgrAxis.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported in addition to those inherited
;   from MGHgrAxis:
;
;     LABEL_GAPS (Init, Get, Set)
;       This property determines whether the gaps and/or tick marks are
;       labelled. Valid values are:
;         0 - Label tick marks and not gaps, just like MGHgrAxis. This
;             is the default
;         1 - Label gaps and not tick marks.
;         2 - Label gaps and tick marks. This is intended mainly for
;             debugging.
;
;     GAPTEXT (Get)
;       A string array containing the gap labels, as calculated last
;       time the axis was drawn.
;
;   The following properties are inherited from MGHgrAxis with
;   additional functionality
;
;     TICKFORMAT, TICKFRMTDATA (Init, Get, Set)
;       If LABEL_GAPS is set to 1 or 2 then these are used for
;       formatting the gap labels as well as the tick labels.
;
;   Another note:
;
;     MINOR (Init, Get, Set)
;       This behaves in exactly the same way as in MGHgrAxis, but
;       normally if gaps are labelled one would set it to 0.
;
; TO DO:
;   Make GAPTEXT a settable property? Do most of the gap-text
;   calculations when relevant properties are changed, not when the axis
;   is drawn?
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
;   Mark Hadfield, 1998-06:
;     Written.
;   Mark Hadfield, 2000-05:
;     Changed method of suppressing the tick-mark labels in the Draw
;     method. Previously it was done by retrieving the axis's TICKTEXT
;     object, then setting its STRINGS property to a vector of blank
;     strings. This was found not to work for vector-output devices,
;     introduced in IDL 5.3. So, now the tick mark labels are
;     suppressed by setting the axis's NOTEXT property.
;   Mark Hadfield, 2000-07:
;     Code for labelling gaps was overhauled, so that now the gap
;     labels can be calculated dynamically from corresponding axis
;     values & optionally formatted with the TICKFORMAT and
;     TICKFRMTDATA properties.
;   Mark Hadfield, 2001-11:
;     - Updated for IDL 5.5.
;     - Added support for TICKUNITS--only "years" is supported now but
;       adding the remainder would be trivial.
;   Mark Hadfield, 2002-04:
;     - This class was made a subclass of MGHgrMSAxis, not MGHgrAxis.
;     - Added a boolean value to the class structure to record whether
;       the gap-text object should be protected from being recreated
;       at every redraw.
;   Mark Hadfield, 2004-07:
;     - Modified to be consistent with the new axis classes. Now
;       inherits from MGHgrAxis, which includes the master-slave
;       functionality previously in MGHgrMSAxis.
;     - GAPTEXT now a string property, as are TITLE and TICKTEXT,
;       inherited from MGHgrAxis. The associated IDLgrText objects
;       are handled behind the scenes.
;     - Supports property sheets.
;     - IDL 6.0 logical syntax.
;-
function MGHgrGLaxis::Init, $
     ENABLE_FORMATTING=enable_formatting, $
     FONT=font, LABEL_GAPS=label_gaps, $
     RECOMPUTE_DIMENSIONS=recompute_dimensions, $
     REGISTER_PROPERTIES=register_properties, $
     TICKUNITS=tickunits, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(tickunits) gt 1 then $
        message, 'Multi-level axes not supported'

   self.label_gaps = 0
   if n_elements(label_gaps) gt 0 then self.label_gaps = label_gaps

   if n_elements(enable_formatting) eq 0 then $
        enable_formatting = 1B

   if n_elements(recompute_dimensions) eq 0 then $
        recompute_dimensions = 2

   self.ogap = $
        obj_new('IDLgrText', ENABLE_FORMATTING=enable_formatting, $
                FONT=font, RECOMPUTE_DIMENSIONS=recompute_dimensions, $
                STRINGS='')

   ok = self->MGHgrAxis::Init(ENABLE_FORMATTING=enable_formatting, $
                              FONT=font, RECOMPUTE_DIMENSIONS=recompute_dimensions, $
                              REGISTER_PROPERTIES=register_properties, $
                              TICKUNITS=tickunits, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGHgrAxis'

   if keyword_set(register_properties) then begin

      self->RegisterProperty, 'LABEL_GAPS', NAME='Label gaps', $
           ENUMLIST=['Ticks only','Gaps only','Ticks and gaps']

   endif

   return, 1

end

; MGHgrGLaxis::GetProperty
;
PRO MGHgrGLaxis::GetProperty, $
     GAPTEXT=gaptext, LABEL_GAPS=label_gaps, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.ogap->GetProperty, STRINGS=gaptext

   label_gaps = self.label_gaps

   self->MGHgrAxis::GetProperty, _STRICT_EXTRA=extra

END

; MGHgrGLaxis::SetProperty
;
PRO MGHgrGLaxis::SetProperty, $
     ENABLE_FORMATTING=enable_formatting, $
     FONT=font, LABEL_GAPS=label_gaps, $
     RECOMPUTE_DIMENSIONS=recompute_dimensions, $
     TICKUNITS=tickunits, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(tickunits) gt 1 then $
        message, 'Multi-level axes not supported'

   self.ogap->SetProperty, $
        ENABLE_FORMATTING=enable_formatting, FONT=font, $
        RECOMPUTE_DIMENSIONS=recompute_dimensions

   if n_elements(label_gaps) gt 0 then $
        self.label_gaps = label_gaps

   self->MGHgrAxis::SetProperty, $
        ENABLE_FORMATTING=enable_formatting, FONT=font, $
        RECOMPUTE_DIMENSIONS=recompute_dimensions, TICKUNITS=tickunits, $
        _STRICT_EXTRA=extra

end


; MGHgrGLaxis::Cleanup
;
pro MGHgrGLaxis::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.ogap

   self->MGHgrAxis::Cleanup

end


pro MGHgrGLaxis::CalculateGapStrings

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, $
        MAJOR=major, TICKVALUES=tickvalues, $
        TICKFORMAT=tickformat, TICKFRMTDATA=tickfrmtdata, $
        TICKUNITS=tickunits

   gapvalues = mgh_stagger(tickvalues, DELTA=-1)

   if strlen(tickformat[0]) gt 0 then begin

      if strmid(tickformat[0], 0, 1) eq '(' then begin

         gap_string = string(gapvalues, FORMAT=tickformat[0])

      endif else begin

         gap_string = strarr(major-1)
         for i=0,n_elements(gap_string)-1 do begin
            gap_string[i] = $
                 call_function(tickformat[0], direction, 0, $
                               gapvalues[i], DATA=tickfrmtdata)
         endfor

      endelse

   endif else begin

      case 1B of
         strmatch(tickunits[0], 'numeric', /FOLD_CASE): $
              gap_string = format_axis_values(gapvalues)
         strmatch(tickunits[0], 'years', /FOLD_CASE): $
              gap_string = string(gapvalues, FORMAT='(C(CYI4))')
         strmatch(tickunits[0], 'months', /FOLD_CASE): $
              gap_string = string(gapvalues, FORMAT='(C(CMoA3))')
         strmatch(tickunits[0], 'days', /FOLD_CASE): $
              gap_string = string(gapvalues, FORMAT='(C(CDI2.2))')
         else: $
              gap_string = format_axis_values(gapvalues)
      endcase

   endelse

   self.ogap->SetProperty, STRINGS=gap_string

end

pro MGHgrGLaxis::Draw, oDest, oView

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; If LABEL_GAPS is 0, just call MGHgrAxis::Draw and return

   if self.label_gaps eq 0 then begin
      self->MGHgrAxis::Draw, oDest, oView
      return
   endif

   ;; Call MGHgrAxis::Draw. If necessary, hide the tick labels by
   ;; temporarily setting the NOTEXT property. Hiding the tick
   ;; labels also hides the title.  By drawing the axis here we
   ;; ensure that the TICKTEXT object has its location and
   ;; alignment properties set appropriately

   self->GetProperty, NOTEXT=notext
   if self.label_gaps eq 1 then self->SetProperty, NOTEXT=1
   self->MGHgrAxis::Draw, oDest, oView
   self->SetProperty, NOTEXT=notext

   ;; Draw gap labels & title (unless NOTEXT has been set).

   if ~ notext then begin

      ;; Get info about axis & tick labels. The MGHgrAxis class
      ;; hides the tick-text & title objects (though I may provide
      ;; some access in future) so get these from its superclass.

      self->GetProperty, $
           XCOORD_CONV=xcoord, YCOORD_CONV=ycoord, ZCOORD_CONV=zcoord

      self->IDLgrAxis::GetProperty, $
           TICKTEXT=otick, TITLE=otitle

      otick->GetProperty, $
           ALIGNMENT=tick_align, LOCATIONS=tick_locations, $
           VERTICAL_ALIGNMENT=tick_valign

      ;; If the title was suppressed above, then draw it now

      if self.label_gaps eq 1 then begin
         otitle->SetProperty, $
              XCOORD_CONV=xcoord, YCOORD_CONV=ycoord, ZCOORD_CONV=zcoord
         otitle->Draw, oDest, oView
      endif

      ;; Calculate gap labels

      self->CalculateGapStrings

      ;; Set the gap-text object's locations, alignment & scaling, then
      ;; draw it.

      self.ogap->SetProperty, $
           ALIGNMENT=tick_align, VERTICAL_ALIGNMENT=tick_valign, $
           LOCATIONS=mgh_stagger(tick_locations, DELTA=[0,-1]), $
           XCOORD_CONV=xcoord, YCOORD_CONV=ycoord, ZCOORD_CONV=zcoord

      self.ogap->Draw, oDest, oView

   endif

end

pro MGHgrGLaxis__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, $
        {MGHgrGLaxis, inherits MGHgrAxis, label_gaps: 0B,  $
         ogap: obj_new()}

end

