;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      RECALIBRATE_DOUBLETS       
;* 
;* PURPOSE:
;*      RECALIBRATES EXTRACTED DOUBLET DATA USING THE COMPUTED INTERCALIBRATION COEFICIENTS.
;*      THE ROUTINE AUTOMATICALLY RECALIBRATES ALL AVAILABLE BAND DATA WITHIN THE CAL_SENSOR.
;* 
;* CALLING SEQUENCE:
;*      RES = RECALIBRATE_DOUBLETS(OUTPUT_FOLDER,RC_REGION,REF_SENSOR,REF_PROC_VER,$
;*                                 CAL_SENSOR,CAL_PROC_VER)      
;* 
;* INPUTS:
;*      OUTPUT_FOLDER   - THE FULL PATH OF THE OUTPUT FOLDER  
;*      RC_REGION       - THE VALIDATION SITE NAME E.G. 'Uyuni'
;*      REF_SENSOR      - THE NAME OF THE REFERENCE SENSOR FOR INTERCALIBRATION
;*      REF_PROC_VER    - THE PROCESSING VERSION OF THE REFERENCE SENSOR
;*      CAL_SENSOR      - THE NAME OF THE 2ND SENSOR FOR INTERCALIBRATION
;*      CAL_PROC_VER    - THE PROCESSING VERSION OF THE 2ND SENSOR
;*      VZA_MIN         - THE MINIMUM VIEWING ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      VZA_MAX         - THE MAXIMUM VIEWING ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      VAA_MIN         - THE MINIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      VAA_MAX         - THE MAXIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      SZA_MIN         - THE MINIMUM SOLAR ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      SZA_MAX         - THE MAXIMUM SOLAR ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      SAA_MIN         - THE MINIMUM SOLAR AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      SAA_MAX         - THE MAXIMUM SOLAR AZIMTUH ANGLE ALLOWED FOR AN OBSERVATION
;*
;* KEYWORDS:
;*      VERBOSE         - PROCESSING STATUS OUTPUTS
;*      SADE1           - THE FULL PATH NAME OF THE CEOS IVOS SADE DATA FILE FOR SENSOR1
;*      SADE2           - THE FULL PATH NAME OF THE CEOS IVOS SADE DATA FILE FOR SENSOR2
;*
;* OUTPUTS:
;*      STATUS          - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*                    - M BOUVET  - PROTOTYPE DIMITRI VERSION
;*        21 JAN 2011 - C KENT    - DIMITRI-2 V1.0
;*        01 APR 2011 - C KENT    - ADDED ROI/CLOUD COVERAGE PARAMETERS AND APPLICATION 
;*                                  OF POLYNOMIAL FIT TO ORIGINAL CAL DATA
;*        26 APR 2011 - C KENT    - ADDED UNCERTAINTY PROPAGATION AND OUTPUT
;*        30 JUN 2011 - C KENT    - UPDATED CLOUD SCREENING TO CHECK FOR SUSPECT PRODUCTS
;*        02 JUL 2011 - C KENT    - ADDED ABSOLUTE ANGULAR CRITERIA
;*        04 JUL 2011 - C KENT    - UPDATED SAV FILES TO INCLUDE AUX DATA
;*        05 JUL 2011 - C KENT    - ADDED MODISA SURFACE DEPENDANCE
;*        15 AUG 2011 - C KENT    - CHANGED PIXEL THRESHOLD TO AN INTEGER
;*        11 JAN 2012 - C KENT    - ADDED CEOS IVOS SADE FILE HANDLING
;*        17 JAN 2012 - C KENT    - UPDATED SADE FILE PROCESSING
;*        08 MAR 2012 - C KENT    - UPDATED DATABASE/SAV FILE TIME MATCHING TO +-20 MINUTES
;*        09 MAR 2012 - C KENT    - ADDED ROI COVER CHECK
;*
;* VALIDATION HISTORY:
;*        13 APR 2011 - C KENT    - WINDOWS 32-BIT MACHINE IDL 8.0 AND LINUX 64-BIT MACHINE 
;*                                  IDL 8.0, NOMINAL COMPILATION AND OPERATION. TESTED FOR 
;*                                  MERIS VS MERIS AND MERIS VS MODIS 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION RECALIBRATE_DOUBLETS,OUTPUT_FOLDER,RC_REGION,REF_SENSOR,REF_PROC_VER,$
                              CAL_SENSOR,CAL_PROC_VER,CLOUD_PERCENTAGE,ROI_PERCENTAGE,$
                              VZA_MIN,VZA_MAX,VAA_MIN,VAA_MAX,SZA_MIN,SZA_MAX,SAA_MIN,SAA_MAX,VERBOSE=VERBOSE,$
                              SADE1=SADE1,SADE2=SADE2

;----------------------------------------- 
; CHECK INPUT SENSORS AND PROC_VERSIONS 

  IF STRCMP(REF_SENSOR,CAL_SENSOR) EQ 1 AND $
     STRCMP(REF_PROC_VER,CAL_PROC_VER) EQ 1 THEN BEGIN
    PRINT, 'RECALIBRATE_DATA: ERROR, TRYING TO COMPARE THE SAME DATA'
    RETURN,0     
  ENDIF
  
;-----------------------------------------
; CHECK OFOLDER EXISTS AND IS CORRECT FORMAT
  
  RES = FILE_INFO(OUTPUT_FOLDER)
  IF RES.EXISTS EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,"RECALIBRATE_DATA: OUTPUT FOLDER DOESN'T EXIST"
    RETURN,-1
  ENDIF
  
;-----------------------------------------
; DEFINE INPUT/OUTPUT FILES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: DEFINING INPUT/OUTPUT FILES'
  CFIG_DATA     = GET_DIMITRI_CONFIGURATION()
  SITE_FILE     = GET_DIMITRI_LOCATION('SITE_DATA')
  DB_FILE       = GET_DIMITRI_LOCATION('DATABASE')
  DL            = GET_DIMITRI_LOCATION('DL')
  MAIN_DIRC     = GET_DIMITRI_LOCATION('DIMITRI')
  
  ED_FOLDER     = STRING(OUTPUT_FOLDER+DL+'DOUBLET_EXTRACTION'+DL)
  IC_FOLDER     = STRING(OUTPUT_FOLDER+DL+'INTERCALIBRATION'+DL)
  RC_FOLDER     = STRING(OUTPUT_FOLDER+DL+'RECALIBRATION'+DL)
  RC_LOG        = STRING(RC_FOLDER+DL+'RECALIBRATION_LOG.txt')
  REF_IFILE     = STRING(MAIN_DIRC+'Input'+DL+'Site_'+RC_REGION+DL+REF_SENSOR+DL+'Proc_'+REF_PROC_VER+DL+REF_SENSOR+'_TOA_REF.dat')
  CAL_IFILE     = STRING(MAIN_DIRC+'Input'+DL+'Site_'+RC_REGION+DL+CAL_SENSOR+DL+'Proc_'+CAL_PROC_VER+DL+CAL_SENSOR+'_TOA_REF.dat')
  TMP_IFILE     = STRING(IC_FOLDER+       'ICOEF_'+    RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_')
  UCT_FILE      = STRING(IC_FOLDER+       'IUCRT_'+    RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_')
  CSV_FILE      = STRING(OUTPUT_FOLDER+DL+'RCAL_' +    RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_REF_'+REF_SENSOR+'_'+REF_PROC_VER+'.csv')  
  ED_REFS_CALS  = STRING(ED_FOLDER+       'ED_'+       RC_REGION+'_'+REF_SENSOR+'_'+REF_PROC_VER+'_'+    CAL_SENSOR+'_'+CAL_PROC_VER+'.dat')
  ED_CALS_REFS  = STRING(ED_FOLDER+       'ED_'+       RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_'+    REF_SENSOR+'_'+REF_PROC_VER+'.dat')
  OFILE_CAL     = STRING(RC_FOLDER+       'RECAL_'+    RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_REF_'+REF_SENSOR+'_'+REF_PROC_VER+'.dat')
  OFILE_REF     = STRING(RC_FOLDER+       'RECAL_REF_'+RC_REGION+'_'+REF_SENSOR+'_'+REF_PROC_VER+'.dat')
  OFILE_CAL_UCT = STRING(RC_FOLDER+       'RECAL_'+    RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_UCERT.dat')
  OFILE_REF_UCT = STRING(RC_FOLDER+       'RECAL_REF_'+RC_REGION+'_'+REF_SENSOR+'_'+REF_PROC_VER+'_UCERT.dat')
  OFILE_UCT_CSV = STRING(OUTPUT_FOLDER+DL+'RCAL_' +    RC_REGION+'_'+CAL_SENSOR+'_'+CAL_PROC_VER+'_REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_UCERT.csv')
  
;-----------------------------------------
; RETRIEVE THE SITE TYPE

  SITE_TYPE = GET_SITE_TYPE(RC_REGION,VERBOSE=VERBOSE)  
  
;-----------------------------------------
; CREATE RECALIBRATION FOLDER IF IT 
; DOESN'T EXIST

  RES = FILE_INFO(RC_FOLDER)
  IF RES.EXISTS NE 1 OR RES.DIRECTORY NE 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,"RECALIBRATE_DATA: RECALIBRATION FOLDER DOESN'T EXIST, CREATING"
    FILE_MKDIR,RC_FOLDER 
  ENDIF
  
;-----------------------------------------
; DEFINE SENSOR AND PROC_VERSION ARRAYS

  SENS = [REF_SENSOR,CAL_SENSOR,CAL_SENSOR]
  PVER = [REF_PROC_VER,CAL_PROC_VER,CAL_PROC_VER]  

;-----------------------------------------
; SET SENSOR RANDOM UNCFERTAINTY AT 5% 
; (IDEALLY SHOULD BE DERIVED FROM EARLIER)

  SEN_UNCERTR = 0.03
  SEN_UNCERTS = 0.03

;-----------------------------------------
; CHECKS OFFSET AND PERCENTAGES ARE OK

  CP_LIMIT          = FLOAT(CLOUD_PERCENTAGE)
  RP_LIMIT          = FLOAT(ROI_PERCENTAGE)
  NUM_NON_REF       = 5+12 ; TIME, ANGLES (4) AND AUX INFO (12)

  IF  CP_LIMIT  GT 1.0 OR CP_LIMIT  LT 0.0 OR $
      RP_LIMIT  GT 1.0 OR RP_LIMIT  LT 0.0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR, CLOUD/ROI PERCENTAGES OUT OF RANGE'
    RETURN,-1
  ENDIF

;-----------------------------------------
; COMPUTE ROI AREA IN KM^2

  IF KEYWORD_SET(SADE1) OR KEYWORD_SET(SADE2) THEN GOTO, RC_SADE_IN
  ICOORDS = GET_SITE_COORDINATES(RC_REGION,SITE_FILE,VERBOSE=VERBOSE)
  
  IF ICOORDS[0] EQ -1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: ERROR, REGION COORDINATES NOT FOUND'
    RETURN,-1
  ENDIF
  
  ROI_X     = GREAT_CIRCLE_DISTANCE(ICOORDS[0],ICOORDS[2],ICOORDS[0],ICOORDS[3],/DEGREES,VERBOSE=VERBOSE)
  ROI_Y     = GREAT_CIRCLE_DISTANCE(ICOORDS[0],ICOORDS[2],ICOORDS[1],ICOORDS[2],/DEGREES,VERBOSE=VERBOSE)
  ROI_AREA  = FLOAT(ROI_X)*FLOAT(ROI_Y)
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: COMPUTED ROI AREA = ',ROI_AREA

;-----------------------------------------
; GET PIXEL AREA RESOLUTIONS OF SENSORS

  SPX_AREA    = MAKE_ARRAY(2,/FLOAT)
  SPX_AREA[0] = SENSOR_PIXEL_SIZE(REF_SENSOR,/AREA,VERBOSE=VERBOSE)
  SPX_AREA[1] = SENSOR_PIXEL_SIZE(CAL_SENSOR,/AREA,VERBOSE=VERBOSE)
  
;-----------------------------------------
; DEFINE ROI PIX THRESHOLD FOR EACH SENSOR

  PX_THRESH     = MAKE_ARRAY(2,/INTEGER)
  PX_THRESH[0]  = FLOOR(DOUBLE(RP_LIMIT*ROI_AREA)/DOUBLE(SPX_AREA[0]))
  PX_THRESH[1]  = FLOOR(DOUBLE(RP_LIMIT*ROI_AREA)/DOUBLE(SPX_AREA[1]))
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: COMPUTED PX_THRESHOLDS = ',PX_THRESH

;-----------------------------------------
; ROICOVERAGE CHECK

  IF RP_LIMIT GE 1.0 THEN BEGIN
    ROICOVER = 1
    PX_THRESH[*] = 1  
  ENDIF ELSE ROICOVER = 0

;----------------------------------------
; READ THE DIMITRI DATABASE

  TEMP = FILE_INFO(DB_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR, DIMITRI DATABASE FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: READING DIMITRI DATABASE'
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DB_DATA     = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

;----------------------------------------
; RESTORE THE SENSOR TOA DATA

  IF FILE_TEST(REF_IFILE) EQ 0 OR $
     FILE_TEST(CAL_IFILE) EQ 0 THEN BEGIN
     
     IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR, INPUT DATA NOT FOUND'
     RETURN,0
  ENDIF
       
  RESTORE,REF_IFILE
  S1_ADATA = SENSOR_L1B_REF
  RESTORE,CAL_IFILE
  S2_ADATA = SENSOR_L1B_REF 
  SENSOR_L1B_REF=0

;----------------------------------------
; LOOP OVER BOTH SENSORS TO EXTRACT DATA 
; WITHIN CLOUD/ROI PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: STARTING LOOP OVER BOTH SENSORS DATA'
  FOR RCALS = 0,1 DO BEGIN
  
;----------------------------------------  
; SET ALL DATA VARIABLE  
  
    IF RCALS EQ 0 THEN SENSOR_ALL_DATA = S1_ADATA
    IF RCALS EQ 1 THEN SENSOR_ALL_DATA = S2_ADATA
  
    RES = WHERE(STRCMP(DB_DATA.SITE_NAME,RC_REGION)                EQ 1 AND $
                STRCMP(DB_DATA.SENSOR,SENS[RCALS])              EQ 1 AND $
                STRCMP(DB_DATA.PROCESSING_VERSION,PVER[RCALS])  EQ 1 AND $
                DB_DATA.ROI_STATUS  GE ROICOVER                       AND $
                DB_DATA.ROI_PIX_NUM GE PX_THRESH[RCALS])            

    IF RES[0] EQ -1 THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR, NO SENSOR DATA FOUND WITHIN PIXEL THRESHOLD'  
      RETURN,-1
    ENDIF
    
;----------------------------------------
; GET A LIST OF DATES IN WHICH DATA IS ALSO 
; WITHIN THE CLOUD PERCENTAGE 

    GD_DATE = 0.0
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: STARTING LOOP OVER GOOD DATES FOR CLOUD PERCENTAGE'  
    FOR I_CS=0,N_ELEMENTS(RES)-1 DO BEGIN
    
      IF DB_DATA.MANUAL_CS[RES[I_CS]] GE 1.0 THEN CONTINUE
      IF DB_DATA.MANUAL_CS[RES[I_CS]] EQ 0.0 THEN BEGIN
        GD_DATE = [GD_DATE,DB_DATA.DECIMAL_YEAR[RES[I_CS]]]
        CONTINUE
      ENDIF  
    ;---------------------
    ; IF AUTO_CS IS LESS THAN PERCENTAGE BUT GREATER THAN -1.0 STORE DECIMAL DATE 
      
      IF DB_DATA.AUTO_CS[RES[I_CS]] LE CP_LIMIT AND DB_DATA.AUTO_CS[RES[I_CS]] GT -1.0 THEN $
      GD_DATE = [GD_DATE,DB_DATA.DECIMAL_YEAR[RES[I_CS]]]

    ENDFOR;END OF LOOP ON GOOD DATES

    IF N_ELEMENTS(GD_DATE) EQ 1 THEN BEGIN
       IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR, NO SENSOR DATA FOUND WITHIN CLOUD THRESHOLD'
       RETURN,-1
    ENDIF

;---------------------------------------
; EXTRACT GOOD DECIMAL DATES AND CORRESPONDING 
; INDEX IN ALL DATA VARIABLE    
  
    GD_DATE = GD_DATE[1:N_ELEMENTS(GD_DATE)-1]
    GD_IDX = MAKE_ARRAY(N_ELEMENTS(SENSOR_ALL_DATA[0,*]),/INTEGER,VALUE=0)
    TOL=0.00004
    FOR GD=0,N_ELEMENTS(GD_DATE)-1 DO BEGIN
      RES = WHERE(ABS(SENSOR_ALL_DATA[0,*]-GD_DATE[GD]) LE TOL AND $ 
                  SENSOR_ALL_DATA[NUM_NON_REF,*] GT 0.0        AND $
                  SENSOR_ALL_DATA[NUM_NON_REF,*] LT 5.0        AND $
                  SENSOR_ALL_DATA[1,*] GT VZA_MIN              AND $
                  SENSOR_ALL_DATA[1,*] LT VZA_MAX              AND $
                  SENSOR_ALL_DATA[2,*] GT VAA_MIN              AND $
                  SENSOR_ALL_DATA[2,*] LT VAA_MAX              AND $                
                  SENSOR_ALL_DATA[3,*] GT SZA_MIN              AND $
                  SENSOR_ALL_DATA[3,*] LT SZA_MAX              AND $
                  SENSOR_ALL_DATA[4,*] GT SAA_MIN              AND $
                  SENSOR_ALL_DATA[4,*] LT SAA_MAX              )
     
      IF RES[0] GT -1 THEN GD_IDX[RES]=1
    ENDFOR ;END OF LOOP ON GOOD DATES TO FIND INDEX IN ALL_DATA ARRAY

;---------------------------------------
; DEFINE FINAL VARIABLES WHICH CONTAIN THE 
; ACCEPTABLE DATA

    RES = WHERE(GD_IDX EQ 1)
    IF RES[0] GT -1 THEN BEGIN
      IF RCALS EQ 0 THEN GD_REF_DATA = SENSOR_ALL_DATA[*,RES]
      IF RCALS EQ 1 THEN GD_CAL_DATA = SENSOR_ALL_DATA[*,RES]
    ENDIF ELSE BEGIN
      IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR DURING DOUBLET EXTRACTION, NO GOOD DATES FOUND FOR SENSOR ',SENS[RCALS]
      RETURN,-1
    ENDELSE
  ENDFOR ;END OF LOOP ON SENSOR1 AND SENSOR2 FILTERING
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: COMPLETED LOOP ON GOOD DATES FOR CLOUD TESTING'

;-----------------------------------------
; RELEASE UNEEDED MEMORY

  S1_ADATA=0
  S2_ADATA=0

;----------------------------------------
; CEOS IVOS SADE INPUT FILES

  RC_SADE_IN:
  IF KEYWORD_SET(SADE1) THEN BEGIN
;---------------------------------------  
; LOAD THE SADE DATA
  
  SENSOR_TOA_REF = CONVERT_SADE_TO_DIMITRI(SADE1,REF_SENSOR)
  RES = WHERE(SENSOR_TOA_REF[1,*] GT VZA_MIN              AND $
              SENSOR_TOA_REF[1,*] LT VZA_MAX              AND $
              SENSOR_TOA_REF[2,*] GT VAA_MIN              AND $
              SENSOR_TOA_REF[2,*] LT VAA_MAX              AND $                
              SENSOR_TOA_REF[3,*] GT SZA_MIN              AND $
              SENSOR_TOA_REF[3,*] LT SZA_MAX              AND $
              SENSOR_TOA_REF[4,*] GT SAA_MIN              AND $
              SENSOR_TOA_REF[4,*] LT SAA_MAX              ,COUNT)
  IF COUNT GT 0 THEN SENSOR_TOA_REF=SENSOR_TOA_REF[*,RES]

;---------------------------------------  
; OVER WRITE THE SENSOR DATA

  IDX = WHERE(SENSOR_TOA_REF[0,*] GT 0.)
  IF N_ELEMENTS(IDX) LT 2 THEN BEGIN
    PRINT,'RECALIBRATE_DATA:ERROR NO MATCHING SADE DATA FOR ANGLE CRITERA'
    RETURN,-3
  ENDIF
  GD_REF_DATA = SENSOR_TOA_REF[*,idx] 
  SENSOR_TOA_REF = 0 
  ENDIF
  
  IF KEYWORD_SET(SADE2) THEN BEGIN
;---------------------------------------  
; LOAD THE SADE DATA
  
  SENSOR_TOA_REF = CONVERT_SADE_TO_DIMITRI(SADE2,CAL_SENSOR)
  RES = WHERE(SENSOR_TOA_REF[1,*] GT VZA_MIN              AND $
              SENSOR_TOA_REF[1,*] LT VZA_MAX              AND $
              SENSOR_TOA_REF[2,*] GT VAA_MIN              AND $
              SENSOR_TOA_REF[2,*] LT VAA_MAX              AND $                
              SENSOR_TOA_REF[3,*] GT SZA_MIN              AND $
              SENSOR_TOA_REF[3,*] LT SZA_MAX              AND $
              SENSOR_TOA_REF[4,*] GT SAA_MIN              AND $
              SENSOR_TOA_REF[4,*] LT SAA_MAX              ,COUNT)
  IF COUNT GT 0 THEN SENSOR_TOA_REF=SENSOR_TOA_REF[*,RES]

;---------------------------------------  
; OVER WRITE THE SENSOR DATA

  IDX = WHERE(SENSOR_TOA_REF[0,*] GT 0.)
  IF N_ELEMENTS(IDX) LT 2 THEN BEGIN
    PRINT,'RECALIBRATE_DATA:ERROR NO MATCHING SADE DATA FOR ANGLE CRITERA'
    RETURN,-3
  ENDIF
  GD_CAL_DATA = SENSOR_TOA_REF[*,idx] 
  SENSOR_TOA_REF = 0 
ENDIF

;-----------------------------------------
; RECORD THIS PROCESSING REQUEST IN A LOG

  TMP_DATE = SYSTIME()
  TMP_DATE = STRING(STRMID(TMP_DATE,8,2)+'-'+STRMID(TMP_DATE,4,3)+'-'+STRMID(TMP_DATE,20,4))
  TEMP = FILE_INFO(RC_LOG)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    OPENW, DLOG,RC_LOG,/GET_LUN
    PRINTF,DLOG,'DATE;REGION;REF_SENSOR;REF_PROC_VER;CAL_SENSOR;CAL_PROC_VER;CLOUD_PERCENTAGE;ROI_PERCENTAGE'
  ENDIF ELSE OPENW,DLOG,RC_LOG,/GET_LUN,/APPEND

  PRINTF,DLOG,FORMAT='(6(A,1H;),1(F6.3,1H;),1(F6.3))',$
  TMP_DATE,RC_REGION,REF_SENSOR,REF_PROC_VER,CAL_SENSOR,CAL_PROC_VER,CP_LIMIT,RP_LIMIT

;----------------------------------------
; CLOSE LOG AND RELEASE THE LUN

  FREE_LUN,DLOG

;----------------------------------------- 
; GET NUMBER OF BANDS WITHIN CAL_SENSOR 
; AND REF_SENSOR

  SIZE_CAL    = SIZE(GD_CAL_DATA)
  SIZE_REF    = SIZE(GD_REF_DATA)
  NBANDS_CAL  = (SIZE_CAL[1]-NUM_NON_REF)/2
  NBANDS_REF  = (SIZE_REF[1]-NUM_NON_REF)/2
  CAL_COUNTER = 0

  CAL_DATA = GD_CAL_DATA
  CAL_DATA[NUM_NON_REF:NUM_NON_REF+2*NBANDS_CAL-1,*] = -999.0

;-----------------------------------------
; SET ANY ERRONEOUS REFLECTANCE VALUES AS -999 IN REF SENSOR ARRAY

  FOR IBAND = 0,NBANDS_REF-1 DO BEGIN
    RES = WHERE(GD_REF_DATA[NUM_NON_REF+IBAND,*] LT 0.0 OR GD_REF_DATA[NUM_NON_REF+IBAND,*] GT 5.0,VCOUNT)
    IF VCOUNT GT 0 THEN BEGIN
      GD_REF_DATA[NUM_NON_REF+IBAND,RES] = -999.0
      GD_REF_DATA[NUM_NON_REF+NBANDS_REF+IBAND,RES] = -999.0
    ENDIF
  ENDFOR

;-----------------------------------------
; SORT REF AND CAL SENSOR UNCERTAINTY

  REF_DATA_UCT = MAKE_ARRAY(4,NBANDS_REF,/DOUBLE,VALUE=-1.0)
  FOR IDX=0,NBANDS_REF-1 DO BEGIN
    REF_DATA_UCT[0,IDX]= 0
    REF_DATA_UCT[1,IDX]= SEN_UNCERTS
    REF_DATA_UCT[2,IDX]= SEN_UNCERTR
    REF_DATA_UCT[3,IDX]= 0
  ENDFOR

  CAL_DATA_UCT = MAKE_ARRAY(4,NBANDS_CAL,/DOUBLE,VALUE=-1.0)
  FOR IDX=0,NBANDS_CAL-1 DO BEGIN
    CAL_DATA_UCT[0,IDX]= 0
    CAL_DATA_UCT[1,IDX]= SEN_UNCERTS
    CAL_DATA_UCT[2,IDX]= SEN_UNCERTR
    CAL_DATA_UCT[3,IDX]= 0
  ENDFOR

;-----------------------------------------
; DEFINE RECAL CAL SENSOR UNCERTAINTY ARRAY

  RCAL_DATA_UCT = MAKE_ARRAY(4,NBANDS_CAL,/DOUBLE,VALUE=-1.0)

;-----------------------------------------
; MODISA SURFACE DEPENDANCE EXCEPTION

    IF CAL_SENSOR EQ 'MODISA' THEN BEGIN
      IF STRUPCASE(SITE_TYPE) EQ 'OCEAN' THEN TEMP_SENSOR = CAL_SENSOR+'_O' ELSE TEMP_SENSOR = CAL_SENSOR+'_L'
    ENDIF ELSE TEMP_SENSOR = CAL_SENSOR

    IF REF_SENSOR EQ 'MODISA' THEN BEGIN
      IF STRUPCASE(SITE_TYPE) EQ 'OCEAN' THEN TEMPR_SENSOR = REF_SENSOR+'_O' ELSE TEMPR_SENSOR = REF_SENSOR+'_L'
    ENDIF ELSE TEMPR_SENSOR = REF_SENSOR

;-----------------------------------------
; LOOP OVER EACH CAL_SENSOR BAND AND 
; RECALIBRATE IF COEFICIENTS COMPUTED
 
  FOR RC_BAND=0,NBANDS_CAL-1 DO BEGIN

;-----------------------------------------  
; GET DIMITRI WAVELENGTH STRING AND 
; FIND CALIBRATION COEFICIENTS

    TEMPB = CONVERT_INDEX_TO_WAVELENGTH(RC_BAND,TEMP_SENSOR,VERBOSE=verbose)
    IF STRUPCASE(TEMPB) EQ 'ERROR' THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: ERROR FINDING WAVELENGTH STRING, GOING TO NEXT BAND'
      GOTO,NEXT_BAND
    ENDIF
    TEMP = STRING(TMP_IFILE+TEMPB+'.dat')
    RES  = FILE_INFO(TEMP)
    IF RES.EXISTS EQ 0 THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: NO CALIBRATION COEFICIENTS FOUND, GOING TO NEXT BAND'
      GOTO,NEXT_BAND
    ENDIF

;----------------------------------------- 
; SEARCH FOR UNCERTAINTY FILE,  RESTORE AND STORE DATA

    UCT_IFILE = STRING(UCT_FILE+TEMPb+'.dat')
    UCT_RES   = FILE_INFO(UCT_IFILE)
    IF RES.EXISTS EQ 1 THEN BEGIN
      RESTORE,UCT_IFILE
      RCAL_DATA_UCT[1:3,RC_BAND] = UNCERT_ARRAY
      RCAL_DATA_UCT[0,RC_BAND] = 0
    ENDIF

;----------------------------------------- 
; RESTORE CALIBRATION COEFICIENTS AND APPLY

    RESTORE,TEMP
    BIAS                             = POLY_COEFS[0]+CAL_DATA[0,*]*POLY_COEFS[1]+ $
                                       (CAL_DATA[0,*])^2*POLY_COEFS[2]
    CAL_DATA[NUM_NON_REF+RC_BAND,*]  = GD_CAL_DATA[NUM_NON_REF+RC_BAND, *]*(1.0-BIAS/100.0)
    CAL_DATA[NUM_NON_REF+NBANDS_CAL+RC_BAND,*] = GD_CAL_DATA[NUM_NON_REF+NBANDS_CAL+RC_BAND,*]
    
    RES = WHERE(CAL_DATA[NUM_NON_REF+RC_BAND,*] LT 0.0 OR CAL_DATA[NUM_NON_REF+RC_BAND,*] GT 5.0,VCOUNT)
    IF VCOUNT GT 0 THEN BEGIN
      CAL_DATA[NUM_NON_REF+RC_BAND,RES] = -999.0
      CAL_DATA[NUM_NON_REF+NBANDS_CAL+RC_BAND,RES] = -999.0
    ENDIF
        
    CAL_COUNTER++
    NEXT_BAND:
  ENDFOR
  IF CAL_COUNTER EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RECALIBRATE_DATA: ERROR, NO INTERCAL COEFICIENTS FOUND'
    RETURN,0
  ENDIF

;---------------------------------------- 
; SAVE THE REFLECTANCE DATA AS SAV FILES

  SAVE,GD_REF_DATA,     FILENAME=OFILE_REF
  SAVE,CAL_DATA,        FILENAME=OFILE_CAL

;---------------------------------------- 
; SAVE THE UNCERTAINTIES

  SAVE,REF_DATA_UCT,    FILENAME=OFILE_REF_UCT
  SAVE,RCAL_DATA_UCT,   FILENAME=OFILE_CAL_UCT

;---------------------------------------- 
; CREATE AN OUTPUT CSV FILE CONTAINING ALL DATA 
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: SAVING DATA AS A CSV FILE'
  HEADER = ['REGION','SENSOR','PROCESSING_VERSION','PARAMETER']
  HEADER2 = [HEADER,'SYS_ERROR','RAN_ERROR','POLY_FLAG']
  TMP_HD = ['TIME','VZA','VAA','SZA','SAA','OZONE_MU','OZONE_SD','PRESSURE_MU','PRESSURE_SD','HUMIDITY_MU','HUMIDITY_SD', $
            'WIND_ZONAL_MU','WIND_ZONAL_SD','WIND_MERID_MU','WIND_MERID_SD','WVAP_MU','WVAP_SD'                           ]
  FORMAT = STRING('(3(A,1H;),1(A))')
  FORMAT2 = STRING('(6(A,1H;),1(A))')
  
  OPENW,OUTF,CSV_FILE,/GET_LUN
  PRINTF,OUTF,FORMAT=FORMAT,HEADER
  
  OPENW,OUTG,OFILE_UCT_CSV,/GET_LUN
  PRINTF,OUTG,FORMAT=FORMAT2,HEADER2
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: STARTING LOOP TO OUTPUT SENSOR DATA TO CSV, ',$
    'OUTPUTTING REF DATA, CAL DATA AND RECAL DATA FOR SELECTED PARMATERS'  
  FOR RCS=0,2 DO BEGIN
    CASE RCS OF
    0:BEGIN
        DATA = GD_REF_DATA  
        TMP_BANDS = NBANDS_REF
        UCT_DATA = REF_DATA_UCT
        TSENS = REF_SENSOR
      END
    1:BEGIN
        DATA = GD_CAL_DATA  
        TMP_BANDS = NBANDS_CAL
        UCT_DATA = CAL_DATA_UCT
        TSENS = CAL_SENSOR
      END
    2:BEGIN
        DATA = CAL_DATA
        TMP_BANDS = NBANDS_CAL
        UCT_DATA = RCAL_DATA_UCT
        TSENS = CAL_SENSOR
      END
    ENDCASE
    
    NTIME       = N_ELEMENTS(DATA[0,*])
    FORMAT      = STRING('(4(A,1H;),'+STRTRIM(STRING(NTIME-1),2)+'(F15.6,1H;),(F15.6))')
    BAND_NAMES  = [INDGEN(TMP_BANDS),INDGEN(TMP_BANDS)]

    COUNTER = 0
    FOR RCB=0,2*TMP_BANDS+NUM_NON_REF-1 DO BEGIN
      IF RCB LE NUM_NON_REF-1 THEN BEGIN
        IF RCS EQ 2 THEN PRINTF,OUTF,FORMAT=FORMAT,RC_REGION,SENS[RCS],PVER[RCS],STRING('RECAL_'+TMP_HD[RCB]),DATA[RCB,*] $
        ELSE PRINTF,OUTF,FORMAT=FORMAT,RC_REGION,SENS[RCS],PVER[RCS],TMP_HD[RCB],DATA[RCB,*]
      ENDIF ELSE BEGIN
        TBAND = CONVERT_INDEX_TO_WAVELENGTH(BAND_NAMES[COUNTER],TSENS)
        TBAND = GET_SENSOR_BAND_NAME(TSENS,BAND_NAMES[COUNTER])
        IF STRUPCASE(TBAND) EQ 'ERROR' THEN GOTO,SKIP_OCSV
        IF COUNTER LT TMP_BANDS THEN TBAND = 'TOA_REF_'+TBAND+'_NM' ELSE TBAND = 'TOA_STD_'+TBAND+'_NM'
        IF RCS EQ 2 THEN begin
        PRINTF,OUTF,FORMAT=FORMAT,RC_REGION,SENS[RCS],PVER[RCS],'RECAL_'+TBAND,DATA[NUM_NON_REF+COUNTER,*]
        IF COUNTER LT TMP_BANDS THEN PRINTF,OUTG,FORMAT=FORMAT2,RC_REGION,SENS[RCS],PVER[RCS],'RECAL_'+TBAND,UCT_DATA[1:3,COUNTER]  
        ENDIF ELSE BEGIN
        PRINTF,OUTF,FORMAT=FORMAT,RC_REGION,SENS[RCS],PVER[RCS],TBAND,DATA[NUM_NON_REF+COUNTER,*]
        IF COUNTER LT TMP_BANDS THEN PRINTF,OUTG,FORMAT=FORMAT2,RC_REGION,SENS[RCS],PVER[RCS],TBAND,UCT_DATA[1:3,COUNTER]
        ENDELSE

        SKIP_OCSV:
        COUNTER++   
      ENDELSE
    ENDFOR
  ENDFOR
  
  FREE_LUN,OUTF 
  FREE_LUN,OUTG
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RECALIBRATE_DATA: SUCCESSFULLY RECALIBRATED DATA'    
  RETURN,1

END