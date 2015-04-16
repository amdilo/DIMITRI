;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DHMI_INGEST    
;* 
;* PURPOSE:
;*      THIS PROGRAM DISPLAYS A WIDGET ALLOWING INGESTION OF A USER SPECIFIED 
;*      SITE/SENSOR/PROCESSING VERSION CONFIGURATION. THE PROCESS ALL BUTTON WILL MAKE 
;*      DIMITRI SEARCH RECURSIVELY FOR ALL SENSOR L1B DATA OVER ALL SITES. PLEAS NOTE, 
;*      ONLY SITES REGISTERED WITH THE NEW SITE MODULE SHOULD BE SELECTED, AND THAT 
;*      INGESTION TIME CAN BE SIGNIFICANT DEPENDING ON PROCESSING HARDWARE AND L1B DATA.
;*
;* CALLING SEQUENCE:
;*      DHMI_INGEST      
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
;*      25 FEB 2011 - C KENT   - DIMITRI-2 V1.0
;*      21 MAR 2011 - C KENT   - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*      22 MAR 2011 - C KENT   - ADDED CONFIGURATION FILE DEPENDENCE
;*      07 JUN 2012 - C KENT   - ADDED YEAR OPTION
;*      29 JAN 2015 - NCG / MAGELLIUM - REMOVE SUNGLINT INGESTION PARAMETERS - DIMITRI V4.0
;*
;* VALIDATION HISTORY:
;*      25 FEB 2011 - C KENT   - WINDOWS 32-BIT MACHINE IDL 7.1/IDL 8.0: NOMINAL 
;*      14 APR 2011 - C KENT   - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                               COMPILATION AND OPERATION
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

PRO DHMI_INGEST_EXIT,EVENT

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INGEST_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; CLEAN UP OBJECTS

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->EXIT: DESTROYING OBJECTS'
  OBJ_DESTROY,DHMI_INGEST_INFO.CLTAB
  OBJ_DESTROY,DHMI_INGEST_INFO.PLTX
  OBJ_DESTROY,DHMI_INGEST_INFO.PLTY
  OBJ_DESTROY,DHMI_INGEST_INFO.PROCV
  OBJ_DESTROY,DHMI_INGEST_INFO.SNAME
  OBJ_DESTROY,DHMI_INGEST_INFO.VSITE
  OBJ_DESTROY,DHMI_INGEST_INFO.YEARV
;  OBJ_DESTROY,DHMI_INGEST_INFO.ALL
  
;--------------------------
; DESTROY THE WIDGET

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->EXIT: DESTROYING THE WIDGET'
  WIDGET_CONTROL,EVENT.TOP,/DESTROY

END


;**************************************************************************************
;**************************************************************************************

PRO DHMI_INGEST_PROCESS,EVENT

COMMON DHMI_DATABASE

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INGEST_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; GET THE REQUIRED DATA VALUES

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->PROCESS: RETRIEVING THE REQUIRED VARIABLES FOR INGESTION'
  DHMI_INGEST_INFO.VSITE->GETPROPERTY,VALUE=INGEST_REGION
  DHMI_INGEST_INFO.SNAME->GETPROPERTY,VALUE=INGEST_SENSOR 
  DHMI_INGEST_INFO.PROCV->GETPROPERTY,VALUE=INGEST_PROC_VER
  DHMI_INGEST_INFO.YEARV->GETPROPERTY,VALUE=INGEST_YEAR
  DHMI_INGEST_INFO.CLTAB->GETPROPERTY,VALUE=COLOUR_TABLE
  DHMI_INGEST_INFO.PLTX->GETPROPERTY,VALUE=PLOT_XSIZE
  DHMI_INGEST_INFO.PLTY->GETPROPERTY,VALUE=PLOT_YSIZE
  IF INGEST_YEAR NE 'ALL' THEN IYEAR = INGEST_YEAR
;--------------------------
;CREATE NEW POP DISPLAY WIDGET

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->PROCESS: CREATING A POP DISPLAY'
  XSIZE = 280
  YSIZE = 60
  XLOC  = (DHMI_INGEST_INFO.DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DHMI_INGEST_INFO.DIMS[1]/2)-(YSIZE/2)

  INFO_WD = WIDGET_BASE(COLUMN=1, XSIZE=XSIZE, YSIZE=YSIZE, TITLE='Please Wait...',XOFFSET=XLOC,YOFFSET=YLOC)
  LBLTXT = WIDGET_LABEL(INFO_WD,VALUE='INGEST L1B PRODUCTS',/DYNAMIC_RESIZE)
  LBLTXT = WIDGET_LABEL(INFO_WD,VALUE='Please wait while',/DYNAMIC_RESIZE)
  LBLTXT = WIDGET_LABEL(INFO_WD,VALUE='file reading in progress...',/DYNAMIC_RESIZE)
  WIDGET_CONTROL, INFO_WD, /REALIZE
  WIDGET_CONTROL, /HOURGLASS

;--------------------------
; CALL INGEST INTERFACE

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->PROCESS: CALLING THE INGESTION INTERFACE ROUTINE'
  CASE ACTION OF
    'PROCESS':  RES = DIMITRI_INTERFACE_INGEST(INGEST_REGION,INGEST_SENSOR,INGEST_PROC_VER,YEAR=IYEAR,$
                                              COLOUR_TABLE=COLOUR_TABLE,PLOT_XSIZE=PLOT_XSIZE,PLOT_YSIZE=PLOT_YSIZE,VERBOSE=DHMI_INGEST_INFO.IVERBOSE)

    'ALL':      RES = DIMITRI_INTERFACE_INGEST(INGEST_REGION,INGEST_SENSOR,INGEST_PROC_VER,/ALL,YEAR=IYEAR,$
                                              COLOUR_TABLE=COLOUR_TABLE,PLOT_XSIZE=PLOT_XSIZE,PLOT_YSIZE=PLOT_YSIZE,VERBOSE=DHMI_INGEST_INFO.IVERBOSE)
  ENDCASE

;--------------------------
; CLOSE DISPLAY WIDGET AND REPORT STATUS

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->PROCESS: DESTROYING THE POP DISPLAY'
  WIDGET_CONTROL,INFO_WD,/DESTROY
  WAIT,0.5

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->PROCESS: USE OUTPUT TO IDENTIFY CLOSING MESSAGE'
  CASE RES OF
    -1: MSG = ['One or more errors encountered','Please check database file and output plots']
     0: MSG = ['No new products found']
     1: MSG = ['Successfully ingested L1b Data']
  ENDCASE
  TMP = DIALOG_MESSAGE(['L1B Data Ingest Result: ','',MSG],/INFORMATION,/CENTER)

  ;--------------------------
  ; RELOAD THE L1 DATABASE COMMON FILE
  IF (RES EQ 1) THEN BEGIN
    DB_FILE = GET_DIMITRI_LOCATION('DATABASE')
    DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
    DHMI_DB_DATA = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)
  ENDIF
 
;--------------------------
; RETURN TO INGEST WIDGET 

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->PROCESS: RETURNING TO THE INGEST WIDGET'  
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_INGEST_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_INGEST_CHANGE,EVENT

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INGEST_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; GET ACTION TYPE, P,N,S,C,Y

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: RETRIEVING ACTION TYPE'
  ACTION_TYPE = STRMID(ACTION,0,1)
  CASE ACTION_TYPE OF

;--------------------------
; UPDATE PROCESSING VERSION FIELD

  'P':  BEGIN
          IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: PROC_VER ACTION TYPE, UPDATING FIELDS'
          CASE ACTION OF
            'PROC<':DHMI_INGEST_INFO.PIDX = DHMI_INGEST_INFO.PIDX-1
            'PROC>':DHMI_INGEST_INFO.PIDX = DHMI_INGEST_INFO.PIDX+1
          ENDCASE
     
          IF DHMI_INGEST_INFO.PIDX LT 0 THEN DHMI_INGEST_INFO.PIDX = DHMI_INGEST_INFO.NPROC-1
          IF DHMI_INGEST_INFO.PIDX EQ DHMI_INGEST_INFO.NPROC THEN DHMI_INGEST_INFO.PIDX = 0
          DHMI_INGEST_INFO.PROCV->SETPROPERTY, VALUE=STRMID(DHMI_INGEST_INFO.PROC_SEARCH[DHMI_INGEST_INFO.PIDX],5,STRLEN(DHMI_INGEST_INFO.PROC_SEARCH[DHMI_INGEST_INFO.PIDX])-5)
        END
        
;--------------------------
; UPDATE SENSOR NAME FIELD

  'N':  BEGIN
          IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: SENSOR ACTION TYPE, UPDATING FIELDS'
          CASE ACTION OF
            'NAME<':DHMI_INGEST_INFO.SIDX = DHMI_INGEST_INFO.SIDX-1
            'NAME>':DHMI_INGEST_INFO.SIDX = DHMI_INGEST_INFO.SIDX+1
          ENDCASE

          IF DHMI_INGEST_INFO.SIDX LT 0 THEN DHMI_INGEST_INFO.SIDX = DHMI_INGEST_INFO.NSENS-1
          IF DHMI_INGEST_INFO.SIDX EQ DHMI_INGEST_INFO.NSENS THEN DHMI_INGEST_INFO.SIDX = 0
          DHMI_INGEST_INFO.SNAME->SETPROPERTY, VALUE=DHMI_INGEST_INFO.SENS_SEARCH[DHMI_INGEST_INFO.SIDX]
          
          CD, DHMI_INGEST_INFO.INPUT_FOLDER+DHMI_INGEST_INFO.SITE_SEARCH[DHMI_INGEST_INFO.VIDX]+DHMI_INGEST_INFO.DL+DHMI_INGEST_INFO.SENS_SEARCH[DHMI_INGEST_INFO.SIDX]
          SEARCH = FILE_SEARCH('Proc_*',/TEST_DIRECTORY)
          DHMI_INGEST_INFO.NPROC = N_ELEMENTS(SEARCH)
          DHMI_INGEST_INFO.PROC_SEARCH[0:DHMI_INGEST_INFO.NPROC-1] = SEARCH
          DHMI_INGEST_INFO.PIDX = 0
          DHMI_INGEST_INFO.PROCV->SETPROPERTY, VALUE=STRMID(DHMI_INGEST_INFO.PROC_SEARCH[DHMI_INGEST_INFO.PIDX],5,STRLEN(DHMI_INGEST_INFO.PROC_SEARCH[DHMI_INGEST_INFO.PIDX])-5)
        END

;--------------------------
; UPDATE SITE FIELD

  'S':  BEGIN
          IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: SITE ACTION TYPE, UPDATING FIELDS'
          CASE ACTION OF
            'SITE<':DHMI_INGEST_INFO.VIDX = DHMI_INGEST_INFO.VIDX-1
            'SITE>':DHMI_INGEST_INFO.VIDX = DHMI_INGEST_INFO.VIDX+1
          ENDCASE
          IF DHMI_INGEST_INFO.VIDX LT 0 THEN DHMI_INGEST_INFO.VIDX = N_ELEMENTS(DHMI_INGEST_INFO.SITE_SEARCH)-1
          IF DHMI_INGEST_INFO.VIDX EQ N_ELEMENTS(DHMI_INGEST_INFO.SITE_SEARCH) THEN DHMI_INGEST_INFO.VIDX = 0
          DHMI_INGEST_INFO.VSITE->SETPROPERTY, VALUE=STRMID(DHMI_INGEST_INFO.SITE_SEARCH[DHMI_INGEST_INFO.VIDX],5,STRLEN(DHMI_INGEST_INFO.SITE_SEARCH[DHMI_INGEST_INFO.VIDX])-5)

          DHMI_INGEST_INFO.SIDX = 0
          CD, DHMI_INGEST_INFO.INPUT_FOLDER+DHMI_INGEST_INFO.SITE_SEARCH[DHMI_INGEST_INFO.VIDX]+DHMI_INGEST_INFO.DL
          SEARCH = FILE_SEARCH('*',/TEST_DIRECTORY)
          DHMI_INGEST_INFO.NSENS = N_ELEMENTS(SEARCH)
          DHMI_INGEST_INFO.SENS_SEARCH[0:DHMI_INGEST_INFO.NSENS-1] = SEARCH
          DHMI_INGEST_INFO.SNAME->SETPROPERTY, VALUE=DHMI_INGEST_INFO.SENS_SEARCH[DHMI_INGEST_INFO.SIDX]

          CD, DHMI_INGEST_INFO.INPUT_FOLDER+DHMI_INGEST_INFO.SITE_SEARCH[DHMI_INGEST_INFO.VIDX]+DHMI_INGEST_INFO.DL+DHMI_INGEST_INFO.SENS_SEARCH[DHMI_INGEST_INFO.SIDX]
          SEARCH = FILE_SEARCH('Proc_*',/TEST_DIRECTORY)
          DHMI_INGEST_INFO.NPROC = N_ELEMENTS(SEARCH)
          DHMI_INGEST_INFO.PROC_SEARCH[0:DHMI_INGEST_INFO.NPROC-1] = SEARCH
          DHMI_INGEST_INFO.PIDX = 0
          DHMI_INGEST_INFO.PROCV->SETPROPERTY, VALUE=STRMID(DHMI_INGEST_INFO.PROC_SEARCH[DHMI_INGEST_INFO.PIDX],5,STRLEN(DHMI_INGEST_INFO.PROC_SEARCH[DHMI_INGEST_INFO.PIDX])-5)
        END

;--------------------------
; UPDATE COLOUR TABLE INFO

  'C':  BEGIN
          IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: COLOUR TABLE ACTION TYPE, UPDATING FIELDS'
          DHMI_INGEST_INFO.CLTAB->GETPROPERTY, VALUE=CTAB
          CASE ACTION OF
            'COLR<':CTAB = CTAB-1
            'COLR>':CTAB = CTAB+1
          ENDCASE
          IF CTAB LT 0 THEN CTAB = DHMI_INGEST_INFO.MAX_COLOUR
          IF CTAB GT DHMI_INGEST_INFO.MAX_COLOUR THEN CTAB = 0
          DHMI_INGEST_INFO.CLTAB->SETPROPERTY, VALUE=CTAB
        END

;--------------------------
; UPDATE YEAR

  'Y':  BEGIN
          IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: YEAR ACTION TYPE, UPDATING FIELDS'
          IYEAR = DHMI_INGEST_INFO.YIDX
          CASE ACTION OF
            'YEAR<':IYEAR = IYEAR-1
            'YEAR>':IYEAR = IYEAR+1
          ENDCASE
          IF IYEAR LT 0 THEN IYEAR = DHMI_INGEST_INFO.NYEAR-1
          IF IYEAR GT DHMI_INGEST_INFO.NYEAR-1 THEN IYEAR = 0
          DHMI_INGEST_INFO.YEARV->SETPROPERTY, VALUE=DHMI_INGEST_INFO.YEAR_SEARCH[IYEAR]
          DHMI_INGEST_INFO.YIDX = IYEAR
        END


  ENDCASE

;--------------------------
; MAKE SURE WE'RE IN THE CORRECT 
; DIRECTORY AND RETURN TO WIDGET

  IF DHMI_INGEST_INFO.IVERBOSE EQ 1 THEN PRINT, 'DHMI_INGEST->CHANGE: RESETTING CURRENT DIRECTORY AND RETURNING TO THE WIDGET'
  CD,DHMI_INGEST_INFO.CDIR
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_INGEST_INFO, /NO_COPY

END
;**************************************************************************************
;**************************************************************************************

PRO DHMI_INGEST,GROUP_LEADER=GROUP_LEADER,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    IVERBOSE=1
    PRINT,'DHMI_INGEST: STARTING INGEST WIDGET ROUTINE'
  ENDIF ELSE IVERBOSE=0
  
  IF STRUPCASE(!VERSION.OS_FAMILY) EQ 'WINDOWS' THEN WIN_FLAG = 1 ELSE WIN_FLAG = 0

;--------------------------
; FIND MAIN DIMITRI FOLDER AND DELIMITER

  CD, CURRENT=CDIR
  DL            = GET_DIMITRI_LOCATION('DL')
  INPUT_FOLDER  = GET_DIMITRI_LOCATION('INPUT')
  
;--------------------------
; GET LIST OF ALL SITE NAMES
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: SEARCHING FOR SITE FOLDERS'
  
  RES = FILE_INFO(INPUT_FOLDER)
  IF RES.EXISTS NE 1 OR RES.DIRECTORY NE 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, INPUT_FOLDER + " FOLDER DOESN'T EXIST, CREATION"
    FILE_MKDIR, INPUT_FOLDER
  ENDIF
  CD,INPUT_FOLDER

  SITE_SEARCH = FILE_SEARCH('Site_*',/TEST_DIRECTORY)

  SENS_SEARCH = STRARR(30)
  PROC_SEARCH = STRARR(30)
  YEAR_SEARCH = STRING(INDGEN(15)+2000,FORMAT='(I4)')
  YEAR_SEARCH = ['ALL',YEAR_SEARCH]

  IF SITE_SEARCH[0] EQ '' THEN BEGIN
    MSG='DHMI_INGEST: ERROR, NO SITES FOUND IN INPUT FOLDER!'
    TMP = DIALOG_MESSAGE(MSG,/ERROR,/CENTER)
    RETURN
  ENDIF  

;--------------------------
; SET THE FIRST SITE FOUND AS DEFAULT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: GETTING INFO FOR FIRST SITE FOLDER FOUND' 
  FIRST_SITE_FOLDER = SITE_SEARCH[0]
  TEMP = STRPOS(FIRST_SITE_FOLDER,'Site_',/REVERSE_SEARCH)
  FIRST_SITE = STRMID(FIRST_SITE_FOLDER,TEMP+5,STRLEN(FIRST_SITE_FOLDER)-TEMP)

;--------------------------
; GET AVAILABLE SENSORS IN FIRST SITE 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: SEARCHING FOR SENSORS WITHIN FIRST SITE' 
  CD,INPUT_FOLDER+FIRST_SITE_FOLDER
  SEARCH = FILE_SEARCH('*',/TEST_DIRECTORY)
  NSENS = N_ELEMENTS(SEARCH)
  SENS_SEARCH[0:NSENS-1] =SEARCH
  FIRST_SENSOR = SEARCH[0]

;--------------------------
; GET AVAILABLE PROC VERS FOR 
; FIRST SENSORS IN FIRST SITE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: SEARCHING FOR PROCESSING VERSIONS WITHIN FIRST SENSOR'   
  CD, INPUT_FOLDER+FIRST_SITE_FOLDER+DL+FIRST_SENSOR
  SEARCH = FILE_SEARCH('Proc_*',/TEST_DIRECTORY)
  NPROC = N_ELEMENTS(SEARCH)
  PROC_SEARCH[0:NPROC-1] =SEARCH
  FIRST_PROC = STRMID(PROC_SEARCH[0],5,STRLEN(PROC_SEARCH[0])-5)

;--------------------------
; GET AVAILABLE YEARS

  NYEAR = N_ELEMENTS(YEAR_SEARCH)
  FIRST_YEAR = YEAR_SEARCH[0]

;--------------------------
; RETURN TO ORIGNAL DIRECTORY

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: RESETTING THE CURRENT DIRECTORY' 
  CD, CDIR

;------------------------------------ 
; GET THE DISPLAY RESOLUTION FOR WIDGET POSITIONING

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: RETRIEVEING SCREEN DIMENSIONS FOR WIDGET' 
  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 320
  YSIZE = 300
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)
  CFIG_DATA = GET_DIMITRI_CONFIGURATION()

;--------------------------
; BUILD UP THE WIDGET

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: DEFINING THE WIDGET BUTTONS AND FSC FIELDS'

  DHMI_INGEST_TLB     = WIDGET_BASE(COLUMN=1,TITLE=GET_DIMITRI_LOCATION('TOOL')+': INGEST L1B',XSIZE=XSIZE,XOFFSET=XLOC,YOFFSET=YLOC)
  DHMI_INGEST_TLB_FRM = WIDGET_BASE(DHMI_INGEST_TLB, COLUMN=1,FRAME=1)
  DHMI_INGEST_TLB_PAR = WIDGET_BASE(DHMI_INGEST_TLB_FRM, ROW=5,/ALIGN_CENTER)

  DHMI_INGEST_TLB_PAR_LBL = WIDGET_LABEL(DHMI_INGEST_TLB_PAR,VALUE='INGEST PARAMETERS :  ')
  
  DHMI_INGEST_TLB_PAR_TMP = WIDGET_LABEL(DHMI_INGEST_TLB_PAR,VALUE='')
  DHMI_INGEST_TLB_PAR_TMP = WIDGET_LABEL(DHMI_INGEST_TLB_PAR,VALUE='')
  
  IF WIN_FLAG THEN DHMI_INGEST_TLB_PAR_VSID  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='SITE NAME          : ', VALUE=FIRST_SITE, OBJECT=VSITE,/NOEDIT) $
    ELSE DHMI_INGEST_TLB_PAR_VSID  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='SITE NAME    : ', VALUE=FIRST_SITE, OBJECT=VSITE,/NOEDIT)
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='<',UVALUE= 'SITE<',EVENT_PRO='DHMI_INGEST_CHANGE')
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='>',UVALUE= 'SITE>',EVENT_PRO='DHMI_INGEST_CHANGE')  
  
  IF WIN_FLAG THEN DHMI_INGEST_TLB_PAR_SNID  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='SENSOR NAME   : ', VALUE=FIRST_SENSOR, OBJECT=SNAME,/NOEDIT) $
    ELSE DHMI_INGEST_TLB_PAR_SNID  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='SENSOR NAME  : ', VALUE=FIRST_SENSOR, OBJECT=SNAME,/NOEDIT)
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='<',UVALUE= 'NAME<',EVENT_PRO='DHMI_INGEST_CHANGE')
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='>',UVALUE= 'NAME>',EVENT_PRO='DHMI_INGEST_CHANGE')    

  IF WIN_FLAG THEN DHMI_INGEST_TLB_PAR_PVID  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='PROC VERSION  : ', VALUE=FIRST_PROC, OBJECT=PROCV,/NOEDIT) $
    ELSE DHMI_INGEST_TLB_PAR_PVID  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='PROC VERSION : ', VALUE=FIRST_PROC, OBJECT=PROCV,/NOEDIT)
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='<',UVALUE= 'PROC<',EVENT_PRO='DHMI_INGEST_CHANGE')
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='>',UVALUE= 'PROC>',EVENT_PRO='DHMI_INGEST_CHANGE')      

  IF WIN_FLAG THEN DHMI_INGEST_TLB_PAR_YEAR  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='YEAR                   : ', VALUE=FIRST_YEAR, OBJECT=YEARV,/NOEDIT) $
    ELSE DHMI_INGEST_TLB_PAR_YEAR  = FSC_FIELD(DHMI_INGEST_TLB_PAR, TITLE='YEAR :         ', VALUE=FIRST_YEAR, OBJECT=YEARV,/NOEDIT)
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='<',UVALUE= 'YEAR<',EVENT_PRO='DHMI_INGEST_CHANGE')
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_PAR,VALUE='>',UVALUE= 'YEAR>',EVENT_PRO='DHMI_INGEST_CHANGE')      
  
  DHMI_INGEST_TLB_OPT = WIDGET_BASE(DHMI_INGEST_TLB_FRM, ROW=4)

  DHMI_INGEST_TLB_OPT_LBL   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='INGEST OPTIONS -')
  DHMI_INGEST_TLB_OPT_TMP   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='')
  DHMI_INGEST_TLB_OPT_TMP   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='')  

  IF WIN_FLAG THEN DHMI_INGEST_TLB_OPT_CTID  = FSC_FIELD(DHMI_INGEST_TLB_OPT, TITLE='COLOUR TABLE    :', VALUE=FIX(CFIG_DATA.(1)[2]), OBJECT=CLTAB,/NOEDIT) $
    ELSE DHMI_INGEST_TLB_OPT_CTID  = FSC_FIELD(DHMI_INGEST_TLB_OPT, TITLE='COLOUR TABLE : ', VALUE=FIX(CFIG_DATA.(1)[2]), OBJECT=CLTAB,/NOEDIT)
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_OPT,VALUE='<',UVALUE= 'COLR<',EVENT_PRO='DHMI_INGEST_CHANGE')
  DHMI_INGEST_TLB_PAR_TMP   = WIDGET_BUTTON(DHMI_INGEST_TLB_OPT,VALUE='>',UVALUE= 'COLR>',EVENT_PRO='DHMI_INGEST_CHANGE')    
  
  IF WIN_FLAG THEN DHMI_INGEST_TLB_OPT_XSID  = FSC_FIELD(DHMI_INGEST_TLB_OPT, TITLE='PLOT X-SIZE (PIX)  :', VALUE=FIX(CFIG_DATA.(1)[0]), OBJECT=PLTX) $
    ELSE DHMI_INGEST_TLB_OPT_XSID  = FSC_FIELD(DHMI_INGEST_TLB_OPT, TITLE='PLOT X-SIZE (PIX): ', VALUE=FIX(CFIG_DATA.(1)[0]), OBJECT=PLTX)
  DHMI_INGEST_TLB_OPT_TMP   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='')
  DHMI_INGEST_TLB_OPT_TMP   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='')

  IF WIN_FLAG THEN DHMI_INGEST_TLB_OPT_YSID  = FSC_FIELD(DHMI_INGEST_TLB_OPT, TITLE='PLOT Y-SIZE (PIX)  :', VALUE=FIX(CFIG_DATA.(1)[1]), OBJECT=PLTY) $
    ELSE DHMI_INGEST_TLB_OPT_YSID  = FSC_FIELD(DHMI_INGEST_TLB_OPT, TITLE='PLOT Y-SIZE (PIX): ', VALUE=FIX(CFIG_DATA.(1)[1]), OBJECT=PLTY) 
  DHMI_INGEST_TLB_OPT_TMP   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='')
  DHMI_INGEST_TLB_OPT_TMP   = WIDGET_LABEL(DHMI_INGEST_TLB_OPT,VALUE='')    
  
  DHMI_INGEST_TLB_BTM = WIDGET_BASE(DHMI_INGEST_TLB, ROW=1,/ALIGN_RIGHT)  
  
  DHMI_INGEST_TLB_BTM_BTN   = WIDGET_BUTTON(DHMI_INGEST_TLB_BTM,VALUE='Process',UVALUE='PROCESS',EVENT_PRO='DHMI_INGEST_PROCESS')
  DHMI_INGEST_TLB_BTM_BTN   = WIDGET_BUTTON(DHMI_INGEST_TLB_BTM,VALUE='Close',EVENT_PRO='DHMI_INGEST_EXIT')

;--------------------------
; STORE IMPORTANT INFORMATION IN A STRUCTURE
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: STORING ALL INFORMATION FOR WIDGET'  
  DHMI_INGEST_INFO = {                                  $
                      DIMS          : DIMS              ,$
                      CDIR          : CDIR              ,$
                      INPUT_FOLDER  : INPUT_FOLDER      ,$
                      DL            : DL                ,$
                      VSITE         : VSITE             ,$
                      SNAME         : SNAME             ,$
                      PROCV         : PROCV             ,$
                      YEARV         : YEARV             ,$
                      YIDX          : 0                 ,$
                      VIDX          : 0                 ,$
                      SIDX          : 0                 ,$
                      PIDX          : 0                 ,$
                      PLTX          : PLTX              ,$
                      PLTY          : PLTY              ,$
                      MAX_COLOUR    : 40                ,$
                      NSENS         : NSENS             ,$
                      NPROC         : NPROC             ,$
                      NYEAR         : NYEAR             ,$
                      CLTAB         : CLTAB             ,$
                      YEAR_SEARCH   : YEAR_SEARCH       ,$
                      SITE_SEARCH   : SITE_SEARCH       ,$
                      SENS_SEARCH   : SENS_SEARCH       ,$
                      PROC_SEARCH   : PROC_SEARCH       ,$
                      IVERBOSE      : IVERBOSE          $
                      }

;--------------------------
; REALISE THE WIDGET AND REGISTER 
; WITH THE X-MANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_INGEST: REALISING THE WIDGET AND REGISTERING WITH THE XMANAGER'  
  IF N_ELEMENTS(GROUP_LEADER) GT 0 THEN $  
    WIDGET_CONTROL, DHMI_INGEST_TLB, /REALIZE,GROUP_LEADER=GROUP_LEADER,SET_UVALUE=DHMI_INGEST_INFO, /NO_COPY  $
      ELSE WIDGET_CONTROL, DHMI_INGEST_TLB, /REALIZE,SET_UVALUE=DHMI_INGEST_INFO,/NO_COPY
  
  XMANAGER,'DHMI_INGEST', DHMI_INGEST_TLB
  
END 