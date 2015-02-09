;+
; CLASS NAME:
;   MGHgrPalette
;
; PURPOSE:
;   An MGHgrPalette is an IDLgrPalette with a few enhancements to the
;   Init method.
;
; OBJECT CREATION SEQUENCE:
;   palette = obj_new('MGHgrPalette', 10)
;   palette = obj_new('MGHgrPalette', 'MGH Special 2')
;   palette = obj_new('MGHgrPalette', mgh_color(['red','white','blue']))
;
; SUPERCLASSES:
;   IDLgrPalette
;
; POSITIONAL PARAMETERS (Init method):
;   tbl
;     Synonym for TABLE property.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported in addition to those inherited
;   from IDLgrPalette:
;
;     INVERT (Init)
;       Set this property to invert the colour table.
;
;     REVERSE (Init)
;       Set this property to reverse the colour table.
;
;     SYSTEM (Init)
;       This keyword has an effect only if the TABLE parameter is a
;       scalar integer or string. It is passed to the MGH_GET_CT
;       function and determines whether the user-default (SYSTEM=0) or
;       system (SYSTEM=1) colour table file is to be read.
;
;     TABLE (Init)
;       Specify the colour table associated with the palette in one
;       of the following forms:
;
;         Scalar structure: The red, green and blue vectors of the
;           palette's colour table are specified via the RED, GREEN and
;           BLUE tags of the structure.
;
;         Integer array [3,n]: The red, green and blue vectors of the
;           palette's colour table are specified via the respective
;           rows of the array.
;
;         Scalar integer or string: The color table is read from the colour
;           table file by function MGH_GET_CT; the table parameter
;           specifies the zero-based  index (numeric) or table name
;           (string) of the colour table to be read.
;
;###########################################################################
; Copyright (c) 2013 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-11:
;     Written.
;   Mark Hadfield, 2002-06:
;     Changed initialisation options: reduced maximum number of
;     positional parameters from 3 to 1 and added TABLE keyword.
;-
function MGHgrPalette::Init, tbl, $
     INVERT=invert, REVERSE=reverse, SYSTEM=system, TABLE=table, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(table) eq 0 then if n_elements(tbl) gt 0 then table = tbl

   case 1 of

      n_elements(table) eq 0: begin

         ;; Table not specified

         ok = self->IDLgrPalette::Init(_STRICT_EXTRA=extra)
         if ~ ok then $
              message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrPalette'

      end

      n_elements(table) eq 1 and size(table, /TYPE) eq 8: begin

         ;; Table is scalar structure

         ok = self->IDLgrPalette::Init(RED=table.red, GREEN=table.green, $
                                       BLUE=table.blue, NAME=table.name, $
                                       _STRICT_EXTRA=extra)
         if ~ ok then $
              message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrPalette'

      end

      size(table, /N_DIMENSIONS) eq 2 and (size(table, /DIMENSIONS))[0] eq 3: begin

         ;; Table is [3,n] array.

         ok = self->IDLgrPalette::Init(RED=table[0,*], GREEN=table[1,*], $
                                       BLUE=table[0,*], _STRICT_EXTRA=extra)
         if ~ ok then $
              message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrPalette'
      end

      size(table, /N_DIMENSIONS) eq 0: begin

         ;; Table is scalar integer or string

         ct = mgh_get_ct(table, SYSTEM=system)
         ok = self->IDLgrPalette::Init(RED=ct.red, GREEN=ct.green, BLUE=ct.blue, $
                                       NAME=ct.name, _STRICT_EXTRA=extra)
         if ~ ok then $
              message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'IDLgrPalette'

      end

   endcase

   if keyword_set(invert) then self->Invert

   if keyword_set(reverse) then self->Reverse
   
   return, 1

end

; MGHgrPalette::Cleanup
;
pro MGHgrPalette::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->IDLgrPalette::Cleanup

end

; MGHgrPalette::GetProperty
;
pro MGHgrPalette::GetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->IDLgrPalette::GetProperty, _STRICT_EXTRA=extra

end

; MGHgrPalette::SetProperty
;
pro MGHgrPalette::SetProperty, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->IDLgrPalette::SetProperty, _STRICT_EXTRA=extra

end

; MGHgrPalette::Invert
;
pro MGHgrPalette::Invert

   compile_opt DEFINT32
   compile_opt STRICTARR

   self->GetProperty, N_COLORS=n_colors, RED=red, GREEN=green, BLUE=blue

   if n_colors gt 1 then $
        self->SetProperty, RED=(255-red), GREEN=(255-green), BLUE=(255-blue)

end

; MGHgrPalette::Reverse
;
pro MGHgrPalette::Reverse

  compile_opt DEFINT32
  compile_opt STRICTARR
  
  self->GetProperty, N_COLORS=n_colors, RED=red, GREEN=green, BLUE=blue
  
  if n_colors gt 1 then $
    self->SetProperty, RED=reverse(red), GREEN=reverse(green), BLUE=reverse(blue)
    
end

pro MGHgrPalette__define

   compile_opt DEFINT32
   compile_opt STRICTARR

   struct_hide, {MGHgrPalette, inherits IDLgrPalette}

end

