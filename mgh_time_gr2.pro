; svn $Id$
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
 ;+
; NAME:
;   MGH_TIME_GR2
;
; PURPOSE:
;   Run speed tests for object graphics
;
; CATEGORY:
;   Testing.
;
; CALLING SEQUENCE:
;   MGH_TIME_GR2
;
; KEYWORD PARAMETERS:
;   N_LOOPS (input, integer, scalar)
;     The number of runs to be averaged together.  Default:1
;
;   FILENAME (input, string, scalar)
;     The name of a file to which performance data are to be appended.
;     Default:stdout
;
;   RENDERER (input, integer)
;     The OpenGL renderer: 0=Native OpenGL(the default), 1=Mesa
;
;   COLOR_MODEL:  Set this keyword to select between RGB (0) or Color
;       Index (1) modes.  Default: 0  (RGB)
;
;   RETAIN: Set this keyword to the RETAIN value to be used in the test.
;   WIN_TYPE:  This keyword selects the type of destination device to
;       use: 0=WIDGET_DRAW, 1=IDLgrWindow, 2=IDLgrBuffer
;       Default: 0
;
; OUTPUTS:
;   Timing information for each of the various tests are sent to
;   stdout or appended to the output file.  All times are in secs
;   and lower numbers are better.
;
; RESTRICTIONS:
;
; EXAMPLE:
;   To test the speed of a Mesa widget in ColorIndex mode use:
;       MGH_TIME_GR2,RENDERER=1,COLOR_MODEL=1
; NOTES:
;   An extra proceedure is provided to excercise all the devices in
;   every mode: MGH_TIME_GR2_ALL.  It takes only the N_LOOPS and FILENAME
;   keywords and calls MGH_TIME_GR2 with all possible combinations of
;   the other keywords.
;
; MODIFICATION HISTORY:
;   Randall Frank, 1997-10-23:
;     Written as TIME_TEST_GR2.
;   Mark Hadfield, 2000-08:
;     Received from Randall Frank.
;   Mark Hadfield, 2001-02:
;     Renamed MGH_TIME_GR2. Print more information, including
;     properties & device info from the window object. No change yet
;     in number or type of tests.
;-

; Utility function to print contents of structure (MGH)
; Test the time to erase and swap a dest
FUNCTION mgh_time_gr2_erase,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 1000L

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["NONE"]
        RETURN,iNum
    ENDIF

; setup
    oView=OBJ_NEW('IDLgrView')
; run
    t0 = SYSTIME(1)
    FOR i=0,iNum-1 DO oWin->Draw,oView
    fTime = SYSTIME(1) - t0
; tear down
    OBJ_DESTROY,oView

    RETURN,fTime
END

; Test the time to traverse a deep model tree
FUNCTION mgh_time_gr2_traverse,oWin,GET_OPTS=get_opts, $
    OPTS=opts
    iNum = 20L
    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["NONE"]
        RETURN,iNum*iNum*iNum
    ENDIF
; setup
    oView=OBJ_NEW('IDLgrView')
    FOR i=1,iNum DO BEGIN
        oI = OBJ_NEW('IDLgrModel')
        oView->Add,oI
        FOR j=1,iNum DO BEGIN
            oJ = OBJ_NEW('IDLgrModel')
            oI->Add,oJ
            FOR k=1,iNum DO BEGIN
                oK = OBJ_NEW('IDLgrModel')
                oJ->Add,oK
            ENDFOR
        ENDFOR
    ENDFOR
; run
    t0 = SYSTIME(1)
    oWin->Draw,oView
    fTime = SYSTIME(1) - t0
; tear down
    OBJ_DESTROY,oView

    RETURN,fTime
END

; Testing - none, thick, dashed, shaded, symbol
FUNCTION mgh_time_gr2_line,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 50000L

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["NONE","THICK","DASHED","SHADED","SYMBOL"]
        RETURN,iNum
    ENDIF
; setup
    oView=OBJ_NEW('IDLgrView',VIEW=[-1,-1,2,2])
    oModel=OBJ_NEW('IDLgrModel')
    oView->add,oModel
    oSym=OBJ_NEW('IDLgrSymbol',SIZE=[0.02,0.02])
    fData = FLTARR(3,2L*iNum)
    iPoly = LONARR(3L*iNum)
    k = 0L
    FOR i=0L,iNum-1L DO BEGIN
        a = (FLOAT(i)*3.0)*(!PI/180.0)
        fData[*,i*2] = [cos(a),sin(a),FLOAT(i)/FLOAT(iNum)]
        fData[*,i*2+1] = [-cos(a),-sin(a),FLOAT(i)/FLOAT(iNum)]
        iPoly[k] = 2L
        iPoly[k+1] = i*2L
        iPoly[k+2] = i*2 + 1
        k = k + 3
    ENDFOR
    oPoly=OBJ_NEW("IDLgrPolyline",DATA=fData,COLOR=[0,0,0],POLYLINES=iPoly)
    CASE opts OF
        "NONE" : BEGIN
             END
        "THICK" : BEGIN
             oPoly->SetProperty,THICK=2.0
             END
        "DASHED" : BEGIN
             oPoly->SetProperty,LINESTYLE=2
             END
        "SHADED" : BEGIN
             oPoly->SetProperty,VERT_COLORS=[0,255], $
                SHADING=1
             END
        "SYMBOL" : BEGIN
             oPoly->SetProperty,SYMBOL=oSym
             END
    ENDCASE
    oModel->Add,oPoly
; run
    oWin->Draw,oView   ; build caches
    t0 = SYSTIME(1)
    oWin->Draw,oView
    fTime = SYSTIME(1) - t0
; tear down
    OBJ_DESTROY,[oView,oSym]

    RETURN,fTime
END

; Image - RGB, CI, GS, GA, RGBA, blended, line_inter, band_inter
FUNCTION mgh_time_gr2_image,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 1500L

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["CI","GS","GSA","RGB","RGBA","BLEND","LINE_INTER",$
                "BAND_INTER","STRETCH"]
        RETURN,iNum
    ENDIF
; setup
    view=[0,0,400,400]
    IF (opts EQ "STRETCH") THEN view=[0,0,100,100]
    iBlend = [0,0]
    IF (opts EQ "BLEND") THEN iBlend = [3,4]
    iInter = 0
    iGrey = 0
    CASE opts OF
        "GSA" : BEGIN
            data = BYTARR(2,100,100)
            data[0,*,*] = BYTSCL(DIST(100))
            data[1,*,*] = BYTSCL(DIST(100))
            END
        "RGB" : BEGIN
            data = BYTARR(3,100,100)
            data[0,*,*] = BYTSCL(DIST(100))
            data[1,*,*] = BYTSCL(DIST(100))
            data[2,*,*] = BYTSCL(DIST(100))
            END
        "LINE_INTER": BEGIN
                  iInter = 1
                  data = BYTARR(100,3,100)
                  data[*,0,*] = BYTSCL(DIST(100))
                  data[*,1,*] = BYTSCL(DIST(100))
                  data[*,2,*] = BYTSCL(DIST(100))
                      END
        "BAND_INTER": BEGIN
                  iInter = 2
                  data = BYTARR(100,100,3)
                  data[*,*,0] = BYTSCL(DIST(100))
                  data[*,*,1] = BYTSCL(DIST(100))
                  data[*,*,2] = BYTSCL(DIST(100))
                      END
        "GS" : BEGIN
            data = BYTSCL(DIST(100))
            iGrey = 1
               END
        "CI" : BEGIN
            data = BYTSCL(DIST(100))
               END
        ELSE : BEGIN
            data = BYTARR(4,100,100)
            data[0,*,*] = BYTSCL(DIST(100))
            data[1,*,*] = BYTSCL(DIST(100))
            data[2,*,*] = BYTSCL(DIST(100))
            data[3,*,*] = BYTSCL(DIST(100))
               END
    ENDCASE

    oView=OBJ_NEW('IDLgrView',VIEW=view)
    oModel=OBJ_NEW('IDLgrModel')
    oView->add,oModel
    iLoops = 10
    iImages = iNum / iLoops
    FOR i=0L,iImages-1L DO BEGIN
        oImag=OBJ_NEW("IDLgrImage",data,BLEND_FUNCTION=iBlend, $
            INTERLEAVE=iInter,GREYSCALE=iGrey)
        oModel->Add,oImag
    ENDFOR
; run
    oWin->Draw,oView   ; build caches
    t0 = SYSTIME(1)
    FOR i=0L,iLoops-1L DO BEGIN
        oWin->Draw,oView
    ENDFOR
    fTime = SYSTIME(1) - t0
; tear down
    OBJ_DESTROY,oView

    RETURN,fTime
END

; Polygon -  none, mesh, fill_pat, fill_line, hidden_line,
;    texture_rgb
FUNCTION mgh_time_gr2_polygon,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 50000L

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["NONE","NOMESH","FILLPAT","FILLLINE","HIDDEN", $
            "TEXTURE"]
        RETURN,iNum
    ENDIF
; setup
    oView=OBJ_NEW('IDLgrView',VIEW=[-1,-1,2,2],COLOR=[0,0,0])
    oModel=OBJ_NEW('IDLgrModel')
    oView->add,oModel

    bMesh = 1
    IF (opts EQ "NOMESH") THEN bMesh = 0

    pat = LONARR(32)
    pat[*] = 'a0a0a0a0'x
    oPat=OBJ_NEW('IDLgrPattern',2,PATTERN=pat)
    oLin=OBJ_NEW('IDLgrPattern',1,SPACING=10)

    iData = BYTARR(3,128,128)
    iData[0,*,*] = BYTSCL(DIST(128))
    iData[1,*,*] = BYTSCL(DIST(128))
    iData[2,*,*] = BYTSCL(DIST(128))
    oImg=OBJ_NEW('IDLgrImage',iData)

    fData = FLTARR(3,iNum)
    fNorm = FLTARR(3,iNum)
    fText = FLTARR(2,iNum)
    iPoly = LONARR(4*iNum)
    k = 0L
    fData[*,0] = [0.,0.,0.]
    fData[*,1] = [cos(0),sin(0),0.]
    FOR i=2L,iNum-1L DO BEGIN
        a = (FLOAT(i)*3.0)*(!PI/180.0)
        fData[*,i] = [cos(a),sin(a),FLOAT(i)/FLOAT(iNum)]
        iPoly[k+0] = 3
        IF ((bMesh EQ 1) OR (i AND 1)) THEN BEGIN
            iPoly[k+1] = 0
            iPoly[k+2] = i-1
            iPoly[k+3] = i
        ENDIF ELSE BEGIN
            iPoly[k+1] = i-1
            iPoly[k+2] = 0
            iPoly[k+3] = i
        ENDELSE
        k = k + 4
    ENDFOR

    fText[0,*] = (fData[0,*]*0.5)+0.5
    fText[1,*] = (fData[1,*]*0.5)+0.5

    fNorm[0,*] = 0.0
    fNorm[1,*] = 0.0
    fNorm[2,*] = 1.0

    iPoly[k] = -1
    oPoly=OBJ_NEW("IDLgrPolygon",DATA=fData,COLOR=[255,255,255], $
        POLYGONS=iPoly,SHADING=1,STYLE=2,NORMALS=fNorm)
    CASE opts OF
        "NONE" : BEGIN
             END
        "NOMESH" : BEGIN
             END
        "FILLPAT" : BEGIN
             oPoly->SetProperty,FILL_PATTERN=oPat
             END
        "FILLLINE" : BEGIN
             oPoly->SetProperty,FILL_PATTERN=oLin
             END
        "HIDDEN" : BEGIN
             oPoly->SetProperty,HIDDEN_LINES=1,STYLE=1
             END
        "TEXTURE" : BEGIN
             oPoly->SetProperty,TEXTURE_COORD=fText, $
                TEXTURE_MAP=oImg
             END
    ENDCASE
    oModel->Add,oPoly
; run
    oWin->Draw,oView   ; build caches
    t0 = SYSTIME(1)
    oWin->Draw,oView
    fTime = SYSTIME(1) - t0
; tear down
    OBJ_DESTROY,[oView,oPat,oLin,oImg]

    RETURN,fTime
END

; Text - none, hersh, ONGLASS, gettextdimensions
;
;   Could add tessellation test...
;
FUNCTION mgh_time_gr2_text,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 5000L

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["NONE","HERSH","ONGLASS","GETTEXTDIMS"]
        RETURN,iNum
    ENDIF
; setup
    oView=OBJ_NEW('IDLgrView',VIEW=[-3,-3,6,6],COLOR=[0,0,0])
    oModel=OBJ_NEW('IDLgrModel')
    oView->add,oModel

    IF (opts EQ "HERSH") THEN BEGIN
        oFont=OBJ_NEW('IDLgrFont','Hershey*1',SIZE=12)
    ENDIF ELSE BEGIN
        oFont=OBJ_NEW('IDLgrFont','Helvetica',SIZE=12)
    ENDELSE

    FOR i=0L,iNum-1L DO BEGIN
        a = (FLOAT(i)/FLOAT(iNum))*!PI*20.0
        fData = [cos(a),sin(a),FLOAT(i)/FLOAT(iNum)]
        oText=OBJ_NEW("IDLgrText","ABCDEFG",COLOR=[255,255,255], $
            FONT=oFont,LOCATION=fData)
        IF (opts EQ "ONGLASS") THEN BEGIN
             oText->SetProperty,ONGLASS=1
        ENDIF
        oModel->Add,oText
    ENDFOR

; run
    oWin->Draw,oView ; build caches
    IF (opts EQ "GETTEXTDIMS") THEN BEGIN
        t0 = SYSTIME(1)
        FOR i=0,iNum-1 DO BEGIN
            oText->SetProperty,CHAR_DIMENSIONS=[0,0]
            rect=oWin->GetTextDimensions(oText)
        ENDFOR
        fTime = SYSTIME(1) - t0
    ENDIF ELSE BEGIN
        t0 = SYSTIME(1)
        oWin->Draw,oView
        fTime = SYSTIME(1) - t0
    ENDELSE
; tear down
    OBJ_DESTROY,[oView,oFont]

    RETURN,fTime
END

; Light - ambient, directional, positional, spot
FUNCTION mgh_time_gr2_light,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 50000L

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["AMBIENT","DIRECTIONAL","POSITIONAL", $
            "SPOT","POSQUADATTEN"]
        RETURN,iNum
    ENDIF
; setup
    oView=OBJ_NEW('IDLgrView',VIEW=[-1,-1,2,2],COLOR=[0,0,0])
    oModel=OBJ_NEW('IDLgrModel')
    oView->add,oModel

    fData = FLTARR(3,iNum)
    iPoly = LONARR(4*iNum)
    k = 0L
    fData[*,0] = [0.,0.,0.]
    fData[*,1] = [cos(0),sin(0),0.]
    FOR i=2L,iNum-1L DO BEGIN
        a = (FLOAT(i)*3.0)*(!PI/180.0)
        fData[*,i] = [cos(a),sin(a),FLOAT(i)/FLOAT(iNum)]
        iPoly[k+0] = 3
        iPoly[k+1] = 0
        iPoly[k+2] = i-1
        iPoly[k+3] = i
        k = k + 4
    ENDFOR

    iPoly[k] = -1
    oPoly=OBJ_NEW("IDLgrPolygon",DATA=fData,COLOR=[255,0,0], $
        POLYGONS=iPoly,SHADING=1,STYLE=2)
    CASE opts OF
        "AMBIENT" : BEGIN
             oLight = OBJ_NEW('IDLgrLight',TYPE=0,LOC=[0,0,1])
             END
        "DIRECTIONAL" : BEGIN
             oLight = OBJ_NEW('IDLgrLight',TYPE=1,LOC=[0,0,1])
             END
        "POSITIONAL" : BEGIN
             oLight = OBJ_NEW('IDLgrLight',TYPE=2,LOC=[0,0,1])
             END
        "SPOT" : BEGIN
             oLight = OBJ_NEW('IDLgrLight',TYPE=3,LOC=[0,0,1])
             END
        "POSQUADATTEN" : BEGIN
             oLight = OBJ_NEW('IDLgrLight',TYPE=1,LOC=[0,0,1], $
                ATTENUATION=[1.,0.01,0.01])
             END
        "SINGLESIDED" : BEGIN
             oLight = OBJ_NEW('IDLgrLight',TYPE=1,LOC=[0,0,1])
             oModel->SetProperty,LIGHTING=1
             END
    ENDCASE
    oModel->Add,oLight
    oModel->Add,oPoly
; run
    oWin->Draw,oView   ; build caches
    t0 = SYSTIME(1)
    oWin->Draw,oView
    fTime = SYSTIME(1) - t0
; tear down
    OBJ_DESTROY,oView

    RETURN,fTime
END

; Instancing - NONE,CREATE_INSTANCE,CREATE_INSTANCE=2,DRAW_INSTANCE
FUNCTION mgh_time_gr2_instance,oWin,GET_OPTS=get_opts, $
    OPTS=opts

    iNum = 100L
    iRead = 0

    IF (ARG_PRESENT(get_opts)) THEN BEGIN
        get_opts = ["NONE","CREATE1","CREATE2","DRAW","READBACK"]
        RETURN,iNum
    ENDIF

; setup
    oView=OBJ_NEW('IDLgrView',VIEW=[0,0,400,400])
    oModel=OBJ_NEW('IDLgrModel')
    oView->Add,oModel
    oLine=OBJ_NEW('IDLgrPolyline',[[0,0],[400,400]],COLOR=[255,0,0])
    oModel->Add,oLine

    CASE opts OF
        "NONE" : BEGIN
             iCreate = 0
             iDraw = 0
                 END
        "CREATE1" : BEGIN
             iCreate = 1
             iDraw = 0
                 END
        "CREATE2" : BEGIN
             iCreate = 2
             iDraw = 0
                 END
        "DRAW" : BEGIN
             iCreate = 0
             iDraw = 1
                 END
        "READBACK" : BEGIN
             iRead = 1
                END
        ENDCASE

    IF (iRead NE 0) THEN BEGIN

        oWin->Draw,oView
        t0 = SYSTIME(1)
        FOR i=0,iNum-1 DO BEGIN
            oWin->GetProperty,IMAGE_DATA=img
        END
        fTime = SYSTIME(1) - t0

    END ELSE BEGIN
; run
        oWin->Draw,oView,/CREATE_INSTANCE
        t0 = SYSTIME(1)
        FOR i=0,iNum-1 DO oWin->Draw,oView, $
            DRAW_INSTANCE=iDraw,CREATE_INSTANCE=iCreate
        fTime = SYSTIME(1) - t0

    END

; tear down
    OBJ_DESTROY,oView

    RETURN,fTime
END

; Future additions

; Volume - single, double, quad, MIP

;
;   Routine to run ALL of the time tests
;
PRO mgh_time_gr2_all,N_LOOPS=n_loops,FILENAME=file

    FOR iWinType=0,2 DO BEGIN
      FOR iRetain=0,2,2 DO BEGIN
        FOR iColor_model=0,1 DO BEGIN
          FOR iRenderer=0,1 DO BEGIN

        mgh_time_gr2,N_LOOPS=n_loops,FILENAME=file, $
            RENDERER=iRenderer,COLOR_MODEL=iCcolor_model, $
            RETAIN=iRetain,WIN_TYPE=iWinType

          ENDFOR
        ENDFOR
      ENDFOR
    ENDFOR

END

;
;   Program for running a series of time tests on the GR2 graphics system
;
PRO mgh_time_gr2,N_LOOPS=n_loops,FILENAME=file,RENDERER=iRenderer, $
                 COLOR_MODEL=iCcolor_model,RETAIN=iRetain,WIN_TYPE=iWinType

   IF (N_ELEMENTS(n_loops) NE 1) THEN n_loops = 1

   IF (N_ELEMENTS(file) NE 1) THEN BEGIN
      iLun = -1
   ENDIF ELSE BEGIN
      GET_LUN,iLun
      OPENW,iLun,file,/APPEND
   ENDELSE

   IF (N_ELEMENTS(iRenderer) NE 1) THEN iRenderer = 0
   IF (N_ELEMENTS(iColor_model) NE 1) THEN iColor_model = 0
   IF (N_ELEMENTS(iRetain) NE 1) THEN iRetain = 0
   IF (N_ELEMENTS(iWinType) NE 1) THEN iWinType = 0

   PRINTF,iLun,SYSTIME(0)

; Get the procs to call
   sProcs = ["mgh_time_gr2_light","mgh_time_gr2_text","mgh_time_gr2_traverse",$
             "mgh_time_gr2_image","mgh_time_gr2_erase","mgh_time_gr2_line",$
             "mgh_time_gr2_polygon","mgh_time_gr2_instance"]
   pOpts = PTRARR(N_ELEMENTS(sProcs))
   iNElms = LONARR(N_ELEMENTS(sProcs))

; Collect the options
   iCount = 0
   FOR i=0,N_ELEMENTS(sProcs)-1 DO BEGIN
      iNElms[i] = CALL_FUNCTION(sProcs[i],OBJ_NEW(),GET_OPTS=sOpts)
      iCount = iCount + N_ELEMENTS(sOpts)
      pOpts[i] = PTR_NEW(sOpts,/NO_COPY)
   ENDFOR
   fElapsed = FLTARR(iCount)

; Build the destination
   CASE iWinType OF
      0: BEGIN
         wBase = WIDGET_BASE(/COLUMN, XPAD=0, YPAD=0, $
                             TITLE="GR2 Speed tests")
         wDraw = WIDGET_DRAW(wBase, XSIZE=400, YSIZE=400, $
                             RETAIN=iRetain,GRAPHICS_LEVEL=2, $
                             COLOR_MODEL=iColor_model,$
                             RENDERER=iRenderer )
         WIDGET_CONTROL, wBase, /REALIZE
         WIDGET_CONTROL, wDraw, GET_VALUE=oWin
         sDest = "WIDGET_DRAW"
      END
      1: BEGIN
         oWin = OBJ_NEW('IDLgrWindow',DIMENSION=[400,400], $
                        RETAIN=iRetain,COLOR_MODEL=iColor_model, $
                        RENDERER=iRenderer )
         sDest = "IDLgrWindow"
      END
      ELSE: BEGIN
         oWin = OBJ_NEW('IDLgrBuffer',DIMENSION=[400,400], $
                        COLOR_MODEL=iColor_model)
         sDest = "IDLgrBuffer"
      END
   ENDCASE

; Print options
   PRINTF,iLun
   PRINTF,iLun,'Options:'
   PRINTF,iLun,"DEST=",sDest,",COLOR_MODEL=",iColor_model,$
          ",RETAIN=",iRetain,",RENDERER=",iRenderer

; Print IDL version info (MGH)
   PRINTF,iLun
   PRINTF,iLun,'IDL version info:'
   mgh_struct_print, UNIT=iLun, !VERSION

; Print window object properties & device info (MGH)
   PRINTF,iLun
   PRINTF,iLun, 'Properties for object ',owin
   owin->GetProperty, ALL=mProperties
   mgh_struct_print, UNIT=iLun, mProperties
   PRINTF,iLun
   PRINTF,iLun, 'Device info for object ',owin
   owin->GetDeviceInfo, ALL=mDeviceInfo
   mgh_struct_print, UNIT=iLun, mDeviceInfo

; run all tests for one dest
   fElapsed[*] = 0.0
   FOR i=0,n_loops-1 DO BEGIN
      PRINTF,iLun
      PRINTF,iLun,"Pass ",i+1," of ",n_loops
      k = 0
      FOR p=0,N_ELEMENTS(sProcs)-1 DO BEGIN
         FOR j=0,N_ELEMENTS(*(pOpts[p]))-1 DO BEGIN
            PRINTF,iLun,"Proc:",sProcs[p],$
                   ",OPTS=",(*(pOpts[p]))[j]
            fTime = CALL_FUNCTION(sProcs[p],oWin, $
                                  OPTS=(*(pOpts[p]))[j])
            fElapsed[k] = fElapsed[k] + fTime
            k = k + 1
         ENDFOR
      ENDFOR
   ENDFOR
   fElapsed = fElapsed / FLOAT(n_loops)

   CASE iWinType OF
      0 : WIDGET_CONTROL,wBase,/DESTROY
      ELSE : OBJ_DESTROY,oWin
   ENDCASE

; Output
   k = 0
   FOR p=0,N_ELEMENTS(sProcs)-1 DO BEGIN
      FOR j=0,N_ELEMENTS(*(pOpts[p]))-1 DO BEGIN
         PRINTF,iLun,sProcs[p],",",iNElms[p],",OPTS=", $
                (*(pOpts[p]))[j],",",fElapsed[k]
         k = k + 1
      ENDFOR
   ENDFOR

; Summary output
   PRINTF,iLun
   PRINTF,iLun,"Total=",total(fElapsed), $
          "  Mean=",total(fElapsed)/iCount, $
          "  Geom. Mean=",exp(total(alog(fElapsed))/iCount)

   PRINTF,iLun
   PRINTF,iLun,SYSTIME(0)

   PTR_FREE,pOpts

   IF (iLun NE -1) THEN BEGIN
      CLOSE,iLun
      FREE_LUN,iLun
   END
END

