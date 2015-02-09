; svn $Id$
;+
; CLASS NAME:
;   MGH_GUI_ColorScale
;
; PURPOSE:
;   This class implements a graphics window displaying a colour scale
;   (ie. a mapping between numeric and colour values) via a colour
;   bar. The ultimate aim is to use this object to make changes in the
;   colour scale then pass them back to the client but I haven't
;   implemented this yet.
;
; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'MGH_GUI_ColorScale', CLIENT=client
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
;   Mark Hadfield, Jul 2001:
;       Written.
;-

; MGH_GUI_ColorScale::Init
;
function MGH_GUI_ColorScale::Init, CLIENT=client, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.client = n_elements(client) gt 0 ? client : obj_new()

   case obj_valid(self.client) of
      0: begin
         palette = obj_new()
         data_range = [0,1]
         byte_range = [0,255]
      end
      1: begin
         self.client->GetProperty, $
              BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
              GRAPHICS_TREE=graphics_tree, PALETTE=palette
         if obj_valid(graphics_tree) then $
              graphics_tree->GetProperty, NAME=name
      end
   endcase

   self.palette = palette
   self.data_range = data_range
   self.byte_range = byte_range

   ograph = obj_new('MGHgrGraph', $
                    NAME=n_elements(name) gt 0 ? name + ' colour scale' : '(no graph)')

   ograph->NewFont, SIZE=10

   ograph->NewAtom, 'MGHgrColorBar', BYTE_RANGE=self.byte_range, $
        DATA_RANGE=self.data_range, PALETTE=self.palette, $
        FONT=ograph->GetFont(), RESULT=obar

   obar->GetProperty, XRANGE=xrange, YRANGE=yrange

   ograph->SetProperty, $
        VIEWPLANE_RECT=[xrange[0],yrange[0],xrange[1]-xrange[0], $
                        yrange[1]-yrange[0]]+[-0.1,-0.2,0.2,0.3]

   ok = self->MGH_Window::Init(ograph, CHANGEABLE=0, MBAR=0, EXPAND_STATUS_BAR=0, $
                               MOUSE_ACTION=['Pick','None','Context'], $
                               _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Window'

   self->Finalize, 'MGH_GUI_ColorScale'

   return, 1

end

; MGH_GUI_ColorScale::Cleanup
;
pro MGH_GUI_ColorScale::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::Cleanup

end


; MGH_GUI_ColorScale::GetProperty
;
pro MGH_GUI_ColorScale::GetProperty, $
     BYTE_RANGE=byte_range, CLIENT=client, DATA_RANGE=data_range, PALETTE=palette, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::GetProperty, _STRICT_EXTRA=extra

   byte_range = self.byte_range

   client = self.client

   data_range = self.data_range

   palette = self.palette

end

; MGH_GUI_ColorScale::SetProperty
;
pro MGH_GUI_ColorScale::SetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::SetProperty, _STRICT_EXTRA=extra

end


; MGH_GUI_ColorScale__Define

pro MGH_GUI_ColorScale__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_GUI_ColorScale, inherits MGH_Window, $
                 client: obj_new(), palette: obj_new(), $
                 data_range: fltarr(2), byte_range: bytarr(2)}

end
