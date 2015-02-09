; svn $Id$
;+
; NAME:
;   MGH_NORM_COORD
;
; PURPOSE:
;
;   This is my version of the IDL NORM_COORD function (in the
;   'examples/objects' subdirectory), with an optional second
;   argument, renamed to avoid confusion.
;
;   This is a utility routine to calculate the scaling vector required
;   to map a specified range into normalised coordinates.  The scaling
;   vector is given as a two-element array like this:
;
;     scalingVector = [translationFactor, scalingFactor]
;
;   The scaling vector should be used with the [XYZ]COORD_CONV
;   keywords of a graphics object or model. For example, if you wanted
;   to scale an X axis into the range [-0.5,0.5], you would use:
;
;     xAxis->GetProperty, CRANGE=xrange
;     xAxis->SetProperty, COORD_CONV=MGH_NORM_COORD(xrange, [-0.5, 0.5])
;
;   Note that we have retrieved the CRANGE property of the axis,
;   rather than the RANGE property, to get the actual range. Then, to
;   calculate the position in normalised coordinates of a data point x
;   associated with this axis:
;
;     xAxis->GetProperty, COORD_CONV=xcoord_conv
;     xnorm = xcoord_conv[0] + xcoord_conv[1]*x
;
; CATEGORY:
;   Object Graphics.
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
;   Mark Hadfield, 1998-03:
;     Written.
;   Mark Hadfield, 2004-11:
;     Now returns a DOUBLE value if either of the inputs is DOUBLE, otherwise
;     FLOAT.
;   Mark Hadfield, 200?-??:
;     Now returns a DOUBLE value in all cases.
;-

function MGH_NORM_COORD, data_range, norm_range

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(norm_range) eq 0 then norm_range = [0,1]

   d = double(data_range)
   n = double(norm_range)

   return, [((n[0]*d[1])-(n[1]*d[0])) / (d[1]-d[0]), $
            (n[1]-n[0])/(d[1]-d[0])]

end
