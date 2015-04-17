;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DHMI_SENSOR_TO_SIMULATION_REPORT    
;* 
;* PURPOSE:
;*      THIS PROGRAM MANAGE THE HMI (HUMAN/MAN INTERFACE) FOR THE STATISTICAL REPORT 
;*      PROCESS OF THE VICARIOUS SENSOR TO SIMULATION METHOD
;*
;* CALLING SEQUENCE:
;*      DHMI_SENSOR_TO_SIMULATION_REPORT      
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
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      03 MAR 2015 - NCG / MAGELLIUM - CREATION
;*
;* VALIDATION HISTORY:
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_METHOD_LIST, METHOD, SITE, SENSOR, PROC
  
  CD, CURRENT=CDIR
  DL = GET_DIMITRI_LOCATION('DL')
  INPUT_FOLDER  = GET_DIMITRI_LOCATION('OUTPUT')  
  CD,INPUT_FOLDER

  SEARCH = FILE_SEARCH(METHOD+'*'+DL+'Site_'+SITE+DL+SENSOR+DL+'Proc_*'+PROC,/TEST_DIRECTORY, COUNT=NB_COUNT)

  SEP = DL
  LIST = STRMID(SEARCH[0],0,STRPOS(SEARCH[0], SEP, 0))
  FOR NUM=1, NB_COUNT-1 DO BEGIN
    ELT = STRMID(SEARCH[NUM],0,STRPOS(SEARCH[NUM], SEP, 0))
    IDX = WHERE(STRCMP(LIST, ELT) EQ 1,NB_MATCH)
    IF NB_MATCH EQ 0 THEN LIST = [ LIST, ELT ]
  ENDFOR
  
  CD, CDIR
  
  RETURN, LIST

END

FUNCTION DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_PROC_LIST, METHOD, SITE, SENSOR
  
  CD, CURRENT=CDIR
  DL = GET_DIMITRI_LOCATION('DL')
  INPUT_FOLDER  = GET_DIMITRI_LOCATION('OUTPUT')  
  CD,INPUT_FOLDER
  
  SEARCH = FILE_SEARCH(METHOD+'*'+DL+'Site_'+SITE+DL+SENSOR+DL+'Proc_*',/TEST_DIRECTORY, COUNT=NB_COUNT)

  SEP = 'Proc_'
  LIST = (STRSPLIT(SEARCH[0], SEP, /REGEX, /EXTRACT))[1]
  FOR NUM=1, NB_COUNT-1 DO BEGIN
    ELT = (STRSPLIT(SEARCH[NUM], SEP, /REGEX, /EXTRACT))[1]
    IDX = WHERE(STRCMP(LIST, ELT) EQ 1,NB_MATCH)
    IF NB_MATCH EQ 0 THEN LIST = [ LIST, ELT ]
  ENDFOR

  CD, CDIR

  RETURN, LIST
  
END

FUNCTION DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_SENSOR_LIST, METHOD, SITE
  
  CD, CURRENT=CDIR
  DL = GET_DIMITRI_LOCATION('DL')
  INPUT_FOLDER  = GET_DIMITRI_LOCATION('OUTPUT')  
  CD,INPUT_FOLDER

  SEARCH = FILE_SEARCH(METHOD+'*'+DL+'Site_'+SITE+DL+'*',/TEST_DIRECTORY, COUNT=NB_COUNT)
  
  SEP = DL
  LIST = STRMID(SEARCH[0],STRPOS(SEARCH[0], SEP, STRLEN(SEARCH[0])-1, /REVERSE_SEARCH)+1,STRLEN(SEARCH[0]))
  FOR NUM=1, NB_COUNT-1 DO BEGIN
    ELT = STRMID(SEARCH[NUM],STRPOS(SEARCH[NUM], SEP, STRLEN(SEARCH[NUM])-1, /REVERSE_SEARCH)+1,STRLEN(SEARCH[NUM]))
    IDX = WHERE(STRCMP(LIST, ELT) EQ 1,NB_MATCH)
    IF NB_MATCH EQ 0 THEN LIST = [ LIST, ELT ]
  ENDFOR
  
  CD, CDIR

  RETURN, LIST
  
END


PRO DHMI_SENSOR_TO_SIMULATION_REPORT_EXIT,EVENT

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; DESTROY THE WIDGET

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->EXIT: DESTROYING THE WIDGET'
  WIDGET_CONTROL,EVENT.TOP,/DESTROY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SENSOR_TO_SIMULATION_REPORT_PROCESS,EVENT

  FCT_NAME = 'DHMI_SENSOR_TO_SIMULATION_REPORT_PROCESS'

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; GET THE REQUIRED DATA VALUES

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, FCT_NAME + ': RETRIEVING THE REQUIRED VARIABLES FOR INGESTION'
  
  METHOD       = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_METHOD, /COMBOBOX_GETTEXT)
  SITE_NAME    = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_SITE, /COMBOBOX_GETTEXT)
  SENSOR       = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_SENSOR, /COMBOBOX_GETTEXT)
  PROC_VERSION = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_PROC, /COMBOBOX_GETTEXT)
  YEAR         = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_YEAR, /COMBOBOX_GETTEXT)
  
  IF YEAR NE 'ALL' THEN IYEAR = YEAR ELSE ACTION='ALL'

;--------------------------
;CREATE NEW POP DISPLAY WIDGET

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, FCT_NAME + ': CREATING A POP DISPLAY'
  XSIZE = 200
  YSIZE = 60
  XLOC  = (DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.DIMS[1]/2)-(YSIZE/2)

  INFO_WD = WIDGET_BASE(COLUMN=1, XSIZE=XSIZE, YSIZE=YSIZE, TITLE=METHOD+' VIEW...',XOFFSET=XLOC,YOFFSET=YLOC)
  LBLTXT = WIDGET_LABEL(INFO_WD,VALUE=' ')
  LBLTXT = WIDGET_LABEL(INFO_WD,VALUE='Please wait while')
  LBLTXT = WIDGET_LABEL(INFO_WD,VALUE='files process in progress...')
  WIDGET_CONTROL, INFO_WD, /REALIZE
  WIDGET_CONTROL, /HOURGLASS

;--------------------------
; CALL INGEST INTERFACE

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, FCT_NAME + ': CALLING THE INGESTION INTERFACE ROUTINE'
  CASE ACTION OF
    'PROCESS':  RES = DIMITRI_INTERFACE_CALIB_REPORT(SITE_NAME,SENSOR,PROC_VERSION,METHOD,YEAR=IYEAR,VERBOSE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE)

    'ALL':      RES = DIMITRI_INTERFACE_CALIB_REPORT(SITE_NAME,SENSOR,PROC_VERSION,METHOD,/ALL,VERBOSE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE)    
  ENDCASE

;--------------------------
; CLOSE DISPLAY WIDGET AND REPORT STATUS

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, FCT_NAME + ': DESTROYING THE POP DISPLAY'
  WIDGET_CONTROL,INFO_WD,/DESTROY
  WAIT,0.5

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, FCT_NAME + ': USE OUTPUT TO IDENTIFY CLOSING MESSAGE'
  CASE RES OF
    -1: MSG = ['One or more errors encountered','Please check database file and output plots']
     0: MSG = ['No '+DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.METHOD+' products found']
     1: MSG = ['Successful']
  ENDCASE
  TMP = DIALOG_MESSAGE([DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.METHOD+' Results View : ','',MSG],/INFORMATION,/CENTER)


;--------------------------
; RETURN TO INGEST WIDGET 

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, FCT_NAME + ': RETURNING TO THE INGEST WIDGET'  
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SENSOR_TO_SIMULATION_REPORT_CHANGE,EVENT

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

  CUR_SITE_NAME    = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_SITE, /COMBOBOX_GETTEXT)
  CUR_SENSOR       = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_SENSOR, /COMBOBOX_GETTEXT)
  CUR_PROC_VERSION = WIDGET_INFO( DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_PROC, /COMBOBOX_GETTEXT)

  METHOD = DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.METHOD
  
;--------------------------
; GET ACTION TYPE, M,P,N,S,Y

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: RETRIEVING ACTION TYPE'
;  ACTION_TYPE = STRMID(ACTION,0,1)
;  CASE ACTION_TYPE OF
  CASE ACTION OF

;--------------------------
; UPDATE METHOD FIELD

  'METHOD':  BEGIN
          IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: METHOD ACTION TYPE, UPDATING FIELDS'     
        END

;--------------------------
; UPDATE PROCESSING VERSION FIELD

  'PROC':  BEGIN
          IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: PROC_VER ACTION TYPE, UPDATING FIELDS'
          
          ; UPDATE METHOD
          SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_METHOD_LIST(METHOD, CUR_SITE_NAME, CUR_SENSOR, CUR_PROC_VERSION)
          WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_METHOD, SET_VALUE=SEARCH
        END
        
;--------------------------
; UPDATE SENSOR NAME FIELD

  'SENSOR':  BEGIN
          IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: SENSOR ACTION TYPE, UPDATING FIELDS'
          
          ; UPDATE PROC
          SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_PROC_LIST(METHOD, CUR_SITE_NAME, CUR_SENSOR)
          WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_PROC, SET_VALUE=SEARCH
          CUR_PROC_VERSION = SEARCH[0]

          ; UPDATE METHOD
          SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_METHOD_LIST(METHOD, CUR_SITE_NAME, CUR_SENSOR, CUR_PROC_VERSION)
          WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_METHOD, SET_VALUE=SEARCH
        END

;--------------------------
; UPDATE SITE FIELD

  'SITE':  BEGIN
          IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: SITE ACTION TYPE, UPDATING FIELDS'

          ; UPDATE SENSOR
          SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_SENSOR_LIST(METHOD, CUR_SITE_NAME)
          WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_SENSOR, SET_VALUE=SEARCH
          CUR_SENSOR = SEARCH[0]

          ; UPDATE PROC
          SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_PROC_LIST(METHOD, CUR_SITE_NAME, CUR_SENSOR)
          WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_PROC, SET_VALUE=SEARCH
          CUR_PROC_VERSION = SEARCH[0]

          ; UPDATE METHOD
          SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_METHOD_LIST(METHOD, CUR_SITE_NAME, CUR_SENSOR, CUR_PROC_VERSION)
          WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.WIDGET_METHOD, SET_VALUE=SEARCH
        END

;--------------------------
; UPDATE YEAR FIELD

  'YEAR':  BEGIN
          IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: YEAR ACTION TYPE, UPDATING FIELDS'
        END

  ENDCASE

;--------------------------
; MAKE SURE WE'RE IN THE CORRECT 
; DIRECTORY AND RETURN TO WIDGET

  IF DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_SENSOR_TO_SIMULATION_REPORT->CHANGE: RESETTING CURRENT DIRECTORY AND RETURNING TO THE WIDGET'
  CD,DHMI_SENSOR_TO_SIMULATION_REPORT_INFO.CDIR
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SENSOR_TO_SIMULATION_REPORT,GROUP_LEADER=GROUP_LEADER,VERBOSE=VERBOSE, METHOD=METHOD

  FCT_NAME = 'DHMI_SENSOR_TO_SIMULATION_REPORT'
  
  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    IVERBOSE=1
    PRINT,FCT_NAME + ': STARTING DESERT WIDGET ROUTINE'
  ENDIF ELSE IVERBOSE=0
  

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    IVERBOSE=1
    PRINT,FCT_NAME + ': STARTING INGEST WIDGET ROUTINE'
  ENDIF ELSE IVERBOSE=0
  
  IF STRUPCASE(!VERSION.OS_FAMILY) EQ 'WINDOWS' THEN WIN_FLAG = 1 ELSE WIN_FLAG = 0

;--------------------------
; FIND MAIN DIMITRI FOLDER AND DELIMITER

  CD, CURRENT=CDIR
  DL = GET_DIMITRI_LOCATION('DL')
  INPUT_FOLDER  = GET_DIMITRI_LOCATION('OUTPUT')
  
  CD,INPUT_FOLDER
  
;--------------------------
; CHECK IIF METHOD FOLDER EXIST
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': SEARCHING FOR METHOD FOLDERS'  
  METHOD_SEARCH = FILE_SEARCH(METHOD+'*',/TEST_DIRECTORY, COUNT=NB_METHOD_FOLDER)

  IF NB_METHOD_FOLDER  EQ 0 THEN BEGIN
    MSG = FCT_NAME + ': ERROR, NO METHOD FOUND IN INPUT FOLDER, PLEASE APPLY METHOD FIRST!'
    TMP = DIALOG_MESSAGE(MSG,/ERROR,/CENTER)
    RETURN
  ENDIF  

;--------------------------
; GET LIST OF ALL (UNIQ) SITE NAMES ACROSS METHOD FOLDERS (WITHOUT 'Site_' PREFIXE)

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': SEARCHING FOR SITE FOLDERS'  
  SEARCH = FILE_SEARCH(METHOD+'*'+DL+'Site_*',/TEST_DIRECTORY, COUNT=NB_COUNT)
  
  SEP = 'Site_'
  LIST = STRMID(SEARCH[0],STRPOS(SEARCH[0], SEP, STRLEN(SEARCH[0])-1, /REVERSE_SEARCH)+5,STRLEN(SEARCH[0]))
  FOR NUM=1, NB_COUNT-1 DO BEGIN
    ELT = STRMID(SEARCH[NUM],STRPOS(SEARCH[NUM], SEP, STRLEN(SEARCH[NUM])-1, /REVERSE_SEARCH)+5,STRLEN(SEARCH[NUM]))
    IDX = WHERE(STRCMP(LIST, ELT) EQ 1,NB_MATCH)
    IF NB_MATCH EQ 0 THEN LIST = [ LIST, ELT ]
  ENDFOR
  
  ; SET THE FIRST SITE FOUND AS DEFAULT
  SITE_SEARCH = LIST
  NSITE = N_ELEMENTS(SITE_SEARCH)
  FIRST_SITE = SITE_SEARCH[0]
  
;--------------------------
; RETURN TO ORIGNAL DIRECTORY
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': RESETTING THE CURRENT DIRECTORY'
  CD, CDIR

;--------------------------
; GET AVAILABLE SENSORS IN FIRST SITE 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': SEARCHING FOR SENSORS WITHIN FIRST SITE' 
  
  SENS_SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_SENSOR_LIST(METHOD, FIRST_SITE)
  NSENS = N_ELEMENTS(SENS_SEARCH)
  ; SET THE FIRST SENSOR FOUND AS DEFAULT
  FIRST_SENSOR = SENS_SEARCH[0]

;--------------------------
; GET AVAILABLE PROC VERSION IN FIRST SITE FOR FIRST SENSOR

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': SEARCHING FOR PROCESSING VERSIONS WITHIN FIRST SENSOR'   

  PROC_SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_PROC_LIST(METHOD, FIRST_SITE, FIRST_SENSOR)
  NPROC = N_ELEMENTS(PROC_SEARCH)
  ; SET THE FIRST PROC VERSION FOUND AS DEFAULT
  FIRST_PROC = PROC_SEARCH[0]
  
;--------------------------
; GET AVAILABLE METHOD NAMES IN FIRST SITE FOR FIRST SENSOR AND FIRST PROC VERSION

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': SEARCHING FOR METHOD FOLDERS'  

  METHOD_SEARCH = DHMI_SENSOR_TO_SIMULATION_REPORT_SEARCH_METHOD_LIST(METHOD, FIRST_SITE, FIRST_SENSOR, FIRST_PROC)
  NMETHOD = N_ELEMENTS(METHOD_SEARCH)
  ; SET THE FIRST METHOD FOUND AS DEFAULT
  FIRST_METHOD = METHOD_SEARCH[0]


;--------------------------
; GET AVAILABLE YEARS
  CALDAT, SYSTIME(/UTC,/JULIAN),TMM,TDD,YEARCUR,THR,TMN,TSS
  YEAR_SEARCH = STRING(INDGEN(YEARCUR-1999)+2000,FORMAT='(I4)')
  YEAR_SEARCH = ['ALL',YEAR_SEARCH]
  NYEAR = N_ELEMENTS(YEAR_SEARCH)
  FIRST_YEAR = YEAR_SEARCH[0]

;;--------------------------
;; GET AVAILABLE AUX DATA
;IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': SEARCHING FOR AUX DATA'
;  AUX_DATA_FILE  = GET_DIMITRI_LOCATION('AUX_DATA')
;  AUX_DATA_FULL  = STRING(READ_BINARY(AUX_DATA_FILE))
;  AUX_DATA_CHANNELS  = STRSPLIT(AUX_DATA_FULL,STRING(STRING(10B)+STRING(13B)),/EXTRACT)
;  AUX_DATA_CHANNELS_NB = N_ELEMENTS(AUX_DATA_CHANNELS)         ; DATA from CONFIGURATION FILE
;  
;  IF AUX_DATA_CHANNELS_NB EQ 0 THEN BEGIN
;    MSG=FCT_NAME + ': ERROR, NO AUXDAT FOUND IN FILE AUX_DATA !'
;    TMP = DIALOG_MESSAGE(MSG,/ERROR,/CENTER)
;    RETURN
;  ENDIF

;------------------------------------ 
; GET THE DISPLAY RESOLUTION FOR WIDGET POSITIONING

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': RETRIEVING SCREEN DIMENSIONS FOR WIDGET' 
  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 340
  YSIZE = 300
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)
  CFIG_DATA = GET_DIMITRI_CONFIGURATION()

;--------------------------
; BUILD UP THE WIDGET

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': DEFINING THE WIDGET BUTTONS AND FSC FIELDS'

  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB     = WIDGET_BASE(COLUMN=1,TITLE=GET_DIMITRI_LOCATION('TOOL')+': ' + METHOD + ' RESULT VIEW ',XSIZE=XSIZE,XOFFSET=XLOC,YOFFSET=YLOC)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_FRM = WIDGET_BASE(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB, COLUMN=1,FRAME=1)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR = WIDGET_BASE(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_FRM, ROW=6,/ALIGN_LEFT)

  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='SELECTION PARAMETERS : ')
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='')
  
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='SITE NAME ', XSIZE=110)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_VSID  = WIDGET_COMBOBOX(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR, /DYNAMIC_RESIZE, VALUE=SITE_SEARCH, UVALUE='SITE', EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_CHANGE')
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='SENSOR NAME ', XSIZE=110)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_SNID  = WIDGET_COMBOBOX(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR, /DYNAMIC_RESIZE, VALUE=SENS_SEARCH, UVALUE='SENSOR', EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_CHANGE')
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='PROC VERSION ', XSIZE=110)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_PVID  = WIDGET_COMBOBOX(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR, /DYNAMIC_RESIZE, VALUE=PROC_SEARCH, UVALUE='PROC', EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_CHANGE')
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='YEAR ', XSIZE=110)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_YEAR  = WIDGET_COMBOBOX(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR, /DYNAMIC_RESIZE, VALUE=YEAR_SEARCH, UVALUE='YEAR', EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_CHANGE')
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_LBL = WIDGET_LABEL(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR,VALUE='METHOD PROCESS ', XSIZE=110)
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_METHOD= WIDGET_COMBOBOX(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR, /DYNAMIC_RESIZE, VALUE=METHOD_SEARCH, UVALUE='METHOD', EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_CHANGE')
  
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_BTM = WIDGET_BASE(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB, ROW=1,/ALIGN_RIGHT)  
  
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_BTM_BTN   = WIDGET_BUTTON(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_BTM,VALUE='PROCESS REPORT',UVALUE='PROCESS',EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_PROCESS')
  DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_BTM_BTN   = WIDGET_BUTTON(DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_BTM,VALUE='CLOSE',EVENT_PRO='DHMI_SENSOR_TO_SIMULATION_REPORT_EXIT')

;--------------------------
; STORE IMPORTANT INFORMATION IN A STRUCTURE
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': STORING ALL INFORMATION FOR WIDGET'  
  DHMI_SENSOR_TO_SIMULATION_REPORT_INFO = {                                  $
                      DIMS          : DIMS              ,$
                      CDIR          : CDIR              ,$
                      INPUT_FOLDER  : INPUT_FOLDER      ,$
                      METHOD        : METHOD            ,$
                      DL            : DL                ,$
                      MAX_COLOUR    : 40                ,$
                      WIDGET_SITE   : DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_VSID,$
                      WIDGET_SENSOR : DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_SNID,$
                      WIDGET_PROC   : DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_PVID,$
                      WIDGET_YEAR   : DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_YEAR,$
                      WIDGET_METHOD : DHMI_SENSOR_TO_SIMULATION_REPORT_TLB_PAR_METHOD,$
                      IVERBOSE      : IVERBOSE          $
                      }
;--------------------------
; REALISE THE WIDGET AND REGISTER 
; WITH THE X-MANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': REALISING THE WIDGET AND REGISTERING WITH THE XMANAGER'  
  IF N_ELEMENTS(GROUP_LEADER) GT 0 THEN $  
    WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_TLB, /REALIZE,GROUP_LEADER=GROUP_LEADER,SET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO, /NO_COPY  $
      ELSE WIDGET_CONTROL, DHMI_SENSOR_TO_SIMULATION_REPORT_TLB, /REALIZE,SET_UVALUE=DHMI_SENSOR_TO_SIMULATION_REPORT_INFO,/NO_COPY
  
  XMANAGER,'DHMI_SENSOR_TO_SIMULATION_REPORT', DHMI_SENSOR_TO_SIMULATION_REPORT_TLB
  
  
 
END 