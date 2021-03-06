;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      BRDF_CLOUD_SCREENING 
;* 
;* PURPOSE:
;*      SCREEN CLOUD OF A GIVEN SENSOR THROUGH BRDF COMPUTATION OVER PSEUDO INVARIANT CALIBRATION SITE 
;*
;* CALLING SEQUENCE:
;*      RES=BRDF_CLOUD_SCREENING(OUTPUT_FOLDER, REGION, SENSOR, PROC_VER,$
;*                               ROI_PERCENTAGE, DECIMAL_YEAR_START, DECIMAL_YEAR_STOP,$
;*                               BRDF_BAND, BRDF_THRESHOLD_PC, $
;*                               DB_FILE_CT, BIN_PERIOD, NB_ACQUI_LIMIT,$
;*                               VZAMIN, VZAMAX, VAAMIN, VAAMAX, SZAMIN, SZAMAX, SAAMIN, SAAMAX,$
;*                               CLEAN=CLEAN, VERBOSE=VERBOSE)
;* 
;* INPUTS:
;*      OUTPUT_FOLDER      - THE FULL PATH OF THE OUTPUT FOLDER REQUIRED
;*      REGION             - A STRING OF THE DIMITRI VALIDATION SITE
;*      SENSOR             - A STRING OF THE SENSOR TO BE UTILISED
;*      PROC_VER           - A STRING OF THE SENSOR PROCESSING VERSION TO BE UTILISED
;*      ROI_PERCENTAGE     - A FLOAT OF THE ACCEPTABLE ROI COVERAGE PERCENTAGE (0-100)
;*      DECIMAL_YEAR_START - START DECIMAL YEAR OF THE PERIOD TO BE UTILISED
;*      DECIMAL_YEAR_STOP  - STOP DECIMAL YEAR OF THE PERIOD TO BE UTILISED
;*      BRDF_BAND          - BAND USED IN THE TOA SIMULATED/OBS RATIO FOR CLOUD DETECTION
;*      BRDF_THRESHOLD_PC  - THRESHOLD ON THE TOA SIMULATED/OBS TO DETECT CLOUD (IN PERCENT)
;*      DB_FILE_CT         - DIMITRI DATABASE CLOUD TRAINING FILE (CLEAR SKY) FOR BRDF COMPUTATION
;*      BIN_PERIOD         - AN INTEGER OF THE BINNING PERIOD TO BE CONSIDERED IN DAYS FOR BRDF COMPUTATION
;*      NB_ACQUI_LIMIT     - THE MINIMUM NUMBER OF ACQUISITIONS DURING ONE BIN FOR BRDF COMPUTATION
;*      VZAMIN             - THE MINIMUM VIEWING ZENITH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      VZAMAX             - THE MAXIMUM VIEWING ZENITH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      VAAMIN             - THE MINIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      VAAMAX             - THE MAXIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      SZAMIN             - THE MINIMUM SOLAR ZENITH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      SZAMAX             - THE MAXIMUM SOLAR ZENITH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      SAAMIN             - THE MINIMUM SOLAR AZIMUTH ANGLE ALLOWED FOR BRDF COMPUTATION
;*      SAAMAX             - THE MAXIMUM SOLAR AZIMTUH ANGLE ALLOWED FOR BRDF COMPUTATION
;*
;* KEYWORDS:
;*      VERBOSE    - PROCESSING STATUS OUTPUTS
;*      CLEAN      - REMOVE INTERMEDIATE FOLDERS FOR BRDF COMPUTATION
;*
;* OUTPUTS:
;*      STATUS   - 1: NOMINAL OUTPUT, 0 OR -1 ERROR ENCOUNTERED
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      17 FEB 2014 - C MAZERAN   - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*      17 FEB 2014 - C MAZERAN   - LINUX 64BIT MACHINE IDL 8.2: COMPILATION AND OPERATION SUCCESSFUL
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION BRDF_CLOUD_SCREENING, OUTPUT_FOLDER, REGION, SENSOR, PROC_VER,$
                               ROI_PERCENTAGE, DECIMAL_YEAR_START, DECIMAL_YEAR_STOP,$
                               BRDF_BAND, BRDF_THRESHOLD_PC, $
                               DB_FILE_CT, BIN_PERIOD, NB_ACQUI_LIMIT,$
                               VZAMIN, VZAMAX, VAAMIN, VAAMAX, SZAMIN, SZAMAX, SAAMIN, SAAMAX,$
                               CLEAN=CLEAN, VERBOSE=VERBOSE

;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME
; AND SOME NUMERICAL CONSTANTS

  FCT_NAME  = 'BRDF_CLOUD_SCREENING'
  BADVAL    = -999.0
  TOL       = 0.000001 ; TOLERANCE FOR FLOAT COMPARISON
  REF_O3    = 300.0
  REF_WV    = 2.0

  NUM_NON_REF = 5+12 ;TIME, ANGLES (4) AND AUX INFO (12)
  NUM_NON_ROU = 2

;-----------------------------------------
; SET SENSOR RANDOM UNCERTAINTY AT 3% 
; (IDEALLY SHOULD BE DERIVED FROM EARLIER, SEE RECAL/RECALIBRATE_DOUBLETS.PRO)

  SEN_UNCERTR = 0.03
  SEN_UNCERTS = 0.03

;-----------------------------------------
; MODISA SURFACE DEPENDANCE EXCEPTION

  SITE_TYPE = GET_SITE_TYPE(REGION,VERBOSE=VERBOSE)
  IF SENSOR EQ 'MODISA' THEN BEGIN
    IF STRUPCASE(SITE_TYPE) EQ 'OCEAN' THEN TEMP_SENSOR = SENSOR+'_O' ELSE TEMP_SENSOR = SENSOR+'_L'
  ENDIF ELSE TEMP_SENSOR = SENSOR

;----------------------------------------
; RETRIEVE WAVELENGTHS

  NB_BANDS    = (SENSOR_BAND_INFO(SENSOR,VERBOSE=VERBOSE))[0]
  WAVELENGTHS = FLTARR(NB_BANDS)
  FOR BAND=0, NB_BANDS -1 DO WAVELENGTHS[BAND]= FLOAT(GET_SENSOR_BAND_NAME(SENSOR,BAND))
  BRDF_WAV = WAVELENGTHS[BRDF_BAND]

;--------------------------------
; CREATE OUTPUT FOLDER IF IT DOESN'T EXIST

  RES = FILE_INFO(OUTPUT_FOLDER)
  IF RES.EXISTS NE 1 OR RES.DIRECTORY NE 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+": OUTPUT FOLDER DOESN'T EXIST, CREATING"
    FILE_MKDIR,OUTPUT_FOLDER
  ENDIF

;-----------------------------------------
; CHECKS INPUT CRITERIA ARE OK

  BRDF_THRESHOLD = FLOAT(BRDF_THRESHOLD_PC)*0.01
  RP_LIMIT = FLOAT(ROI_PERCENTAGE)*0.01
  IF BRDF_THRESHOLD LT 0 OR RP_LIMIT GT  1.0 OR RP_LIMIT LT 0.0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, BRDF_THRESHOLD OR ROI CRITERIA OUT OF RANGE'
    RETURN,-1
  ENDIF

;-----------------------------------------
; DEFINE INPUT/OUTPUT FILES AND DIRECTORIES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': DEFINING INPUT/OUTPUT FILES'
  SITE_FILE  = GET_DIMITRI_LOCATION('SITE_DATA')
  DB_FILE    = GET_DIMITRI_LOCATION('DATABASE')
  MAIN_DIRC  = GET_DIMITRI_LOCATION('DIMITRI')
  IFILE      = FILEPATH(ROOT_DIR=MAIN_DIRC, SUBDIRECTORY=['Input','Site_'+REGION,SENSOR,'Proc_'+PROC_VER], SENSOR+'_TOA_REF.dat')
  RSR_FOLDER = FILEPATH(ROOT_DIR=GET_DIMITRI_LOCATION('RSR'), SENSOR)

  RC_FOLDER  = FILEPATH(ROOT_DIR=OUTPUT_FOLDER,'RECALIBRATION')
  SSEN_DATA  = FILEPATH(ROOT_DIR=RC_FOLDER, 'SSEN_'+REGION+'_REF_'+SENSOR+'_'+PROC_VER+'_')
  RB_FOLDER  = FILEPATH(ROOT_DIR=OUTPUT_FOLDER,'ROUJEAN_BRDF')
  SEN_BRDF1  = FILEPATH(ROOT_DIR=RB_FOLDER, 'ROUJEAN_K1_'+REGION+'_REF_'+SENSOR+'_'+PROC_VER+'.dat')
  SEN_BRDF2  = FILEPATH(ROOT_DIR=RB_FOLDER, 'ROUJEAN_K2_'+REGION+'_REF_'+SENSOR+'_'+PROC_VER+'.dat')
  SEN_BRDF3  = FILEPATH(ROOT_DIR=RB_FOLDER, 'ROUJEAN_K3_'+REGION+'_REF_'+SENSOR+'_'+PROC_VER+'.dat')
  SEN_UCERT  = FILEPATH(ROOT_DIR=RB_FOLDER, 'ROUJEAN_UC_'+REGION+'_REF_'+SENSOR+'_'+PROC_VER+'.dat')
  RB_FILE    = FILEPATH(ROOT_DIR=OUTPUT_FOLDER,'ROUJEAN_'+REGION+'_REF_'+SENSOR+'_'+PROC_VER+'.csv')

  BRDF_CS_LOG    = FILEPATH(ROOT_DIR=OUTPUT_FOLDER, 'BRDF_CS_LOG.txt')
  DB_FILE_OUT    = FILEPATH(ROOT_DIR=OUTPUT_FOLDER, 'DIMITRI_DATABASE_BRDF_CS.CSV')
  OFILE_STAT_CSV = FILEPATH(ROOT_DIR=OUTPUT_FOLDER, STRJOIN(['BRDF_CS_PERF',REGION,SENSOR,PROC_VER],'_')+'.csv')

;-----------------------------------------
; CHECK DIMITRI DATABASE EXISTS

  TEMP = FILE_INFO(DB_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, DIMITRI DATABASE FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF

;-----------------------------------------
; CHECK INPUT SAV FILE EXISTS

  TEMP = FILE_INFO(IFILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, INPUT SAV FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF

;-----------------------------------------
; CHECK DIMITRI CLOUD TRAINING DATABASE EXISTS

  TEMP = FILE_INFO(DB_FILE_CT)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, DIMITRI CLOUD TRAINING FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF

;-----------------------------------------
; CREATE TEMPORARY OUTPUT DIRECTORY

  FILE_MKDIR, RC_FOLDER

;-----------------------------------------
; RECORD THIS PROCESSING REQUEST IN A LOG

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+": WRITTING LOG FILE"
  TMP_DATE = SYSTIME()
  TMP_DATE = STRING(STRMID(TMP_DATE,8,2)+'-'+STRMID(TMP_DATE,4,3)+'-'+STRMID(TMP_DATE,20,4)+' '+STRMID(TMP_DATE,11,8))
  TEMP = FILE_INFO(BRDF_CS_LOG)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    OPENW, LUNLOG,BRDF_CS_LOG,/GET_LUN
    PRINTF,LUNLOG,'DATE;REGION;SENSOR;PROC_VER;ROI_PERCENTAGE;START;STOP;WAV;THRESHOLD;TRAINING_DB;BIN_PERIOD;ACQUI_LIMIT'
  ENDIF ELSE OPENW,LUNLOG,BRDF_CS_LOG,/GET_LUN,/APPEND
  
  PRINTF,LUNLOG,FORMAT='(4(A,1H;),(F6.2,1H;),2(F10.4,1H;),(F8.2,1H;),(F6.3,1H;),2(A,1H;),A)',$
  TMP_DATE,REGION,SENSOR,PROC_VER,ROI_PERCENTAGE,DECIMAL_YEAR_START,DECIMAL_YEAR_STOP, BRDF_WAV, BRDF_THRESHOLD_PC,$
  DB_FILE_CT, STRTRIM(BIN_PERIOD,2), STRTRIM(NB_ACQUI_LIMIT,2)
  FREE_LUN,LUNLOG

;-----------------------------------------
; COMPUTE ROI AREA IN KM^2

  ICOORDS = GET_SITE_COORDINATES(REGION,SITE_FILE,VERBOSE=VERBOSE)

  IF ICOORDS[0] EQ -1 THEN BEGIN
    PRINT,FCT_NAME+': ERROR, REGION COORDINATES NOT FOUND'
    RETURN,-1
  ENDIF

  ROI_X     = GREAT_CIRCLE_DISTANCE(ICOORDS[0],ICOORDS[2],ICOORDS[0],ICOORDS[3],/DEGREES,VERBOSE=VERBOSE)
  ROI_Y     = GREAT_CIRCLE_DISTANCE(ICOORDS[0],ICOORDS[2],ICOORDS[1],ICOORDS[2],/DEGREES,VERBOSE=VERBOSE)
  ROI_AREA  = FLOAT(ROI_X)*FLOAT(ROI_Y)
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': COMPUTED ROI AREA = ',ROI_AREA

;-----------------------------------------
; GET PIXEL AREA RESOLUTIONS OF SENSOR

  SPX_AREA = (SENSOR_PIXEL_SIZE(SENSOR,/AREA,VERBOSE=VERBOSE))[0]

;-----------------------------------------
; DEFINE ROI PIX THRESHOLD

  PX_THRESH  = FLOOR(DOUBLE(RP_LIMIT*ROI_AREA)/DOUBLE(SPX_AREA))
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': COMPUTED PX_THRESHOLDS = ',PX_THRESH

;-----------------------------------------
; ROICOVERAGE CHECK

  IF RP_LIMIT GE 1.0 THEN BEGIN
    ROICOVER = 1
    PX_THRESH = 1
  ENDIF ELSE ROICOVER = 0

;----------------------------------------
; READ THE DIMITRI CLOUD TRAINING DATABASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING DIMITRI CLOUD TRAINING DATABASE'
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DB_DATA_CT  = READ_ASCII(DB_FILE_CT,TEMPLATE=DB_TEMPLATE)

;----------------------------------------
; SELECT CLOUD TRAINING DATA UPON ROI CRITERIA

  RES = WHERE(STRCMP(DB_DATA_CT.REGION,REGION)               EQ 1 AND $
              STRCMP(DB_DATA_CT.SENSOR,SENSOR)               EQ 1 AND $
              STRCMP(DB_DATA_CT.PROCESSING_VERSION,PROC_VER) EQ 1 AND $
              DB_DATA_CT.ROI_COVER  GE ROICOVER                   AND $
              DB_DATA_CT.NUM_ROI_PX GE PX_THRESH)
                  
  IF RES[0] EQ -1 THEN BEGIN
    PRINT, FCT_NAME+': WARNING, NO SENSOR DATA FOUND WITHIN PIXEL THRESHOLD CONDITION IN CLOUD TRAINING DB, RETURN'
    RETURN,0
  ENDIF

;----------------------------------------
; RESTORE THE SENSOR TOA DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': RESTORING SENSOR DATA'
  RESTORE, IFILE

;----------------------------------------
; SEARCH SENSOR TOA CORRESPONDING TO
; CLOUD TRAINING DATABASE SELECTION

  CT_ID = []
  FOR I = 0l, N_ELEMENTS(RES)-1 DO BEGIN
     ID = WHERE(ABS(SENSOR_L1B_REF[0,*]-DB_DATA_CT.DECIMAL_YEAR[RES[I]]) LE TOL AND $ 
                    SENSOR_L1B_REF[1,*] GT VZAMIN AND SENSOR_L1B_REF[1,*] LT VZAMAX AND $
                    SENSOR_L1B_REF[2,*] GT VAAMIN AND SENSOR_L1B_REF[2,*] LT VAAMAX AND $
                    SENSOR_L1B_REF[3,*] GT SZAMIN AND SENSOR_L1B_REF[3,*] LT SZAMAX AND $
                    SENSOR_L1B_REF[4,*] GT SAAMIN AND SENSOR_L1B_REF[4,*] LT SAAMAX)
     IF ID[0] GT -1 THEN CT_ID = [CT_ID,ID]
  ENDFOR

  IF N_ELEMENTS(CT_ID) EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, NO SENSOR DATA MATCHING THE CLOUD TRAINING DATABASE SELECTION, RETURN'
    RETURN, -1
  ENDIF

;----------------------------------------
; CLEAN FOR DUBIOUS TOA SIGNAL

  ID = WHERE(SENSOR_L1B_REF[NUM_NON_REF+BRDF_BAND,CT_ID] GT 0.0 AND SENSOR_L1B_REF[NUM_NON_REF+BRDF_BAND,CT_ID] LT 5.0, N_CT)
  IF N_CT EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, NO TOA SIGNAL WITHIN PROPER RANGE'
    RETURN, -1
  ENDIF
  CT_ID = CT_ID[ID]
           
;---------------------------------------
; READ GEOMETRY FOR ALL EXTRACTIONS

  N_TOT = N_ELEMENTS(SENSOR_L1B_REF[0,*])

  SZA = REFORM(SENSOR_L1B_REF[3,*])
  VZA = REFORM(SENSOR_L1B_REF[1,*])
  RAA = ACOS(COS(REFORM(SENSOR_L1B_REF[2,*]-SENSOR_L1B_REF[4,*])*!DTOR))*!RADEG

  ; DEFINE AIR MASS FRACTION
  AIR_MASS = REFORM(1./COS(SZA*!DTOR)+1./COS(VZA*!DTOR))

;---------------------------------------
; READ OZONE AND WATER VAPOUR FOR ALL EXTRACTIONS

  OZONE = REFORM(SENSOR_L1B_REF[5,*])
  TMP   = WHERE(OZONE EQ BADVAL)
  IF TMP[0] NE -1 THEN OZONE[TMP]=REF_O3
  
  WVAP  = REFORM(SENSOR_L1B_REF[15,*])
  TMP = WHERE(WVAP EQ BADVAL)
  IF TMP[0] NE -1 THEN WVAP[TMP]=REF_WV
 
;---------------------------------------
; COMPUTE TRANSMISSION AT EACH BAND
; TAKING INTO ACCOUNT RSR

  TRANS=FLTARR(NB_BANDS,N_TOT)
  RSR_TEMPLATE  = GET_DIMITRI_RSR_TEMPLATE()
 
  FOR BAND =0, NB_BANDS-1 DO BEGIN

     RSR_FILE = FILEPATH(ROOT_DIR=RSR_FOLDER, 'RSR_'+SENSOR+'_BAND_'+STRTRIM(BAND,2)+'.txt')
     RSR_DATA = READ_ASCII(RSR_FILE,TEMPLATE = RSR_TEMPLATE)

     ; GET TRANSMISSION FOR REFERENCE CONTENT AND NORMALISED GEOMETRY
     TO3_REF = GET_OZONE_TRANSMISSION(RSR_DATA.WAVELENGTH,VERBOSE=VERBOSE)
     TWV_REF = GET_WVAP_TRANSMISSION(RSR_DATA.WAVELENGTH,VERBOSE=VERBOSE)
     TGS_REF = GET_GASEOUS_TRANSMISSION(RSR_DATA.WAVELENGTH,VERBOSE=VERBOSE)

     ; COMPUTE GASEOUS OPTICAL THICKNESS
     TAUO3   = -0.5*ALOG((TO3_REF>0.000001)/TGS_REF)
     TAUWV   = -0.5*ALOG((TWV_REF>0.000001)/TGS_REF)
     TAUGS   = -0.5*ALOG(TGS_REF)

     ; DEFINE TOTAL OPTICAL THICKNESS ALONG PATH FOR EACH GEOMETRY
     TAU_PATH=TAUO3#((OZONE/REF_O3)*AIR_MASS)+TAUWV#(WVAP/REF_WV*AIR_MASS)+TAUGS#AIR_MASS

     ; INTEGRATE TRANSMISSION OVER SPECTRAL RESPONSE FOR EACH GEOMETRY    
     TRANS[BAND,*]=TOTAL(EXP(-TAU_PATH)*(RSR_DATA.RESPONSE#(1+BYTARR(N_TOT))),1)/TOTAL(RSR_DATA.RESPONSE)

  ENDFOR

;----------------------------------------
; GENERATE FAKE SUPER SENSOR OUTPUTS TO USE DIMITRI BRDF ROUTINES
; NOTE THAT SS_DATA[NUM_NON_REF+3,*] AND SS_DATA[NUM_NON_REF+4,*] ARE NOT USED HEREAFTER

  FOR BAND=0, NB_BANDS-1 DO BEGIN

     TEMP_BID  = CONVERT_INDEX_TO_WAVELENGTH(BAND,TEMP_SENSOR)
     IF STRCMP(TEMP_BID,'ERROR') THEN CONTINUE
 
     SS_DATA = MAKE_ARRAY(NUM_NON_REF+5,N_CT,/DOUBLE,VALUE=-1.0)  

     FOR I=0, NUM_NON_REF-1 DO BEGIN
        SS_DATA[I,*]  = REFORM(SENSOR_L1B_REF[I,CT_ID]) 
     ENDFOR
     SS_DATA[NUM_NON_REF,*]   = REFORM(SENSOR_L1B_REF[NUM_NON_REF+BAND,CT_ID])/TRANS[BAND,CT_ID]
     SS_DATA[NUM_NON_REF+1,*] = MAKE_ARRAY(N_CT,/DOUBLE,VALUE=SEN_UNCERTS)
     SS_DATA[NUM_NON_REF+2,*] = MAKE_ARRAY(N_CT,/DOUBLE,VALUE=SEN_UNCERTR)
    
     SAVE, SS_DATA,FILENAME = SSEN_DATA+TEMP_BID+'.DAT'

  ENDFOR

;---------------------------------------
; COMPUTE ROUJEAN BRDF

  START_BIN_DATE = MIN(SENSOR_L1B_REF[0,CT_ID])
  END_BIN_DATE   = MAX(SENSOR_L1B_REF[0,CT_ID])

  RES = ROUJEAN_BRDF(OUTPUT_FOLDER,REGION,SENSOR,PROC_VER,BIN_PERIOD,/NO_PLOTS,$
  VERBOSE=VERBOSE,START_TIME=START_BIN_DATE,STOP_TIME=END_BIN_DATE,NB_ACQUI_LIMIT=NB_ACQUI_LIMIT)

  IF RES EQ -1 THEN BEGIN
    PRINT,FCT_NAME+': FATAL ERROR ENCOUNTERED IN ROUJEAN BRDF'
    RETURN,-1
  ENDIF

;-----------------------------------------
; CHECK BRDF FILE EXISTS AND RESTORE THEM

  TEMP = [FILE_TEST(SEN_BRDF1), FILE_TEST(SEN_BRDF2), FILE_TEST(SEN_BRDF3), FILE_TEST(SEN_UCERT)]
  IF TOTAL(TEMP) NE N_ELEMENTS(TEMP) THEN BEGIN
    PRINT, FCT_NAME+': ERROR, NOT ALL REQUIRED BRDF FILES EXIST'
    RETURN,-1
  ENDIF

  RESTORE,SEN_BRDF1 ;K1_ROUJEAN
  RESTORE,SEN_BRDF2 ;K2_ROUJEAN
  RESTORE,SEN_BRDF3 ;K3_ROUJEAN
  RESTORE,SEN_UCERT ;BRDF_UCERT

;---------------------------------------
; COMPUTE NUMBER OF BIN

  DIMS=SIZE(K1_ROUJEAN)
  IF DIMS[0] EQ 1 THEN NBIN=1 ELSE NBIN=DIMS[2]

;---------------------------------------
; ARRAY TO STORE ROUJEAN COEFFICIENTS FROM BIN

  SEN_ROUJ  = MAKE_ARRAY(/FLOAT,NB_BANDS,3,VALUE=-999.0)

;----------------------------------------
; READ THE DIMITRI DATABASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING DIMITRI DATABASE'
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DB_DATA     = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

;----------------------------------------
; SELECT DATA TO BE SCREENED

  RES = WHERE(STRCMP(DB_DATA.REGION,REGION)               EQ 1 AND $
              STRCMP(DB_DATA.SENSOR,SENSOR)               EQ 1 AND $
              STRCMP(DB_DATA.PROCESSING_VERSION,PROC_VER) EQ 1 AND $
              DB_DATA.DECIMAL_YEAR GE DECIMAL_YEAR_START       AND $
              DB_DATA.DECIMAL_YEAR LE DECIMAL_YEAR_STOP        AND $ 
              DB_DATA.ROI_COVER  GE ROICOVER                   AND $
              DB_DATA.NUM_ROI_PX GE PX_THRESH)
                  
  IF RES[0] EQ -1 THEN BEGIN
    PRINT, FCT_NAME+': WARNING, NO SENSOR DATA FOUND IN DB, RETURN'
    RETURN,0
  ENDIF

;----------------------------------------
; SEARCH CORRESPONDING SENSOR TOA

  GD_I      = []
  GD_ID     = []
  AUTO_CS   = []
  MANUAL_CS = []
  FOR I = 0l, N_ELEMENTS(RES)-1 DO BEGIN
     ID = WHERE(ABS(SENSOR_L1B_REF[0,*]-DB_DATA.DECIMAL_YEAR[RES[I]]) LE TOL AND SENSOR_L1B_REF[NUM_NON_REF+BRDF_BAND,*] NE BADVAL)
     IF ID[0] GT -1 THEN BEGIN
       ; DEAL WITH DIRECTIONS AND POSSIBLE DB DOUBLONS; TAKE THE ACQUISITION WITH LOWEST VIEW ZENITH ANGLE
       IF (N_ELEMENTS(ID)) GT 1 THEN BEGIN
           TMP= MIN(SENSOR_L1B_REF[1,ID],ID_MIN)
           ID=ID[ID_MIN]
       ENDIF
       GD_I      = [GD_I, I]
       GD_ID     = [GD_ID,ID]
       AUTO_CS   = [AUTO_CS,  DB_DATA.AUTO_CS[RES[I]]]
       MANUAL_CS = [MANUAL_CS,DB_DATA.MANUAL_CS[RES[I]]]
     ENDIF
  ENDFOR
  RES=RES[GD_I]

  N_GD_ID=N_ELEMENTS(GD_ID)
  IF N_GD_ID EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, NO SENSOR DATA MATCHING THE DATABASE SELECTION, RETURN'
    RETURN, -1
  ENDIF

;---------------------------------------
; IDENTIFY BIN FOR EACH GOOD DATE

  IF NBIN EQ 1 THEN IDX_BIN = INTARR(N_GD_ID) ELSE BEGIN
    IDX_BIN = ROUND(INTERPOL(INDGEN(NBIN),REFORM(K1_ROUJEAN[0,*]),REFORM(SENSOR_L1B_REF[0,GD_ID])))
    TEMP = WHERE(IDX_BIN EQ -1)
    IF TEMP[0] NE -1 THEN IDX_BIN[TEMP]=0
    TEMP = WHERE(IDX_BIN GE NBIN)
    IF TEMP[0] NE -1 THEN IDX_BIN[TEMP]=NBIN-1
  ENDELSE

;---------------------------------------
; CREATE TOA SIMULATED REFLECTANCE ARRAY

  SEN_RHO = MAKE_ARRAY(/FLOAT,N_GD_ID)

;---------------------------------------
; LOOP OVER ALL BRDF BIN

  FOR IBIN=0, NBIN-1 DO BEGIN
  
;---------------------------------------
; STORE ROUJEAN COEFICIENTS FROM BIN

     SEN_ROUJ[*,0] = K1_ROUJEAN[NUM_NON_ROU:NUM_NON_ROU+NB_BANDS-1,IBIN]
     SEN_ROUJ[*,1] = K2_ROUJEAN[NUM_NON_ROU:NUM_NON_ROU+NB_BANDS-1,IBIN]
     SEN_ROUJ[*,2] = K3_ROUJEAN[NUM_NON_ROU:NUM_NON_ROU+NB_BANDS-1,IBIN]

;---------------------------------------
; SELECT PIXELS FROM BIN 

     IDX = WHERE(IDX_BIN EQ IBIN)
     IF IDX[0] EQ -1 THEN CONTINUE

;---------------------------------------
; COMPUTE TOA BRDF MODEL

     IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': COMPUTING TOA RHO AT BRDF BAND'
     SEN_RHO[IDX] = ROUJEAN_BRDF_COMPUTE_RHO(SZA[GD_ID[IDX]],VZA[GD_ID[IDX]],RAA[GD_ID[IDX]],[SEN_ROUJ[BRDF_BAND,0], $
                                                                                              SEN_ROUJ[BRDF_BAND,1], $
                                                                                              SEN_ROUJ[BRDF_BAND,2]],$
                                            /DEGREES,VERBOSE=VERBOSE)
  ENDFOR

;---------------------------------------
; CORRECT RHO FOR TRANSMISSION

  SEN_RHO[*]=SEN_RHO[*]*TRANS[BRDF_BAND,GD_ID]

;---------------------------------------
; COMPUTE BRDF CLOUD SCREENING

  RATIO = REFORM(SEN_RHO[*]/SENSOR_L1B_REF[NUM_NON_REF+BRDF_BAND,GD_ID])
 
  BRDF_CS = ( ABS(RATIO-1.) GT BRDF_THRESHOLD)

;---------------------------------------
; COMPUTE PERFORMANCE STATS

  ID_MANUAL       = WHERE(MANUAL_CS EQ 0 OR MANUAL_CS EQ 1, N_MANUAL)
  ID_MANUAL_CLEAR = WHERE(MANUAL_CS EQ 0, N_MANUAL_CLEAR)
  ID_MANUAL_CLOUD = WHERE(MANUAL_CS EQ 1, N_MANUAL_CLOUD)

  TMP = WHERE(MANUAL_CS EQ 0 AND AUTO_CS EQ 0,  N_AUTO_CLEAR_GD)
  TMP = WHERE(MANUAL_CS EQ 1 AND AUTO_CS GT 0., N_AUTO_CLOUD_GD)

  ID_BRDF_CLEAR_GD = WHERE(MANUAL_CS EQ 0 AND BRDF_CS EQ 0, N_BRDF_CLEAR_GD)
  ID_BRDF_CLEAR_BD = WHERE(MANUAL_CS EQ 1 AND BRDF_CS EQ 0, N_BRDF_CLEAR_BD)
  ID_BRDF_CLOUD_GD = WHERE(MANUAL_CS EQ 1 AND BRDF_CS EQ 1, N_BRDF_CLOUD_GD)
  ID_BRDF_CLOUD_BD = WHERE(MANUAL_CS EQ 0 AND BRDF_CS EQ 1, N_BRDF_CLOUD_BD)

;---------------------------------------
; WRITE PERFORMANCE STATS IN CSV OUPUT FILE

  FORMAT='(A,1h;,F5.1,1h;,F5.1)'
  OPENW, LUNCSV, OFILE_STAT_CSV,/GET_LUN
  PRINTF,LUNCSV,'          ;MANUAL_CS CLEAR;MANUAL_CS CLOUDY'
  PRINTF,LUNCSV,FORMAT=FORMAT,'AUTO_CS CLEAR',FLOAT(N_AUTO_CLEAR_GD)/N_MANUAL_CLEAR*100.,FLOAT(N_MANUAL_CLOUD-N_AUTO_CLOUD_GD)/N_MANUAL_CLOUD*100.
  PRINTF,LUNCSV,FORMAT=FORMAT,'AUTO_CS >0',FLOAT(N_MANUAL_CLEAR-N_AUTO_CLEAR_GD)/N_MANUAL_CLEAR*100.,FLOAT(N_AUTO_CLOUD_GD)/N_MANUAL_CLOUD*100.
  PRINTF,LUNCSV,FORMAT=FORMAT,'BRDF_CS CLEAR',FLOAT(N_BRDF_CLEAR_GD)/N_MANUAL_CLEAR*100.,FLOAT(N_MANUAL_CLOUD-N_BRDF_CLOUD_GD)/N_MANUAL_CLOUD*100.
  PRINTF,LUNCSV,FORMAT=FORMAT,'BRDF_CS CLOUDY',FLOAT(N_MANUAL_CLEAR-N_BRDF_CLEAR_GD)/N_MANUAL_CLEAR*100.,FLOAT(N_BRDF_CLOUD_GD)/N_MANUAL_CLOUD*100.

  CLOSE,LUNCSV

;---------------------------------------
; GET CURRENT DEVICE TYPE FOR PLOT

  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': CHANGING TO THE ZBUFFER'
  MACHINE_WINDOW = !D.NAME
  SET_PLOT, 'Z'
  DEVICE, SET_RESOLUTION=[700,400],SET_PIXEL_DEPTH=24
  ERASE
  DEVICE, DECOMPOSED = 0
  LOADCT, 39
  !P.COLOR=0

;---------------------------------------
; PLOT PERFORMANCE STATS OF AUTO_CS

  GOOD = [FLOAT(N_AUTO_CLEAR_GD)/N_MANUAL_CLEAR, FLOAT(N_AUTO_CLOUD_GD)/N_MANUAL_CLOUD]*100.
  BAD  = [FLOAT(N_MANUAL_CLEAR-N_AUTO_CLEAR_GD)/N_MANUAL_CLEAR, FLOAT(N_MANUAL_CLOUD-N_AUTO_CLOUD_GD)/N_MANUAL_CLOUD]*100.

  BAR_PLOT, [100.,100.], BACKGROUND=255, BARSPACE=0.5, COLORS=[255,255], BAROFFSET=50, TITLE='AUTO CLOUD SCREENING PERFORMANCE'
  BAR_PLOT, GOOD, BACKGROUND=255, BARSPACE=0.5, COLORS=[150.,150.],  /OUTLINE, /OVERPLOT,$
            BARNAMES=['          MANUAL CLEAR', '           MANUAL CLOUDY']
  BAR_PLOT, BAD, BARSPACE=0.5, COLORS=[240.,240.], /OVERPLOT, /OUTLINE, BAROFFSET=3.
  XYOUTS, 0.1,90, 'CORRECT',COLOR=150.
  XYOUTS, 0.1,80, 'WRONG', COLOR=240.

  TEMP = TVRD(TRUE=1)
  JPEG = STRJOIN(['AUTO_CS_PERF',REGION,SENSOR,PROC_VER],'_')+'.JPG'
  OUT_JPEG=FILEPATH(JPEG, ROOT_DIR=OUTPUT_FOLDER)
  WRITE_JPEG,OUT_JPEG,TEMP,TRUE=1,QUALITY=100
  
  ERASE

;---------------------------------------
; PLOT PERFORMANCE STATS OF BRDF_CS

  GOOD = [FLOAT(N_BRDF_CLEAR_GD)/N_MANUAL_CLEAR, FLOAT(N_BRDF_CLOUD_GD)/N_MANUAL_CLOUD]*100.
  BAD  = [FLOAT(N_MANUAL_CLEAR-N_BRDF_CLEAR_GD)/N_MANUAL_CLEAR, FLOAT(N_MANUAL_CLOUD-N_BRDF_CLOUD_GD)/N_MANUAL_CLOUD]*100.

  BAR_PLOT, [100.,100.], BACKGROUND=255, BARSPACE=0.5, COLORS=[255,255], BAROFFSET=50, TITLE='BRDF CLOUD SCREENING PERFORMANCE'
  BAR_PLOT, GOOD, BARSPACE=0.5, COLORS=[150,150], /OUTLINE, /OVERPLOT, $
          BARNAMES=['          MANUAL CLEAR', '           MANUAL CLOUDY']
  BAR_PLOT, BAD, BARSPACE=0.5, COLORS=[240,240], /OVERPLOT, /OUTLINE, BAROFFSET=3.
  XYOUTS, 0.1,90, 'CORRECT',COLOR=150.
  XYOUTS, 0.1,80, 'WRONG', COLOR=240.

  TEMP = TVRD(TRUE=1)
  JPEG = STRJOIN(['BRDF_CS_PERF',REGION,SENSOR,PROC_VER],'_')+'.JPG'
  OUT_JPEG=FILEPATH(JPEG, ROOT_DIR=OUTPUT_FOLDER)
  WRITE_JPEG,OUT_JPEG,TEMP,TRUE=1,QUALITY=100

  ERASE

;---------------------------------------
; PLOT ANALYSIS OF BRDF RATIO

  rho  ='!4q!X'

  XMIN = FIX(MIN(SENSOR_L1B_REF[0,GD_ID[ID_MANUAL]]))
  XMAX = CEIL(MAX(SENSOR_L1B_REF[0,GD_ID[ID_MANUAL]]))
  PLOT, SENSOR_L1B_REF[0,GD_ID[ID_MANUAL]], RATIO[ID_MANUAL], PSYM=4, BACKGROUND=255, XTITLE = 'DECIMAL YEAR', XRANGE=[XMIN,XMAX], $
        YTITLE = rho+'_sim/'+rho+'_obs('+STRTRIM(BRDF_WAV,2)+')', /YNOZERO
  OPLOT, [XMIN,XMAX], [1.+BRDF_THRESHOLD, 1.+BRDF_THRESHOLD], COLOR=50
  OPLOT, [XMIN,XMAX], [1.-BRDF_THRESHOLD, 1.-BRDF_THRESHOLD], COLOR=50
  IF N_MANUAL_CLEAR GT 0 THEN OPLOT, SENSOR_L1B_REF[0,GD_ID[ID_MANUAL_CLEAR]], RATIO[ID_MANUAL_CLEAR], PSYM=4, COLOR=90
  IF N_BRDF_CLOUD_BD GT 0 THEN OPLOT, SENSOR_L1B_REF[0,GD_ID[ID_BRDF_CLOUD_BD]], RATIO[ID_BRDF_CLOUD_BD], PSYM=4, COLOR=200
  IF N_BRDF_CLEAR_BD GT 0 THEN OPLOT, SENSOR_L1B_REF[0,GD_ID[ID_BRDF_CLEAR_BD]], RATIO[ID_BRDF_CLEAR_BD], PSYM=4, COLOR=240

  LEGEND,['MANUAL CLOUD AND BRDF CLOUD','MANUAL CLEAR AND BRDF CLEAR','MANUAL CLEAR AND BRDF CLOUD',$
          'MANUAL CLOUD AND BRDF CLEAR','THRESHOLD'], COLORS=[0,90,200,240,50], TEXTCOLORS=[0,90,200,240,50],PSYM=[4,4,4,4,0],$
          /RIGHT_LEGEND, /BOTTOM_LEGEND

  TEMP = TVRD(TRUE=1)
  JPEG = STRJOIN(['BRDF_CS_ANALYSIS',REGION,SENSOR,PROC_VER],'_')+'.JPG'
  OUT_JPEG=FILEPATH(JPEG, ROOT_DIR=OUTPUT_FOLDER)
  WRITE_JPEG,OUT_JPEG,TEMP,TRUE=1,QUALITY=100

;---------------------------------------
; SAVE DIMITRI DB WITH BRDF CLOUD SCREENING

  DB_ITER   = N_ELEMENTS(RES)
  DB_FORMAT = GET_DIMITRI_TEMPLATE(1,/FORMAT)
  DB_HEADER = GET_DIMITRI_TEMPLATE(1,/HDR)
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)

  POS=STRPOS(DB_HEADER,'AUTO_CS')
  STRPUT, DB_HEADER,'BRDF_CS',POS

  OPENW,DB_LUN,DB_FILE_OUT,/GET_LUN
  PRINTF,DB_LUN,DB_HEADER
  FOR DBI = 0L,DB_ITER-1 DO BEGIN
    PRINTF,DB_LUN,FORMAT=DB_FORMAT,$
      DB_DATA.DIMITRI_DATE[RES[DBI]],$
      DB_DATA.REGION[RES[DBI]],$
      DB_DATA.SENSOR[RES[DBI]],$
      DB_DATA.PROCESSING_VERSION[RES[DBI]],$
      DB_DATA.YEAR[RES[DBI]],$
      DB_DATA.MONTH[RES[DBI]],$
      DB_DATA.DAY[RES[DBI]],$
      DB_DATA.DOY[RES[DBI]],$
      DB_DATA.DECIMAL_YEAR[RES[DBI]],$
      DB_DATA.FILENAME[RES[DBI]],$
      DB_DATA.ROI_COVER[RES[DBI]],$
      DB_DATA.NUM_ROI_PX[RES[DBI]],$
      BRDF_CS[DBI],$
      DB_DATA.MANUAL_CS[RES[DBI]],$
      DB_DATA.AUX_DATA_1[RES[DBI]],$
      DB_DATA.AUX_DATA_2[RES[DBI]],$
      DB_DATA.AUX_DATA_3[RES[DBI]],$
      DB_DATA.AUX_DATA_4[RES[DBI]],$
      DB_DATA.AUX_DATA_5[RES[DBI]],$
      DB_DATA.AUX_DATA_6[RES[DBI]],$
      DB_DATA.AUX_DATA_7[RES[DBI]],$
      DB_DATA.AUX_DATA_8[RES[DBI]],$
      DB_DATA.AUX_DATA_9[RES[DBI]],$
      DB_DATA.AUX_DATA_10[RES[DBI]]
  ENDFOR
  FREE_LUN,DB_LUN

;-----------------------------------------------
; RETURN DEVISE WINDOW TO NOMINAL SETTING

  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': RESETTING DEVICE WINDOW PROPERTIES'
  SET_PLOT, MACHINE_WINDOW

;-----------------------------------------
; REMOVE TEMPORARY BRDF OUTPUTS

  IF KEYWORD_SET(CLEAN) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': REMOVE TEMPORARY BRDF OUTPUTS'
    FILE_DELETE, RC_FOLDER, /RECURSIVE
    FILE_DELETE, RB_FOLDER, /RECURSIVE
    FILE_DELETE, RB_FILE
  ENDIF


  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': SUCCESSFULL'
  RETURN, 1

END
