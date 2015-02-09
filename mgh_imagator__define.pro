;+
; CLASS NAME:
;   MGH_Imagator
;
; PURPOSE:
;   This is a subclass of MGH_Atomator specialised for displaying
;   image sequences.
;
; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'MGH_Imagator'
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-12:
;     Written.
;   Mark Hadfield, 2001-09:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2002-10:
;     Updated for IDL 5.6.
;   Mark Hadfield, 2007-06:
;     Added the GRAPHICS_TREE_PROPERTIES property (initialise
;     only). Cool name, huh?
;-
; MGH_Imagator::Init

function MGH_Imagator::Init, $
     DIMENSIONS=dimensions, GRAPHICS_TREE_PROPERTIES=graphics_tree_properties, $
     PALETTE=palette, UNITS=units, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Set keyword defaults

   if n_elements(dimensions) eq 0 then dimensions=[500,500]

   if n_elements(units) eq 0 then units = 0

   if n_elements(visible) eq 0 then visible = 1

   ;; Create a graphics tree

   ograph = obj_new('MGHgrGraph', UNITS=units, DIMENSIONS=dimensions, $
                    VIEWPLANE_RECT=[-0.5,-0.5,1.0,1.0], COLOR=[127,127,127], $
                    _STRICT_EXTRA=graphics_tree_properties)

   ;; If necessary, create a palette object. This will be destroyed
   ;; with the graph.

   if n_elements(palette) eq 0 then begin
      ograph->NewPalette, RESULT=palette, $
           RED=indgen(256), GREEN=indgen(256), BLUE=indgen(256)
   endif

   ;; Store a reference to the palette in the class structure

   self.palette = palette

   ;; Initialise the superclass.

   mouse_action = ['Magnify','Translate', 'Context']
   mouse_list = ['None','Magnify','Scale', 'Translate','Undo Trans.','Context']

   ok = self->MGH_Atomator::Init(CHANGEABLE=0, GRAPHICS_TREE=ograph, $
                                 ANIMATION_PROPERTIES={multiple:0}, $
                                 MOUSE_ACTION=mouse_action, $
                                 MOUSE_LIST=mouse_list, $
                                 DIMENSIONS=dimensions, UNITS=units, $
                                 RESIZEABLE=0, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Atomator'

   return, 1

end

; MGH_Imagator::GetProperty
;
PRO MGH_Imagator::GetProperty, PALETTE=palette, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   palette = self.palette

   self->MGH_Atomator::GetProperty, _STRICT_EXTRA=extra

END

; MGH_Imagator::SetProperty
;
pro MGH_Imagator::SetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Atomator::SetProperty, _STRICT_EXTRA=extra

END

; MGH_Imagator::About
;
;   Print information about the window and its contents
;
pro MGH_Imagator::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Atomator::About, lun

   self->GetProperty, PALETTE=palette
   if obj_valid(palette) then begin
      message, /INFORM, 'The palette is '+mgh_obj_string(palette, /SHOW_NAME)
   endif

end

; MGH_Imagator::AddImage
;
;   Given an image in the form of a byte array, wrap it in an image
;   object and add it to the animation.
;
pro MGH_Imagator::AddImage, image

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.animation->GetProperty, GRAPHICS_TREE=ograph

   ograph->NewAtom, 'IDLgrImage', image, DIMENSIONS=[1,1], $
        LOCATION=[-0.5,-0.5], PALETTE=self.palette, RESULT=oimage, ADD=0

   self->AddFrame, oimage

end

; MGH_Imagator::AddPlot
;
;   Convert Z buffer contents to an image & load it into the animation
;
pro MGH_Imagator::AddPlot

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if strlowcase(!d.name) ne 'z' then $
        message, 'Z buffer is not active'

   if strlen(self.previous_device) eq 0 then $
        message, 'Cannot restore previous device: name not known'

   image = tvrd()

   set_plot, self.previous_device

   self.previous_device = ''

   self->AddImage, image

end

; MGH_Imagator::EventMenuBar
;
function MGH_Imagator::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'TOOLS.EDIT PALETTE': begin
         self->GetProperty, PALETTE=palette
         mgh_new, 'MGH_GUI_Palette_Editor', palette, CLIENT=self, $
                  /IMMEDIATE, /FLOATING, GROUP_LEADER=self.base
         return, 0
      end

      else: return, self->MGH_Atomator::EventMenuBar(event)

   endcase

end

; MGH_Imagator::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Imagator::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Atomator::BuildMenuBar

   ombar = mgh_widget_self(self.menu_bar)

   if obj_valid(ombar) then $
        ombar->NewItem, PARENT='Tools', ['Edit Palette...']

end


; MGH_Imagator::SetPlot
;
;   Prepare to accept direct graphics plotting commands--these will be
;   rendered to the Z buffer and then converted to images and added to
;   the animation via the LoadPlot method.
;
pro MGH_Imagator::SetPlot

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.animation->GetProperty, GRAPHICS_TREE=ograph

   ograph->GetProperty, DIMENSIONS=dimensions

   self.previous_device = !d.name

   set_plot, 'z'

   device, SET_RESOLUTION=dimensions

end

; MGH_Imagator__Define

pro MGH_Imagator__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Imagator, inherits MGH_Atomator, palette: obj_new(), $
                 previous_device: ''}

end
