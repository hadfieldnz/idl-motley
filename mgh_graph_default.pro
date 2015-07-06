;+
; PROCEDURE NAME:
;   MGH_GRAPH_DEFAULT
;
; PURPOSE:
;   Provide default values for MGHgrGraph properties related to sizing
;   and layout.
;
;   Beginning with version 7.1, ITT has been mucking about with object
;   graphics window resolution and font sizes. See history. This
;   procedure is an attempt to cope with this.
;
; CATEGORY:
;   Object graphics.
;
;###########################################################################
; Copyright (c) 2009-2012 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2009-05:
;     Written. In version 7.1 under Windows, the resolution of
;     IDLgrWindow objects was changed to 72 DPI (0.035/cm).
;     Previously it had been taken from the nominal resolution of the
;     OS, typically ~100 DPI (0.025/cm). In version 7.1 under Linux,
;     it still seems to be 100 DPI, curiously enough.
;   Mark Hadfield, 2010-11:
;     Now that the change in IDLgrWindow resolution has been reversed
;     in IDL 8.0.1, the version-dependent code has been altered
;     accordingly.
;   Mark Hadfield, 2011-05:
;     IDL 8.1 reimposes approximately the "new" resolution behaviour
;     of IDL 7.1 and 8.0, but with larger fonts. A third option
;     (option 2) has been added to cope with this.
;   Mark Hadfield, 2011-06:
;     Option 2 now used for IDL 8.x under Unix. However Unix settings
;     are still highly uncertain.
;   Mark Hadfield, 2012-02:
;     Added option 3 for IDL 8.x under Unix. Same as option 2 but larger
;     font size.
;   Mark Hadfield, 2014-05:
;     Changed default FONTSIZE for option 2 to 9.0, as I now have a smaller,
;     high-resolution monitor and am running medium-size system fonts. I know
;     this is not ideal. I think some day I will allow the user to specify
;     defaults via a system variable, but this is not that day.
;   Mark Hadfield, 2014-05:
;     Threw away all the system-dependent defaults and switched to a universal
;     set of defaults that can be overridden with the MGH_GRAPH system variable.
;-
pro mgh_graph_default, $
     DIMENSIONS=dimensions, FONTSIZE=fontsize, $
     SCALE=scale, SYMSIZE=symsize, TICKLEN=ticklen, $
     UNITS=units

  compile_opt DEFINT32
  compile_opt STRICTARR
  compile_opt STRICTARRSUBS
  compile_opt LOGICAL_PREDICATE

  defsysv, '!mgh_graph', EXISTS=has_mgh_graph

  if n_elements(fontsize) eq 0 then begin
    if has_mgh_graph && mgh_struct_has_tag(!mgh_graph, 'fontsize') then begin
      fontsize = !mgh_graph.fontsize
    endif else begin
      fontsize = 12
    endelse
  endif

  if n_elements(symsize) eq 0 then begin
    if has_mgh_graph && mgh_struct_has_tag(!mgh_graph, 'symsize') then begin
      symsize = !mgh_graph.symsize
    endif else begin
      symsize = 0.02
    endelse
  endif

  if n_elements(ticklen) eq 0 then begin
    if has_mgh_graph && mgh_struct_has_tag(!mgh_graph, 'ticklen') then begin
      ticklen = !mgh_graph.ticklen
    endif else begin
      ticklen = 0.04
    endelse
  endif

  if n_elements(units) eq 0 then begin
    if has_mgh_graph && mgh_struct_has_tag(!mgh_graph, 'units') then begin
      units = !mgh_graph.units
    endif else begin
      units = 2
    endelse
  endif

  if has_mgh_graph && mgh_struct_has_tag(!mgh_graph, 'scale_cm') then begin
    scale_cm = !mgh_graph.scale_cm
  endif else begin
    scale_cm = 10
  endelse

  if has_mgh_graph && mgh_struct_has_tag(!mgh_graph, 'scale_pix') then begin
    scale_pix = !mgh_graph.scale_pix
  endif else begin
    scale_pix = 300
  endelse

  case units of
    0: begin
      if n_elements(scale) eq 0 then $
        scale = scale_pix
    end
    1: begin
      if n_elements(scale) eq 0 then $
        scale = scale_cm/2.54
    end
    2: begin
      if n_elements(scale) eq 0 then $
        scale = scale_cm
    end
    3: begin
      if n_elements(dimensions) eq 0 then  $
        dimensions = [1,1]
    end
  endcase

end


