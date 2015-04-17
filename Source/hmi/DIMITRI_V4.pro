;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_V4 
;* 
;* PURPOSE:
;*      THESE ROUTINES GENERATE THE MAIN DIMITRI HMI WIDGET WHICH ALLOWS INTERFACE 
;*      TO A NUMBER OF THE DIMITRI FUNCTIONS
;* 
;* CALLING SEQUENCE:
;*      DIMITRI_V4     
;* 
;* INPUTS:
;*      NONE     
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*        31 MAR 2011 - C KENT    - DIMITRI-2 V1.0
;*        17 MAY 2011 - C KENT    - ADDED PROCESS 2
;*        20 JUN 2011 - C KENT    - ADDED LINUX ACROBAT READER FOR SUM
;*        06 JUL 2011 - C KENT    - ADDED DATABASE COMMON BLOCK TO DIMITRI HMI
;*        xx SEP 2013 - PML / MAGELLIUM(MAG)  - ADDED V3.0 METHODS (AUXDATA+VICARIOUS CALIBRATION)
;*        27 JAN 2015 - NCG / MAGELLIUM(MAG)  - UPDATE WITH V4.0 SPECIFICATIONS
;*
;* VALIDATION HISTORY:
;*        14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                  COMPILATION AND OPERATION        
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

PRO DHMI_OBJECT_EVENT,EVENT

;---------------------------
; CATCH WIDGET RESIZE AND DO NOTHING

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.TOP,  SET_UVALUE=DHMI_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_BUTTON_EVENT,EVENT

;---------------------------
; RETRIEVE WIDGET INFORMATION

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;---------------------------
; CALL FUNCTIONALITY DEPENDING ON ACTION REQUEST

  IF DHMI_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_HMI->EVENT: STARTING FUNCTION FOR ACTION - ',ACTION 
  
  CASE ACTION OF
    'INGEST'          : DHMI_INGEST,              GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'NEW_SITE'        : DIMITRI_NEW_SITE_WD,      GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'RSR'             : DHMI_RSR,                 GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'DATABASE_STATS'  : DIMITRI_DATABASE_STATS_WD,GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE

    'MANUAL_CS'       : DHMI_CS_SETUP,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
;    'SSV_CS'          : DHMI_SSV_CS,           GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE         ; DIMITRI V3.1 ARGANS => DHMI_SSV_CS
;    'BRDF_CS'         : DHMI_BRDF_CS,           GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE        ; DIMITRI V3.1 ARGANS => DHMI_BRDF_CS
    'ANG_MATCHING'    : DHMI_PROCESS_1,                GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'SENSOR_TO_SENSOR_VISU' : DHMI_VISU,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'RAYLEIGH_ARG'    : DHMI_RAYLEIGH_ARG,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE  ; DIMITRI V3.1 ARGANS => DHMI_PROCESS_3
    'RAYLEIGH_MAG'    : DHMI_RAYLEIGH_MAG,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE 
    'RAYLEIGH_REPORT' : DHMI_SENSOR_TO_SIMULATION_REPORT,       GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE, METHOD='RAYLEIGH'
    'SUNGLINT_ARG'    : DHMI_SUNGLINT_ARG,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE  ; DIMITRI V3.1 ARGANS => DHMI_PROCESS_4
    'SUNGLINT_MAG'    : DHMI_SUNGLINT_MAG,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE 
    'SUNGLINT_REPORT' : DHMI_SENSOR_TO_SIMULATION_REPORT,       GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE, METHOD='SUNGLINT'
    'DESERT_ARG'      : DHMI_DESERT_ARG,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'DESERT_MAG'      : DHMI_DESERT_MAG,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'DESERT_REPORT'   : DHMI_SENSOR_TO_SIMULATION_REPORT,       GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE, METHOD='DESERT' 

    'OPTIONS'         : DHMI_CONFIGURATION,       GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'HELP'            : BEGIN
                          CASE STRUPCASE(!VERSION.OS_FAMILY) OF 
                            'WINDOWS':  SPAWN,DHMI_INFO.SUM,/HIDE,/NOWAIT
                            'UNIX':     SPAWN,STRING('acroread '+DHMI_INFO.SUM)
                          ENDCASE  
                        END
    'ABOUT'           : BEGIN
                          MSG   = [	GET_DIMITRI_LOCATION('TOOL'),'Release Date: xx/xx/2013'              ,$
                                    'IDL 7.0 Or Higher required','___________________',''             ,$
                                    'Email: ','=> PML / MAGELLIUM@magellium.fr'                  ,$
                                    'Authors:','=> Marc Bouvet (ESA-ESTEC)','=> Chris Kent (ARGANS Ltd)','=> Pascal Mettel (MAGELLIUM)']                          
	                        ABOUT = DIALOG_MESSAGE(MSG,/INFORMATION,TITLE = GET_DIMITRI_LOCATION('TOOL')+': ABOUT',/CENTER)
                        END
                        
    ELSE: BEGIN
          MSG   = [ 'Action ' + ACTION + ' not implemented at the moment... ' ]                          
          OTHER = DIALOG_MESSAGE(MSG,/INFORMATION,TITLE = 'INFORMATION',/CENTER)
          END
          
  ENDCASE

  WIDGET_CONTROL, EVENT.TOP,  SET_UVALUE=DHMI_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_EXIT_EVENT,EVENT

;---------------------------
; DESTROY THE WIDGET

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INFO, /NO_COPY
  IF DHMI_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_HMI->EXIT: DESTROYING THE WIDGET'
  WIDGET_CONTROL,EVENT.TOP,/DESTROY

END

;**************************************************************************************
;**************************************************************************************

PRO DIMITRI_V4,VERBOSE=VERBOSE

COMMON DHMI_DATABASE, DHMI_DB_DATA

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
  IVERBOSE = 1 
  PRINT, 'DIMITRI_HMI: STARTING HMI GENERATION SCRIPT'
  ENDIF ELSE IVERBOSE=0
  SUM  = GET_DIMITRI_LOCATION('SUM')

; CHECK FOR DIMITRI PATH
  DIMITRI_PATH = GET_DIMITRI_LOCATION('DIMITRI')
  TEMP = FILE_INFO(DIMITRI_PATH)
  IF TEMP.EXISTS NE 1 THEN BEGIN
    PRINT, 'DIMITRI: ERROR, DIMITRI CENTRAL FOLDER DOES NOT EXIST'
    PRINT, 'PLEASE CHECK YOUR INSTALLATION OR IDL START FOLDER : ' + DIMITRI_PATH 
    RETURN
  ENDIF
;---------------------------
; SET THE WINDOW PROPERTIES

  MACHINE_WINDOW = !D.NAME
  CASE STRUPCASE(!VERSION.OS_FAMILY) OF 
    'WINDOWS':  SET_PLOT,'WIN'
    'UNIX':     SET_PLOT,'X'
  ENDCASE

;---------------------------
; LOAD PNG IMAGES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: LOADING PNG IMAGES'

  TITLE     = GET_DIMITRI_LOCATION('TITLE_PNG')
  TEMP = FILE_INFO(TITLE)
  IF TEMP.EXISTS NE 1 THEN BEGIN
    PRINT, 'DIMITRI: ERROR LOADING PNG IMAGES, DIMITRI FOLDER DOES NOT EXIST'
    PRINT, 'PLEASE CHECK YOUR INSTALLATION OR IDL START FOLDER : ' + DIMITRI_PATH
    RETURN
  ENDIF
  INGEST    = GET_DIMITRI_LOCATION('INGEST_PNG')
  CLOUD_SCREENING = GET_DIMITRI_LOCATION('CLOUD_SCREENING_PNG')
  SENSOR_TO_SENSOR_COMP   = GET_DIMITRI_LOCATION('SENSOR_TO_SENSOR_COMP_PNG')
  SENSOR_TO_SIMU_COMP = GET_DIMITRI_LOCATION('SENSOR_TO_SIMU_COMP_PNG')

  READ_PNG, TITLE, TITLE_IMAGE
  READ_PNG, INGEST, INGEST_IMAGE
  READ_PNG, CLOUD_SCREENING, CLOUD_SCREENING_IMAGE
  READ_PNG, SENSOR_TO_SENSOR_COMP, SENSOR_TO_SENSOR_COMP_IMAGE
  READ_PNG, SENSOR_TO_SIMU_COMP, SENSOR_TO_SIMU_COMP_IMAGE
    
  DIMS = SIZE(TITLE_IMAGE)
  
  DIMS_SUBIMAGE = SIZE(INGEST_IMAGE)
  SUBIMAGE_W_INGEST = DIMS_SUBIMAGE(2)
  SUBIMAGE_H_INGEST = DIMS_SUBIMAGE(3)
  DIMS_SUBIMAGE = SIZE(CLOUD_SCREENING_IMAGE)
  SUBIMAGE_W_CS = DIMS_SUBIMAGE(2)
  SUBIMAGE_H_CS = DIMS_SUBIMAGE(3)
  DIMS_SUBIMAGE = SIZE(SENSOR_TO_SENSOR_COMP_IMAGE)
  SUBIMAGE_W_SENSOR_TO_SENSOR = DIMS_SUBIMAGE(2)
  SUBIMAGE_H_SENSOR_TO_SENSOR = DIMS_SUBIMAGE(3)
  DIMS_SUBIMAGE = SIZE(SENSOR_TO_SIMU_COMP_IMAGE)
  SUBIMAGE_W_SENSOR_TO_SIMU = DIMS_SUBIMAGE(2)
  SUBIMAGE_H_SENSOR_TO_SIMU = DIMS_SUBIMAGE(3)


;--------------------------
; LOAD THE L1B DATABASE INTO A COMMON BLOCK

  DB_FILE = GET_DIMITRI_LOCATION('DATABASE')
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DHMI_DB_DATA = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

;---------------------------
; DEFINE WIDGET PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: DEFINING WIDGET PARAMETERS'  
  LABEL_SIZE = 90
  MAIN_BTN_SIZE = 105
  SMLL_BTN_SIZE = 80
  MID_BTN_SIZE = 52

  XSIZE = MAX( [ DIMS[2]+30, 4*MAIN_BTN_SIZE+3*MID_BTN_SIZE+LABEL_SIZE+8*15, SUBIMAGE_W_INGEST+SUBIMAGE_W_CS+SUBIMAGE_W_SENSOR_TO_SENSOR+SUBIMAGE_W_SENSOR_TO_SIMU+4*15 ] )  
  YSIZE = 225 + 40
  
  
  SCR_DIMS = GET_SCREEN_SIZE()
  XLOC  = (SCR_DIMS[0]/2)-(XSIZE/2)
  YLOC  = (YSIZE/2)
  
  BTEVENT = 'DHMI_BUTTON_EVENT'
  EXEVENT = 'DHMI_EXIT_EVENT'

;---------------------------
; DEFINE MAIN WIDGET BASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: DEFINING MAIN HMI WIDGET'
DTLB = WIDGET_BASE(XSIZE=XSIZE,YSIZE=YSIZE,XOFFSET=XLOC,YOFFSET=YLOC,TITLE=GET_DIMITRI_LOCATION('TOOL'),COLUMN=1, /BASE_ALIGN_CENTER)
   
;---------------------------
; ADD DRAW_WIDGET FOR MAIN TITLE IMAGE
  DTLB_IMGBASE = WIDGET_BASE(DTLB,COLUMN=1,/ALIGN_CENTER)
  DTLB_IMG = WIDGET_DRAW(DTLB_IMGBASE,XSIZE=DIMS[2],YSIZE=DIMS[3],SENSITIVE=0,RETAIN=2,TOOLTIP='DIMITRI Main Window')
  DTLB_TOP = WIDGET_BASE(DTLB,COLUMN=8,/ALIGN_CENTER)

;---------------------------
; ADD INGEST IMAGE AND BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING INGESTION OPTION BOX'
  DTLB_TOP_INGEST       = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_INGEST_IMG_B = WIDGET_BASE(DTLB_TOP_INGEST)
  DTLB_TOP_INGEST_IMG   = WIDGET_DRAW(DTLB_TOP_INGEST_IMG_B,XSIZE=SUBIMAGE_W_INGEST,YSIZE=SUBIMAGE_H_INGEST,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_INGEST_C     = WIDGET_BASE(DTLB_TOP_INGEST,COLUMN=2,/ALIGN_CENTER)
  DTLB_TOP_INGEST_BTN   = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='Add L1B Data',UVALUE='INGEST',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT,$
      TOOLTIP='Ingest L1B Products to DIMITRI Database')
  DTLB_TOP_INGEST_BTN   = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='New Site',XSIZE=MAIN_BTN_SIZE,UVALUE='NEW_SITE',EVENT_PRO=BTEVENT,$
      TOOLTIP='Define a new study site for dimitri database (name, coords...)')
  DTLB_TOP_VISU_BTN       = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='View Sensor RSR',XSIZE=MAIN_BTN_SIZE,UVALUE='RSR',EVENT_PRO=BTEVENT,$
    TOOLTIP='View RSR DIMITRI Data')
  DTLB_TOP_VISU_BTN       = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='Database Stats',XSIZE=MAIN_BTN_SIZE,UVALUE='DATABASE_STATS',EVENT_PRO=BTEVENT,$
    TOOLTIP='View current DIMITRI Database Contents and Stats')
  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)



;---------------------------
; ADD CLOUD SCREENING AND BUTTONS
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING CLOUD SCREENING OPTION BOX'
  DTLB_TOP_CS         = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_CS_B       = WIDGET_BASE(DTLB_TOP_CS)
  DTLB_TOP_CLOUD_SCREENING_IMG  = WIDGET_DRAW(DTLB_TOP_CS_B,XSIZE=SUBIMAGE_W_CS,YSIZE=SUBIMAGE_H_CS,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_CS_C       = WIDGET_BASE(DTLB_TOP_CS,COLUMN=1,/ALIGN_CENTER)
  DTLB_TOP_CS_BTN     = WIDGET_BUTTON(DTLB_TOP_CS_C,VALUE='Manual',UVALUE='MANUAL_CS',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT,$
    TOOLTIP='Manual Cloud Screening Process')
  DTLB_TOP_CS_BTN     = WIDGET_BUTTON(DTLB_TOP_CS_C,VALUE='SSV',UVALUE='SSV_CS',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT,$
    TOOLTIP='SSV cloud screening method')
  DTLB_TOP_CS_BTN     = WIDGET_BUTTON(DTLB_TOP_CS_C,VALUE='BRDF',UVALUE='BRDF_CS',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT,$
    TOOLTIP='BRDF cloud screening method')

  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  
  ;---------------------------
; ADD SENSOR TO SENSOR COMPARISON PROCESS AND BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING SENSOR TO SENSOR COMPARISON OPTION BOX'
  DTLB_TOP_SENSOR_TO_SENSOR         = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_SENSOR_TO_SENSOR_B       = WIDGET_BASE(DTLB_TOP_SENSOR_TO_SENSOR)
  DTLB_TOP_SENSOR_TO_SENSOR_IMG  = WIDGET_DRAW(DTLB_TOP_SENSOR_TO_SENSOR_B,XSIZE=SUBIMAGE_W_SENSOR_TO_SENSOR, YSIZE=SUBIMAGE_H_SENSOR_TO_SENSOR,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_SENSOR_TO_SENSOR_C       = WIDGET_BASE(DTLB_TOP_SENSOR_TO_SENSOR,COLUMN=1,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SENSOR_BTN     = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SENSOR_C,VALUE='Angular Matching',UVALUE='ANG_MATCHING',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT,$
    TOOLTIP='Angular matching Process')
  DTLB_TOP_VISU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SENSOR_C,VALUE='View Outputs',XSIZE=MAIN_BTN_SIZE,UVALUE='SENSOR_TO_SENSOR_VISU',EVENT_PRO=BTEVENT,$
    TOOLTIP='View Sensor to Sensor Comparison Output Data')

  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  
;---------------------------
; ADD SENSOR TO SIMULATION COMPARISON PROCESS AND BUTTONS
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING SENSOR TO SIMULATION COMPARISON OPTION BOX'
  DTLB_TOP_SENSOR_TO_SIMU           = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_SENSOR_TO_SIMU_B         = WIDGET_BASE(DTLB_TOP_SENSOR_TO_SIMU)
  DTLB_TOP_SENSOR_TO_SIMU_IMG      = WIDGET_DRAW(DTLB_TOP_SENSOR_TO_SIMU_B,XSIZE=SUBIMAGE_W_SENSOR_TO_SIMU,YSIZE=SUBIMAGE_H_SENSOR_TO_SIMU,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_SENSOR_TO_SIMU_C         = WIDGET_BASE(DTLB_TOP_SENSOR_TO_SIMU,ROW=1,FRAME=1,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_LABEL(DTLB_TOP_SENSOR_TO_SIMU_C,VALUE='Rayleigh',XSIZE=LABEL_SIZE,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C,VALUE='ARG',XSIZE=MID_BTN_SIZE,UVALUE='RAYLEIGH_ARG',EVENT_PRO=BTEVENT,$
    TOOLTIP='ARGANS Rayleigh Sensor To Simulation Comparison Process (ocean sites)')
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C,VALUE='MAG',XSIZE=MID_BTN_SIZE,UVALUE='RAYLEIGH_MAG',EVENT_PRO=BTEVENT,$
    TOOLTIP='MAGELLIUM Rayleigh Sensor To Simulation Comparison Process (ocean sites)')
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C,VALUE='Report',XSIZE=MID_BTN_SIZE,UVALUE='RAYLEIGH_REPORT',EVENT_PRO=BTEVENT,$
    TOOLTIP='Statistical Report on Rayleigh Sensor To Simulation Comparison Process (ocean sites)')
  DTLB_TOP_SENSOR_TO_SIMU_C1         = WIDGET_BASE(DTLB_TOP_SENSOR_TO_SIMU,ROW=1,FRAME=1,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_LABEL(DTLB_TOP_SENSOR_TO_SIMU_C1,VALUE='Sunglint',XSIZE=LABEL_SIZE,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C1,VALUE='ARG',XSIZE=MID_BTN_SIZE,UVALUE='SUNGLINT_ARG',EVENT_PRO=BTEVENT,$
    TOOLTIP='ARGANS Sunglint Sensor To Simulation Comparison Process (sunglint sites)')
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C1,VALUE='MAG',XSIZE=MID_BTN_SIZE,UVALUE='SUNGLINT_MAG',EVENT_PRO=BTEVENT,$
    TOOLTIP='MAGELLIUM Sunglint Sensor To Simulation Comparison Process (sunglint sites)')
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C1,VALUE='Report',XSIZE=MID_BTN_SIZE,UVALUE='SUNGLINT_REPORT',EVENT_PRO=BTEVENT,$
    TOOLTIP='Statistical Report on Sunglint Sensor To Simulation Comparison Process (sunglint sites)')
  DTLB_TOP_SENSOR_TO_SIMU_C2         = WIDGET_BASE(DTLB_TOP_SENSOR_TO_SIMU,ROW=1,FRAME=1,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_LABEL(DTLB_TOP_SENSOR_TO_SIMU_C2,VALUE='Desert',XSIZE=LABEL_SIZE,/ALIGN_CENTER)
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C2,VALUE='ARG',XSIZE=MID_BTN_SIZE,UVALUE='DESERT_ARG',EVENT_PRO=BTEVENT,$
    TOOLTIP='ARGANS Desert Sensor To Simulation Comparison Process (land sites)')
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C2,VALUE='MAG',XSIZE=MID_BTN_SIZE,UVALUE='DESERT_MAG',EVENT_PRO=BTEVENT,$
    TOOLTIP='MAGELLIUM Desert Sensor To Simulation Comparison Process (land sites)')
  DTLB_TOP_SENSOR_TO_SIMU_BTN       = WIDGET_BUTTON(DTLB_TOP_SENSOR_TO_SIMU_C2,VALUE='Report',XSIZE=MID_BTN_SIZE,UVALUE='DESERT_REPORT',EVENT_PRO=BTEVENT,$
    TOOLTIP='Statistical Report on Desert Sensor To Simulation Comparison Process (land sites)')
   
;---------------------------
; ADD OPTION BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING USER OPTION BOX'
  DTLB_BTM      = WIDGET_BASE(DTLB,ROW=1,FRAME=1,/ALIGN_CENTER)
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='Options',XSIZE=SMLL_BTN_SIZE,UVALUE='OPTIONS',EVENT_PRO=BTEVENT,TOOLTIP='DIMITRI Options')
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='Help',XSIZE=SMLL_BTN_SIZE,UVALUE='HELP',EVENT_PRO=BTEVENT,TOOLTIP='DIMITRI Documentation')
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='About',XSIZE=SMLL_BTN_SIZE,UVALUE='ABOUT',EVENT_PRO=BTEVENT,TOOLTIP='DIMITRI About')
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='Exit',XSIZE=SMLL_BTN_SIZE,EVENT_PRO=EXEVENT,TOOLTIP='Exit DIMITRI')

;---------------------------
; REALISE THE WIDGET AND DISPLAY THE PNG IMAGES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: REALISING THE WIDGET AND DISPLAYING PNG IMAGES'
  WIDGET_CONTROL, DTLB, /REALIZE
  WIDGET_CONTROL, DTLB_IMG, GET_VALUE=D1
  WSET, D1
  TV, TITLE_IMAGE, TRUE=1
   
  WIDGET_CONTROL, DTLB_TOP_INGEST_IMG, GET_VALUE=D2
  WSET, D2
  TV, INGEST_IMAGE, TRUE=1

  WIDGET_CONTROL, DTLB_TOP_CLOUD_SCREENING_IMG, GET_VALUE=D3
  WSET, D3
  TV, CLOUD_SCREENING_IMAGE, TRUE=1

  WIDGET_CONTROL, DTLB_TOP_SENSOR_TO_SENSOR_IMG, GET_VALUE=D4
  WSET, D4
  TV, SENSOR_TO_SENSOR_COMP_IMAGE, TRUE=1

  WIDGET_CONTROL, DTLB_TOP_SENSOR_TO_SIMU_IMG, GET_VALUE=D5
  WSET, D5
  TV, SENSOR_TO_SIMU_COMP_IMAGE, TRUE=1  
 
  
;---------------------------
; STORE WIDGET INFO IN STRUCTURE
  
  DHMI_INFO = {$
                IVERBOSE:IVERBOSE ,$  
                SUM:SUM           ,$
                GROUP_LEADER: DTLB $
              }

;---------------------------
; REGISTER WITH THE XMANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: REGISTERING WITH THE XMANAGER'  
  WIDGET_CONTROL, DTLB, SET_UVALUE=DHMI_INFO,/NO_COPY
  XMANAGER,'DHMI_OBJECT', DTLB

END