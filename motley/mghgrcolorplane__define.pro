;+
; CLASS NAME:
;   MGHgrColorPlane
;
; PURPOSE:
;
;   The MGHgrColorPlane implements a flat, coloured surface consisting
;   of a rectangular array of quadrilateral cells, optionally with
;   some of the cells omitted. Colours are either uniform over the
;   cells (STYLE=0) or interpolated from the vertices (STYLE=1). A
;   "colour plane" is a lot like an image, but has more flexibility in
;   the pixel geometry & shading.
;
;   The MGHgrColorPlane is used as a base for the density plot class,
;   MGHgrDensityPlane.
;
;   I have two different colour plane implementations: the
;   MGHgrColorPolygon displays data using an IDLgrPolygon and the
;   MGHgrColorSurface displays data using an IDLgrsurface. These two
;   implementations are largely interchangeable but have various
;   strengths and weaknesses. In the past I have dithered about which
;   one should be labelled "MGHgrColorPlane". Now the MGHgrColorPlane
;   is just a trivial subclass of one of them. Last time I looked it
;   was MGHgrColorSurface-see MGHgrColorPlane__Define below.
;
;   I haven't yet sorted out the full story about performance of the
;   two colour-plane implementations. For interpolated colour (STYLE=1)
;   they are about the same but for block colour (STYLE=0) the
;   IDLgrSurface-based implementation takes somewhat longer to draw
;   to a window and (I think) *much* longer to draw to a Postscript file.
;   I think this is because it is based on a lego-style surface.
;
;   In versions 5.4
;   and before, the IDLgrSurface-based implementation looked very odd
;   when the horizontal grid was rotated with STYLE = 0. This was
;   fixed in version 5.5.
;
;   Both the MGHgrColorPolygon and the MGHgrColorSurface inherits from
;   IDLgrModel, to which the surface or polygon is added. This avoids
;   the need to carry a 2-D array of Z information around with the
;   object.
;
;   For further information see the documentation for the
;   MGHgrColorPolygon and MGHgrColorSurface classes.
;
;###########################################################################
; Copyright (c) 2000-2014 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-12:
;     The name MGHgrColorPlane has been used for various classes in
;     the past. Now it is a trivial subclass of the polygon-based
;     colour plane, MGHgrColorPolygon.
;   Mark Hadfield, 2001-07:
;     Now a subclass of the surface-based colour plane,
;     MGHgrColorSurface.
;-
pro MGHgrColorPlane__Define

   struct_hide, {MGHgrColorPlane, inherits MGHgrColorSurface}

end

