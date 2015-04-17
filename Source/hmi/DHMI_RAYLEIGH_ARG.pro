;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DHMI_RAYLEIGH_ARG    
;* 
;* PURPOSE:
;*      THIS PROGRAM DISPLAYS A WIDGET ALLOWING SPECIFICATION OF THE REQUIRED PARAMETERS 
;*      TO LAUNCH THE RAYLEIGH VICARIOUS CALIBRATION 
;*
;* CALLING SEQUENCE:
;*      DHMI_RAYLEIGH_ARG      
;*
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      GROUP_LEADER - THE ID OF ANOTHER WIDGET TO BE USED AS THE GROUP LEADER
;*      VERBOSE      - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*      01 NOV 2013 - C MAZERAN - DIMITRI-2 V1.0
;*      10 MAR 2015 - NCG / MAGELLIUM - UPDATED WITH DIMITRI V4 SPECIFICATIONS
;*
;* VALIDATION HISTORY:
;*      01 NOV 2013 - C MAZERAN - LINUX 64-BIT IDL 8.2 NOMINAL COMPILATION AND OPERATION       
;*
;**************************************************************************************
;**************************************************************************************

PRO DHMI_RAYLEIGH_ARG_START,EVENT

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_P3_INFO, /NO_COPY

;---------------------------
; RETRIEVE ALL PARAMETERS

  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->START: RETRIEVING PARAMETERS FROM WIDGET FIELDS' 
  DHMI_P3_INFO.FSCP3_REGION->GETPROPERTY, VALUE=P3_REGION
  DHMI_P3_INFO.FSCP3_SENSOR->GETPROPERTY,  VALUE=P3_SENSOR
  DHMI_P3_INFO.FSCP3_PROC->GETPROPERTY,  VALUE=P3_PROC
  DHMI_P3_INFO.FSCP3_YEAR->GETPROPERTY,  VALUE=P3_YEAR
;  DHMI_P3_INFO.FSCP3_OFOLDER->GETPROPERTY,VALUE=P3_OFOLDER
  DHMI_P3_INFO.FSCP3_CSP->GETPROPERTY,    VALUE=P3_CSPERCENT
  DHMI_P3_INFO.FSCP3_RIP->GETPROPERTY,    VALUE=P3_ROIPERCENT
  DHMI_P3_INFO.FSCP3_WINDMAX->GETPROPERTY,    VALUE=P3_WINDMAX
  DHMI_P3_INFO.FSCP3_CHL->GETPROPERTY,    VALUE=P3_CHL
  DHMI_P3_INFO.FSCP3_TRC865->GETPROPERTY,    VALUE=P3_TRC865
  DHMI_P3_INFO.FSCP3_AER->GETPROPERTY,    VALUE=P3_AER
;  IF DHMI_P3_INFO.CURRENT_BUTTON_PIX EQ DHMI_P3_INFO.DHMI_P3_TLB_PIX1 THEN PIX = 1 ELSE PIX = 0
  IF DHMI_P3_INFO.CURRENT_BUTTON_CLIM EQ DHMI_P3_INFO.DHMI_P3_TLB_CLIM1 THEN CLIM = 1 ELSE CLIM = 0

;---------------------------
; CHECK USER VALUES

  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->START: CHECKING USER PARAMETERS'
  ERR_CLIM = 0
  ERR_CHL  = 0
  ERR_AER  = 0
  IF CLIM EQ 0 AND (P3_CHL LT 0.01 OR P3_CHL GT 30) THEN ERR_CHL=1
  IF P3_AER EQ '(NONE)' THEN ERR_AER=1
  IF ERR_CLIM OR ERR_CHL OR ERR_AER THEN BEGIN
    MSG = ['INPUT ERROR']
    IF ERR_CLIM THEN MSG = [MSG, 'NO CHL CLIMATOLOGY FILE IN AUXILIARY DATA']
    IF ERR_CHL  THEN MSG = [MSG, 'CHL MUST BE WITHIN [0.01,30]']
    IF ERR_AER  THEN MSG = [MSG, 'NO AEROSOL AVAILABLE IN AUX_DATA FOR CHOSEN SENSOR']
    TEMP = DIALOG_MESSAGE(MSG,/INFORMATION,/CENTER)
    GOTO,P3_ERR
  ENDIF


;--------------------------
; GET SCREEN DIMENSIONS FOR 
; CENTERING INFO WIDGET

  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 200
  YSIZE = 60
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->START: CREATING AN INFO WIDGET'
  INFO_WD = WIDGET_BASE(COLUMN=1, XSIZE=XSIZE, YSIZE=YSIZE, TITLE='Please Wait...',XOFFSET=XLOC,YOFFSET=YLOC)
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE=' ')
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE='Please wait,')
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE='Processing...')
  WIDGET_CONTROL, INFO_WD, /REALIZE
  WIDGET_CONTROL, /HOURGLASS

;--------------------------
; RAYLEIGH CAL

  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->START: RUNNING RAYLEIGH CALIBRATION'  

;   MSG = ['DIMITRI RAYLEIGH ARG : Not implemented at the moment']
;   TMP = DIALOG_MESSAGE(MSG,/INFORMATION,/CENTER)
  RES = RAYLEIGH_CALIBRATION(P3_REGION,P3_SENSOR,P3_PROC,P3_YEAR,P3_CSPERCENT,P3_ROIPERCENT,$
                             P3_WINDMAX,P3_CHL,P3_TRC865,P3_AER, CLIM=CLIM, VERBOSE=DHMI_P3_INFO.IVERBOSE)
  
  IF RES NE 1 THEN BEGIN
   MSG = ['RAYLEIGH_ARG:','ERROR DURING RAYLEIGH CAL']
   TMP = DIALOG_MESSAGE(MSG,/INFORMATION,/CENTER)
   GOTO,P3_ERR
  ENDIF

;--------------------------
; DESTROY INFO WIDGET AND RETURN 
; TO PROCESS_3 WIDGET

  P3_ERR:
  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->START: DESTROYING INFO WIDGET AND RETURNING'
  IF N_ELEMENTS(INFO_WD) GT 0 THEN WIDGET_CONTROL,INFO_WD,/DESTROY
  NO_SELECTION:
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_P3_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_RAYLEIGH_ARG_EXIT,EVENT

;--------------------------
; RETRIEVE WIDGET INFORMATION

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_P3_INFO, /NO_COPY
  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->EXIT: DESTROYING OBJECTS'

;--------------------------
; DESTROY OBJECTS

;  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_OFOLDER
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_REGION
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_SENSOR
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_PROC
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_YEAR
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_CSP
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_RIP
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_WINDMAX
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_CHL
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_TRC865
  OBJ_DESTROY,DHMI_P3_INFO.FSCP3_AER

;--------------------------
; DESTROY THE WIDGET

  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->EXIT: DESTROYING PROCESS 3 WIDGET'
  WIDGET_CONTROL,EVENT.TOP,/DESTROY

END

;**************************************************************************************
;**************************************************************************************

;PRO DHMI_RAYLEIGH_ARG_PIX,EVENT
;
;COMMON DHMI_DATABASE
;
;;--------------------------
;; GET EVENT AND WIDGET INFO
;
;  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE=DHMI_P3_INFO, /NO_COPY
;
;;---------------------
;; UPDATE CURRENT_BUTTON_PIX WITH SELECTION
;
;  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->PIX: UPDATING CURRENT BUTTON SELECTION'
;  DHMI_P3_INFO.CURRENT_BUTTON_PIX = EVENT.ID
;  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_P3_INFO, /NO_COPY
;
;END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_RAYLEIGH_ARG_CLIM,EVENT

COMMON DHMI_DATABASE

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE=DHMI_P3_INFO, /NO_COPY

;---------------------
; UPDATE CURRENT_BUTTON_CLIM WITH SELECTION

  IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG->CLIM: UPDATING CURRENT BUTTON SELECTION'
  DHMI_P3_INFO.CURRENT_BUTTON_CLIM = EVENT.ID
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_P3_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_RAYLEIGH_ARG_SETUP_CHANGE,EVENT

COMMON DHMI_DATABASE
  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_P3_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; GET THE ACTION TYPE

  ACTION_TYPE = STRMID(ACTION,0,1)

;--------------------------
; UPDATE SENSOR VALUE

  IF ACTION_TYPE EQ 'V' THEN BEGIN
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG_SETUP->CHANGE: UPDATING THE SITE FIELD AND INDEX'
    CASE ACTION OF
      'VSITE<':DHMI_P3_INFO.ISITE = DHMI_P3_INFO.ISITE-1
      'VSITE>':DHMI_P3_INFO.ISITE = DHMI_P3_INFO.ISITE+1
    ENDCASE
    IF DHMI_P3_INFO.ISITE LT 0 THEN DHMI_P3_INFO.ISITE = DHMI_P3_INFO.NASITE-1
    IF DHMI_P3_INFO.ISITE EQ DHMI_P3_INFO.NASITE THEN DHMI_P3_INFO.ISITE = 0

    DHMI_P3_INFO.FSCP3_REGION->SETPROPERTY, VALUE=DHMI_P3_INFO.ASITE[DHMI_P3_INFO.ISITE]

;--------------------------
; GET AVAILABLE SENSORS WITHIN REGION

    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_RAYLEIGH_ARG_SETUP->CHANGE: UPDATING THE SENSOR FIELD AND INDEX'
    CSITE=DHMI_P3_INFO.ASITE[DHMI_P3_INFO.ISITE]

    TEMP = DHMI_DB_DATA.SENSOR[WHERE(STRMATCH(DHMI_DB_DATA.SITE_NAME,CSITE))]
    TEMP = TEMP[UNIQ(TEMP,SORT(TEMP))]
    DHMI_P3_INFO.ASENS[0:N_ELEMENTS(TEMP)-1] = TEMP
    DHMI_P3_INFO.NASENS = N_ELEMENTS(TEMP)
    DHMI_P3_INFO.ISENS  = 0
    DHMI_P3_INFO.FSCP3_SENSOR->SETPROPERTY, VALUE=DHMI_P3_INFO.ASENS[DHMI_P3_INFO.ISENS]

    GOTO,UPDATE_PROC

  ENDIF

;--------------------------
; UPDATE SENSOR VALUE

  IF ACTION_TYPE EQ 'S' THEN BEGIN
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE SENSOR FIELD AND INDEX'
    CASE ACTION OF
      'SENS<':DHMI_P3_INFO.ISENS = DHMI_P3_INFO.ISENS-1
      'SENS>':DHMI_P3_INFO.ISENS = DHMI_P3_INFO.ISENS+1
    ENDCASE
    IF DHMI_P3_INFO.ISENS LT 0 THEN DHMI_P3_INFO.ISENS = DHMI_P3_INFO.NASENS-1
    IF DHMI_P3_INFO.ISENS EQ DHMI_P3_INFO.NASENS THEN DHMI_P3_INFO.ISENS = 0

    DHMI_P3_INFO.FSCP3_SENSOR->SETPROPERTY, VALUE=DHMI_P3_INFO.ASENS[DHMI_P3_INFO.ISENS]

;--------------------------
; GET AVAILABLE PROC_VERS 
; FOR SITE AND SENSOR

    UPDATE_PROC:
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE PROCESSING VERSION FIELD AND INDEX'
    CSITE = DHMI_P3_INFO.ASITE[DHMI_P3_INFO.ISITE]
    CSENS = DHMI_P3_INFO.ASENS[DHMI_P3_INFO.ISENS]

    TEMP = DHMI_DB_DATA.PROCESSING_VERSION[WHERE($
                                                 STRMATCH(DHMI_DB_DATA.SITE_NAME,CSITE) AND $
                                                 STRMATCH(DHMI_DB_DATA.SENSOR,CSENS))]
    TEMP = TEMP[UNIQ(TEMP,SORT(TEMP))]
    DHMI_P3_INFO.APROC[0:N_ELEMENTS(TEMP)-1] = TEMP
    DHMI_P3_INFO.NAPROC = N_ELEMENTS(TEMP)
    DHMI_P3_INFO.IPROC  = 0
    DHMI_P3_INFO.FSCP3_PROC->SETPROPERTY, VALUE=DHMI_P3_INFO.APROC[DHMI_P3_INFO.IPROC]

;--------------------------
; GET AVAILABLE AER 
; FOR SENSOR

    UPDATE_AER:
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE AEROSOL FIELD AND INDEX'
    CSENS = DHMI_P3_INFO.ASENS[DHMI_P3_INFO.ISENS]

    RTM_DIR = GET_DIMITRI_LOCATION('RTM',VERBOSE=DHMI_P3_INFO.IVERBOSE)
    SEARCH_DIR = FILEPATH(CSENS,ROOT_DIR=RTM_DIR)
    PATTERN='XC_'+CSENS+'_'
    SEARCH_FILTER = PATTERN+'*.txt'
    RES=FILE_SEARCH(SEARCH_DIR,SEARCH_FILTER,COUNT=NAER,/TEST_REGULAR)
    IF NAER EQ 0 THEN BEGIN
      NAER=1
      DHMI_P3_INFO.AAER[0] = '(NONE)'
    ENDIF ELSE BEGIN
      POS=STRPOS(RES,PATTERN,/REVERSE_SEARCH)
      PS =STRLEN(PATTERN)
      FOR IAER=0, NAER-1 DO DHMI_P3_INFO.AAER[IAER]=STRMID(RES[IAER],POS[IAER]+PS,STRLEN(RES[IAER])-POS[IAER]-PS-4)
    ENDELSE
    DHMI_P3_INFO.NAER = NAER
    DHMI_P3_INFO.IAER  = 0
    DHMI_P3_INFO.FSCP3_AER->SETPROPERTY, VALUE=DHMI_P3_INFO.AAER[DHMI_P3_INFO.IAER]

    GOTO,UPDATE_YEAR

  ENDIF

;--------------------------
; UPDATE PROC VALUE

  IF ACTION_TYPE EQ 'P' THEN BEGIN
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE PROCESSING VERSION FIELD AND INDEX'
    CASE ACTION OF
      'PROC<':DHMI_P3_INFO.IPROC = DHMI_P3_INFO.IPROC-1
      'PROC>':DHMI_P3_INFO.IPROC = DHMI_P3_INFO.IPROC+1
    ENDCASE
    IF DHMI_P3_INFO.IPROC LT 0 THEN DHMI_P3_INFO.IPROC = DHMI_P3_INFO.NAPROC-1
    IF DHMI_P3_INFO.IPROC EQ DHMI_P3_INFO.NAPROC THEN DHMI_P3_INFO.IPROC = 0

    DHMI_P3_INFO.FSCP3_PROC->SETPROPERTY, VALUE=DHMI_P3_INFO.APROC[DHMI_P3_INFO.IPROC]

;--------------------------
; GET AVAILABLE YEARS FOR SITE,
; SENSOR AND PROC VERSION

    UPDATE_YEAR:
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE YEAR FIELD AND INDEX'
    CSITE = DHMI_P3_INFO.ASITE[DHMI_P3_INFO.ISITE]
    CSENS = DHMI_P3_INFO.ASENS[DHMI_P3_INFO.ISENS]
    CPROC = DHMI_P3_INFO.APROC[DHMI_P3_INFO.IPROC]

    TEMP = STRTRIM(STRING(DHMI_DB_DATA.YEAR[WHERE($
                                                  STRMATCH(DHMI_DB_DATA.SITE_NAME,CSITE)       AND $
                                                  STRMATCH(DHMI_DB_DATA.SENSOR,CSENS)       AND $
                                                  STRMATCH(DHMI_DB_DATA.PROCESSING_VERSION,CPROC))]),2)
    TEMP = TEMP[UNIQ(TEMP,SORT(TEMP))]
    DHMI_P3_INFO.AYEAR[0:N_ELEMENTS(TEMP)] = [TEMP,'ALL']
    DHMI_P3_INFO.NAYEAR = N_ELEMENTS(TEMP)+1
    DHMI_P3_INFO.IYEAR=0
    DHMI_P3_INFO.FSCP3_YEAR->SETPROPERTY, VALUE=DHMI_P3_INFO.AYEAR[DHMI_P3_INFO.IYEAR]

  ENDIF

;--------------------------
; UPDATE YEAR VALUE

  IF ACTION_TYPE EQ 'Y' THEN BEGIN
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE YEAR FIELD AND INDEX'
    CASE ACTION OF
      'YEAR<':DHMI_P3_INFO.IYEAR = DHMI_P3_INFO.IYEAR-1
      'YEAR>':DHMI_P3_INFO.IYEAR = DHMI_P3_INFO.IYEAR+1
    ENDCASE
    IF DHMI_P3_INFO.IYEAR LT 0 THEN DHMI_P3_INFO.IYEAR = DHMI_P3_INFO.NAYEAR-1
    IF DHMI_P3_INFO.IYEAR EQ DHMI_P3_INFO.NAYEAR THEN DHMI_P3_INFO.IYEAR = 0

    DHMI_P3_INFO.FSCP3_YEAR->SETPROPERTY, VALUE=DHMI_P3_INFO.AYEAR[DHMI_P3_INFO.IYEAR]
  ENDIF

;--------------------------
; UPDATE AER VALUE

  IF ACTION_TYPE EQ 'A' THEN BEGIN
    IF DHMI_P3_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_PROCESSOR_3_SETUP->CHANGE: UPDATING THE AEROSOL FIELD AND INDEX'
    CASE ACTION OF
      'AER<':DHMI_P3_INFO.IAER = DHMI_P3_INFO.IAER-1
      'AER>':DHMI_P3_INFO.IAER = DHMI_P3_INFO.IAER+1
    ENDCASE
    IF DHMI_P3_INFO.IAER LT 0 THEN DHMI_P3_INFO.IAER = DHMI_P3_INFO.NAER-1
    IF DHMI_P3_INFO.IAER EQ DHMI_P3_INFO.NAER THEN DHMI_P3_INFO.IAER = 0

    DHMI_P3_INFO.FSCP3_AER->SETPROPERTY, VALUE=DHMI_P3_INFO.AAER[DHMI_P3_INFO.IAER]
  ENDIF


;--------------------------
; RETRUN TO THE WIDGET

  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_P3_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_RAYLEIGH_ARG,GROUP_LEADER=GROUP_LEADER,VERBOSE=VERBOSE

COMMON DHMI_DATABASE

;--------------------------
; FIND MAIN DIMITRI FOLDER AND DELIMITER

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    PRINT,'DHMI_RAYLEIGH_ARG: STARTING PROCESS 3 HMI ROUTINE'
    IVERBOSE=1
  ENDIF ELSE IVERBOSE=0
  IF STRUPCASE(!VERSION.OS_FAMILY) EQ 'WINDOWS' THEN WIN_FLAG = 1 ELSE WIN_FLAG = 0
 
;  DL          = GET_DIMITRI_LOCATION('DL')
;  MAIN_OUTPUT = GET_DIMITRI_LOCATION('OUTPUT')

;--------------------------
; DEFINE BASE PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: DEFINING BASE PARAMETERS'
  CFIG_DATA = GET_DIMITRI_CONFIGURATION() 

  BASE_CLOUD  = CFIG_DATA.(1)[7]
  BASE_ROI    = CFIG_DATA.(1)[8] 
  NAER_MAX    = FIX(CFIG_DATA.(1)[14])
  BASE_WIND   = CFIG_DATA.(1)[15]
  BASE_CHL    = CFIG_DATA.(1)[16]
  BASE_TRC865 = CFIG_DATA.(1)[17]
  
  OPT_BTN   = 60
  SML_BTNX  = 30
  SML_BTNY  = 10 
  SML_DEC   = 2
  SML_FSC_X = 7

;--------------------------
; GET LIST OF ALL OUTPUT FOLDERS, 
; SITES, SENSORS AND PROCESSING VERSIONS

  ASITES = DHMI_DB_DATA.SITE_NAME[UNIQ(DHMI_DB_DATA.SITE_NAME,SORT(DHMI_DB_DATA.SITE_NAME))]
  USENSS = DHMI_DB_DATA.SENSOR[UNIQ(DHMI_DB_DATA.SENSOR,SORT(DHMI_DB_DATA.SENSOR))]
  UPROCV = DHMI_DB_DATA.PROCESSING_VERSION[UNIQ(DHMI_DB_DATA.PROCESSING_VERSION,$
                                       SORT(DHMI_DB_DATA.PROCESSING_VERSION))]
  UYEARS = DHMI_DB_DATA.YEAR[UNIQ(DHMI_DB_DATA.YEAR,SORT(DHMI_DB_DATA.YEAR))]

;--------------------------  
; SELECT FIRST SITE AND GET 
; AVAILABLE SENSORS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: RETRIEVING AVAILABLE SITES AND SENSORS'
  ASENS = MAKE_ARRAY(N_ELEMENTS(USENSS),/STRING,VALUE='')
  APROC = MAKE_ARRAY(N_ELEMENTS(UPROCV),/STRING,VALUE='')
  AYEAR = MAKE_ARRAY(N_ELEMENTS(UYEARS)+1,/STRING,VALUE='')

  NASITE = N_ELEMENTS(ASITES)
  CSITE  = ASITES[0]
  TEMP   = DHMI_DB_DATA.SENSOR[WHERE(DHMI_DB_DATA.SITE_NAME EQ CSITE)]
  TEMP   = TEMP[UNIQ(TEMP,SORT(TEMP))]
  ASENS[0:N_ELEMENTS(TEMP)-1] = TEMP
  NASENS = N_ELEMENTS(TEMP)
  CSENS  = ASENS[0]

;--------------------------  
; GET AVAILABLE PROCESSING VERSIONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: RETRIEVING AVAILABLE PROCESSING VERSIONS'
  TEMP    = DHMI_DB_DATA.PROCESSING_VERSION[WHERE(DHMI_DB_DATA.SITE_NAME EQ CSITE AND $
                                                  DHMI_DB_DATA.SENSOR EQ CSENS)]
  TEMP    = TEMP[UNIQ(TEMP,SORT(TEMP))]
  APROC[0:N_ELEMENTS(TEMP)-1] = TEMP
  NAPROC  = N_ELEMENTS(TEMP)
  CPROC   = APROC[0]

;--------------------------  
; GET AVAILABLE YEARS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: RETRIEVING AVAILABLE YEARS'
  TEMP    = STRTRIM(STRING(DHMI_DB_DATA.YEAR[WHERE(DHMI_DB_DATA.SITE_NAME EQ CSITE AND $
                                              DHMI_DB_DATA.SENSOR EQ CSENS AND $
                                              DHMI_DB_DATA.PROCESSING_VERSION EQ CPROC)]),2)
  TEMP    = TEMP[UNIQ(TEMP,SORT(TEMP))]
  AYEAR[0:N_ELEMENTS(TEMP)] = [TEMP,'ALL']
  CYEAR   = AYEAR[0]
  NAYEAR  = N_ELEMENTS(TEMP)+1

;--------------------------  
; GET AVAILABLE AER
  AAER=STRARR(NAER_MAX)
  RTM_DIR = GET_DIMITRI_LOCATION('RTM',VERBOSE=VERBOSE)
  SEARCH_DIR = FILEPATH(CSENS,ROOT_DIR=RTM_DIR)
  PATTERN='XC_'+CSENS+'_'
  SEARCH_FILTER = PATTERN+'*.txt'
  RES=FILE_SEARCH(SEARCH_DIR,SEARCH_FILTER,COUNT=NAER,/TEST_REGULAR)
  IF NAER EQ 0 THEN BEGIN
     NAER=1
     AAER[0]='(NONE)'
  ENDIF ELSE BEGIN
    POS=STRPOS(RES,PATTERN,/REVERSE_SEARCH)
    PS =STRLEN(PATTERN)
    FOR IAER=0, NAER-1 DO AAER[IAER]=[STRMID(RES[IAER],POS[IAER]+PS,STRLEN(RES[IAER])-POS[IAER]-PS-4)]
  ENDELSE
  CAER = AAER[0]

;--------------------------
; DEFINE THE MAIN WIDGET 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: RETRIEVING SCREEN DIMENSIONS FOR WIDGET'
  DIMS  = GET_SCREEN_SIZE()
  IF WIN_FLAG THEN XSIZE = 425 ELSE XSIZE = 490
  YSIZE = 800
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

	TOOL = GET_DIMITRI_LOCATION('TOOL')

  DHMI_P3_TLB = WIDGET_BASE(COLUMN=1,TITLE=TOOL+': RAYLEIGH CAL SETUP',XSIZE=XSIZE,$
                                  XOFFSET=XLOC,YOFFSET=YLOC)
;--------------------------
; DEFINE WIDGET TO HOLD OUTPUTFOLDER,
; REGION, SENSOR AND CONFIGURATION

  DHMI_P3_TLB_1 = WIDGET_BASE(DHMI_P3_TLB,ROW=5, FRAME=1)
  DHMI_P3_TLB_1_LBL = WIDGET_LABEL(DHMI_P3_TLB_1,VALUE='CASE STUDY:')
  DHMI_P3_TLB_1_LBL = WIDGET_LABEL(DHMI_P3_TLB_1,VALUE='')
  DHMI_P3_TLB_1_LBL = WIDGET_LABEL(DHMI_P3_TLB_1,VALUE='')

;  IF WIN_FLAG THEN DHMI_P3_TLB_1_OFID = FSC_FIELD(DHMI_P3_TLB_1,VALUE='AUTO',TITLE='FOLDER    :',OBJECT=FSCP3_OFOLDER) $
;              ELSE DHMI_P3_TLB_1_OFID = FSC_FIELD(DHMI_P3_TLB_1,VALUE='AUTO',TITLE='FOLDER    :',OBJECT=FSCP3_OFOLDER) 
;  DHMI_BLK      = WIDGET_LABEL(DHMI_P3_TLB_1,VALUE='')
;  DHMI_BLK      = WIDGET_LABEL(DHMI_P3_TLB_1,VALUE='')

  IF WIN_FLAG THEN DHMI_P3_TLB_1_RID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CSITE,TITLE  ='REGION    :',OBJECT=FSCP3_REGION) $
              ELSE DHMI_P3_TLB_1_RID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CSITE,TITLE  ='REGION    :',OBJECT=FSCP3_REGION)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='<',UVALUE='VSITE<',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='>',UVALUE='VSITE>',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')  
  
  IF WIN_FLAG THEN DHMI_P3_TLB_1_SID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CSENS,TITLE  ='SENSOR    :',OBJECT=FSCP3_SENSOR) $
              ELSE DHMI_P3_TLB_1_SID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CSENS,TITLE  ='SENSOR    :',OBJECT=FSCP3_SENSOR)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='<',UVALUE='SENS<',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='>',UVALUE='SENS>',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')  

  IF WIN_FLAG THEN DHMI_P3_TLB_1_PID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CPROC,TITLE  ='PROCESSING:',OBJECT=FSCP3_PROC) $
              ELSE DHMI_P3_TLB_1_PID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CPROC,TITLE  ='PROCESSING:',OBJECT=FSCP3_PROC)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='<',UVALUE='PROC<',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='>',UVALUE='PROC>',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')  

  IF WIN_FLAG THEN DHMI_P3_TLB_1_YID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CYEAR,TITLE  ='YEAR      :',OBJECT=FSCP3_YEAR) $
              ELSE DHMI_P3_TLB_1_YID = FSC_FIELD(DHMI_P3_TLB_1,VALUE=CYEAR,TITLE  ='YEAR      :',OBJECT=FSCP3_YEAR)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='<',UVALUE='YEAR<',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_1,VALUE='>',UVALUE='YEAR>',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')  

       
;--------------------------
; DEFINE WIDGET TO HOLD  
; CLOUD AND ROI PARAMETERS

  DHMI_P3_TLB_2       = WIDGET_BASE(DHMI_P3_TLB,ROW=2,FRAME=1)
  DHMI_P3_TLB_2_LBL   = WIDGET_LABEL(DHMI_P3_TLB_2,VALUE='COVERAGE CRITERIA:')
  DHMI_P3_TLB_2_LBL   = WIDGET_LABEL(DHMI_P3_TLB_2,VALUE='')
  IF WIN_FLAG THEN DHMI_P3_TLB_2_CSPID = FSC_FIELD(DHMI_P3_TLB_2,VALUE=BASE_CLOUD,TITLE='CLOUD %   :',OBJECT=FSCP3_CSP,DECIMAL=SML_DEC,XSIZE=SML_FSC_X) $
              ELSE DHMI_P3_TLB_2_CSPID = FSC_FIELD(DHMI_P3_TLB_2,VALUE=BASE_CLOUD,TITLE='CLOUD %   :',OBJECT=FSCP3_CSP,DECIMAL=SML_DEC,XSIZE=SML_FSC_X)
  IF WIN_FLAG THEN DHMI_P3_TLB_2_RIPID = FSC_FIELD(DHMI_P3_TLB_2,VALUE=BASE_ROI,TITLE ='REGION %   :',OBJECT=FSCP3_RIP,DECIMAL=SML_DEC,XSIZE=SML_FSC_X) $  
              ELSE DHMI_P3_TLB_2_RIPID = FSC_FIELD(DHMI_P3_TLB_2,VALUE=BASE_ROI,TITLE ='REGION %   :',OBJECT=FSCP3_RIP,DECIMAL=SML_DEC,XSIZE=SML_FSC_X)

;--------------------------
; DEFINE WIDGET TO HOLD  
; RAYLEIGH CAL PARAMETERS

  DHMI_P3_TLB_3       = WIDGET_BASE(DHMI_P3_TLB,COLUMN=1,FRAME=1)
  DHMI_P3_TLB_3_LBL   = WIDGET_LABEL(DHMI_P3_TLB_3,VALUE='RAYLEIGH CAL PARAMETERS:', /ALIGN_LEFT)

;  DHMI_P3_TLB_PID     = WIDGET_BASE(DHMI_P3_TLB_3,ROW=1)
;  DHMI_P3_TLB_LBL     = WIDGET_LABEL(DHMI_P3_TLB_PID,VALUE                              ='PIXEL-BY-PIXEL MODE :')
;  DHMI_P3_TLB_PIX     = WIDGET_BASE(DHMI_P3_TLB_PID,ROW=1,/EXCLUSIVE)
;  DHMI_P3_TLB_PIX1    = WIDGET_BUTTON(DHMI_P3_TLB_PIX,VALUE='ON',EVENT_PRO='DHMI_RAYLEIGH_ARG_PIX')
;  DHMI_P3_TLB_PIX2    = WIDGET_BUTTON(DHMI_P3_TLB_PIX,VALUE='OFF',EVENT_PRO='DHMI_RAYLEIGH_ARG_PIX')
;  WIDGET_CONTROL, DHMI_P3_TLB_PIX1, SET_BUTTON=1
;  CURRENT_BUTTON_PIX = DHMI_P3_TLB_PIX1

  DHMI_P3_TLB_CID     = WIDGET_BASE(DHMI_P3_TLB_3,ROW=1, /BASE_ALIGN_CENTER)
  DHMI_P3_TLB_LBL     = WIDGET_LABEL(DHMI_P3_TLB_CID,VALUE                              ='CHLOROPHYLL CONC.   :')
  DHMI_P3_TLB_CLIM     = WIDGET_BASE(DHMI_P3_TLB_CID,ROW=1,/EXCLUSIVE)
  DHMI_P3_TLB_CLIM1    = WIDGET_BUTTON(DHMI_P3_TLB_CLIM,VALUE='CLIMATOLOGY',EVENT_PRO='DHMI_RAYLEIGH_ARG_CLIM')
  DHMI_P3_TLB_CLIM2    = WIDGET_BUTTON(DHMI_P3_TLB_CLIM,VALUE='FIXED (MG/M3) :',EVENT_PRO='DHMI_RAYLEIGH_ARG_CLIM')
  IF WIN_FLAG THEN DHMI_P3_TLB_3_CHID = FSC_FIELD(DHMI_P3_TLB_CID,VALUE=BASE_CHL,   TITLE ='',OBJECT=FSCP3_CHL,DECIMAL=3,XSIZE=SML_FSC_X) $  
              ELSE DHMI_P3_TLB_3_CHID = FSC_FIELD(DHMI_P3_TLB_CID,VALUE=BASE_CHL,   TITLE ='',OBJECT=FSCP3_CHL,DECIMAL=3,XSIZE=SML_FSC_X)
  WIDGET_CONTROL, DHMI_P3_TLB_CLIM2, SET_BUTTON=1
  CURRENT_BUTTON_CLIM = DHMI_P3_TLB_CLIM2


  IF WIN_FLAG THEN DHMI_P3_TLB_3_WMID = FSC_FIELD(DHMI_P3_TLB_3,VALUE=BASE_WIND,TITLE   ='MAX WIND SPEED (M/S):         ',OBJECT=FSCP3_WINDMAX,DECIMAL=SML_DEC,XSIZE=SML_FSC_X) $  
              ELSE DHMI_P3_TLB_3_WMID = FSC_FIELD(DHMI_P3_TLB_3,VALUE=BASE_WIND,TITLE   ='MAX WIND SPEED (M/S):         ',OBJECT=FSCP3_WINDMAX,DECIMAL=SML_DEC,XSIZE=SML_FSC_X)

;  IF WIN_FLAG THEN DHMI_P3_TLB_3_TRID = FSC_FIELD(DHMI_P3_TLB_3,VALUE=BASE_TRC865,TITLE ='MAX RAYLEIGH CORRECTED TOA    '+STRING([13B,10B])+'NORMALISED RADIANCE AT 865 NM:',OBJECT=FSCP3_TRC865,DECIMAL=3,XSIZE=SML_FSC_X) $  
;              ELSE DHMI_P3_TLB_3_TRID = FSC_FIELD(DHMI_P3_TLB_3,VALUE=BASE_TRC865,TITLE ='MAX RAYLEIGH CORRECTED TOA    '+STRING(10B)+'NORMALISED RADIANCE AT 865 NM:',OBJECT=FSCP3_TRC865,DECIMAL=3,XSIZE=SML_FSC_X)
  IF WIN_FLAG THEN DHMI_P3_TLB_3_TRID = FSC_FIELD(DHMI_P3_TLB_3,VALUE=BASE_TRC865,TITLE ='MAX RAYLEIGH CORRECTED TOA (NORMALISED RADIANCE AT 865 NM):',OBJECT=FSCP3_TRC865,DECIMAL=3,XSIZE=SML_FSC_X) $  
              ELSE DHMI_P3_TLB_3_TRID = FSC_FIELD(DHMI_P3_TLB_3,VALUE=BASE_TRC865,TITLE ='MAX RAYLEIGH CORRECTED TOA (NORMALISED RADIANCE AT 865 NM):',OBJECT=FSCP3_TRC865,DECIMAL=3,XSIZE=SML_FSC_X)
  DHMI_P3_TLB_AER     = WIDGET_BASE(DHMI_P3_TLB_3,ROW=1)
  IF WIN_FLAG THEN DHMI_P3_TLB_3_AEID = FSC_FIELD(DHMI_P3_TLB_AER,VALUE=CAER,TITLE      ='AEROSOL MODEL:                ',OBJECT=FSCP3_AER) $
              ELSE DHMI_P3_TLB_3_AEID = FSC_FIELD(DHMI_P3_TLB_AER,VALUE=CAER,TITLE      ='AEROSOL MODEL:                ',OBJECT=FSCP3_AER)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_AER,VALUE='<',UVALUE='AER<',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_P3_TLB_AER,VALUE='>',UVALUE='AER>',EVENT_PRO='DHMI_RAYLEIGH_ARG_SETUP_CHANGE')  

;--------------------------
; DEFINE WIDGET TO HOLD START  
; AND EXIT BUTTONS
  
  DHMI_P3_TLB_6       = WIDGET_BASE(DHMI_P3_TLB,ROW=1,/ALIGN_RIGHT)
  DHMI_P3_TLB_6_BTN   = WIDGET_BUTTON(DHMI_P3_TLB_6,VALUE='Start',XSIZE=OPT_BTN,EVENT_PRO='DHMI_RAYLEIGH_ARG_START')
  DHMI_P3_TLB_6_BTN   = WIDGET_BUTTON(DHMI_P3_TLB_6,VALUE='Exit',XSIZE=OPT_BTN, EVENT_PRO='DHMI_RAYLEIGH_ARG_EXIT')

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: COMPLETED DEFINING WIDGET'
  IF NOT KEYWORD_SET(GROUP_LEADER) THEN GROUP_LEADER = DHMI_P3_TLB
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: STORING WIDGET INFO INTO STRUCTURE'
  DHMI_P3_INFO = {$
                  IVERBOSE              : IVERBOSE,$
                  GROUP_LEADER          : GROUP_LEADER,$
;                  MAIN_OUTPUT           : MAIN_OUTPUT,$
;                  FSCP3_OFOLDER         : FSCP3_OFOLDER,$
                  FSCP3_REGION          : FSCP3_REGION,$
                  ASITE                 : ASITES,$
                  NASITE                : NASITE,$
                  ISITE                 : 0,$
                  FSCP3_SENSOR          : FSCP3_SENSOR,$
                  ASENS                 : ASENS,$
                  NASENS                : NASENS,$
                  ISENS                 : 0,$
                  FSCP3_PROC            : FSCP3_PROC,$
                  APROC                 : APROC,$
                  NAPROC                : NAPROC,$
                  IPROC                 : 0,$
                  FSCP3_YEAR            : FSCP3_YEAR,$
                  AYEAR                 : AYEAR,$
                  NAYEAR                : NAYEAR,$
                  IYEAR                 : 0,$
                  FSCP3_CSP             : FSCP3_CSP,$
                  FSCP3_RIP             : FSCP3_RIP,$
;                  CURRENT_BUTTON_PIX    : CURRENT_BUTTON_PIX,$
;                  DHMI_P3_TLB_PIX1      : DHMI_P3_TLB_PIX1,$
;                  DHMI_P3_TLB_PIX2      : DHMI_P3_TLB_PIX2,$ 
                  FSCP3_AER             : FSCP3_AER,$
                  AAER                  : AAER,$
                  NAER                  : NAER,$
                  IAER                  : 0,$
                  FSCP3_WINDMAX         : FSCP3_WINDMAX,$
                  CURRENT_BUTTON_CLIM   : CURRENT_BUTTON_CLIM,$
                  DHMI_P3_TLB_CLIM1     : DHMI_P3_TLB_CLIM1,$
                  DHMI_P3_TLB_CLIM2     : DHMI_P3_TLB_CLIM2,$ 
                  FSCP3_CHL             : FSCP3_CHL,$
                  FSCP3_TRC865          : FSCP3_TRC865 $
                  }
                  
;--------------------------
; REALISE THE WIDGET AND REGISTER WITH THE XMANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_RAYLEIGH_ARG: REALISING THE WIDGET AND REGISTERING WITH THE XMANAGER'
  WIDGET_CONTROL,DHMI_P3_TLB,/REALIZE,SET_UVALUE=DHMI_P3_INFO,/NO_COPY,GROUP_LEADER=GROUP_LEADER
  XMANAGER,'DHMI_RAYLEIGH_ARG',DHMI_P3_TLB

END
