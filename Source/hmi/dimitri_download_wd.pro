;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_DOWNLOAD_WD    
;* 
;* PURPOSE:
;*      THIS PROGRAM DISPLAYS A WIDGET ALLOWING AUTOMATED CALLING OF A WEB BROWSER 
;*      TO THE SENSOR DOWNLOAD AREAS FOR DIMITRI. tHE PROGRAM USES SMALLER ROUTINES 
;*      FOR THE BUTTON AND OPTION ACTIONS 
;*
;* CALLING SEQUENCE:
;*      DIMITRI_DOWNLOAD_WD      
;*
;* INPUTS:
;*
;* KEYWORDS:
;*      GROUP_LEADER - THE ID OF ANOTHER WIDGET TO BE USED AS THE GROUP LEADER
;*      VERBOSE - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      17 FEB 2011 - C KENT    - DIMITRI-2 V1.0
;*      21 FEB 2011 - C KENT    - UPDATED CODE HEADER INFORMATION
;*      25 FEB 2010 - C KENT    - ADDED GROUP_LEADER KEYWORD
;*      21 MAR 2011 - C KENT    - UPDATED FIREFOX CALLING ON LINUX
;*      21 JAN 2015 - B ALHAMMOUD    - UPDATED TO DIMITRI-3.1.1
;*      16 FEB 2015 - B ALHAMMOUD    - ADDED DIMITRI_VERSION AS VARIABLE
;*
;* VALIDATION HISTORY:
;*      17 FEB 2011 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1/IDL 8.0: NOMINAL 
;*      18 FEB 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: NOMINAL BEHAVIOUR
;*      14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************

PRO DOWNLOAD_MOD_SITE,EVENT

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DL_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

  IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->SITE: STARTING SITE BUTTON ACTION'

;----------------------------
; IF NO ACTION (E.G. DUE 
; TO RESIZING THEN DO NOTHING

  IF N_ELEMENTS(ACTION) EQ 0 THEN GOTO,NO_DOWNLOAD

;----------------------------
; FIND WHICH BUTTON HAS 
; BEEN PRESSED 
  
  RES = WHERE(DL_INFO.SENSORS EQ ACTION,COUNT)
  IF COUNT EQ 0 THEN BEGIN
    PRINT, 'DIMITRI_DOWNLOAD_WD->SITE: FATAL INTERNAL ERROR'
    GOTO,NO_DOWNLOAD
  ENDIF

;----------------------------
; SAVE THE CURRENT DIRECTORY 
; AND CHANGE TO OS DEPENDENT FOLDER

  IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->SITE: STORING CURRENT DIRECTORY AND CHANGIN TO LOCATION OF BROWSER'
  CD,CURRENT=CURRENT_DIR
  CD,DL_INFO.BROWSE_STR
  COMMAND = DL_INFO.BROWSER+' '+DL_INFO.S_WEBS[RES]

;----------------------------
; SPAWN THE COMMAND TO OPEN 
; THE WEB BROWSER

  IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->SITE: SPAWNING THE COMMAND'
  CASE STRUPCASE(!VERSION.OS_FAMILY) OF 
    'WINDOWS' : SPAWN,COMMAND,/NOWAIT,/NOSHELL
    'UNIX'    : SPAWN,COMMAND+'&'
  ENDCASE

;----------------------------
; RESET TO THE CURRENT DIRECTORY 
; AND RETURN TO THE WIDGET

  IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->SITE: RESETTING THE DIRECTORY AND RELOADING THE WIDGET'
  CD,CURRENT_DIR
  NO_DOWNLOAD:
  WIDGET_CONTROL,EVENT.TOP,SET_UVALUE=DL_INFO,/NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DOWNLOAD_MOD_OPTION,EVENT

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DL_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

  IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->OPTION: STARTING OPTION WIDGET'

;----------------------------
; IF NO ACTION (E.G. DUE 
; TO RESIZING THEN DO NOTHING

  IF N_ELEMENTS(ACTION) EQ 0 THEN GOTO,NO_OPTION

;----------------------------
; DEPENDING ON ACTION SELECTED, 
; EITHER CLOSE THE WIDGET OR 
; LOAD THE USER MANUAL

  CASE ACTION OF
    'CLOSE':BEGIN
    IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->OPTION: CLOSING THE DOWNLOAD WIDGET'
              WIDGET_CONTROL, EVENT.TOP, /DESTROY
              RETURN
            END
  
    'HELP': BEGIN
    IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->SITE: LOADING THE USER MANUAL'
            ;SPAWN THE HELP FILE (PDF IF WINDOWS, EMACS/GEDIT TXT FILE)
            ;
            END
  ENDCASE

  IF DL_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_DOWNLOAD_WD->SITE: RELOADING THE WIDGET'
  NO_OPTION:
  WIDGET_CONTROL, EVENT.TOP,SET_UVALUE=DL_INFO,/NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DIMITRI_DOWNLOAD_WD,VERBOSE=VERBOSE,GROUP_LEADER=GROUP_LEADER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: STARTING MODULE'

;----------------------------
; SET INITIAL PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN IVERBOSE = 1 ELSE IVERBOSE = 0
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: DEFINING WEBSITE PARAMETERS'
  MATCH   = 0
  DRIVES  = ['A','B','C','D']
  SENSORS = ['CAL/VAL PORTAL','AATSR','ATSR2','MERIS','MODISA','PARASOL','VEGETATION']
  S_WEBS  = [$
          'http://calvalportal.ceos.org/cvp/web/guest/home',$
          'http://ats-merci-uk.eo.esa.int:8080/merci/welcome.do',$
          'http://ats-merci-uk.eo.esa.int:8080/merci/welcome.do',$
          'http://merci-srv.eo.esa.int/merci/welcome.do',$
          'http://ladsweb.nascom.nasa.gov/data/search.html',$
          'http://polder.cnes.fr/',$
          'http://suvweb.vgt.vito.be/suv/index.jsp'$
          ] 

  S_TEXT  = [$
          ': The CEOS CAL/VAL Portal',$
          ': The AATSR MERCI Catalogue',$
          ': The ATSR2 MERCI Catalogue',$
          ': The MERIS MERCI Catalogue',$
          ': The LAADS L1 Data Ordering Webpage',$
          ': The PARASOL Product Distribution Centre',$
          ': The VEGETATION User Services Website'$
          ] 

;----------------------------
; FIND WEB BROWSERS DEPENDING ON OS TYPE,
; WINDOWS--> IEXPLORE
; LINUX-->FIREFOX
; MAC-->SAFARI

  CASE STRUPCASE(!VERSION.OS_FAMILY) OF 
  'WINDOWS':begin
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: WINDOWS USER, FINDING IEXPLORE'
              TT = 0
              WHILE MATCH EQ 0 DO BEGIN
                BROWSE_STR = DRIVES[TT]+':\Program Files\Internet Explorer\'      
                BROWSER = 'iexplore.exe'
                RES = FILE_INFO(BROWSE_STR)
                IF RES.DIRECTORY EQ 1 THEN MATCH=1
                TT++
                IF TT EQ N_ELEMENTS(DRIVES) THEN GOTO,NO_MATCH
              ENDWHILE
            END
  'UNIX':   BEGIN
            CASE STRUPCASE(!VERSION.OS) OF 
              'LINUX':  BEGIN
                          IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: LINUX USER, FINDING FIREFOX'
                          CD,CURRENT=CDIR
                          BROWSE_STR = CDIR
                          BROWSER = 'firefox'
                          ;RES = FILE_SEARCH(BROWSE_STR,/TEST_DIRECTORY)
                          ;IF RES[0] EQ '' THEN GOTO, NO_MATCH
                          ;BROWSE_STR = RES[N_ELEMENTS(RES)-1]+'/'
                          MATCH=1
              
                        END
              'DARWIN': BEGIN
                          IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: MAC USER, USING "OPEN"'
                          CD,CURRENT=CDIR
                          BROWSE_STR = CDIR
                          BROWSER = 'open'
                          MATCH=1
          
                        END
      
            ENDCASE
            END
  ENDCASE

  NO_MATCH:
  IF MATCH EQ 0 THEN BEGIN
    PRINT, 'DIMITRI_DOWNLOAD_WD: NO MATCHES FOUND, WIDGET WILL NOT BE DISPLAYED'
    RETURN
  ENDIF

;----------------------------
; DEFINE DIMENSIONS OF WIDGET

  DIMITRI_VERSION = GET_DIMITRI_LOCATION('D_VERSION') ;BAH
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: DEFINING DIMENSIONS OF WIDGET'
  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 370
  YSIZE = 180
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)
  TITLE = 'DIMITRI V'+DIMITRI_VERSION+': DATA DOWNLOAD'
  BTSIZE = 120

;----------------------------
; DEFINE WIDGET BASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: CREATING WIDGET AND BUTTONS'
  DWNL_TLB       = WIDGET_BASE(COL=1,XOFFSET=XLOC,YOFFSET=YLOC,TITLE=TITLE)
  DWNL_TLB_LINK  = WIDGET_BASE(DWNL_TLB,ROW=7,FRAME=1)

;----------------------------
; CREATE BUTTONS FOR EACH SENSOR

  FOR I=0,N_ELEMENTS(SENSORS)-1 DO BEGIN 
    TEMP = WIDGET_BUTTON(DWNL_TLB_LINK,VALUE=SENSORS[I],UVALUE=SENSORS[I],XSIZE=BTSIZE,EVENT_PRO='DOWNLOAD_MOD_SITE')
    TEMP = WIDGET_LABEL( DWNL_TLB_LINK,VALUE=S_TEXT[I])
  ENDFOR

;----------------------------
; ADD THE HELP AND CLOSE BUTTONS

  DWNL_TLB_OPTIONS = WIDGET_BASE(DWNL_TLB,ROW=1,/ALIGN_RIGHT)
  ;TEMP = WIDGET_BUTTON(DWNL_TLB_OPTIONS,VALUE='Help',UVALUE='HELP',XSIZE=BTSIZE,EVENT_PRO='DOWNLOAD_MOD_OPTION')
  TEMP = WIDGET_BUTTON(DWNL_TLB_OPTIONS,VALUE='Close',UVALUE='CLOSE',XSIZE=BTSIZE-20,EVENT_PRO='DOWNLOAD_MOD_OPTION')

;----------------------------
; STORE ALL INFO

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: CREATE STRUCTURE TO CONTAIN ALL DATA'
  DL_INFO = {$
              SENSORS:SENSORS         ,$
              S_WEBS:S_WEBS           ,$
              S_TEXT:S_TEXT           ,$
              BROWSER:BROWSER         ,$
              IVERBOSE:IVERBOSE       ,$
              BROWSE_STR:BROWSE_STR       $
            }

;----------------------------
; REALISE THE WIDGET AND REGISTER 
; IT WITH THE X-MANAGER
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DOWNLOAD_WD: REALISING THE WIDGET AND REGISTERING WITH XMANAGER'  
  IF KEYWORD_SET(GROUP_LEADER) THEN WIDGET_CONTROL, DWNL_TLB, /REALIZE, SET_UVALUE=DL_INFO, /NO_COPY,GROUP_LEADER=GROUP_LEADER $
    ELSE WIDGET_CONTROL, DWNL_TLB, /REALIZE, SET_UVALUE=DL_INFO, /NO_COPY
  XMANAGER,'DOWNLOAD_OBJECT', DWNL_TLB

END
