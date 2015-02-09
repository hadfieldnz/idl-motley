; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_DGWINDOW
;
; PURPOSE:
;   Direct-graphics window example. The MGH_DGwindow object can
;   store one or more commands that are re-run as necessary (eg when
;   the window is resized).
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
;   Mark Hadfield, 2001-06:
;     Written.
;-

pro mgh_example_dgwindow, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   case option of

      0: begin

         ;; A map

         mgh_new, 'MGH_DGwindow', DIMENSIONS=[500,500], NAME='My map', $
                  RESULT=odg0

         odg0->newcommand, 'map_set', 0, 170, LIMIT=[-50,160,-30,180], $
              /ISOTROPIC, /MERCATOR

         odg0->newcommand, 'map_continents', /HIRES, /FILL_CONTINENTS

         odg0->newcommand, 'map_grid'

         odg0->update

      end

      1: begin

         ;; A line plot with a large amount of data. Note that the
         ;; progress of the re-drawing operation is visible. If the
         ;; MGH_DGwindow's USE_PIXMAP keyword is set, the scene is
         ;; first drawn to an off-screen pixmap then copied to the
         ;; display

         mgh_new, 'MGH_DGwindow', DIMENSIONS=[550,450], NAME='My line plot', $
                  XOFFSET=60, YOFFSET=80, USE_PIXMAP=0, RESULT=odg1

         odg1->newcommand, 'plot', findgen(1000000)

         odg1->update

      end

      2: begin

         ;; Show two images using different color scales.

         openr, lun, filepath('ctscan.dat', subdir='examples/data'), /GET_LUN
         image = bytarr(256, 256)
         readu, lun, image
         free_lun, lun

         mgh_new, 'MGH_DGwindow', DIMENSIONS=[512,256], RESIZEABLE=0, $
                  NAME='My images', XOFFSET=120, YOFFSET=160, RESULT=odg2

         odg2->newcommand, 'loadct', 2, /SILENT
         odg2->newcommand, 'imdisp', image, MARGIN=0, /NOSCALE, $
              POSITION=[0,0,0.5,1]

         odg2->newcommand, 'loadct', 5, /SILENT
         odg2->newcommand, 'imdisp', hist_equal(image), MARGIN=0, /NOSCALE, $
              POSITION=[0.5,0,1,1]

         odg2->update

      end

      3: begin

         ;; Showing the same image several times with different colour scales

         openr, lun, filepath('ctscan.dat', subdir='examples/data'), /GET_LUN
         image = bytarr(256, 256)
         readu, lun, image
         free_lun, lun

         mgh_new, 'MGH_DGwindow', RESIZEABLE=0, DIMENSIONS=[100,600], $
                  NAME='Lots of images', RESULT=odg

         n_ct = 40
         d_ct = 1./float(n_ct)

         for ct=0,n_ct-1 do begin

            odg->newcommand, 'loadct', ct, /SILENT
            odg->newcommand, 'imdisp', image, MARGIN=0, /NOSCALE, $
                 POSITION=[0,ct*d_ct,1,(ct+1)*d_ct]

         endfor

         odg->update

      end

   endcase

end

