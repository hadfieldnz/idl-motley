;+
; NAME:
;   MGH_EXAMPLE_IMAGE_VISIBILITY
;
; PURPOSE:
;   Display an IDLgrImage and check visibility of atoms above & below the
;   viewplane.
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
;   Mark Hadfield, 2000-06:
;     Written.
;-

pro mgh_example_image_visibility, OPTION=option, RENDERER=renderer

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(option) eq 0 then option = 0

   ograph = obj_new('MGHgrGraph', NAME='Test image plot')

   ograph->NewFont, NAME="Helvetica*Italic", SIZE=12

   ograph->NewPalette, mgh_get_ct(2, /SYSTEM), RESULT=opal0

   bdata = bytscl(mgh_dist(32))

   xrange = [-0.25,0.25]
   yrange = [-0.6,0.6]

   ograph->NewText, 'Text drawn before the image above the view plane', $
        ALIGNMENT=0.5, LOCATION=[0, 0.1, 0.2]
   ograph->NewText, 'Text drawn before the image below the view plane', $
        ALIGNMENT=0.5, LOCATION=[0,-0.3,-0.2]

   case option of

      0: begin
         ;; Stand-alone image.
         ograph->NewAtom, 'IDLgrImage', bdata, $
              LOCATION=[xrange[0],yrange[0]], $
              DIMENSIONS=[xrange[1]-xrange[0],yrange[1]-yrange[0]], $
              PALETTE=opal0
      end

      1: begin
         ;; Stand-alone true-color image with transparency
         tdata = replicate(0B, [4,size(bdata,/DIMENSIONS)])
         opal0->GetProperty, RED=r, GREEN=g, BLUE=b
         tdata[0,*,*] = r[bdata]
         tdata[1,*,*] = g[bdata]
         tdata[2,*,*] = b[bdata]
         tdata[3,*,*] = 191
         ograph->NewAtom, 'IDLgrImage', tdata, $
              BLEND_FUNCTION=[3,4], $
              LOCATION=[xrange[0],yrange[0]], $
              DIMENSIONS=[xrange[1]-xrange[0],yrange[1]-yrange[0]]
      end

      2: begin
         ;; Image as texture map on an IDLgrPolygon
         oimage = obj_new('IDLgrImage', bdata, PALETTE=opal0)
         ograph->Dispose, oimage
         ograph->NewAtom, 'IDLgrPolygon', xrange[[0,1,1,0]], yrange[[0,0,1,1]], $
              COLOR=mgh_color('white'), $
              TEXTURE_COORD=[[0,0],[0,1],[1,1],[1,0]], $
              TEXTURE_MAP=oimage
      end

      3: begin
         ;; True-color image with transparency as texture map on an IDLgrPolygon
         tdata = replicate(0B, [4,size(bdata,/DIMENSIONS)])
         opal0->GetProperty, RED=r, GREEN=g, BLUE=b
         tdata[0,*,*] = r[bdata]
         tdata[1,*,*] = g[bdata]
         tdata[2,*,*] = b[bdata]
         tdata[3,*,*] = 191
         oimage = obj_new('IDLgrImage', tdata, BLEND_FUNCTION=[3,4])
         ograph->Dispose, oimage
         ograph->NewAtom, 'IDLgrPolygon', xrange[[0,1,1,0]], yrange[[0,0,1,1]], $
              COLOR=mgh_color('white'), $
              TEXTURE_COORD=[[0,0],[0,1],[1,1],[1,0]], $
              TEXTURE_MAP=oimage
      end

   endcase

   ograph->NewText, 'Text drawn after the image above the view plane', $
        ALIGNMENT=0.5, LOCATION=[0, 0.3, 0.2]
   ograph->NewText, 'Text drawn after the image below the view plane', $
        ALIGNMENT=0.5, LOCATION=[0,-0.1,-0.2]

   mgh_new, 'MGH_Window', ograph, RENDERER=renderer

end
