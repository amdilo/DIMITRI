;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DHMI_CLOUD_SCREENING    
;* 
;* PURPOSE:
;*      THIS PROGRAM GENERATES AN INTERACTIVE WIDGET DISPLAYING THE QUICKLOOKS FOR INDIVIDUAL 
;*      PRODUCTS; USERS CAN MANUALLY SELECT IF PRODUCTS ARE CLOUDY OR CLEAR. THIS INFORMATION 
;*      CAN THEN BE SAVED BACK INTO THE DIMITRI DATABASE FOR USE DURING DOUBLET MATCHING. 
;*
;*      THIS WIDGET HAS BEEN DESIGNED TO BE CALLED BY DHMI_CS_SETUP.PRO
;*
;* CALLING SEQUENCE:
;*      DHMI_CLOUD_SCREENING     
;*
;* INPUTS:
;*      DB_DATA       - THE DIMITRI DATABASE IN THE DEFINED DIMITRI STRUCTURE. AS RETURNED 
;*                      WHEN READING THE DATABASE USING THE TEMPLATRE RETURNED BY 
;*                      GET_DIMITRI_TEMPLATE 
;*      DB_IDX        - THE INDEX OF PRODUCTS TO BE DISPLAYED WITHIN THE WUDGET, AS 
;*                      RETURNED BY DHMI_CS_SETUP
;*
;* KEYWORDS:
;*      GROUP_LEADER  - ID OF THE WIDGET TO BE USED AS THE GROUP LEADER
;*      VERBOSE       - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*      12 MAR 2011 - C KENT    - DIMITRI-2 V1.0
;*      13 MAR 2011 - C KENT    - ADDED VERBOSE COMMENTS
;*      21 MAR 2011 - C KENT    - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*      06 JUL 2011 - C KENT    - ADDED DATABASE COMMON BLOCK TO DIMITRI HMI
;*
;* VALIDATION HISTORY:
;*      14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                COMPILATION AND OPERATION
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

PRO DHMI_CLOUD_SCREENING_TOOLBAR,EVENT

COMMON DHMI_DATABASE

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_CS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;>>> TEMP CODE WHICH WHEN AGREED WILL UPDATE THE NETCDF INTERNAL FILES WITH THE MANUAL CLOUD SCREENING RESULTS
        TMPSITE = DHMI_CS_INFO.DB_DATA.SITE_NAME[DHMI_CS_INFO.DB_IDX[0]]
        TMPSENS = DHMI_CS_INFO.DB_DATA.SENSOR[DHMI_CS_INFO.DB_IDX[0]] 
        TMPPRCV = DHMI_CS_INFO.DB_DATA.PROCESSING_VERSION[DHMI_CS_INFO.DB_IDX[0]] 
        IDX = WHERE(DHMI_CS_INFO.DB_DATA.SITE_NAME EQ TMPSITE AND $
                    DHMI_CS_INFO.DB_DATA.SENSOR EQ TMPSENS AND $
                    DHMI_CS_INFO.DB_DATA.PROCESSING_VERSION EQ TMPPRCV)
        VARNAME = 'cloud_fraction_manual'
        N_DIRS  = SENSOR_DIRECTION_INFO(TMPSENS)
        VARDATA = FIX(DHMI_CS_INFO.DB_DATA.MANUAL_CS[IDX])
        ;VARDATA = REBIN(VARDATA,N_DIRS[0]*N_ELEMENTS(VARDATA))

;--------------------------
; CHECK IF DATA HAS BEEN SAVED

  IF ACTION EQ 'EXIT' THEN BEGIN
  WIDGET_KILL:
  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->TOOLBAR: EXIT BUTTON PRESSED'
    IF DHMI_CS_INFO.NOT_SAVED EQ 1 THEN BEGIN
      MSG = ['Save changes?']
      RES = DIALOG_MESSAGE(MSG,/QUESTION,/CENTER)
      IF STRUPCASE(RES) EQ 'YES' THEN BEGIN
        IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->TOOLBAR: SAVING DATA'

;>>> TEMP CODE WHICH WHEN AGREED WILL UPDATE THE NETCDF INTERNAL FILES WITH THE MANUAL CLOUD SCREENING RESULTS
        IDX = UPDATE_DIMITRI_EXTRACT_TOA_NCDF(TMPSITE,TMPSENS,TMPPRCV,VARNAME,VARDATA,VERBOSE=VERBOSE)

        RES = SAVE_DIMITRI_DATABASE(DHMI_CS_INFO.DB_DATA,VERBOSE=DHMI_CS_INFO.IVERBOSE)                
        DHMI_DB_DATA = DHMI_CS_INFO.DB_DATA
      IF RES EQ -1 THEN PRINT,'DHMI_CLOUD_SCREENING->TOOLBAR: ERROR SAVING DATA, NOT SAVED'
      ENDIF
    ENDIF

;--------------------------
; DESTROY THE WIDGET
  
  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->TOOLBAR: DESTROYING THE WIDGET'    
    WIDGET_CONTROL,EVENT.TOP,/DESTROY
  ENDIF

;--------------------------
; SAVE THE CHANGES MADE

  IF ACTION EQ 'SAVE' THEN BEGIN
    IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->TOOLBAR: SAVE BUTTON PRESSED'

;>>> TEMP CODE WHICH WHEN AGREED WILL UPDATE THE NETCDF INTERNAL FILES WITH THE MANUAL CLOUD SCREENING RESULTS
        IDX = UPDATE_DIMITRI_EXTRACT_TOA_NCDF(TMPSITE,TMPSENS,TMPPRCV,VARNAME,VARDATA,VERBOSE=VERBOSE)

    RES = SAVE_DIMITRI_DATABASE(DHMI_CS_INFO.DB_DATA,VERBOSE=DHMI_CS_INFO.IVERBOSE)
    DHMI_DB_DATA = DHMI_CS_INFO.DB_DATA
    IF RES EQ -1 THEN PRINT,'DHMI_CLOUD_SCREENING->TOOLBAR: ERROR SAVING DATA, NOT SAVED'
    DHMI_CS_INFO.NOT_SAVED = 0
    WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_CS_INFO, /NO_COPY
  ENDIF

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_CLOUD_SCREENING_CHANGE_IMAGE,EVENT

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_CS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION
  
  ACTION_TYPE = STRMID(ACTION,0,1)

;--------------------------
; IF CLOUDY/CLEAR SET THEN MOVE 
; TO NEXT AVAILABLE QUICKLOOK AND 
; STORE RESULT
  
  IF ACTION_TYPE EQ 'C' THEN BEGIN
  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: USER SELECTED STATUS --> ',ACTION
    DHMI_CS_INFO.NOT_SAVED = 1
    CASE ACTION OF
      'CLEAR'   : DHMI_CS_INFO.DB_DATA.MANUAL_CS[DHMI_CS_INFO.DB_IDX[DHMI_CS_INFO.CS_IDX]] = 0
      'CLOUDY'  : DHMI_CS_INFO.DB_DATA.MANUAL_CS[DHMI_CS_INFO.DB_IDX[DHMI_CS_INFO.CS_IDX]] = 1
      'CSUSPECT': DHMI_CS_INFO.DB_DATA.MANUAL_CS[DHMI_CS_INFO.DB_IDX[DHMI_CS_INFO.CS_IDX]] = 2
    ENDCASE
    DHMI_CS_INFO.CS_IDX = DHMI_CS_INFO.CS_IDX+1
    GOTO,NEXT_QUICKLOOK
  ENDIF  

;--------------------------
; IF <</>> SET THEN MOVE 
; TO NEXT AVAILABLE QUICKLOOK
    
  IF ACTION EQ '>>' THEN DHMI_CS_INFO.CS_IDX =DHMI_CS_INFO.CS_IDX+1
  IF ACTION EQ '<<' THEN DHMI_CS_INFO.CS_IDX =DHMI_CS_INFO.CS_IDX-1
  
  NEXT_QUICKLOOK:

  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: UPDATING INDEX VALUE'
  IF DHMI_CS_INFO.CS_IDX LT 0 THEN DHMI_CS_INFO.CS_IDX = N_ELEMENTS(DHMI_CS_INFO.DB_IDX)-1
  IF DHMI_CS_INFO.CS_IDX EQ N_ELEMENTS(DHMI_CS_INFO.DB_IDX) THEN DHMI_CS_INFO.CS_IDX=0
  
  N_RETRIES=0
  IF DHMI_CS_INFO.DB_DATA.ROI_PIX_NUM[DHMI_CS_INFO.DB_IDX[DHMI_CS_INFO.CS_IDX]] LT 0 THEN BEGIN
    IJPG_RESTART:
    IF ACTION EQ '<<' THEN DHMI_CS_INFO.CS_IDX = DHMI_CS_INFO.CS_IDX-1 ELSE $
    DHMI_CS_INFO.CS_IDX = DHMI_CS_INFO.CS_IDX+1
    GOTO,NEXT_QUICKLOOK
  ENDIF

;--------------------------
; FIND NEXT QUICKLOOK

  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: FINDING THE NEXT QUICKLOOK'  
  CIDX      = DHMI_CS_INFO.DB_IDX[DHMI_CS_INFO.CS_IDX]
  DL        = DHMI_CS_INFO.DL
  QL_FOLDER = DHMI_CS_INFO.SITE_DIRC+DHMI_CS_INFO.DB_DATA.SITE_NAME[CIDX]+DL+DHMI_CS_INFO.DB_DATA.SENSOR[CIDX]+DL+$
                'Proc_'+DHMI_CS_INFO.DB_DATA.PROCESSING_VERSION[CIDX]+DL+STRTRIM(STRING(DHMI_CS_INFO.DB_DATA.YEAR[CIDX]),2)+DL

  TMP       = STRLEN(DHMI_CS_INFO.DB_DATA.L1_FILENAME[CIDX])
  JPG_FILE  = FILE_SEARCH(QL_FOLDER,STRMID(DHMI_CS_INFO.DB_DATA.L1_FILENAME[CIDX],0,TMP-4)+'*.jpg')

  IF DHMI_CS_INFO.DB_DATA.SENSOR[CIDX] EQ 'VEGETATION' THEN BEGIN
    TT = STRSPLIT(DHMI_CS_INFO.DB_DATA.L1_FILENAME[CIDX],'_',/EXTRACT,/preserve_null)
    QLFOLDER = DHMI_CS_INFO.SITE_DIRC+DHMI_CS_INFO.DB_DATA.SITE_NAME[CIDX]+DL+DHMI_CS_INFO.DB_DATA.SENSOR[CIDX]+DL+$
            'Proc_'+DHMI_CS_INFO.DB_DATA.PROCESSING_VERSION[CIDX]+DL+STRTRIM(STRING(DHMI_CS_INFO.DB_DATA.YEAR[CIDX]),2)+DL+strjoin(tt[0:n_elements(tt)-4],'_')+dl+'0001'+dl
    JPG_FILE  = FILE_SEARCH(QLFOLDER,'*QUICKLOOK.jpg')
  ENDIF

;--------------------------
; IF NOT AVAILABLE THEN MOVE TO NEXT IMAGE

  IF N_ELEMENTS(JPG_FILE) GT 1 OR JPG_FILE[0] EQ '' THEN BEGIN
    PRINT, 'DHMI_CLOUD_SCREENING->CHANGE: ERROR WHEN FINDING QUICKLOOK'
    N_RETRIES++
    IF N_RETRIES EQ N_ELEMENTS(DHMI_CS_INFO.DB_IDX) THEN BEGIN
    MSG = ['ERROR: NO QUICKLOOKS AVAILABLE','CLOSING CLOUD SCREENING']
    RES = DIALOG_MESSAGE(MSG,/WARNING)
    RETURN
    ENDIF ELSE GOTO,IJPG_RESTART
  ENDIF

;--------------------------
; READ QUICKLOOK DATA

  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: READING QUICKLOOK INFORMATION'
  READ_JPEG,JPG_FILE,QUICKLOOK_IMAGE
  DHMI_CS_INFO.QL_YSIZE = DHMI_CS_INFO.SCROLL_WD_YSIZE

;--------------------------
; RESIZE QUICKLOOK TO WIDGET DIMENSIONS

  QL_DIMS = SIZE(QUICKLOOK_IMAGE,/DIMENSIONS)
  IF QL_DIMS[1] GE DHMI_CS_INFO.QL_XSIZE THEN BEGIN ;IF THE QUICKLOOK IS BIGGER THAN THE WIDGET in x direction RESIZE IT
    SF = FLOAT(DHMI_CS_INFO.QL_XSIZE)/FLOAT(QL_DIMS[1])
    QL_DIMS[2]=QL_DIMS[2]*SF
    QL_DIMS[1]=DHMI_CS_INFO.QL_XSIZE
    QUICKLOOK_IMAGE = CONGRID(QUICKLOOK_IMAGE,3,QL_DIMS[1],QL_DIMS[2])
  ENDIF
  IF QL_DIMS[2] GT DHMI_CS_INFO.QL_YSIZE THEN DHMI_CS_INFO.QL_YSIZE = QL_DIMS[2]

  NEW_QUICKLOOK_IMAGE = MAKE_ARRAY(/BYTE,3,DHMI_CS_INFO.QL_XSIZE,DHMI_CS_INFO.QL_YSIZE,VALUE=0)
  XOFFSET = (DHMI_CS_INFO.QL_XSIZE-QL_DIMS[1])/2
  YOFFSET = (DHMI_CS_INFO.QL_YSIZE-QL_DIMS[2])/2
  NEW_QUICKLOOK_IMAGE[*,XOFFSET:XOFFSET+QL_DIMS[1]-1,YOFFSET:YOFFSET+QL_DIMS[2]-1] = QUICKLOOK_IMAGE

  TMP_DIMS = SIZE(NEW_QUICKLOOK_IMAGE,/DIMENSIONS)
  DHMI_CS_INFO.QL_YSIZE = TMP_DIMS[2]

;--------------------------
; VIEW THE QUICKLOOK IN THE DRAW WIDGET

  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: LOADING QUICKLOOK INTO DRAW WIDGET'    
  WIDGET_CONTROL,DHMI_CS_INFO.DRAW_ID, DRAW_YSIZE = DHMI_CS_INFO.QL_YSIZE, DRAW_XSIZE = DHMI_CS_INFO.QL_XSIZE
  WSET, DHMI_CS_INFO.QL_WINDOW
  TV, NEW_QUICKLOOK_IMAGE, TRUE=1

;--------------------------
; GET THE NEW INFO VALUES

  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: RETRIEVING NEW PRODUCT INFO'
  QL_FNAME      = DHMI_CS_INFO.DB_DATA.L1_FILENAME[CIDX]
  QL_REGION     = DHMI_CS_INFO.DB_DATA.SITE_NAME[CIDX]
  QL_SENSOR     = DHMI_CS_INFO.DB_DATA.SENSOR[CIDX]
  QL_PROCV      = DHMI_CS_INFO.DB_DATA.PROCESSING_VERSION[CIDX]
  QL_NUM_ROI_PX = DHMI_CS_INFO.DB_DATA.ROI_PIX_NUM[CIDX]
  QL_AUTO_CS_1    = DHMI_CS_INFO.DB_DATA.AUTO_CS_1_MEAN[CIDX]
  QL_AUTO_CS_2    = DHMI_CS_INFO.DB_DATA.AUTO_CS_2_MEAN[CIDX]
  QL_MANUAL_CS  = DHMI_CS_INFO.DB_DATA.MANUAL_CS[CIDX]
  
  IF QL_NUM_ROI_PX  EQ -1 THEN QL_NUM_ROI_PX  = 'N/A' ELSE QL_NUM_ROI_PX  = STRTRIM(STRING(QL_NUM_ROI_PX,FORMAT='(I12)'),2)
  IF QL_AUTO_CS_1   EQ -1 THEN QL_AUTO_CS_1   = 'N/A' ELSE QL_AUTO_CS_1   = STRTRIM(STRING(100.*QL_AUTO_CS_1,format='( 1(F6.2))'),2)+' %'
  IF QL_AUTO_CS_2   EQ -1 THEN QL_AUTO_CS_2   = 'N/A' ELSE QL_AUTO_CS_2   = STRTRIM(STRING(100.*QL_AUTO_CS_2,format='( 1(F6.2))'),2)+' %'
  IF QL_MANUAL_CS   LT 0 THEN QL_MANUAL_CS    = 'N/A' ELSE $
    CASE QL_MANUAL_CS OF
      0: QL_MANUAL_CS    = 'CLEAR'
      1: QL_MANUAL_CS    = 'CLOUDY'
      2: QL_MANUAL_CS    = 'SUSPECT'
    ENDCASE
   
;--------------------------
; UPDATE INFO LABELS WITH NEW INFORMATION

  IF DHMI_CS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_CLOUD_SCREENING->CHANGE: DISPLAYING NEW WIDGET INFORMATION'
  WIDGET_CONTROL,DHMI_CS_INFO.LBLF,SET_VALUE = QL_FNAME
  WIDGET_CONTROL,DHMI_CS_INFO.LBLR,SET_VALUE = QL_REGION
  WIDGET_CONTROL,DHMI_CS_INFO.LBLS,SET_VALUE = QL_SENSOR
  WIDGET_CONTROL,DHMI_CS_INFO.LBLP,SET_VALUE = QL_PROCV
  WIDGET_CONTROL,DHMI_CS_INFO.LBLN,SET_VALUE = QL_NUM_ROI_PX
  WIDGET_CONTROL,DHMI_CS_INFO.LBLA1,SET_VALUE = QL_AUTO_CS_1
  WIDGET_CONTROL,DHMI_CS_INFO.LBLA2,SET_VALUE = QL_AUTO_CS_2
  WIDGET_CONTROL,DHMI_CS_INFO.LBLM,SET_VALUE = QL_MANUAL_CS
  
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_CS_INFO, /NO_COPY
  
END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_CLOUD_SCREENING,DB_IDX,GROUP_LEADER=GROUP_LEADER,VERBOSE=VERBOSE

COMMON DHMI_DATABASE

;--------------------------
; FIND MAIN DIMITRI FOLDER AND DELIMITER

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    PRINT,'DHMI_CLOUD_SCREENING: STARTING HMI VISUALISATION ROUTINE'
    IVERBOSE=1
  ENDIF ELSE IVERBOSE=0
  IF STRUPCASE(!VERSION.OS_FAMILY) EQ 'WINDOWS' THEN WIN_FLAG = 1 ELSE WIN_FLAG = 0  
  
  DL        = GET_DIMITRI_LOCATION('DL')
  BITM_DIRC = GET_DIMITRI_LOCATION('BITMAPS')
  INPT_DIRC = GET_DIMITRI_LOCATION('INPUT')
  SITE_DIRC = INPT_DIRC+'Site_'
  DB_DATA   = DHMI_DB_DATA
  
;--------------------------
; DEFINE WIDGET_PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: DEFINING WIDGET PARAMETERS'
  DIMS  = GET_SCREEN_SIZE()
  CLOUD_WD_XSIZE = 950
  CLOUD_WD_YSIZE = 720
  CLOUD_WD_XLOC  = (DIMS[0]/2)-(CLOUD_WD_XSIZE/2)
  CLOUD_WD_YLOC  = (DIMS[1]/2)-(CLOUD_WD_YSIZE/2)

  SCROLL_WD_XSIZE = CLOUD_WD_XSIZE-90
  IF WIN_FLAG THEN SCROLL_WD_YSIZE = CLOUD_WD_YSIZE-230 ELSE SCROLL_WD_YSIZE = CLOUD_WD_YSIZE-300
  QL_XSIZE = SCROLL_WD_XSIZE
  QL_YSIZE = SCROLL_WD_YSIZE

  LGE_BTN_YSIZE = 200
  SML_BTN_YSIZE = 50
  SML_BTN_XSIZE = 100

;--------------------------
; FIND JPG OF FIRST PRODUCT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: RETRIEVEING JPG IMAGE OF FIRST PRODUCT'
  CS_IDX    = 0
  JPG_RESTART:
  IF CS_IDX EQ N_ELEMENTS(DB_IDX) THEN BEGIN
    MSG = ['ERROR: NO QUICKLOOKS AVAILABLE','CLOSING CLOUD SCREENING']
    RES = DIALOG_MESSAGE(MSG,/ERROR)
    RETURN
  ENDIF
   
  CIDX      = DB_IDX[CS_IDX]
  QLFOLDER  = SITE_DIRC+DB_DATA.SITE_NAME[CIDX]+DL+DB_DATA.SENSOR[CIDX]+DL+$
            'Proc_'+DB_DATA.PROCESSING_VERSION[CIDX]+DL+STRTRIM(STRING(DB_DATA.YEAR[CIDX]),2)+DL
  TMP       = STRLEN(DB_DATA.L1_FILENAME[CIDX])
  JPG_FILE  = FILE_SEARCH(QLFOLDER,STRMID(DB_DATA.L1_FILENAME[CIDX],0,TMP-4)+'*.jpg')

  IF DB_DATA.SENSOR[CIDX] EQ 'VEGETATION' THEN BEGIN
    TT = STRSPLIT(DB_DATA.L1_FILENAME[CIDX],'_',/EXTRACT,/preserve_null)
    QLFOLDER = SITE_DIRC+DB_DATA.SITE_NAME[CIDX]+DL+DB_DATA.SENSOR[CIDX]+DL+$
            'Proc_'+DB_DATA.PROCESSING_VERSION[CIDX]+DL+STRTRIM(STRING(DB_DATA.YEAR[CIDX]),2)+DL+strjoin(tt[0:n_elements(tt)-4],'_')+dl+'0001'+dl
    JPG_FILE  = FILE_SEARCH(QLFOLDER,'*QUICKLOOK.jpg')
  ENDIF

;--------------------------
; IF JPG NOT AVAILABLE THEN MOVE TO NEXT PRODUCT

  N_RETRIES=0
  IF N_ELEMENTS(JPG_FILE) GT 1 OR JPG_FILE[0] EQ '' THEN BEGIN
    PRINT, 'DHMI_CLOUD_SCREENING: ERROR WHEN FINDING QUICKLOOK'
    CS_IDX++
    N_RETRIES++
    IF N_RETRIES EQ N_ELEMENTS(DB_IDX) THEN BEGIN
    MSG = ['ERROR: NO QUICKLOOKS AVAILABLE','CLOSING CLOUD SCREENING']
    RES = DIALOG_MESSAGE(MSG,/ERROR)
    RETURN
    ENDIF ELSE GOTO,JPG_RESTART
  ENDIF
    
  READ_JPEG,JPG_FILE,QUICKLOOK_IMAGE

;--------------------------
; RESIZE QUICKLOOK TO WIDGET DIMENSIONS

  QL_DIMS = SIZE(QUICKLOOK_IMAGE,/DIMENSIONS)
  IF QL_DIMS[1] GE QL_XSIZE THEN BEGIN ;IF THE QUICKLOOK IS BIGGER THAN THE WIDGET IN X DIRECTION RESIZE IT
    SF = FLOAT(QL_XSIZE)/FLOAT(QL_DIMS[1])
    QL_DIMS[2]=QL_DIMS[2]*SF
    QL_DIMS[1]=QL_XSIZE
    QUICKLOOK_IMAGE = CONGRID(QUICKLOOK_IMAGE,3,QL_XSIZE,QL_DIMS[2])
  ENDIF
  IF QL_DIMS[2] GT QL_YSIZE THEN QL_YSIZE = QL_DIMS[2]

  NEW_QUICKLOOK_IMAGE = MAKE_ARRAY(/BYTE,3,QL_XSIZE,QL_YSIZE,VALUE=0)
  XOFFSET = (QL_XSIZE-QL_DIMS[1])/2
  YOFFSET = (QL_YSIZE-QL_DIMS[2])/2
  NEW_QUICKLOOK_IMAGE[*,XOFFSET:XOFFSET+QL_DIMS[1]-1,YOFFSET:YOFFSET+QL_DIMS[2]-1] = QUICKLOOK_IMAGE

  TMP_DIMS = SIZE(NEW_QUICKLOOK_IMAGE,/DIMENSIONS)
  QL_YSIZE = TMP_DIMS[2]

;--------------------------
; GET PRODUCT INFORMATION VALUES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: RETRIEVEING PRODUCT INFORMATION'
  CS_FNAME      = DB_DATA.L1_FILENAME[CIDX]
  CS_REGION     = DB_DATA.SITE_NAME[CIDX]
  CS_SENSOR     = DB_DATA.SENSOR[CIDX]
  CS_PROCV      = DB_DATA.PROCESSING_VERSION[CIDX]
  CS_NUM_ROI_PX = DB_DATA.ROI_PIX_NUM[CIDX]
  CS_AUTO_CS_1    = DB_DATA.AUTO_CS_1_MEAN[CIDX]
  CS_AUTO_CS_2    = DB_DATA.AUTO_CS_2_MEAN[CIDX]
  CS_MANUAL_CS  = DB_DATA.MANUAL_CS[CIDX]

  IF CS_NUM_ROI_PX  EQ -1 THEN CS_NUM_ROI_PX  = 'N/A'   ELSE CS_NUM_ROI_PX  = STRTRIM(STRING(CS_NUM_ROI_PX,FORMAT='(I12)'),2)
  IF CS_AUTO_CS_1   EQ -1 THEN CS_AUTO_CS_1   = 'N/A'   ELSE CS_AUTO_CS_1   = STRTRIM(STRING(100.0*CS_AUTO_CS_1,format='( 1(F6.2))'),2)+' %'
  IF CS_AUTO_CS_2   EQ -1 THEN CS_AUTO_CS_2   = 'N/A'   ELSE CS_AUTO_CS_2   = STRTRIM(STRING(100.0*CS_AUTO_CS_2,format='( 1(F6.2))'),2)+' %'
  IF CS_MANUAL_CS   LT 0  THEN QL_MANUAL_CS   = 'N/A'   ELSE $
  IF CS_MANUAL_CS   EQ 0  THEN QL_MANUAL_CS   = 'CLEAR' ELSE $
    CASE CS_MANUAL_CS OF
      0: QL_MANUAL_CS    = 'CLEAR'
      1: QL_MANUAL_CS    = 'CLOUDY'
      2: QL_MANUAL_CS    = 'SUSPECT'
    ENDCASE
 
;--------------------------
; GET SCREEN DIMENSIONS FOR 
; CENTERING WIDGET

  XSIZE = 900
  YSIZE = 690
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)
    
;--------------------------
; CREATE THE BASE WIDGET AND FILE MENU

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: DEFINING BASE WIDGET AND TOOLBAR'
  DHMI_CLOUD_TLB = WIDGET_BASE(COLUMN=1,TITLE=GET_DIMITRI_LOCATION('TOOL')+': CLOUD SCREENING' ,MBAR=FMENU, $
                                XSIZE=CLOUD_WD_XSIZE,YSIZE=CLOUD_WD_YSIZE           ,$
                                XOFFSET=CLOUD_WD_XLOC,YOFFSET=CLOUD_WD_YLOC         $
                               )

  DHMI_CLOUD_FILE_MENU_TMP    = WIDGET_BUTTON(FMENU,VALUE='||',SENSITIVE=0)
  DHMI_CLOUD_FILE_MENU        = WIDGET_BUTTON(FMENU,VALUE='File',/MENU)
  DHMI_CLOUD_FILE_MENU_TMP    = WIDGET_BUTTON(FMENU,VALUE='||',SENSITIVE=0)
  DHMI_CLOUD_FILE_MENU_SAVE   = WIDGET_BUTTON(DHMI_CLOUD_FILE_MENU,VALUE='Save',UVALUE='SAVE',EVENT_PRO='DHMI_CLOUD_SCREENING_TOOLBAR')
  DHMI_CLOUD_FILE_MENU_EXIT   = WIDGET_BUTTON(DHMI_CLOUD_FILE_MENU,VALUE='Exit',UVALUE='EXIT',EVENT_PRO='DHMI_CLOUD_SCREENING_TOOLBAR')
 
;--------------------------
; CREATE THE DRAW WIDGET AND SELECTION BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: DEFINING THE DRAW WIDGET FOR JPEGS AND ADVANCE BUTTONS
  DHMI_CLOUD_TLB_VIEW       = WIDGET_BASE(DHMI_CLOUD_TLB,ROW=1,/BASE_ALIGN_CENTER,/ALIGN_CENTER)
  DHMI_CLOUD_TLB_VIEW_BTTN  = WIDGET_BUTTON(DHMI_CLOUD_TLB_VIEW,VALUE='<<',UVALUE='<<',YSIZE=LGE_BTN_YSIZE,$
                                            EVENT_PRO='DHMI_CLOUD_SCREENING_CHANGE_IMAGE',ACCELERATOR = "Left")
  DHMI_CLOUD_TLB_VIEW_DRAW  = WIDGET_DRAW(DHMI_CLOUD_TLB_VIEW,XSIZE=QL_XSIZE,YSIZE=QL_YSIZE,$
                                            X_SCROLL_SIZE=SCROLL_WD_XSIZE,Y_SCROLL_SIZE=SCROLL_WD_YSIZE,/SCROLL,FRAME=1,RETAIN=2)
  DHMI_CLOUD_TLB_VIEW_BTTN  = WIDGET_BUTTON(DHMI_CLOUD_TLB_VIEW,VALUE='>>',UVALUE='>>',YSIZE=LGE_BTN_YSIZE,$
                                            EVENT_PRO='DHMI_CLOUD_SCREENING_CHANGE_IMAGE',ACCELERATOR = "Right")

;--------------------------
; CREATE WIDGET LABELS FOR PRODUCT INFO

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: DEFINING LABELS FOR PRODUCT INFORMATION'
  DHMI_CLOUD_TLB_DATA       = WIDGET_BASE(DHMI_CLOUD_TLB,COLUMN=2,/BASE_ALIGN_LEFT,/ALIGN_CENTER)
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=STRJOIN(MAKE_ARRAY(/STRING,25,VALUE=' ')))
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Filename:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Region:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Sensor:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Proc_Ver:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Num ROI PX:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Auto CS 1:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Auto CS 2:')
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE='Manual CS:')
  
  DHMI_CLOUD_TLB_DATA_LBL   = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=STRJOIN(MAKE_ARRAY(/STRING,130,VALUE=' ')),/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLF  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_FNAME,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLR  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_REGION,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLS  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_SENSOR,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLP  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_PROCV,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLN  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_NUM_ROI_PX,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLA1  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_AUTO_CS_1,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLA2  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=CS_AUTO_CS_2,/DYNAMIC_RESIZE)
  DHMI_CLOUD_TLB_DATA_LBLM  = WIDGET_LABEL(DHMI_CLOUD_TLB_DATA,VALUE=QL_MANUAL_CS,/DYNAMIC_RESIZE)

;--------------------------
; CREATE THE MANUAL CLOUD SCREENING BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: DEFINING THE MANUAL CLOUD SCREENING OPTION BUTTONS'
  DHMI_CLOUD_TLB_MNCS       = WIDGET_BASE(DHMI_CLOUD_TLB,ROW=1,/ALIGN_CENTER)
  DHMI_CLOUD_TLB_MNCS_BTTN  = WIDGET_BUTTON(DHMI_CLOUD_TLB_MNCS,VALUE='CLEAR',UVALUE='CLEAR',ACCELERATOR = "Ctrl+j",$
                                            YSIZE=SML_BTN_YSIZE,XSIZE=SML_BTN_XSIZE,EVENT_PRO='DHMI_CLOUD_SCREENING_CHANGE_IMAGE')
  DHMI_CLOUD_TLB_MNCS_BTTN  = WIDGET_BUTTON(DHMI_CLOUD_TLB_MNCS,VALUE='CLOUDY',UVALUE='CLOUDY',ACCELERATOR = "Ctrl+k",$
                                            YSIZE=SML_BTN_YSIZE,XSIZE=SML_BTN_XSIZE,EVENT_PRO='DHMI_CLOUD_SCREENING_CHANGE_IMAGE')
  DHMI_CLOUD_TLB_MNCS_BTTN  = WIDGET_BUTTON(DHMI_CLOUD_TLB_MNCS,VALUE='SUSPECT',UVALUE='CSUSPECT',ACCELERATOR = "Ctrl+l",$
                                            YSIZE=SML_BTN_YSIZE,XSIZE=SML_BTN_XSIZE,EVENT_PRO='DHMI_CLOUD_SCREENING_CHANGE_IMAGE')

  IF NOT KEYWORD_SET(GROUP_LEADER) THEN GROUP_LEADER = DHMI_CLOUD_TLB

;--------------------------
; LOAD THE FIRST JPG INTO THE WIDGET

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: LOADING THE FIRST JPG'
  WIDGET_CONTROL, DHMI_CLOUD_TLB, /REALIZE
  WIDGET_CONTROL, DHMI_CLOUD_TLB_VIEW_DRAW, GET_VALUE=QL_WINDOW
  WSET, QL_WINDOW
  TV, NEW_QUICKLOOK_IMAGE, TRUE=1

;--------------------------
; STORE WIDGET INFO IN STRUCTURE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: STORING WIDGET INFORMATION IN A STRUCTURE'
  DHMI_CS_INFO = {                                              $
                  SITE_DIRC       : SITE_DIRC                   ,$
                  DL              : DL                          ,$
                  IVERBOSE        : IVERBOSE                    ,$
                  GROUP_LEADER    : GROUP_LEADER                ,$
                  NOT_SAVED       : 0                           ,$
                  SCROLL_WD_YSIZE : SCROLL_WD_YSIZE             ,$
                  QL_YSIZE        : QL_YSIZE                    ,$
                  QL_XSIZE        : QL_XSIZE                    ,$
                  LBLF            : DHMI_CLOUD_TLB_DATA_LBLF    ,$
                  LBLR            : DHMI_CLOUD_TLB_DATA_LBLR    ,$
                  LBLS            : DHMI_CLOUD_TLB_DATA_LBLS    ,$
                  LBLP            : DHMI_CLOUD_TLB_DATA_LBLP    ,$
                  LBLN            : DHMI_CLOUD_TLB_DATA_LBLN    ,$
                  LBLA1           : DHMI_CLOUD_TLB_DATA_LBLA1   ,$
                  LBLA2           : DHMI_CLOUD_TLB_DATA_LBLA2   ,$
                  LBLM            : DHMI_CLOUD_TLB_DATA_LBLM    ,$
                  DB_DATA         : DB_DATA                     ,$
                  DB_IDX          : DB_IDX                      ,$
                  CS_IDX          : 0                           ,$
                  DRAW_ID         : DHMI_CLOUD_TLB_VIEW_DRAW    ,$
                  QL_WINDOW       : QL_WINDOW                   $
                  }

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_CLOUD_SCREENING: REALISING THE WIDGET AND REGISTERING WITH THE XMANAGER'
  WIDGET_CONTROL, DHMI_CLOUD_TLB, SET_UVALUE=DHMI_CS_INFO,/NO_COPY,GROUP_LEADER=GROUP_LEADER
  XMANAGER,'DHMI_CLOUD_SCREENING', DHMI_CLOUD_TLB

END
