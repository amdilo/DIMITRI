;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      COPY_INGESTION_TO_CALIBRATION_NCDF_STRUCTURE       
;* 
;* PURPOSE:
;*      COPY THE STRUCTURE WHICH CORRESPONDS TO THE OUTPUT NCDF FILE OF THE INGESTION PROCESS 
;*      TO STRUCTURE WHICH CORRESPONDS TO THE OUTPUT NCDF FILE OF THE SUNGLINT, RAYLEIGH OR 
;*      DESERT SENSOR TO SIMULATION COMPARISON PROCESSES 
;* 
;* CALLING SEQUENCE:
;*      RES = COPY_INGESTION_TO_CALIBRATION_NCDF_STRUCTURE(NCDF_INGEST_STRUCT=NCDF_INGEST_STRUCT, NCDF_CALIB_STRUCT=NCDF_CALIB_STRUCT)      
;* 
;* INPUTS:
;*      NCDF_INGEST_STRUCT  = OUTPUT STRUCTURE OF THE INGESTION PROCESS
;*      NCDF_CALIB_STRUCT   = OUTPUT STRUCTURE OF THE SENSOR TO SIMULATION COMPARISON PROCESS
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      20 FEB 2015 - NCG / MAGELLIUM - CREATION (DIMITRI V4.0)
;*
;* VALIDATION HISTORY:
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************
FUNCTION COPY_INGESTION_TO_CALIBRATION_NCDF_STRUCTURE, NCDF_INGEST_STRUCT=NCDF_INGEST_STRUCT, NCDF_CALIB_STRUCT=NCDF_CALIB_STRUCT,VERBOSE=VERBOSE

  DEBUG_MODE = 0      ; SET TO 1 IF WANT TO DEBUG THIS PROCEDURE
  
  FCT_NAME = 'COPY_INGESTION_TO_CALIBRATION_NCDF_STRUCTURE'
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': START'
  
  STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
  STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')
  MISSING_VALUE = GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE')
  
  ;----------------------------
  ; COMPARE DIMENSIONS
  
  IF (  NCDF_INGEST_STRUCT.DIMENSIONS.ROI_PIXEL_NUMBER NE NCDF_CALIB_STRUCT.DIMENSIONS.ROI_PIXEL_NUMBER OR $
        NCDF_INGEST_STRUCT.DIMENSIONS.VIEWDIR_NUMBER NE NCDF_CALIB_STRUCT.DIMENSIONS.VIEWDIR_NUMBER ) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN BEGIN
      PRINT, FCT_NAME + ': ERROR, DIMENSIONS DO NOT CORRESPOND BETWEEN INGEST AND CALIB STRUCTURE >> RETURNING'
    ENDIF 
    RETURN, STATUS_ERROR
  ENDIF
  
  ;----------------------------
  ; COPY GLOBAL ATTIBUTES
  
  NB_INGEST_TAGS = N_TAGS(NCDF_INGEST_STRUCT.GLOBAL_ATT)
  INGEST_TAGS_NAME = TAG_NAMES(NCDF_INGEST_STRUCT.GLOBAL_ATT)
  CALIB_TAGS_NAME = TAG_NAMES(NCDF_CALIB_STRUCT.GLOBAL_ATT)
  
  ; SKIP OF THE TOOL/DATE ATTRIBUTS
  FOR NUM_INGEST=3, NB_INGEST_TAGS-1 DO BEGIN
    IF DEBUG_MODE EQ 1 THEN PRINT, FCT_NAME + ': DEBUG_MODE - TAGS_NAME = ', INGEST_TAGS_NAME[NUM_INGEST], ' / VALUE = ', NCDF_INGEST_STRUCT.GLOBAL_ATT.(NUM_INGEST)
    IDX = WHERE(STRCMP(CALIB_TAGS_NAME, INGEST_TAGS_NAME[NUM_INGEST]) EQ 1, COUNT)
    IF COUNT EQ 1 THEN NCDF_CALIB_STRUCT.GLOBAL_ATT.(IDX) = NCDF_INGEST_STRUCT.GLOBAL_ATT.(NUM_INGEST)
  ENDFOR
  
  ;----------------------------
  ; COPY VARIABLES
  NB_INGEST_TAGS = N_TAGS(NCDF_INGEST_STRUCT.VARIABLES)
  INGEST_TAGS_NAME = TAG_NAMES(NCDF_INGEST_STRUCT.VARIABLES)
  CALIB_TAGS_NAME = TAG_NAMES(NCDF_CALIB_STRUCT.VARIABLES)
  
  IDX_WITHOUT_REFL_BANDS = WHERE(STRMATCH(INGEST_TAGS_NAME, '*REFL_BAND*') EQ 0, COUNT)
                   
  FOR NUM_INGEST=0, COUNT-1 DO BEGIN
    IF DEBUG_MODE EQ 1 THEN PRINT, FCT_NAME + ': DEBUG_MODE - TAGS_NAME = ', INGEST_TAGS_NAME[IDX_WITHOUT_REFL_BANDS[NUM_INGEST]], ' / SIZE = ', SIZE(NCDF_INGEST_STRUCT.VARIABLES.(IDX_WITHOUT_REFL_BANDS[NUM_INGEST]),/DIMENSIONS)
    IDX = WHERE(STRMATCH(CALIB_TAGS_NAME, INGEST_TAGS_NAME[IDX_WITHOUT_REFL_BANDS[NUM_INGEST]]) EQ 1, COUNT)
    IF COUNT EQ 1 THEN NCDF_CALIB_STRUCT.VARIABLES.(IDX) = NCDF_INGEST_STRUCT.VARIABLES.(IDX_WITHOUT_REFL_BANDS[NUM_INGEST])
  ENDFOR
  
  ;----------------------------
  ; COPY SELECTED BANDS OF VARIABLES 'REFL_BAND'
  IDX_REFL_BANDS = WHERE(STRMATCH(INGEST_TAGS_NAME, '*REFL_BAND*') EQ 1, COUNT)
  IDX = WHERE(STRMATCH(CALIB_TAGS_NAME, INGEST_TAGS_NAME[IDX_REFL_BANDS]) EQ 1, COUNT)
  FOR NUM_BAND=0, N_ELEMENTS(NCDF_CALIB_STRUCT.VARIABLES.REFL_BAND_IDS)-1 DO BEGIN
    NCDF_CALIB_STRUCT.VARIABLES.(IDX)[*,*,NUM_BAND] = NCDF_INGEST_STRUCT.VARIABLES.(IDX_REFL_BANDS)[ *,*,NCDF_CALIB_STRUCT.VARIABLES.REFL_BAND_IDS[NUM_BAND] ]
  ENDFOR
  ;----------------------------
  ; COPY VARIABLES ATTRIBUTS
  NB_INGEST_TAGS = N_TAGS(NCDF_INGEST_STRUCT.VARIABLES_ATT)
  INGEST_TAGS_NAME = TAG_NAMES(NCDF_INGEST_STRUCT.VARIABLES_ATT)
  CALIB_TAGS_NAME = TAG_NAMES(NCDF_CALIB_STRUCT.VARIABLES_ATT)
  
  FOR NUM_INGEST=0, NB_INGEST_TAGS-1 DO BEGIN
    IF DEBUG_MODE EQ 1 THEN PRINT, FCT_NAME + ': DEBUG_MODE - TAGS_NAME = ', INGEST_TAGS_NAME[NUM_INGEST], ' / SIZE = ', SIZE(NCDF_INGEST_STRUCT.VARIABLES_ATT.(NUM_INGEST),/DIMENSIONS)
    IDX = WHERE(STRCMP(CALIB_TAGS_NAME, INGEST_TAGS_NAME[NUM_INGEST]) EQ 1, COUNT)
    IF COUNT EQ 1 THEN NCDF_CALIB_STRUCT.VARIABLES_ATT.(IDX) = NCDF_INGEST_STRUCT.VARIABLES_ATT.(NUM_INGEST)
  ENDFOR
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': END'
  
  RETURN, STATUS_OK
  
END
