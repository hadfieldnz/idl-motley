; svn $Id$
;+
; NAME:
;   MGH_PICTURE_GET_VIEWS
;
; PURPOSE:
;   This function returns a list of views contained in a
;   picture. "Picture" is my name for an IDL drawable object, ie an
;   IDLgrView, IDLgrScene or IDLgrViewgroup.
;
; CATEGORY:
;   Object graphics
;
; CALLING SEQUENCE:
;   Result = MGH_PICTURE_GET_VIEWS(picture, N_VIEWS=n_views)
;
; POSITIONAL PARAMETERS:
;   picture (input, scalar object reference)
;     A picture whose properties are to be queried
;
; KEYWORD PARAMETERS:
;   N_VIEWS (output, scalar integer)
;     Number of views contained in the picture.
;
; RETURN VALUE:
;   The function returns a 1-D array of object references to all the
;   views contained in the picture. If no views are found the function
;   returns -1.
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
;   Mark Hadfield, 2002-06:
;       Written.
;-

function MGH_PICTURE_GET_VIEWS, picture, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case 1B of
      obj_valid(picture) eq 0: begin
         result = -1
         count = 0
      end
      obj_isa(picture,'IDLgrView'): begin
         result = [ picture ]
         count = 1
      end
      obj_isa(picture,'IDLgrViewgroup'): begin
         result = picture->Get(ISA='IDLgrView', /ALL, COUNT=count)
      end
      obj_isa(picture,'IDLgrScene'): begin
         result = -1
         count = 0
         obj = picture->Get(/ALL, COUNT=n_obj)
         for i=0,n_obj-1 do begin
            case 1 of
               obj_isa(obj[i], 'IDLgrView'): begin
                  result = count eq 0 ? [obj] : [result, obj]
                  count = count + 1
               end
               obj_isa(obj[i], 'IDLgrViewgroup'): begin
                  views = mgh_picture_get_views(obj[i], COUNT=n_views)
                  if n_views gt 0 then begin
                     result = count eq 0 ? [views] : [result, views]
                     count = count + n_views
                  endif
               end
               else:
            endcase
         endfor
      end
   endcase

   return, result

end


