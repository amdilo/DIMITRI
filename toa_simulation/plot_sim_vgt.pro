;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      PLOT_SIM_VGT 
;* 
;* PURPOSE:
;*      THIS FUNCTION PLOTS THE OPERATIONAL AND SIMULATED VEGETATION RHO DATA
;*
;* CALLING SEQUENCE:
;*      RES = PLOT_SIM_VGT(SL_FOLDER,VGT_DATA,SIM_DATA)
;* 
;* INPUTS:
;*      SL_FOLDER - A STRING OF THE FULL OUTPUT PATH
;*      VGT_DATA  - A DATA ARRAY OF VGT VALUES (INCLUDING TIME,VZA,VAA,SZA,VAA)
;*      SIM_DATA  - A DATA ARRAY OF SIMULATED VALUES (INCLUDING TIME,VZA,VAA,SZA,VAA)
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS    - THE OUTPUT PROCESSING STATUS
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      20 APR 2011 - C KENT   - DIMITRI-2 V1.0
;*      30 SEP 2011 - C KENT   - UPDATED NUM NON REFS
;*
;* VALIDATION HISTORY:
;*      
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION PLOT_SIM_VGT,SL_FOLDER,VGT_DATA,SIM_DATA,VERBOSE=VERBOSE

;-----------------------
; DEFINE OUTPUT JPG AND PARAMETERS

  OUT_JPEG = SL_FOLDER+'VGT_SIM_RHO.JPG'
  NUM_NON_REF=5+12
  DIMS = SIZE(VGT_DATA)
  NB_BANDS = 4
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PLOT_SIM_VGT: OUTPUT JPEG FILE - ',OUT_JPEG

;-----------------------
; GET CURRENT DEVICE TYPE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PLOT_SIM_VGT: CHANGING TO THE ZBUFFER'
  MACHINE_WINDOW = !D.NAME
  SET_PLOT, 'Z'
  DEVICE, SET_RESOLUTION=[700,400],SET_PIXEL_DEPTH=24
  ERASE  
  DEVICE, DECOMPOSED = 0
  LOADCT, 39

;-----------------------
; DEFINE YRANGE AND XRANGE
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PLOT_SIM_VGT: DEFINING PLOT PARAMETERS'
  YRANGE = [0.0,1.0]
  XRANGE = [MIN(VGT_DATA[0,*]),MAX(VGT_DATA[0,*])]
  TEMPX = VGT_DATA[0,*]

;-----------------------
; DEFINE THE COLOURS
  
  BAND_COLOURS = [50,150,200,250]
  LNAME = STRARR(NB_BANDS)

;-----------------------
; CREATE THE PLOT

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PLOT_SIM_VGT: CREATING THE PLOT'
  PLOT,TEMPX,VGT_DATA[NUM_NON_REF,*],COLOR=0,BACKGROUND=255,/NODATA,$
    TITLE   = 'VGT VS VGT (SIMULATED)',$
    YTITLE  = 'TOA RHO (DL)',$
    XTITLE  = 'DATE'

;-----------------------
; LOOP OVER EACH BAND AND PLOT DATA 

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PLOT_SIM_VGT: STARTING LOOP OVER EACH BAND'
  FOR PBAND=0,NB_BANDS-1 DO BEGIN
  
    TBAND = CONVERT_INDEX_TO_WAVELENGTH(PBAND,'VEGETATION')
    LNAME[PBAND] = TBAND
  
    TMP = WHERE(VGT_DATA[NUM_NON_REF+PBAND,*] GT 0.0,COUNT)
    IF COUNT GT 0 THEN OPLOT,TEMPX[TMP],VGT_DATA[NUM_NON_REF+PBAND,TMP],COLOR=BAND_COLOURS[PBAND] 
 
    TMP = WHERE(SIM_DATA[*,NUM_NON_REF+PBAND] GT 0.0,COUNT)
    IF COUNT GT 0 THEN OPLOT,TEMPX[TMP],SIM_DATA[TMP,NUM_NON_REF+PBAND],COLOR=BAND_COLOURS[PBAND],PSYM=2  
    
  ENDFOR
  ;LEGEND,LNAME,COLOR=BAND_COLOURS,/RIGHT

;-----------------------
; SAVE THE PLOT

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PLOT_SIM_VGT: SAVING THE PLOT'
  TEMP = TVRD(TRUE=1)
  WRITE_JPEG,OUT_JPEG,TEMP,TRUE=1,QUALITY=100
  ERASE
  SET_PLOT, MACHINE_WINDOW
  RETURN,1

END