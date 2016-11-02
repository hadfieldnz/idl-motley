; svn $Id$
 ;+
; NAME:
;   MGH_EXAMPLE_TESTBED
;
; PURPOSE:
;   MGH_GUI_Testbed object example. Handy for checking out the behaviour of
;   widgets.
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
;     Written.
;-
pro mgh_example_testbed, option, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   ;; Create a top-level testbed base. To avoid "jumping windows",
   ;; make it invisible now and viaible later.

   obase = obj_new('mgh_gui_testbed', VISIBLE=0, _STRICT_EXTRA=extra)

   case option of

      0: begin
         obase->Test
      end

      1: begin
         obase->Test, 'widget_text', XSIZE=50, YSIZE=2, VALUE='Hello', /EDITABLE
      end

      2: begin
         obase->Test, 'mgh_gui_droplist', /OBJECT, $
                       VALUE=['One','Two','Three'], SELECTED_VALUE='two'
      end

      3: begin
         obase->Test, 'mgh_window', /OBJECT, $
                      GRAPHICS_TREE=obj_new('mghgrgraph2d', /EXAMPLE)
      end

      4: begin
         obase->Test, 'mgh_plot', /OBJECT, findgen(11)
      end

      5: begin
         obase->Test, 'mgh_animator', /OBJECT, /EXAMPLE
      end

      6: begin
         obase->Test, 'mgh_gui_pdmenu', /OBJECT, ['One','Two','Three']
      end

      7: begin
         obase->Test, 'widget_base', /FRAME, XSIZE=100, YSIZE=100, $
                      /CONTEXT_EVENTS, /TRACKING_EVENTS, /TLB_SIZE_EVENTS
      end

      8: begin
         obase->Test, 'cw_fslider', /EDIT
      end

      9: begin
         openr, lun, /GET_LUN, filepath('jet.dat', SUBDIR=['examples','data'])
         h = bytarr(81, 40, 101)
         readu, lun, h
         free_lun, lun
         h = rebin(H, 405, 200, 101)
         dims = size(h, /DIMENSIONS)
         obase->Test, 'cw_animate', dims[0], dims[1], dims[2]
         obase->GetProperty, TEST_ID=cwid
         for f=0,dims[2]-1 do $
              cw_animate_load, cwid, FRAME=f, IMAGE=h[*,*,f]
         cw_animate_run, cwid, 70
      end

      10: begin
         obase->Test, 'mgh_gui_testbed', /OBJECT, RESULT=otest
         otest->Test
      end

      11: begin
         obase->Test, 'mgh_dgwindow', /OBJECT, DIMENSIONS=[500,500], NAME='My map', RESULT=otest
         otest->newcommand, 'map_set', 0, 170, LIMIT=[-50,160,-30,180], $
                           /ISOTROPIC, /MERCATOR
         otest->newcommand, 'map_continents', /HIRES, /FILL_CONTINENTS
         otest->newcommand, 'map_grid'
      end

      12: begin
         obase->Test, 'widget_tab', RESULT=wtab
         mgh_new, 'mgh_gui_base', PARENT=wtab, TITLE='Tab 1', /COLUMN, /FRAME, $
                  XSIZE=100, YSIZE=100
         mgh_new, 'mgh_gui_base', PARENT=wtab, TITLE='Tab 2', /COLUMN, /FRAME, $
                  XSIZE=100, YSIZE=100
      end

      13: begin
         obase->Test, 'widget_tree', RESULT=wtree
         wroot = widget_tree(wtree, VALUE='Root', /FOLDER, /EXPANDED)
         wleaf = widget_tree(wroot, VALUE='Leaf 0')
         wleaf = widget_tree(wroot, VALUE='Leaf 1')
      end

      14: begin
         ct = mgh_get_ct('Prism')
         obase->Test, 'mgh_cw_palette_editor', FILE=mgh_ct_file(), $
                      DATA=transpose([[ct.red],[ct.green],[ct.blue]])
      end

      15: begin
         obj = [obj_new('IDLgrLight', /REGISTER_PROPERTIES), $
                obj_new('IDLgrLight', /REGISTER_PROPERTIES)]
         obase->Dispose, obj
         obase->Test, 'widget_propertysheet', VALUE=obj
      end

   endcase

   ;; Some child objects (e.g. MGH_Window) need their Update methods
   ;; to be called before they become visible. This would normally be
   ;; done in the parent's Finalize method, but in the present case the
   ;; testbed's Finalize method was called when the testbed was
   ;; created. So call the testbed's Update method now and then make
   ;; the object visible.

   obase->Update

   obase->SetProperty, /VISIBLE

   ;; Special handling for a blocking base.

   obase->GetProperty, BLOCK=block

   if block then begin
      obase->Manage
      obj_destroy, obase
   endif

end
