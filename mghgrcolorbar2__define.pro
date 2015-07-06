; svn $Id$
;+
; CLASS NAME:
;   MGHgrColorBar2
;
; PURPOSE:
;   This class implements a colour bar, ie a rectangular bar
;   showing a mapping between numeric values and colours.
;
; CATEGORY:
;   Object graphics.
;
; SUPERCLASSES:
;   This class inherits from IDLgrModel.
;
; PROPERTIES:
;   The following properties are supported:
;
;       AXIS (Get)
;           This keyword returns a reference to the axis object. It can be used
;           to modify the axis properties.
;
;       BYTE_RANGE (Init,Get,Set)
;           The range of byte values to which the data range is to be mapped.
;
;       COLORSCALE (Init)
;           A reference to an object from which default colour mapping information
;           (BYTE_RANGE, DATA_RANGE and PALETTE) can be retrieved.
;
;       DATA_RANGE (Init,Get,Set)
;           The range of data values to be mapped onto the indexed color range.
;           Data values outside the range are mapped to the nearest end of the range.
;
;       DELTAZ (Init,Get,Set)
;           Vertical spacing in normalised units between the components of the
;           object, needed to control visibility. If this property is
;           not set, then the spacing is set at draw time, based on the view's
;           ZCLIP property--the value is 2*(ZCLIP[0] - ZCLIP[1])/65536, which
;           for the default ZCLIP is 6.1E-5. DELTAZ should only need to be
;           set explicitly if the object or its parent is transformed before
;           drawing.
;
;       LOCATION (Init,Get,Set)
;           Location of the lower left corner of the rectangle in data units.
;
;       DIMENSIONS (Init,Get,Set)
;           Horizontal & vertical dimensions of the rectangle in data units.
;
;       PALETTE (Init,Get,Set)
;           A reference to the palette defining the byte-color mapping.
;
;       TICKIN (Init,Get,Set)
;           Controls whether tick marks are directed inwards (1) or outwards (0).
;           The default is 0.
;
;       TITLE (Init,Get,Set)
;           A reference to a text object representing the axis title. If this is
;           specified as a string, then a text object is created automatically
;           using the current setting of the FONT property.
;
;       XCOORD_CONV (Init,Get,Set)
;       YCOORD_CONV (Init,Get,Set)
;       ZCOORD_CONV (Init,Get,Set)
;           Coordinate transformations specifying the relationship between
;           normalised & data units.
;
;       XRANGE (Get)
;       YRANGE (Get)
;       ZRANGE (Get)
;           Position of the extremes of the object in data units. ZRANGE is
;           not finalised until the object is drawn.
;
; METHODS:
;   The usual.
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
;   Mark Hadfield, Aug 1998:
;       Written.
;-

; MGHgrColorBar2::Init

FUNCTION MGHgrColorBar2::Init                $
        , BYTE_RANGE=byte_range             $
        , COLORSCALE=colorscale             $
        , DATA_RANGE=data_range             $
        , DELTAZ=deltaz                     $
        , DIMENSIONS=dimensions             $
        , FONT=font                         $
        , LOCATION=location                 $
        , NAME=name                         $
        , PALETTE=palette                   $
        , SHOW_AXIS=show_axis               $
        , SHOW_OUTLINE=show_outline         $
        , TICKIN=tickin                     $
        , TICKLEN=ticklen                   $
        , TITLE=title                       $
        , VERTICAL=vertical                 $
        , XCOORD_CONV=xcoord_conv           $
        , YCOORD_CONV=ycoord_conv           $
        , ZCOORD_CONV=zcoord_conv           $
        , _EXTRA=extra

    compile_opt DEFINT32
   compile_opt STRICTARR

    if not self->IDLgrModel::Init( /SELECT_TARGET, _EXTRA=extra ) then return, 0

    ; Create child objects

    self.normal_node = obj_new( 'IDLgrModel' )

    self.disposal = obj_new( 'IDL_Container' )

    self.ramp = obj_new( 'IDLgrSurface', STYLE=2 )

    self.outline = obj_new('IDLgrPolyline', [0,1,1,0,0], [0,0,1,1,0], intarr(5), COLOR=[0,0,0])

    self.axis = obj_new( 'IDLgrAxis', /EXACT, TICKLEN=0.3 )

    ; Set up the object hierarchy

    self->Add, self.normal_node

    self.normal_node->Add, self.ramp

    self.normal_node->Add, self.outline

    self.normal_node->Add, self.axis

    ; Specify defaults

    self.vertical = 0

    if keyword_set(vertical) then self.dimensions = [0.1,1.0] else self.dimensions = [1.0,0.1]

    self.byte_range = [0,0]
    self.data_range = [0,0]
    self.deltaz = !values.f_nan
    self.location = [0,0,0]
    self.show_axis = 1
    self.show_outline = 1
    self.tickin = 0
    self.xcoord_conv = [0,1]
    self.ycoord_conv = [0,1]
    self.zcoord_conv = [0,1]

    if n_elements(colorscale) eq 1 then if obj_valid(colorscale) then begin
        colorscale->GetProperty, BYTE_RANGE=c_byte_range, DATA_RANGE=c_data_range, PALETTE=c_palette
        if n_elements(byte_range) ne 2 then byte_range = c_byte_range
        if n_elements(data_range) ne 2 then data_range = c_data_range
        if n_elements(palette) ne 1 then palette = c_palette
    endif

    self->SetProperty                       $
        , BYTE_RANGE=byte_range             $
        , DATA_RANGE=data_range             $
        , DELTAZ=deltaz                     $
        , DIMENSIONS=dimensions             $
        , FONT=font                         $
        , LOCATION=location                 $
        , NAME=name                         $
        , PALETTE=palette                   $
        , SHOW_AXIS=show_axis               $
        , SHOW_OUTLINE=show_outline         $
        , TICKLEN=ticklen                   $
        , TICKIN=tickin                     $
        , TITLE=title                       $
        , VERTICAL=vertical                 $
        , XCOORD_CONV=xcoord_conv           $
        , YCOORD_CONV=ycoord_conv           $
        , ZCOORD_CONV=zcoord_conv

    return, 1

END

; MGHgrColorBar2::Cleanup
;
PRO MGHgrColorBar2::Cleanup

    compile_opt DEFINT32
   compile_opt STRICTARR

    obj_destroy, self.disposal

    self->IDLgrModel::Cleanup

end

; MGHgrColorBar2::SetProperty
;
PRO MGHgrColorBar2::SetProperty                 $
        , BYTE_RANGE=byte_range                 $
        , DATA_RANGE=data_range                 $
        , DELTAZ=deltaz                         $
        , DIMENSIONS=dimensions                 $
        , FONT=font                             $
        , LOCATION=location                     $
        , NAME=name                             $
        , PALETTE=palette                       $
        , SHOW_AXIS=show_axis                   $
        , SHOW_OUTLINE=show_outline             $
        , TICKLEN=ticklen                       $
        , TICKIN=tickin                         $
        , TITLE=title                           $
        , VERTICAL=vertical                     $
        , XCOORD_CONV=xcoord_conv               $
        , YCOORD_CONV=ycoord_conv               $
        , ZCOORD_CONV=zcoord_conv

    compile_opt DEFINT32
   compile_opt STRICTARR

    recalc = 0

    if n_elements(deltaz) eq 1 then self.deltaz = deltaz

    if n_elements(byte_range) eq 2 then begin
        self.byte_range = byte_range
        recalc = 1
    endif

    if n_elements(data_range) eq 2 then begin
        self.data_range = data_range
        recalc = 1
    endif

    if n_elements(dimensions) eq 2 then begin
        self.dimensions = dimensions
        recalc = 1
    endif

    nloc = n_elements(location)
    if nloc ge 2 then begin
        self.location[0:nloc-1] = location
        recalc = 1
    endif

    if n_elements(name) eq 1 then self.ramp->SetProperty, NAME=name

    if n_elements(palette) eq 1 then self.ramp->SetProperty, PALETTE=palette

    if n_elements(show_axis) eq 1 then begin
        self.show_axis = show_axis
        recalc = 1
    endif

    if n_elements(show_outline) eq 1 then begin
        self.outline->SetProperty, HIDE=(self.show_outline eq 0)
        recalc = 1
    endif

    if n_elements(ticklen) eq 1 then begin
        self.axis->SetProperty, TICKLEN=ticklen
        recalc = 1
    endif

    if n_elements(tickin) eq 1 then begin
        self.tickin = tickin
        recalc = 1
    endif

    if n_elements(vertical) eq 1 then begin
        self.vertical = vertical
        recalc = 1
    endif

    if n_elements(xcoord_conv) eq 2 then begin
        self.xcoord_conv = xcoord_conv
        recalc = 1
    endif

    if n_elements(ycoord_conv) eq 2 then begin
        self.ycoord_conv = ycoord_conv
        recalc = 1
    endif

    if n_elements(zcoord_conv) eq 2 then begin
        self.zcoord_conv = zcoord_conv
        recalc = 1
    endif

    if n_elements(font) eq 1 then if obj_valid(font) then begin
        self.font = font
        self.axis->GetProperty, TICKTEXT=tt
        tt->SetProperty, FONT=font
    endif

    case size(title, /TYPE) of
        7: begin
            otitle = obj_new('IDLgrText', title[0], FONT=self.font)
            self.disposal->Add, otitle
            self.axis->SetProperty, TITLE=otitle
        end
        11: self.axis->SetProperty, TITLE=title[0]
        else: dummy = 0
    endcase

    if recalc then self->Calculate

end


; MGHgrColorBar2::GetProperty
;
PRO MGHgrColorBar2::GetProperty                 $
        , ALL=all                               $
        , AXIS=axis                             $
        , BYTE_RANGE=byte_range                 $
        , DATA_RANGE=data_range                 $
        , DELTAZ=deltaz                         $
        , DIMENSIONS=dimensions                 $
        , FONT=font                             $
        , HIDE=hide                             $
        , LOCATION=location                     $
        , NAME=name                             $
        , PALETTE=palette                       $
        , PARENT=parent                         $
        , SHOW_AXIS=show_axis                   $
        , SHOW_OUTLINE=show_outline             $
        , TICKLEN=ticklen                       $
        , TICKIN=tickin                         $
        , TITLE=title                           $
        , XCOORD_CONV=xcoord_conv               $
        , XRANGE=xrange                         $
        , YCOORD_CONV=ycoord_conv               $
        , YRANGE=yrange                         $
        , ZCOORD_CONV=zcoord_conv               $
        , ZRANGE=zrange

    compile_opt DEFINT32
   compile_opt STRICTARR

    ; Get properties from class structure

    axis = self.axis

    byte_range = self.byte_range

    data_range = self.data_range

    deltaz = self.deltaz

    dimensions = self.dimensions

    font = self.font

    location = self.location

    show_axis = self.show_axis

    tickin = self.tickin

    xcoord_conv = self.xcoord_conv
    ycoord_conv = self.ycoord_conv
    zcoord_conv = self.zcoord_conv

    ; Get properties from components

    self.axis->GetProperty, TICKLEN=ticklen, TITLE=title

    self.ramp->GetProperty, NAME=name, PALETTE=palette

    self.outline->GetProperty, HIDE=hide_outline  &  show_outline = 1 - hide_outline

    ; Get properties from superclass

    self->IDLgrModel::GetProperty, HIDE=hide, PARENT=parent

    ; Calculate ranges

    self.ramp->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

    if self.show_outline then begin

        self.outline->GetProperty, XRANGE=outline_xrange, YRANGE=outline_yrange, ZRANGE=outline_zrange

        xrange[0] = xrange[0] < outline_xrange[0]
        xrange[1] = xrange[1] > outline_xrange[1]

        yrange[0] = yrange[0] < outline_yrange[0]
        yrange[1] = yrange[1] > outline_yrange[1]

        zrange[0] = zrange[0] < outline_zrange[0]
        zrange[1] = zrange[1] > outline_zrange[1]

    endif

    if self.show_axis gt 0 then begin

        self.axis->GetProperty, XRANGE=axis_xrange, YRANGE=axis_yrange, ZRANGE=axis_zrange  $
            , XCOORD_CONV=axis_xcoord, YCOORD_CONV=axis_ycoord, ZCOORD_CONV=axis_zcoord

        xrange[0] = xrange[0] < (axis_xrange[0]*axis_xcoord[1] + axis_xcoord[0])
        xrange[1] = xrange[1] > (axis_xrange[1]*axis_xcoord[1] + axis_xcoord[0])

        yrange[0] = yrange[0] < (axis_yrange[0]*axis_ycoord[1] + axis_ycoord[0])
        yrange[1] = yrange[1] > (axis_yrange[1]*axis_ycoord[1] + axis_ycoord[0])

        zrange[0] = zrange[0] < (axis_zrange[0]*axis_zcoord[1] + axis_zcoord[0])
        zrange[1] = zrange[1] > (axis_zrange[1]*axis_zcoord[1] + axis_zcoord[0])

    endif

    self.normal_node->GetProperty, TRANSFORM = normal_transform
    xrange = xrange * normal_transform[0,0] + normal_transform[3,0]
    yrange = yrange * normal_transform[1,1] + normal_transform[3,1]
    zrange = zrange * normal_transform[2,2] + normal_transform[3,2]

    if arg_present(all) then $
        all =   { AXIS: axis                        $
                , BYTE_RANGE: byte_range            $
                , DATA_RANGE: data_range            $
                , DELTAZ: deltaz                    $
                , DIMENSIONS: dimensions            $
                , FONT: font                        $
                , HIDE: hide                        $
                , LOCATION: location                $
                , PALETTE: palette                  $
                , PARENT: parent                    $
                , SHOW_AXIS: show_axis              $
                , SHOW_OUTLINE: show_outline        $
                , TICKIN: tickin                    $
                , TICKLEN: ticklen                  $
                , TITLE: title                      $
                , XCOORD_CONV: xcoord_conv          $
                , XRANGE: xrange                    $
                , YCOORD_CONV: ycoord_conv          $
                , YRANGE: yrange                    $
                , ZCOORD_CONV: zcoord_conv          $
                , ZRANGE: zrange                    $
                }

end


; MGHgrColorBar2::Calculate
;
PRO MGHgrColorBar2::Calculate

    compile_opt DEFINT32
   compile_opt STRICTARR

    if self.byte_range[0] eq self.byte_range[1] then begin
        self.ramp->GetProperty, PALETTE=palette
        if obj_valid(palette) then begin
            palette->GetProperty, N_COLORS=n_colors
            byte_range = [0,n_colors-1]
         endif else begin
            byte_range = [0,255]
         endelse
    endif else begin
        byte_range = self.byte_range
    endelse

    if self.data_range[0] eq self.data_range[1] then begin
        data_range = float(byte_range)
    endif else begin
        data_range = self.data_range
    endelse

    if self.show_axis eq 2 then tickdir = self.tickin else tickdir = 1 - self.tickin

    self.axis->SetProperty                  $
        , DIRECTION=self.vertical           $
        , HIDE=(self.show_axis eq 0)        $
        , RANGE=data_range                  $
        , TICKDIR=tickdir                   $
        , TEXTPOS=(self.show_axis eq 2)     $
        , /EXACT

    nramp = byte_range[1]-byte_range[0]+1

    ramp_byte_values = byte_range[0] + indgen(nramp)

    axis_coord_conv = MGH_NORM_COORD(data_range,[0.5/nramp,1-0.5/nramp])

    if self.vertical then begin
        self.ramp->SetProperty                  $
            , DATAX=[0,1]                       $
            , DATAY=findgen(nramp+1)/nramp      $
            , DATAZ=fltarr(2,nramp+1)           $
            , VERT_COLORS=reform([1,1]#ramp_byte_values,2*nramp)
        if self.show_axis eq 2 then $
            self.axis->SetProperty, LOCATION=[1,0,0], YCOORD_CONV=axis_coord_conv $
        else $
            self.axis->SetProperty, LOCATION=[0,0,0], YCOORD_CONV=axis_coord_conv
    endif else begin
        self.ramp->SetProperty                  $
            , DATAX=findgen(nramp+1)/nramp      $
            , DATAY=[0,1]                       $
            , DATAZ=fltarr(nramp+1,2)           $
            , VERT_COLORS=ramp_byte_values
        if self.show_axis eq 2 then $
            self.axis->SetProperty, LOCATION=[0,1,0], XCOORD_CONV=axis_coord_conv $
        else $
            self.axis->SetProperty, LOCATION=[0,0,0], XCOORD_CONV=axis_coord_conv
    endelse

    self.normal_node->Reset

    self.normal_node->Scale, self.dimensions[0], self.dimensions[1], 1

    self.normal_node->Translate, self.location[0], self.location[1], self.location[2]

    self->Reset

    self->Scale, self.xcoord_conv[1], self.ycoord_conv[1], self.zcoord_conv[1]

    self->Translate, self.xcoord_conv[0], self.ycoord_conv[0], self.zcoord_conv[0]

end

; MGHgrColorBar2::Draw
;
PRO MGHgrColorBar2::Draw, oSrcDest, oView

    compile_opt DEFINT32
   compile_opt STRICTARR

    if finite(self.deltaz) then begin
        deltaz = self.deltaz
    endif else begin
        oView->GetProperty, ZCLIP=zclip
        deltaz = 2.D0*(double(zclip[0]) - double(zclip[1]))/65536.D0
    endelse

    self.outline->GetProperty, DATA=data
    data[2,*] = deltaz/self.zcoord_conv[1]
    self.outline->SetProperty, DATA=data

    self.axis->GetProperty, LOCATION=location
    location[2] = deltaz/self.zcoord_conv[1]
    self.axis->SetProperty, LOCATION=location

    self->IDLgrModel::Draw, oSrcDest, oView

END


; MGHgrColorBar2__Define

pro MGHgrColorBar2__Define

    compile_opt DEFINT32
   compile_opt STRICTARR

    struct = { MGHgrColorBar2                           $
             , inherits IDLgrModel                      $
             , normal_node  : obj_new()                 $
             , disposal     : obj_new()                 $
             , axis         : obj_new()                 $
             , outline      : obj_new()                 $
             , ramp         : obj_new()                 $
             , font         : obj_new()                 $
             , byte_range   : bytarr(2)                 $
             , data_range   : fltarr(2)                 $
             , deltaz       : 0.                        $
             , dimensions   : fltarr(2)                 $
             , location     : fltarr(3)                 $
             , show_axis    : 0B                        $
             , show_outline : 0B                        $
             , tickin       : 0B                        $
             , vertical     : 0B                        $
             , xcoord_conv  : fltarr(2)                 $
             , ycoord_conv  : fltarr(2)                 $
             , zcoord_conv  : fltarr(2)                 $
             }
end


