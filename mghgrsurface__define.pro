; svn $Id$
;+
; CLASS NAME:
;   MGHgrSurface
;
; PURPOSE:
;   This class is basedidentical to IDLgrSurface, except that its
;   GetProperty method accepts DATAX, DATAY and DATAZ keywords.
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
;   Mark Hadfield, 2002-07:
;     Written.
;-

; MGHgrSurface::GetProperty
;
pro MGHgrSurface::GetProperty, $
     DATAX=datax, DATAY=datay, DATAZ=dataz, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->IDLgrSurface::GetProperty, _STRICT_EXTRA=extra

   ;; Get geometry data from the class structure's DATA tag. Note that
   ;; values are supplied even if the tag holds no valid data. This is
   ;; better than leaving the variable undefined or unchanged.

   case ptr_valid(self.data) of

      0: begin

         datax = -1
         datay = -1
         dataz = -1

      end

      1: begin

         data = *self.data

         dims = size(data, /DIMENSIONS)

         datax = reform(data[0,*,*], dims[1:2])
         datay = reform(data[1,*,*], dims[1:2])
         dataz = reform(data[2,*,*], dims[1:2])

      end

   endcase

end

pro MGHgrSurface::Spy

   compile_opt DEFINT32
   compile_opt STRICTARR

   tags = tag_names({mghgrsurface})

   for i=0,n_elements(tags)-1 do $
        print, strlowcase(tags[i]),': ', self.(i)

end

; MGHgrSurface__Define

PRO MGHgrSurface__Define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGHgrSurface, inherits IDLgrSurface}

end

