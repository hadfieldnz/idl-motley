; svn $Id$
;+
; NAME:
;   MGH_PRINT_PICTURE
;
; PURPOSE:
;   This prints a picture (an IDL drawable object, ie an IDLgrView,
;   IDLgrScene or IDLgrViewgroup) to a printer
;
; CATEGORY:
;   Object graphics
;
; CALLING SEQUENCE:
;   result = MGH_PRINT_PICTURE, Picture, PRINTER=printer
;
; POSITIONAL PARAMETERS:
;   Picture (input, object reference)
;     Picture to be printed
;
; KEYWORD PARAMETERS:
;   BACKGROUND_COLOUR (input, colour index or RGB vector)
;     Bakground colour.
;
;   BANNER (input, switch)
;     Set this keyword to print a descriptive banner at the bottom of
;     the page.
;
;   PRINTER (input, object reference)
;     This keyword can be used to specify the printer object. This
;     allows the caller to keep its own printer, so that changes to
;     the setup can be saved between calls. If no value is specified
;     then the routine creates a printer object and destroys it after
;     printing is complete.
;
;   VECTOR (input, switch)
;     This keyword is passed to the printer's Draw method.
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
;   Mark Hadfield, 1999-08:
;     Written, based on code previously in MGH_Window::Print.
;   Mark Hadfield, 1999-09:
;     Added VECTOR keyword to allow vector output under IDL 5.3.
;   Mark Hadfield, 2000-08:
;     Removed call to one of my old MGHDT routines for the date-time
;     string in the banner.
;   Mark Hadfield, 2001-07:
;     Made this routine compatible with the new MGH_PRINTER function,
;     which provides a session-wide default printer.
;   Mark Hadfield, 2004-06:
;     Minor changes to code generating banner text.
;-
pro mgh_print_picture, picture, $
     BACKGROUND_COLOR=background_color, BANNER=banner, PRINTER=printer, $
     VECTOR=vector

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(picture) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'picture'

   if n_elements(picture) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'picture'

   if ~ obj_valid(picture) then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_objrefbad', 'picture'

   if n_elements(printer) eq 0 then printer = mgh_printer()

   print_scene = obj_new('IDLgrScene')

   picture_clone = mgh_obj_clone(picture)

   printer->GetProperty, RESOLUTION=print_res, DIMENSIONS=print_dim

   ;; Draw the background, if any

   if n_elements(background_color) gt 0 then begin

      background_view = obj_new('IDLgrView', COLOR=background_color)
      background_view->SetProperty, UNITS=2
      background_view->SetProperty, DIMENSIONS=print_res*print_dim
      background_view->SetProperty, LOCATION=[0,0]
      print_scene->Add, background_view

   endif

   ;; Write a banner with a shaded background at the bottom of the
   ;; page.

   case keyword_set(banner) of

      0: banner_height = 0.

      1: begin

         banner_height = 1.
         picture_clone->GetProperty, NAME=picture_name
         if strlen(picture_name) eq 0 then picture_name = 'IDL picture'
         banner_text = $
              string(FORMAT='(%"%s printed at %s")', $
                     picture_name, mgh_dt_string(mgh_dt_now(), ZONE=mgh_dt_zone()))
         if keyword_set(vector) then banner_text += '(vector mode)'
         banner_view = obj_new('IDLgrView', COLOR=[200,200,200], $
                               VIEWPLANE_RECT=[0,0,1,1])
         banner_view->SetProperty, UNITS=2
         banner_view->SetProperty, $
              DIMENSIONS=[print_res[0]*print_dim[0], banner_height]
         banner_view->SetProperty, LOCATION=[0,0]
         banner_model = obj_new('IDLgrModel')
         banner_view->Add, banner_model
         banner_text = obj_new('IDLgrText', STRINGS=banner_text, LOCATIONS=[0.02,0.35])
         banner_font = obj_new('IDLgrFont','Helvetica*Bold', SIZE=9)
         banner_text->SetProperty, FONT=banner_font
         banner_model->Add, banner_text
         print_scene->Add, banner_view

      end

   endcase

   ;; A view with default settings, or designed for display on the
   ;; screen, often prints poorly, so we modify the view's positioning
   ;; information (units, dimension & location) appropriately. Inital
   ;; settings are restored after printing

   fittable = mgh_picture_is_fittable(picture_clone, UNITS=picture_units, $
                                      DIMENSIONS=picture_dimensions)

   case 1 of
      obj_isa(picture_clone,'IDLgrView'):  begin
         views = picture_clone
         count = 1
      end
      obj_isa(picture_clone,'IDLgrViewgroup'): begin
         views = picture_clone->Get(ISA='IDLgrView', /ALL, COUNT=count)
      end
      else: begin
         count = 0
      endelse
   endcase

   if count gt 0 then begin

      for i=0,count-1 do begin

         views[i]->GetProperty, LOCATION=view_location

         ;; Most options still to be implemented
         if fittable then begin
            case picture_units of
               2: begin
                  view_location = view_location + $
                       [0.5*(print_res[0]*print_dim[0]-picture_dimensions[0]) > 0., $
                        0.5*(print_res[1]*print_dim[1]-picture_dimensions[1]- $
                             banner_height) > banner_height]
               end
            endcase
         endif

         views[i]->SetProperty, LOCATION=view_location

      endfor

   endif

   print_scene->Add, picture_clone

   printer->Draw, print_scene, VECTOR=vector

   printer->NewDocument

   obj_destroy, print_scene

   if obj_valid(banner_font) then $
        obj_destroy, banner_font

end


