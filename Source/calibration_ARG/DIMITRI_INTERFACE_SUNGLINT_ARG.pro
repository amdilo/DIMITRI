;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_INTERFACE_SUNGLINT_ARG
;* 
;* PURPOSE:
;*      APPLY GLINT VICARIOUS INTERBAND CALIBRATION FOLLOWING HAGOLLE ET AL 1999.
;*      CALIBRATION FACTOR "AK" ARE COMPUTED FROM A REFERENCE BAND (GENERALLY 560 OR 620 NM)
;* 
;* CALLING SEQUENCE:
;*      RES = DIMITRI_INTERFACE_SUNGLINT_ARG(OUTPUT_FOLDER,SITE_NAME,SENSOR,PROC_VERSION, $
;*		   	       YEAR, CLOUD_PERCENTAGE, ROI_PERCENTAGE, WS_MAX, CONE_MAX, BREF, ABS_CALREF, CHL, AER)
;* 
;* INPUTS:
;*      OUTPUT_FOLDER    - THE FULL PATH OF THE OUTPUT FOLDER
;*      SITE_NAME       - THE VALIDATION SITE NAME E.G. 'Uyuni'
;*      SENSOR       - THE NAME OF THE REFERENCE SENSOR FOR INTERCALIBRATION
;*      PROC_VERSION     - THE PROCESSING VERSION OF THE REFERENCE SENSOR
;*      YEAR             - THE YEAR E.G. 2003 OR 'ALL'
;*	CLOUD_PERCENTAGE - THE PERCENTAGE CLOUD COVER THRESHOLD ALLOWED WITHIN PRODUCTS E.G. 60.0
;*	ROI_PERCENTAGE   - THE PERCENTAGE ROI COVERAGE ALLOWED WITHIN PRODUCTS E.G. 75.0 
;*	WS_MAX           - THE MAXIMUM WIND SPEED IN M/S ALLOWED FOR AN OBSERVATION E.G. 5.0 
;*	CONE_MAX         - THE MAXIMUM ANGLE IN DEGREE AROUND THE SPECULAR DIRECTION E.G. 3.0 
;*	BREF             - THE REFERENCE BAND INDEX FOR CHOSEN SENSOR E.G. 5
;*	ABS_CALREF       - THE ABSOLUTE CALIBRATION COEFFICIENT AT BREF E.G. 1.01 
;*	CHL              - THE CHLOROPHYLL CONCENTRATION IN MG/M3 E.G. 0.035 
;*	TAUA_865_CLIM    - THE AEROSOL OPTICAL THICKNESS AT 865 NM FROM A CLIMATOLOGY E.G. 0.1
;*	AER              - THE AEROSOL NAME IN RTM FILE E.G. IAER_1
;*
;* KEYWORDS:
;*      CLIM            - OPTION TO READ CHL CLIMATOLOGY
;*      VERBOSE         - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS          - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - FIRST IMPLEMENTATION
;*        02 JAN 2014 - C MAZERAN - ADDED CORRECTION FOR PRESSURE AND PIXEL-BY-PIXEL CLOUD SCREENING
;*        20 JAN 2014 - C MAZERAN - ADDED SPECTRAL REFRACTIVE INDEX FOR FRESNEL REFLECTANCE
;*        16 MAR 2015 - NCG / MAGELLIUM - UPDATED WITH NCDF INPUT/OUTPUT INTERFACES 
;*                                  AND LOOPS ON PRODUCTS/VIEWING DIRECTIONS (DIMITRI V4)
;*        13 APR 2015 - NCG / MAGELLIUM - REMOVE USE OF CLIM FILES (files under AUX_DATA/marine folder)
;*
;* VALIDATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - LINUX 64-BIT MACHINE IDL 8.0, NOMINAL COMPILATION AND OPERATION.
;*       	30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DIMITRI_INTERFACE_SUNGLINT_ARG, SITE_NAME, SENSOR, PROC_VERSION,$
			       YEAR, CLOUD_PERCENTAGE, ROI_PERCENTAGE, WS_MAX, CONE_MAX, BREF, ABS_CALREF, CHL, TAUA_865_CLIM, CLIM=CLIM, AER, VERBOSE=VERBOSE

  COMMON RTM_LUT

  DEBUG_MODE = 0      ; SET TO 1 IF WANT TO DEBUG THIS PROCEDURE
  
  METHOD = 'SUNGLINT_ARG'

  STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
  STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')
  STATUS_NODATA = GET_DIMITRI_LOCATION('STATUS_NODATA')

  INPUT_FOLDER  = GET_DIMITRI_LOCATION('INGESTION_OUTPUT')
  OUTPUT_FOLDER = GET_DIMITRI_LOCATION('OUTPUT')
  MISSING_VALUE_FLT  = FLOAT(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  MISSING_VALUE_LONG = LONG(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  
;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME
; AND SOME NUMERICAL CONSTANTS

  FCT_NAME         = 'DIMITRI_INTERFACE_SUNGLINT_ARG'
  BADVAL           = -999.0 
  TOL              = 0.000001 ; TOLERANCE FOR FLOAT COMPARISON
  REF_WIND         = 5.
  REF_O3           = 300.0
  REF_P            = 1013.25
 
;-----------------------------------------
; CHECK SITE TYPE

  SITE_TYPE = GET_SITE_TYPE(SITE_NAME,VERBOSE=VERBOSE)
  IF STRUPCASE(SITE_TYPE) NE 'OCEAN' THEN BEGIN
     PRINT,FCT_NAME+': ERROR, INPUT SITE IS NOT EXISTING OR NOT OCEANIC'
     RETURN, STATUS_ERROR
  ENDIF

  ;----------------------
  ; GET BAND INFO STRUCTURE (NB_BANDS, BAND_ID, BAND_LABEL_STD, BAND_WAVELENGTH)
  
  CUR_SENSOR_BAND_INFOS = GET_SENSOR_BAND_INFO(SENSOR)
  NB_BANDS_SENSOR  = CUR_SENSOR_BAND_INFOS.NB_BAND
  NB_DIRECTIONS = SENSOR_DIRECTION_INFO(SENSOR)
  NB_DIRECTIONS = NB_DIRECTIONS[0]

  SENSOR_CONFIG = GET_SENSOR_BAND_CONFIG(SENSOR) ; GET USED CHANNELS / STD LABELS / SMAC FILENAME / LUT FILENAME

;----------------------------------------
; SEARCH FOR WAV AT BREF BAND
 
  WAVREF = FLOAT(GET_SENSOR_BAND_NAME(SENSOR,BREF))

;----------------------------------------
; SEARCH FOR 865 NM BAND INDEX
 
  IF SENSOR EQ 'MODISA' THEN TEMP_SENSOR = 'MODISA_O' ELSE TEMP_SENSOR = SENSOR
  B865 = GET_SENSOR_BAND_INDEX(TEMP_SENSOR,18,VERBOSE=VERBOSE)
  IF SENSOR EQ 'VEGETATION' THEN B865 = GET_SENSOR_BAND_INDEX(TEMP_SENSOR,16,VERBOSE=VERBOSE)

  IF B865 LT 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, NO 865 NM BAND FOUND FOR CHOSEN SENSOR'
    RETURN, STATUS_ERROR
  ENDIF

;----------------------------------------
; SEARCH FOR ALL WAV + VIS BAND <=865 NM 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': SEARCH FOR ALL WAV + VIS BANDS <=885 NM'
  NB_BANDS = (SENSOR_BAND_INFO(SENSOR,VERBOSE=VERBOSE))[0]
;  WAV_ALL = STRARR(NB_BANDS)
;  FOR BK=0, NB_BANDS-1 DO WAV_ALL[BK]=GET_SENSOR_BAND_NAME(SENSOR,BK)

  K_GAS=[11,13,14,20]
  FOR K = 1, 19 DO BEGIN
     
     ; AVOID GASEOUS ABSORPTION BAND
     I = WHERE(K_GAS EQ K)
     IF I[0] NE -1 THEN CONTINUE

     BK = GET_SENSOR_BAND_INDEX(TEMP_SENSOR,K,VERBOSE=VERBOSE)
     IF BK LT 0 THEN CONTINUE ELSE BEGIN
       WAVK     = GET_SENSOR_BAND_NAME(SENSOR,BK)
       IF N_ELEMENTS(BAND_VIS) EQ 0 THEN BEGIN
        BAND_VIS = [BK]
        WAV_VIS  = [FLOAT(WAVK)]
       ENDIF ELSE BEGIN
        BAND_VIS = [BAND_VIS, BK]
        WAV_VIS  = [WAV_VIS, FLOAT(WAVK)]
       ENDELSE
     ENDELSE
  ENDFOR
  NB_BANDS_VIS=N_ELEMENTS(BAND_VIS)

  IF NB_BANDS_VIS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, NO VISIBLE BAND <= 885 NM'
    RETURN, STATUS_ERROR
  ENDIF

  IF DEBUG_MODE EQ 1 THEN BEGIN
    PRINT, ' DEBUG_MODE - SENSOR       = ', SENSOR
    PRINT, ' DEBUG_MODE - NB_BANDS_VIS = ', NB_BANDS_VIS
    PRINT, ' DEBUG_MODE - BAND_VIS     = ', BAND_VIS
    PRINT, ' DEBUG_MODE - WAV_VIS      = ', WAV_VIS
    PRINT, ' DEBUG_MODE - B865     = ', B865
    WAV865 = FLOAT(GET_SENSOR_BAND_NAME(SENSOR,B865))
    PRINT, ' DEBUG_MODE - WAV865   = ', WAV865
    PRINT, ' DEBUG_MODE - BREF     = ', BREF
    PRINT, ' DEBUG_MODE - WAVREF   = ', WAVREF
  ENDIF

;-----------------------------------------
; CHECKS INPUT CRITERIA ARE OK

  CP_LIMIT = FLOAT(CLOUD_PERCENTAGE)*0.01
  RP_LIMIT = FLOAT(ROI_PERCENTAGE)*0.01
  IF CP_LIMIT GT  1.0 OR CP_LIMIT LT 0.0 OR $
     RP_LIMIT GT  1.0 OR RP_LIMIT LT 0.0 OR $
     WS_MAX   LT  0.0 OR                    $
     CONE_MAX GT  90. OR                    $
     CHL      GT 30.0 OR CHL      LT 0.0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, CLOUD/ROI/WIND/CONE/CHL CRITERIA OUT OF RANGE'
    RETURN,-1
  ENDIF
  
  YEAR = STRTRIM(YEAR,2)

;-----------------------------------------
; DEFINE INPUT/OUTPUT FILES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': DEFINING INPUT/OUTPUT FILES'
  SITE_FILE     = GET_DIMITRI_LOCATION('SITE_DATA')
  DB_FILE       = GET_DIMITRI_LOCATION('DATABASE')
  DL            = GET_DIMITRI_LOCATION('DL')
  MAIN_DIRC     = GET_DIMITRI_LOCATION('DIMITRI')
  RTM_DIR       = FILEPATH(SENSOR, ROOT_DIR=GET_DIMITRI_LOCATION('RTM'))

  VIC_LOG         = STRING(OUTPUT_FOLDER+DL+'GLINT_CAL_LOG.txt')

;-----------------------------------------
; CHECK DIMITRI DATABASE EXISTS

  TEMP = FILE_INFO(DB_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, DIMITRI DATABASE FILE DOES NOT EXIST'
    RETURN, STATUS_ERROR
  ENDIF

;-----------------------------------------
; RECORD THIS PROCESSING REQUEST IN A LOG

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+": WRITTING LOG FILE"
  TMP_DATE = SYSTIME()
  TMP_DATE = STRING(STRMID(TMP_DATE,8,2)+'-'+STRMID(TMP_DATE,4,3)+'-'+STRMID(TMP_DATE,20,4)+' '+STRMID(TMP_DATE,11,8))
  TEMP = FILE_INFO(VIC_LOG)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    OPENW, LUNLOG,VIC_LOG,/GET_LUN
    PRINTF,LUNLOG,'DATE;REGION;SENSOR;PROC_VER;YEAR;CLOUD_PERCENTAGE;ROI_PERCENTAGE;WS_MAX;CONE_MAX;WAVREF;ABS_CALREF;CLIM;CHL;TAU865;AER'
  ENDIF ELSE OPENW,LUNLOG,VIC_LOG,/GET_LUN,/APPEND

  PRINTF,LUNLOG,FORMAT='(5(A,1H;),4(F6.3,1H;),(F8.2,1H;),(F6.3,1H;),(A,1H;),2(F6.3,1H;),(A,1H;))',$
  TMP_DATE,SITE_NAME,SENSOR,PROC_VERSION,YEAR,CP_LIMIT,RP_LIMIT,WS_MAX,CONE_MAX,WAVREF,ABS_CALREF,STRTRIM(KEYWORD_SET(CLIM),2),CHL,TAUA_865_CLIM,AER

  FREE_LUN,LUNLOG

;-----------------------------------------
; ROICOVERAGE CHECK

  IF RP_LIMIT GE 1.0 OR STRCMP(SITE_NAME, 'SUNGLINT', /FOLD_CASE) EQ 1 THEN BEGIN

    ROICOVER = 1
    PX_THRESH = 1

  ENDIF ELSE BEGIN
  
    ROICOVER = 0

    ;-----------------------------------------
    ; COMPUTE ROI AREA IN KM^2

    ICOORDS = GET_SITE_COORDINATES(SITE_NAME,SITE_FILE,VERBOSE=VERBOSE)
  
    IF ICOORDS[0] EQ -1 THEN BEGIN
      PRINT,FCT_NAME+': ERROR, REGION COORDINATES NOT FOUND'
      RETURN, STATUS_ERROR
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

  ENDELSE
  
;----------------------------------------
; READ THE DIMITRI DATABASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING DIMITRI DATABASE'
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DB_DATA     = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

;----------------------------------------
; SELECT DATA UPON ROI, CLOUD AND YEAR CRITERIA
  
  IF YEAR EQ 'ALL' THEN CYEAR  = '*' ELSE CYEAR = YEAR

  IDX_FILES = WHERE(STRCMP(DB_DATA.SITE_NAME,SITE_NAME)               EQ 1 AND $
              STRCMP(DB_DATA.SENSOR,SENSOR)               EQ 1 AND $
              STRCMP(DB_DATA.PROCESSING_VERSION,PROC_VERSION) EQ 1 AND $
              STRMATCH(STRTRIM(DB_DATA.YEAR,2),CYEAR)              AND $  
              DB_DATA.ROI_STATUS  GE ROICOVER                       AND $
              DB_DATA.ROI_PIX_NUM GE PX_THRESH                      AND $
              (DB_DATA.MANUAL_CS EQ 0. OR (DB_DATA.MANUAL_CS LT 1. AND DB_DATA.AUTO_CS_1_MEAN GT -1.0 AND DB_DATA.AUTO_CS_1_MEAN LE CP_LIMIT + TOL)), NB_FILES)

  IF NB_FILES EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': WARNING, NO SENSOR DATA FOUND WITHIN PIXEL THRESHOLD OR CLOUD CONDITION, RETURN'
    RETURN, STATUS_NODATA
  ENDIF

  ;----------------------
  ; GET INGESTION OUTPUT FILENAME FROM DATABASE
  
  SEARCH_FOLDER = INPUT_FOLDER + DL + 'Site_' + SITE_NAME + DL + SENSOR + DL + 'Proc_' + PROC_VERSION + DL
  I_FILES = SEARCH_FOLDER + DL + STRTRIM(STRING(DB_DATA.YEAR[IDX_FILES]),2) + DL + DB_DATA.L1_INGESTED_FILENAME[IDX_FILES]
  FILE_RESULT = FILE_SEARCH(I_FILES, COUNT=NB_FILES_SEARCH)
  
  IF NB_FILES_SEARCH NE NB_FILES THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': THE NUMBER OF INGESTION PRODUCTS ON DISK (', NB_FILES_SEARCH, $
                                                    ') DOES NOT MATCH THE NUMBER OF INGESTED PRODUCT IN THE DATABASE (', NB_FILES, ')'
    RETURN, STATUS_ERROR
  ENDIF

;----------------------------------------
; READ RTM LUT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING RAYLEIGH REFLECTANCE LUT'
  STATUS = READ_RAYLEIGH(FILEPATH('RHOR_'+SENSOR+'.txt', ROOT_DIR=RTM_DIR))

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING XC LUT'
  STATUS = READ_XC(FILEPATH('XC_'+SENSOR+'_'+STRTRIM(AER,2)+'.txt', ROOT_DIR=RTM_DIR))

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING TAUA LUT'
  STATUS = READ_TAUA(FILEPATH('TAUA_'+SENSOR+'_'+STRTRIM(AER,2)+'.txt', ROOT_DIR=RTM_DIR))

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': READING TOTAL TRANSMITTANCE LUT'
  STATUS = READ_TRA(FILEPATH('TRA_DOWN_'+SENSOR+'_'+STRTRIM(AER,2)+'.txt', ROOT_DIR=RTM_DIR),$
            FILEPATH('TRA_UP_'  +SENSOR+'_'+STRTRIM(AER,2)+'.txt', ROOT_DIR=RTM_DIR))

 
  ;----------------------
  ; GET OZONE CORRECTION

  TO3_REF_REF = (GET_OZONE_TRANSMISSION(WAVREF,VERBOSE=VERBOSE))[0]
  TGS         = (GET_GASEOUS_TRANSMISSION(WAVREF,VERBOSE=VERBOSE))[0]
  TAUO3_REF   = -0.5*ALOG((TO3_REF_REF>0.000001)/TGS)

  IF DEBUG_MODE THEN BEGIN
    PRINT, ' DEBUG_MODE - TAUO3_REF  = ', TAUO3_REF
  ENDIF  

  ;----------------------
  ; SET OUTPUT CALIB FOLDER
  
  CALDAT, SYSTIME(/UTC,/JULIAN),TMM,TDD,TYY,THR,TMN,TSS

  TYY = STRTRIM(STRING(TYY),2)
  TMM = TMM LT 10 ? '0'+STRTRIM(STRING(TMM),2) : STRTRIM(STRING(TMM),2)
  TDD = TDD LT 10 ? '0'+STRTRIM(STRING(TDD),2) : STRTRIM(STRING(TDD),2)
  THR = THR LT 10 ? '0'+STRTRIM(STRING(THR),2) : STRTRIM(STRING(THR),2)
  TMN = TMN LT 10 ? '0'+STRTRIM(STRING(TMN),2) : STRTRIM(STRING(TMN),2)
  TSS = TSS LT 10 ? '0'+STRTRIM(STRING(TSS,FORMAT='(I)'),2) : STRTRIM(STRING(TSS,FORMAT='(I)'),2)

  PROCESS_DATE = TYY+TMM+TDD+'-'+THR+TMN

  OUT_FILEPATH = OUTPUT_FOLDER + DL + METHOD + '_' + PROCESS_DATE + DL + 'Site_'+ SITE_NAME + DL + SENSOR + DL + 'Proc_' + PROC_VERSION + DL
  OUT_FILENAME_BASE =  SITE_NAME + '_' + SENSOR + '_' + PROC_VERSION + '_' + METHOD 
          
  ;----------------------
  ; LOOP OVER NCDF FILE IN PROCESSING DATASET

  FOR IDX_FILE=0, NB_FILES-1 DO BEGIN

    NCDF_FILENAME = FILE_RESULT[IDX_FILE]
    NCDF_INFOS = FILE_INFO(NCDF_FILENAME)
    
    IF NCDF_INFOS.EXISTS EQ 0 OR STRLEN(NCDF_FILENAME) EQ 0 THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': FILE ',NCDF_FILENAME,' IS MISSING, PLEASE CHECK YOUR INGESTION PROGRESS'
      GOTO, NEXT_IFILES
    ENDIF

    CUR_NCFILE = FILE_BASENAME(NCDF_FILENAME)

    ;----------------------
    ; GET ACQUISITION DATE FROM NCDF FILE
    CUR_NCDF_DATE = STRTRIM(GET_NCDF_GLOBAL_ATT(NCDF_FILENAME, 'ACQUISITION_DATE'))
    NCDF_YEAR_STR=STRMID(CUR_NCDF_DATE,0,4)
    NCDF_MONTH_STR=STRMID(CUR_NCDF_DATE,5,2)
    NCDF_DAY_STR=STRMID(CUR_NCDF_DATE,8,2)
    NCDF_HOURS_STR=STRMID(CUR_NCDF_DATE,11,2)
    NCDF_MINUTES_STR=STRMID(CUR_NCDF_DATE,14,2)
    
    NCDF_YEAR=UINT(NCDF_YEAR_STR)
    NCDF_MONTH=UINT(NCDF_MONTH_STR)
    NCDF_DAY=UINT(NCDF_DAY_STR)
    NCDF_HOURS=UINT(NCDF_HOURS_STR)
    NCDF_MINUTES=UINT(NCDF_MINUTES_STR)
    
    ACQUI_DATE = JULDAY(NCDF_MONTH,NCDF_DAY,NCDF_YEAR,NCDF_HOURS,NCDF_MINUTES,0)
    
    IF KEYWORD_SET(VERBOSE) THEN BEGIN
      PRINT, '[' + STRTRIM(STRING(IDX_FILE+1),1) + '/' + STRTRIM(STRING(NB_FILES),1) + '] > ' + FCT_NAME + ' ' + CUR_NCFILE + ' :: ' + CUR_NCDF_DATE
    ENDIF

    ;----------------------
    ; READ INPUT INGESTION FILE
    
    STATUS = NETCDFREAD_INGEST_OUTPUT( NCDF_FILENAME, NCDF_INGEST_STRUCT=NCDF_INGEST_STRUCT, VERBOSE=VERBOSE)
    IF STATUS NE STATUS_OK THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN BEGIN
        PRINT, FCT_NAME + ': ERROR DURING ', FILE_BASENAME(NCDF_FILENAME),' FILE READING >> FILE SKIPPED'
      ENDIF
      GOTO, NEXT_IFILES
    ENDIF  
        

		;----------------------------------------
		; ASSIGN STANDARD VALUE TO MISSING AUX DATA

		OZONE_ALL = NCDF_INGEST_STRUCT.VARIABLES.ERA_OZONE
		ID = WHERE(OZONE_ALL EQ MISSING_VALUE_FLT)
		IF ID[0] NE -1 THEN OZONE_ALL[ID]= REF_O3 / 1000.0
		OZONE_ALL = OZONE_ALL * 1000.0  

		PRESSURE_ALL = NCDF_INGEST_STRUCT.VARIABLES.ERA_PRESSURE
		ID = WHERE(PRESSURE_ALL EQ MISSING_VALUE_FLT)
		IF ID[0] NE -1 THEN PRESSURE_ALL[ID]=REF_P

		WIND_SPEED_ALL = NCDF_INGEST_STRUCT.VARIABLES.ERA_WIND_SPEED
		ID = WHERE(WIND_SPEED_ALL EQ MISSING_VALUE_FLT)  
		IF ID[0] NE -1 THEN WIND_SPEED_ALL[ID]=REF_WIND

    CHLORO_ALL = NCDF_INGEST_STRUCT.VARIABLES.ESA_CHLOROPHYLL
    ID = WHERE(CHLORO_ALL EQ MISSING_VALUE_FLT)  
    IF ID[0] NE -1 THEN CHLORO_ALL[ID]=CHL

		;==FOR VALIDATION ONLY =====================
;    PRINT, ' DEBUG_MODE - !!!!! WARNING !!!! METEO VALUE FORCED TO CSTE VALUES FOR VALIDATION PURPOSE !!!!!
;	  OZONE_ALL[*] = REF_O3
;	  PRESSURE_ALL[*] = REF_P
;	  WIND_SPEED_ALL[*]= REF_WIND
		;==========================================

		IF DEBUG_MODE THEN BEGIN
			PRINT, ' DEBUG_MODE - REF_O3 = ', REF_O3, ' / REF_P = ', REF_P, ' / REF_WIND = ', REF_WIND, ' / CHL = ', CHL
			PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(OZONE_ALL)       = ', MIN(OZONE_ALL), MAX(OZONE_ALL), MEAN(OZONE_ALL), STDDEV(OZONE_ALL)
			PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(PRESSURE_ALL)    = ', MIN(PRESSURE_ALL), MAX(PRESSURE_ALL), MEAN(PRESSURE_ALL), STDDEV(PRESSURE_ALL)
			PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(WIND_SPEED_ALL)  = ', MIN(WIND_SPEED_ALL), MAX(WIND_SPEED_ALL), MEAN(WIND_SPEED_ALL), STDDEV(WIND_SPEED_ALL)
      PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(CHLORO_ALL)      = ', MIN(CHLORO_ALL), MAX(CHLORO_ALL), MEAN(CHLORO_ALL), STDDEV(CHLORO_ALL)
		ENDIF

    ;----------------------
    ; SELECT DATA UPON WIND, CLOUD MASK, CONE ANGLE CONDITIONS
    ; COMPUTE MAXIMAL COUNT PIXEL ACROSS DIRECTION FOR AN ESTIMATION OF VALID CALIBRATION PIXELS
    
    COUNT_PIX_MAX = 0
    FOR NUM_DIR=0, NB_DIRECTIONS-1 DO BEGIN

			VZA = REFORM(NCDF_INGEST_STRUCT.VARIABLES.VZA[*,NUM_DIR])
			SZA = REFORM(NCDF_INGEST_STRUCT.VARIABLES.SZA[*,NUM_DIR])
			RAA = ACOS(COS(REFORM(NCDF_INGEST_STRUCT.VARIABLES.VAA[*,NUM_DIR]-NCDF_INGEST_STRUCT.VARIABLES.SAA[*,NUM_DIR])*!DTOR))*!RADEG

			GLINT_ANGLE = ACOS(COS(SZA*!DTOR)*COS(VZA*!DTOR)-SIN(SZA*!DTOR)*SIN(VZA*!DTOR)*COS(RAA*!DTOR))*!RADEG
  	
      INDX_PIX = WHERE( REFORM(WIND_SPEED_ALL[*,NUM_DIR]) LE WS_MAX $
      									AND REFORM(NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_1_MASK[*,NUM_DIR]) EQ 0 $
      									AND GLINT_ANGLE LE CONE_MAX, COUNT_PIX)
      
      COUNT_PIX_MAX = MAX( [ COUNT_PIX_MAX, COUNT_PIX ] )
    ENDFOR

    IF COUNT_PIX_MAX EQ 0 THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN BEGIN
        PRINT, ' COUNT_PIX_MAX = ' + STRTRIM(STRING(COUNT_PIX_MAX),1) + ' >> FILE SKIPPED '
      ENDIF 
      GOTO, NEXT_IFILES
    ENDIF     
    
    IF DEBUG_MODE THEN BEGIN
      PRINT, ' DEBUG_MODE - COUNT_PIX_MAX (FOR EACH DIR) = ', COUNT_PIX_MAX
      
			VZA_ALL_DIR = NCDF_INGEST_STRUCT.VARIABLES.VZA
			SZA_ALL_DIR = NCDF_INGEST_STRUCT.VARIABLES.SZA
			RAA_ALL_DIR = ACOS(COS((NCDF_INGEST_STRUCT.VARIABLES.VAA-NCDF_INGEST_STRUCT.VARIABLES.SAA)*!DTOR))*!RADEG
			GLINT_ANGLE_ALL_DIR = ACOS(COS(SZA_ALL_DIR*!DTOR)*COS(VZA_ALL_DIR*!DTOR)-SIN(SZA_ALL_DIR*!DTOR)*SIN(VZA_ALL_DIR*!DTOR)*COS(RAA_ALL_DIR*!DTOR))*!RADEG
      IDX_ALL_DIR = WHERE( WIND_SPEED_ALL LE WS_MAX $
      										AND NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_1_MASK EQ 0 $
      										AND GLINT_ANGLE_ALL_DIR LE CONE_MAX, C)
      PRINT, ' DEBUG_MODE - COUNT_PIX_MAX (ALL DIR) = ', C
    ENDIF

    ;----------------------
    ; GET NCDF STRUCTURE FOR CALIBRATION OUTPUT
    
    CALIB_PIXEL_NUMBER = COUNT_PIX_MAX
    
    NCDF_CALIB_STRUCT = GET_NCDF_CALIB_STRUCT(CALIB_PIXEL_NUMBER, NCDF_INGEST_STRUCT.DIMENSIONS.ROI_PIXEL_NUMBER, NB_DIRECTIONS, NB_BANDS_VIS, VERBOSE=VERBOSE)
    NCDF_CALIB_STRUCT.GLOBAL_ATT.CALIBRATION_METHOD = METHOD
    NCDF_CALIB_STRUCT.VARIABLES.REFL_BAND_IDS = BAND_VIS
    
    ;----------------------
    ; COPY COMMON INFOS FROM INGESTION NCDF TO CALIBRATION NCDF
    STATUS = COPY_INGESTION_TO_CALIBRATION_NCDF_STRUCTURE(NCDF_INGEST_STRUCT=NCDF_INGEST_STRUCT, NCDF_CALIB_STRUCT=NCDF_CALIB_STRUCT, VERBOSE=VERBOSE)
    IF STATUS NE STATUS_OK THEN RETURN, STATUS
    
    ;----------------------
    ; LOOP OVER VIEWING DIRECTION
    
    AT_LEAST_ONE_DIR = 0
    
    FOR NUM_DIR=0, NB_DIRECTIONS-1 DO BEGIN
                  
      IF NUM_DIR+1 LT 10 THEN DIR_ID = 'DIR0' + STRTRIM(STRING(NUM_DIR+1),2) $
                         ELSE DIR_ID = 'DIR' + STRTRIM(STRING(NUM_DIR+1),2)
                          
      IF KEYWORD_SET(VERBOSE) THEN BEGIN
        PRINT, FCT_NAME + ': ----- PROCESS DIRECTION [' + DIR_ID + '/' + STRTRIM(STRING(NB_DIRECTIONS),1) + ']'
      ENDIF

      IF NCDF_INGEST_STRUCT.VARIABLES.ROI_STATUS[NUM_DIR] EQ 0 THEN BEGIN
        IF KEYWORD_SET(VERBOSE) THEN BEGIN
          PRINT, FCT_NAME + ': ROI STATUS WITH 0 VALUE >> DIRECTION SKIPPED'
        ENDIF
        GOTO, NEXT_DIR
      ENDIF

			;----------------------
			; SELECT DATA UPON WIND, CLOUD MASK, CONE ANGLE CONDITIONS
			; COMPUTE MAXIMAL COUNT PIXEL ACROSS DIRECTION FOR AN ESTIMATION OF VALID CALIBRATION PIXELS
    
			VZA = REFORM(NCDF_INGEST_STRUCT.VARIABLES.VZA[*,NUM_DIR])
			SZA = REFORM(NCDF_INGEST_STRUCT.VARIABLES.SZA[*,NUM_DIR])
			RAA = ACOS(COS(REFORM(NCDF_INGEST_STRUCT.VARIABLES.VAA[*,NUM_DIR]-NCDF_INGEST_STRUCT.VARIABLES.SAA[*,NUM_DIR])*!DTOR))*!RADEG

			GLINT_ANGLE = ACOS(COS(SZA*!DTOR)*COS(VZA*!DTOR)-SIN(SZA*!DTOR)*SIN(VZA*!DTOR)*COS(RAA*!DTOR))*!RADEG
  	
      INDX_PIX = WHERE( REFORM(WIND_SPEED_ALL[*,NUM_DIR]) LE WS_MAX $
      									AND REFORM(NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_1_MASK[*,NUM_DIR]) EQ 0 $
      									AND GLINT_ANGLE LE CONE_MAX, NB_PIX)
      
      IF NB_PIX EQ 0 THEN BEGIN
        IF KEYWORD_SET(VERBOSE) THEN BEGIN
          PRINT, ' NB_VALID_PIX = ' + STRTRIM(STRING(NB_PIX),1) + ' : DIRECTION SKIPPED'
        ENDIF 
        GOTO, NEXT_DIR
      ENDIF 
    
      IF DEBUG_MODE THEN PRINT, ' DEBUG_MODE - NB_PIX = ', NB_PIX

			;----------------------------------------
			; DEFINE ANGLES AND LIMIT INPUT DATA TO VALID PIXELS

			VZA = VZA[INDX_PIX]
			SZA = SZA[INDX_PIX]
			RAA = RAA[INDX_PIX]
			GLINT_ANGLE = GLINT_ANGLE[INDX_PIX]

			OZONE = OZONE_ALL[INDX_PIX,NUM_DIR]
			PRESSURE = PRESSURE_ALL[INDX_PIX,NUM_DIR]
			WIND_SPEED = WIND_SPEED_ALL[INDX_PIX,NUM_DIR]
      CHLORO = CHLORO_ALL[INDX_PIX,NUM_DIR]

			;----------------------------------------
			; ASSIGN CHL VALUES

			IF NOT KEYWORD_SET(CLIM) THEN CHLORO[*] = CHL

			;----------------------------------------
			; COMPUTE MARINE SIGNAL WRT CHLOROPHYLL

			R0_REF   = R0_MM01(WAVREF, CHLORO, SZA)
			RHOW_REF = 0.5287*R0_REF ; rhow =PI*Rgoth/Q*R(0-)  Q=PI

			;----------------------------------------
			; APPLY ABSOLUTE CALIBRATION AT BREF

      RTOA_REF_OBS = REFORM(NCDF_INGEST_STRUCT.VARIABLES.REFL_BAND[INDX_PIX,NUM_DIR, BREF])

      INDX_NAN = WHERE(RTOA_REF_OBS EQ MISSING_VALUE_FLT, COUNT_MISSING_VALUE, NCOMPLEMENT=COUNT_VALID, COMPLEMENT=IDX_VALID_REF)
      IF COUNT_MISSING_VALUE GT 0 THEN BEGIN
        PRINT, FCT_NAME + ': ----------- !!!! WARNING, INVALID VALUE FOR BAND REF ', SENSOR_CONFIG.BAND_REF_LABEL[BREF], ' : COUNT_MISSING_VALUE = ', COUNT_MISSING_VALUE, ' / COUNT_VALID = ',COUNT_VALID 
        PRINT, FCT_NAME + ': ----------- !!!! WARNING, THIS ASPECT IS NOT TAKEN INTO ACCOUNT FOR ARG CALIB !!!!!!
      ENDIF 

  		RTOA_REF_OBS /= ABS_CALREF

			;----------------------------------------
			; CORRECT SIGNAL FOR OZONE AT BREF

			AIR_MASS = REFORM(1./COS(SZA*!DTOR)+1./COS(VZA*!DTOR))

			TO3_REF     = EXP(-TAUO3_REF*(OZONE/REF_O3)*AIR_MASS)

			MI_REF_OZ   = RTOA_REF_OBS / TO3_REF

			;----------------------------------------
			; ASSIGN TAUA VALUE

			TAUA_865 = MAKE_ARRAY(NB_PIX,/FLOAT,VALUE=TAUA_865_CLIM)

			;----------------------------------------
			; PROPAGATE TAU AT BREF

			TAUA_REF = SPECTRAL_DEP(TAUA_865, B865, BREF)

			;----------------------------------------
			; COMPUTE DIRECT TRANSMITTANCE AT BREF, WITH CORRECTION FOR PRESSURE

			TAUR_REF = TAUR_HT74(WAVREF) 
			TD_REF = EXP(-(TAUA_REF+TAUR_REF*PRESSURE/REF_P)*AIR_MASS)

  IF DEBUG_MODE THEN BEGIN
    PRINT, ' DEBUG_MODE - TAUO3_REF  = ', TAUO3_REF
    PRINT, ' DEBUG_MODE - TAUR_REF   = ', TAUR_REF
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHOW_REF)        = ', MIN(RHOW_REF), MAX(RHOW_REF), MEAN(RHOW_REF), STDDEV(RHOW_REF)
    
    RTOA_REF = REFORM(NCDF_INGEST_STRUCT.VARIABLES.REFL_BAND[INDX_PIX,NUM_DIR, BREF])
    help, RTOA_REF
    PRINT, ' DEBUG_MODE - N_ELEMENTS(GD_ID)    = ', N_ELEMENTS(GD_ID)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RTOA_REF)        = ', MIN(RTOA_REF), MAX(RTOA_REF), MEAN(RTOA_REF), STDDEV(RTOA_REF)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(AIR_MASS)        = ', MIN(AIR_MASS), MAX(AIR_MASS), MEAN(AIR_MASS), STDDEV(AIR_MASS)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TO3_REF)         = ', MIN(TO3_REF), MAX(TO3_REF), MEAN(TO3_REF), STDDEV(TO3_REF)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(MI_REF_OZ)       = ', MIN(MI_REF_OZ), MAX(MI_REF_OZ), MEAN(MI_REF_OZ), STDDEV(MI_REF_OZ)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TAUA_865)        = ', MIN(TAUA_865), MAX(TAUA_865), MEAN(TAUA_865), STDDEV(TAUA_865)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TD_REF)          = ', MIN(TD_REF), MAX(TD_REF), MEAN(TD_REF), STDDEV(TD_REF)
  ENDIF

			;----------------------------------------
			; ITERATE ON WIND SPEED INVERSION

  		IDX_VALID_PIX = INDX_PIX
  		
  		FOR ITER=0, 5 DO BEGIN
				
				;----------------------------------------
				; COMPUTE RAYLEIGH AT BREF

     		RHOR_REF = COMPUTE_RAYLEIGH(WIND_SPEED, RAA, VZA, SZA, BREF, /COS) 

				;----------------------------------------
				; COMPUTE RHOPATH AT BREF AND CORRECT FOR PRESSURE

				XC_REF = COMPUTE_XC(WIND_SPEED, RAA, VZA, SZA, TAUA_REF, BREF, /COS)
				RHOPATH_REF = XC_REF*RHOR_REF
				RHOPATH_REF = RHOPATH_REF*(1.+TAUR_REF/(TAUR_REF+TAUA_REF)*(PRESSURE/REF_P-1.))

				;----------------------------------------
				; COMPUTE TOTAL (DIRECT+DIFFUSE) TRANSMITTANCE AND CORRECT FOR PRESSURE

				TRANS_REF = COMPUTE_TRA(WIND_SPEED, VZA, SZA, TAUA_REF, BREF, /COS)
				TRANS_REF = TRANS_REF*EXP(-0.5*TAUR_REF*AIR_MASS*(PRESSURE/REF_P-1.))

				;----------------------------------------
				; COMPUTE GLINT FROM BREF SIGNAL
     
				RHO_G = (MI_REF_OZ - RHOPATH_REF - TRANS_REF*RHOW_REF)/ TD_REF

				;----------------------------------------
				; INVERSE WIND SPEED FROM GLINT REFLECTANCE
  
				WIND_SPEED = INV_RHO_GLINT_CM54(RHO_G, WIND_SPEED, RAA, VZA, SZA, WAVREF)

				ID = WHERE(WIND_SPEED GE 0., COUNT)
				IF COUNT EQ 0 THEN BEGIN
					PRINT, FCT_NAME+': WARNING, NO SENSOR DATA FOUND WITH POSITIVE INVERSED WIND AT BREF'
					GOTO, NEXT_DIR
				ENDIF
 
  IF DEBUG_MODE THEN BEGIN
    PRINT, ' DEBUG_MODE ------------------------------ ITER    = ', ITER
    PRINT, ' DEBUG_MODE - N_ELEMENTS(ID)                       = ', N_ELEMENTS(GD_ID)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHOR_REF)        = ', MIN(RHOR_REF), MAX(RHOR_REF), MEAN(RHOR_REF), STDDEV(RHOR_REF)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(XC_REF)          = ', MIN(XC_REF), MAX(XC_REF), MEAN(XC_REF), STDDEV(XC_REF)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHOPATH_REF)     = ', MIN(RHOPATH_REF), MAX(RHOPATH_REF), MEAN(RHOPATH_REF), STDDEV(RHOPATH_REF)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TRANS_REF)       = ', MIN(TRANS_REF), MAX(TRANS_REF), MEAN(TRANS_REF), STDDEV(TRANS_REF)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHO_G)           = ', MIN(RHO_G), MAX(RHO_G), MEAN(RHO_G), STDDEV(RHO_G)
    PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(WIND_SPEED)      = ', MIN(WIND_SPEED), MAX(WIND_SPEED), MEAN(WIND_SPEED), STDDEV(WIND_SPEED)
    PRINT, ' DEBUG_MODE - COUNT WIND_SPEED THRESHOLD (for ALL dir!) = ', COUNT    
  ENDIF

				;----------------------------------------
				; UPDATE ARRAYS ACCORDING TO RHO_G TEST

				IDX_VALID_PIX = IDX_VALID_PIX[ID]
				OZONE      = OZONE[ID]
				PRESSURE   = PRESSURE[ID]
				WIND_SPEED = WIND_SPEED[ID]
        CHLORO     = CHLORO[ID]
				VZA        = VZA[ID]
				SZA        = SZA[ID]
				RAA        = RAA[ID]
				GLINT_ANGLE = GLINT_ANGLE[ID]
				AIR_MASS   = AIR_MASS[ID]
				TAUA_865   = TAUA_865[ID]
				TAUA_REF   = TAUA_REF[ID]
				MI_REF_OZ  = MI_REF_OZ[ID]
				RHO_G      = RHO_G[ID]
				TD_REF     = TD_REF[ID]
				RHOW_REF   = RHOW_REF[ID]
 
  		ENDFOR

      ;-------------------
      ; COMPLETE NCDF CALIBRATION STRUCTURE
      
      NB_PIX = N_ELEMENTS(IDX_VALID_PIX)
      NCDF_CALIB_STRUCT.VARIABLES.CALIB_PIXEL_NUMBER(NUM_DIR) = NB_PIX
      NCDF_CALIB_STRUCT.VARIABLES.CALIB_VALID_INDEX(0:NB_PIX-1,NUM_DIR) = IDX_VALID_PIX
      
      NCDF_CALIB_STRUCT.VARIABLES.WIND_SPEED_ESTIM(0:NB_PIX-1,NUM_DIR)  = WIND_SPEED

			;----------------------------------------
			; LOOP ON VIS BAND 
 
      RHOPATH_865      = MISSING_VALUE_FLT
      RHOPATH_865_PSTD = MISSING_VALUE_FLT
      TAUA_865_CHECK   = MISSING_VALUE_FLT

			IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': STARTING LOOP OVER BANDS <=865 NM'
			FOR K=0, NB_BANDS_VIS-1 DO BEGIN

				BK   = BAND_VIS[K]
				WAVK = WAV_VIS[K] 

				WAVELENGTH = STRTRIM(STRING(SENSOR_CONFIG.BAND_WAVELENGTH[BK]),2)

				IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': ----- ' + SENSOR + ' :: ID : ' + STRTRIM(STRING(SENSOR_CONFIG.BAND_ID[BK]),1) + $
																						', LABEL_STD : ' + SENSOR_CONFIG.BAND_LABEL_STD[BK] + $
																						', REF_LABEL : ' + SENSOR_CONFIG.BAND_REF_LABEL[BK] + $
																						', WAVELENGTH : ' + WAVELENGTH + $
																						', WAVK : ', WAVK

				RTOA_OBS = REFORM(NCDF_INGEST_STRUCT.VARIABLES.REFL_BAND[IDX_VALID_PIX,NUM_DIR, BK])
				
				INDX_NAN = WHERE(RTOA_OBS EQ MISSING_VALUE_FLT, COUNT_MISSING_VALUE, NCOMPLEMENT=COUNT_VALID, COMPLEMENT=IDX_VALID)
        IF COUNT_MISSING_VALUE GT 0 THEN BEGIN
          PRINT, FCT_NAME + ': ----------- !!!! WARNING, INVALID VALUE FOR BAND ', SENSOR_CONFIG.BAND_REF_LABEL[BK], ' : COUNT_MISSING_VALUE = ', COUNT_MISSING_VALUE, ' / COUNT_VALID = ',COUNT_VALID 
          PRINT, FCT_NAME + ': ----------- !!!! WARNING, THIS ASPECT IS NOT TAKEN INTO ACCOUNT FOR ARG CALIB !!!!!!
        ENDIF 
        IF COUNT_VALID EQ 0 THEN BEGIN
				  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': NO VALID SENSOR VALUE FOR THIS BAND >> BAND SKIPPED'
				  GOTO, NEXT_BAND
				ENDIF

				;----------------------------------------
				; CORRECT SIGNAL FOR OZONE
 
				TO3_K_REF = (GET_OZONE_TRANSMISSION(WAVK,VERBOSE=VERBOSE))[0]
				TGS       = (GET_GASEOUS_TRANSMISSION(WAVK,VERBOSE=VERBOSE))[0]
				TAUO3_K   = -0.5*ALOG((TO3_K_REF>0.000001)/TGS)

				TO3_K     = EXP(-TAUO3_K*(OZONE/REF_O3)*AIR_MASS)

				MI_K_OZ   = RTOA_OBS/TO3_K

				;----------------------------------------
				; COMPUTE RAYLEIGH OPTICAL THICKNESS AND REFLECTANCE

				TAUR_K = TAUR_HT74(WAVK) 
				RHOR_K = COMPUTE_RAYLEIGH(WIND_SPEED, RAA, VZA, SZA, BK, /COS) 

				;----------------------------------------
				; PROPAGATE TAU AT BAND BK

				TAUA_K = SPECTRAL_DEP(TAUA_865, B865, BK)

				;----------------------------------------
				; COMPUTE RHOPATH AT BAND BK AND CORRECT FOR PRESSURE

				XC_K      = COMPUTE_XC(WIND_SPEED, RAA, VZA, SZA, TAUA_K, BK, /COS)
				RHOPATH_K = RHOR_K*XC_K
				RHOPATH_K = RHOPATH_K*(1.+TAUR_K/(TAUR_K+TAUA_K)*(PRESSURE/REF_P-1.))

				;----------------------------------------
				; COMPUTE TOTAL (DIRECT+DIFFUSE) TRANSMITTANCE AND CORRECT FOR PRESSURE

				TRANS_K = COMPUTE_TRA(WIND_SPEED, VZA, SZA, TAUA_K, BK, /COS)
				TRANS_K = TRANS_K*EXP(-0.5*TAUR_K*AIR_MASS*(PRESSURE/REF_P-1.))

				;----------------------------------------
				; COMPUTE DIRECT TRANSMITTANCE WITH CORRECTION FOR PRESSURE

				TD_K = EXP(-(TAUA_K+TAUR_K*PRESSURE/REF_P)*AIR_MASS)

				;----------------------------------------
				; COMPUTE MARINE SIGNAL WRT CHLOROPHYLL
    
				R0_K   = R0_MM01(WAVK, CHLORO, SZA)
				RHOW_K = !PI*0.5287/3.*R0_K ; rhow =PI*Rgoth/Q*R(0-)

				;----------------------------------------
				; COMPUTE TOTAL TOA SIGNAL

				I_K     =  RHOPATH_K + TRANS_K*RHOW_K + TD_K*RHO_G*FRESNEL(RAA, VZA, SZA, WAVK)/FRESNEL(RAA, VZA, SZA, WAVREF)
  
				;----------------------------------------
				; COMPUTE VICARIOUS COEFFICIENTS
				; FOLLOWING HAGOLLE ET AL 1999 

				RTOA_TG_RATIO       = MI_K_OZ
				RTOA_TG_RATIO_ESTIM = I_K 
				REF_TO_SIM_RATIO    = RTOA_TG_RATIO / RTOA_TG_RATIO_ESTIM  ; Offical ratio for all calibration on V4.0
				;REF_TO_SIM_RATIO    = RTOA_TG_RATIO_ESTIM / RTOA_TG_RATIO ; Original ratio from Argans V3.1.1
				
     ; VIC_COEF[NUM_NON_REF+BK,*] = I_K/MI_K_OZ
 
				;----------------------------------------
				; COMPUTE UNCERTAINTY (INTERBAND)
				; 1% MAX ACCORDING TO HAGOLLE ET AL 1999
 
				BAND_RHO_SIM_UNCERT = 0.01 * REF_TO_SIM_RATIO
     
     ;VIC_COEF[NUM_NON_REF+NB_BANDS+BK,*] = 0.01*VIC_COEF[NUM_NON_REF+BK,*]

				;----------------------------------------
				; RETRIEVE AEROSOL OPTICAL THICKNESS AT 865 NM

				IF BK EQ B865 THEN BEGIN
					RHOPATH_865      = MI_K_OZ-TRANS_K*RHOW_K-TD_K*RHO_G
					RHOPATH_865_PSTD = RHOPATH_865*(1.-TAUR_K/(TAUR_K+TAUA_K)*(PRESSURE/REF_P-1.))
					TAUA_865_CHECK   = INVERSE_XC(WIND_SPEED, RAA, VZA, SZA,RHOPATH_865_PSTD/RHOR_K,BK, /COS)
				ENDIF

				IF BK EQ BREF THEN BEGIN
					;----------------------------------------
				  ; DEFINE ABSOLUTE CALIBRATION AT BREF (OTHERWHISE IT WOULD BE 1) 					
					;REF_TO_SIM_RATIO /= ABS_CALREF  ; from Argans V3.1.1
          REF_TO_SIM_RATIO *= ABS_CALREF  ; change due to the inversion of the ratio in V4.0
				ENDIF

        IF DEBUG_MODE THEN BEGIN
          PRINT, ' ------ BAND ID ---  BAND :  K = ', K, ' / BK = ', BK, ' / WAVK = ', WAVK, ' / REFL_BAND_IDS = ', NCDF_CALIB_STRUCT.VARIABLES.REFL_BAND_IDS[K], ' / BAND_REF_LABEL = ', SENSOR_CONFIG.BAND_REF_LABEL[BK]
          
          help, RTOA_OBS
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RTOA_OBS)        = ', MIN(RTOA_OBS), MAX(RTOA_OBS), MEAN(RTOA_OBS), STDDEV(RTOA_OBS)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TO3_K)           = ', MIN(TO3_K), MAX(TO3_K), MEAN(TO3_K), STDDEV(TO3_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(MI_K_OZ)         = ', MIN(MI_K_OZ), MAX(MI_K_OZ), MEAN(MI_K_OZ), STDDEV(MI_K_OZ)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHOW_K)          = ', MIN(RHOW_K), MAX(RHOW_K), MEAN(RHOW_K), STDDEV(RHOW_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHOR_K)          = ', MIN(RHOR_K), MAX(RHOR_K), MEAN(RHOR_K), STDDEV(RHOR_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TAUA_K)          = ', MIN(TAUA_K), MAX(TAUA_K), MEAN(TAUA_K), STDDEV(TAUA_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(RHOPATH_K)       = ', MIN(RHOPATH_K), MAX(RHOPATH_K), MEAN(RHOPATH_K), STDDEV(RHOPATH_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TRANS_K)         = ', MIN(TRANS_K), MAX(TRANS_K), MEAN(TRANS_K), STDDEV(TRANS_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TD_K)            = ', MIN(TD_K), MAX(TD_K), MEAN(TD_K), STDDEV(TD_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(I_K)             = ', MIN(I_K), MAX(I_K), MEAN(I_K), STDDEV(I_K)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(I_K/MI_K_OZ)     = ', MIN(REF_TO_SIM_RATIO), MAX(REF_TO_SIM_RATIO), MEAN(REF_TO_SIM_RATIO), STDDEV(REF_TO_SIM_RATIO)
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(I_K/MI_K_OZ)[IDX_VALID] = ', MIN(REF_TO_SIM_RATIO[IDX_VALID]), MAX(REF_TO_SIM_RATIO[IDX_VALID]), MEAN(REF_TO_SIM_RATIO[IDX_VALID]), STDDEV(REF_TO_SIM_RATIO[IDX_VALID])
          PRINT, ' ------ '
        ENDIF

        IF NB_DIRECTIONS GT 1 THEN BEGIN
          OUT_FIG_FILENAME = OUT_FILEPATH + NCDF_YEAR_STR + DL + OUT_FILENAME_BASE + '_' + NCDF_YEAR_STR + NCDF_MONTH_STR + NCDF_DAY_STR $
                                        + '_' + NCDF_HOURS_STR + NCDF_MINUTES_STR $
                                        + '_' + DIR_ID $
                                        + '_' + SENSOR_CONFIG.BAND_REF_LABEL[BK] $
                                        + '_' + STRTRIM(STRING(LONG(WAVK)),2) $
                                        + '.jpg'
        ENDIF ELSE BEGIN
          OUT_FIG_FILENAME = OUT_FILEPATH + NCDF_YEAR_STR + DL + OUT_FILENAME_BASE + '_' + NCDF_YEAR_STR + NCDF_MONTH_STR + NCDF_DAY_STR $
                                        + '_' + NCDF_HOURS_STR + NCDF_MINUTES_STR $
                                        + '_' + SENSOR_CONFIG.BAND_REF_LABEL[BK] $
                                        + '_' + STRTRIM(STRING(LONG(WAVK)),2) $
                                        + '.jpg'
        ENDELSE                                
        RES = GET_SENSOR_TO_SIMULATION_PRODUCT_PLOTS(OUT_FIG_FILENAME, RTOA_TG_RATIO, RTOA_TG_RATIO_ESTIM, REF_TO_SIM_RATIO)

        ;-------------------
        ; COMPLETE NCDF CALIBRATION STRUCTURE
        
        NB_PIX = NCDF_CALIB_STRUCT.VARIABLES.CALIB_PIXEL_NUMBER(NUM_DIR)
        NCDF_CALIB_STRUCT.VARIABLES.BAND_GAZ_TRANS(0:NB_PIX-1,NUM_DIR,K)        = TO3_K
        NCDF_CALIB_STRUCT.VARIABLES.BAND_RHO_SIM(0:NB_PIX-1,NUM_DIR,K)          = I_K
        NCDF_CALIB_STRUCT.VARIABLES.BAND_RHO_SIM_UNCERT(0:NB_PIX-1,NUM_DIR,K)   = BAND_RHO_SIM_UNCERT
        NCDF_CALIB_STRUCT.VARIABLES.BAND_REF_TO_SIM_RATIO(0:NB_PIX-1,NUM_DIR,K) = REF_TO_SIM_RATIO
        NCDF_CALIB_STRUCT.VARIABLES.BAND_VALID_INDEX(0:NB_PIX-1,NUM_DIR,K) = INDGEN(NB_PIX)
        
        NEXT_BAND:
 
 			ENDFOR ; ENDLOOP ON VIS BANDS  

			;----------------------------------------
			; CHECK RETRIEVED AEROSOL OPTICAL THICKNESS AT 865 NM

      IF DEBUG_MODE THEN BEGIN
          PRINT, ' ------ '
          PRINT, ' DEBUG_MODE - MIN/MAX/MEAN/STDDEV(TAUA_865_CHECK)     = ', MIN(TAUA_865_CHECK), MAX(TAUA_865_CHECK), MEAN(TAUA_865_CHECK)
          PRINT, ' DEBUG_MODE - TAUA_865_CLIM     = ', TAUA_865_CLIM
          PRINT, ' ------ '
			ENDIF
			
			INDEX = WHERE(ABS(TAUA_865_CHECK - TAUA_865_CLIM) LE 0.02, COUNT)
			IF COUNT EQ 0 THEN BEGIN
				PRINT, FCT_NAME+':  WARNING, NO SENSOR DATA FOUND WITH PROPER TAUA_865 >> DIRECTION SKIPPED'
				GOTO, NEXT_DIR
			ENDIF
			
			IF COUNT NE NB_PIX THEN BEGIN
				
				; UPDATE RESULTS WITH NEW VALID POINTS
				; USED BAND_VALID_INDEX FIELD FOR THIS PURPOSE 
				; WARNING : THIS STEP WOULD BE UPDATED IF THIS FIELD WAS REALLY USED TO SELECT VALID PIXEL BAND IN PREVIOUS STEPS !!!
				IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+':  WARNING, UPDATE RESULTS WITH NEW VALID POINTS (TAUA_865 CRITERIA)'
				
				IF DEBUG_MODE THEN PRINT, ' DEBUG_MODE - !!!!!!!!!!! WARNING - NO GRAPH UPDATED  (TAUA_865 CRITERIA) !!!!!!!!!!!'
				
        NCDF_CALIB_STRUCT.VARIABLES.BAND_VALID_INDEX(*,NUM_DIR,*) = MISSING_VALUE_LONG
        FOR NUM_BAND=0, NB_BANDS_VIS-1 DO NCDF_CALIB_STRUCT.VARIABLES.BAND_VALID_INDEX(0:COUNT-1,NUM_DIR,NUM_BAND) = INDEX
								
		  ENDIF ELSE IF DEBUG_MODE THEN PRINT, ' DEBUG_MODE - !!!!!!!!!!! NO NEED TO UPDATE GRAPH  (TAUA_865 CRITERIA) !!!!!!!!!!!'
		  
      AT_LEAST_ONE_DIR = 1
      
      NEXT_DIR:
      
    ENDFOR ; END LOOP ON VIEWING DIRECTIONS

    ; CHECK IF AT LEAST ONE DIRECTION HAS BEEN PROCESSED 
    IF AT_LEAST_ONE_DIR EQ 1 THEN BEGIN
      
      ;----------------------
      ; WRITE CALIBRATION OUTPUT
      
      STATUS = NETCDFWRITE_CALIB_OUTPUT(PROCESS_DATE, NCDF_CALIB_STRUCT, NCDF_FILENAME=NCDF_FILENAME, VERBOSE=VERBOSE)
      IF STATUS NE STATUS_OK THEN BEGIN
        IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': ERROR DURING OUTPUT CALIBRATION WRITING >> RETURNING'    
        RETURN, STATUS_ERROR
      ENDIF
      
    ENDIF ELSE IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': NO DIRECTION WITH VALID PIXEL >> FILE SKIPPED'

    NEXT_IFILES:

  ENDFOR ;  END LOOP ON FILES

  NO_IFILES:

  PRINT, FCT_NAME + ': ***** PROCESS COMPLETED SUCCESSFULLY *****'
  RETURN, STATUS_OK

END
