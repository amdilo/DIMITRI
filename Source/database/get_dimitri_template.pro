;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_DIMITRI_TEMPLATE       
;* 
;* PURPOSE:
;*      RETURNS THE DATABASE STRUCTURE, HEADER OR TEMPLATE DEPENDING ON KEYWORD
;* 
;* CALLING SEQUENCE:
;*      RES = GET_DIMITRI_TEMPLATE(NB_FILES)      
;* 
;* INPUTS:
;*      NB_FILES - THE NUMBER OF INPUT FILES. 
;*
;* KEYWORDS:
;*      DB        - SET TO RETRIEVE THE DATABASE STRUCTURE 
;*      HDR       - SET TO RETRIEVE THE DATABASE HEADER
;*      TEMPLATE  - SET TO RETRIEVE THE DATABASE TEMPLATE
;*      FORMAT    - SET TO RETRIEVE THE DATABASE FORMAT
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*      
;* OUTPUTS:
;*      A STRUCTURE, HEADER OR TEMPLATE DEPENDING ON KEYWORDS 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      22 NOV 2010 - C KENT    - DIMITRI-2 V1.0
;*      01 DEC 2010 - C KENT    - ADDED VERBOSE KEYWORD
;*      02 DEC 2010 - C KENT    - UPDATED HEADER INFORMATION
;*      08 MAR 2012 - C KENT    - ADDED ROI COVER
;*      29 JAN 2015 - NCG / MAGELLIUM - UPDATE WITH DIMITRI V4.0 SPECIFICATIONS
;*
;* VALIDATION HISTORY:
;*      01 DEC 2010 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1: COMPILATION SUCCESSFUL,
;*                                VERBOSE COMMENTS,TESTED NB_FILES ERROR CATCH,
;*                                DATABASE STRUCTURE RETRIEVAL,HEADER RETRIEVAL,
;*                                TEMPLATE RETRIEVAL,FORMAT RETRIEVAL,NO_KEYWORD ERROR  
;*      12 APR 2011 - C KENT    - LINUX 64-BIT IDL 8.0: NOMINAL COMPILATION AND OPERATION
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_DIMITRI_TEMPLATE,NB_FILES,DB=DB,HDR=HDR,TEMPLATE=TEMPLATE,FORMAT=FORMAT,VERBOSE=VERBOSE

;-----------------------------------------
; CHECK NUMBER OF FILES SUPPLIED

  IF NB_FILES LT 1 THEN BEGIN
    PRINT, 'DIMITRI_TEMPLATE: ERROR, NUMBER OF FILES SET TO BELOW 1'
    RETURN,-1
  ENDIF

;-----------------------------------------
; IF REQUESTED, DEFINE AND RETURN THE DATABASE STRUCTURE

  IF KEYWORD_SET(DB) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_TEMPLATE: RETRIEVING DATABASE STRUCTURE'
    DB_DATA = {$
              DIMITRI_DATE        : STRARR(NB_FILES),$
              SITE_NAME           : STRARR(NB_FILES),$  ; REGION
              SITE_TYPE           : STRARR(NB_FILES),$  ; new
              SITE_COORDINATES    : STRARR(NB_FILES),$  ; new
              SENSOR              : STRARR(NB_FILES),$
              PROCESSING_VERSION  : STRARR(NB_FILES),$
              YEAR                : INTARR(NB_FILES),$
              MONTH               : INTARR(NB_FILES),$
              DAY                 : INTARR(NB_FILES),$
              DOY                 : INTARR(NB_FILES),$
              DECIMAL_YEAR        : DBLARR(NB_FILES),$
              L1_FILENAME         : STRARR(NB_FILES),$  ; FILENAME
              L1_INGESTED_FILENAME: STRARR(NB_FILES),$  ; new
              ROI_STATUS          : INTARR(NB_FILES),$  ; ROI_COVER
              ROI_PIX_NUM         : DBLARR(NB_FILES),$  ; NUM_ROI_PX
              THETA_N_MEAN        : DBLARR(NB_FILES),$  ; new
              THETA_R_MEAN        : DBLARR(NB_FILES),$  ; new
              AUTO_CS_1_NAME      : STRARR(NB_FILES),$  ; AUTO_CS
              AUTO_CS_1_MEAN      : DBLARR(NB_FILES),$  ; new
              ROI_CS_1_CLEAR_PIX_NUM : DBLARR(NB_FILES),$  ; new  
              AUTO_CS_2_NAME      : STRARR(NB_FILES),$  ; new
              AUTO_CS_2_MEAN      : DBLARR(NB_FILES),$  ; new
              ROI_CS_2_CLEAR_PIX_NUM : DBLARR(NB_FILES),$  ; new  
              BRDF_CS_MEAN        : DBLARR(NB_FILES),$  ; new
              SSV_CS_MEAN         : DBLARR(NB_FILES),$  ; new  
              MANUAL_CS           : INTARR(NB_FILES),$
              ERA_WIND_SPEED_MEAN : DBLARR(NB_FILES),$  ; new  
              ERA_WIND_DIR_MEAN   : DBLARR(NB_FILES),$  ; new  
              ERA_OZONE_MEAN      : DBLARR(NB_FILES),$  ; new  
              ERA_PRESSURE_MEAN   : DBLARR(NB_FILES),$  ; new  
              ERA_WATERVAPOUR_MEAN: DBLARR(NB_FILES),$  ; new  
              ESA_CHLOROPHYLL_MEAN: DBLARR(NB_FILES),$  ; new  
              AUX_DATA_1          : STRARR(NB_FILES),$
              AUX_DATA_2          : STRARR(NB_FILES),$
              AUX_DATA_3          : STRARR(NB_FILES),$
              AUX_DATA_4          : STRARR(NB_FILES),$
              AUX_DATA_5          : STRARR(NB_FILES),$
              AUX_DATA_6          : STRARR(NB_FILES),$
              AUX_DATA_7          : STRARR(NB_FILES),$
              AUX_DATA_8          : STRARR(NB_FILES),$
              AUX_DATA_9          : STRARR(NB_FILES),$
              AUX_DATA_10         : STRARR(NB_FILES)  }
     ;IF KEYWORD_SET(VERBOSE) THEN HELP,DB_DATA
     RETURN, DB_DATA
   ENDIF

;-----------------------------------------
; IF REQUESTED, DEFINE AND RETURN THE DATABASE HEADER

  IF KEYWORD_SET(HDR) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_TEMPLATE: RETRIEVING DATABASE HEADER'
    DB_HEAD =  STRING('DIMITRI_DATE;SITE_NAME;SITE_TYPE;SITE_COORDINATES;'+$
                      'SENSOR;PROCESSING_VERSION;'+$
                      'YEAR;MONTH;DAY;DOY;DECIMAL_YEAR;'+$
                      'L1_FILENAME;L1_INGESTED_FILENAME;'+$
                      'ROI_STATUS;ROI_PIX_NUM;THETA_N_MEAN;THETA_R_MEAN;'+$
                      'AUTO_CS_1_NAME;AUTO_CS_1_MEAN;ROI_CS_1_CLEAR_PIX_NUM;'+$
                      'AUTO_CS_2_NAME;AUTO_CS_2_MEAN;ROI_CS_2_CLEAR_PIX_NUM;'+$
                      'BRDF_CS_MEAN;SSV_CS_MEAN;MANUAL_CS;'+$
                      'ERA_WIND_SPEED_MEAN;ERA_WIND_DIR_MEAN;ERA_OZONE_MEAN;'+$
                      'ERA_PRESSURE_MEAN;ERA_WATERVAPOUR_MEAN;ESA_CHLOROPHYLL_MEAN;'+$
                      'AUX_DATA_1;AUX_DATA_2;AUX_DATA_3;AUX_DATA_4;AUX_DATA_5;'+$
                      'AUX_DATA_6;AUX_DATA_7;AUX_DATA_8;AUX_DATA_9;AUX_DATA_10')
    IF KEYWORD_SET(VERBOSE) THEN HELP, DB_HEAD
    RETURN, DB_HEAD
  ENDIF

;-----------------------------------------
; IF REQUESTED, DEFINE AND RETURN THE DATABASE TEMPLATE

  IF KEYWORD_SET(TEMPLATE) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_TEMPLATE: RETRIEVING DATABASE TEMPLATE'

    DB_NAME = [ 'DIMITRI_DATE','SITE_NAME','SITE_TYPE','SITE_COORDINATES',$
                'SENSOR','PROCESSING_VERSION','YEAR','MONTH','DAY','DOY','DECIMAL_YEAR',$
                'L1_FILENAME','L1_INGESTED_FILENAME',$
                'ROI_STATUS','ROI_PIX_NUM','THETA_N_MEAN','THETA_R_MEAN',$
                'AUTO_CS_1_NAME','AUTO_CS_1_MEAN','ROI_CS_1_CLEAR_PIX_NUM',$
                'AUTO_CS_2_NAME','AUTO_CS_2_MEAN','ROI_CS_2_CLEAR_PIX_NUM',$
                'BRDF_CS_MEAN','SSV_CS_MEAN','MANUAL_CS',$
                'ERA_WIND_SPEED_MEAN','ERA_WIND_DIR_MEAN','ERA_OZONE_MEAN',$
                'ERA_PRESSURE_MEAN','ERA_WATERVAPOUR_MEAN','ESA_CHLOROPHYLL_MEAN',$
                'AUX_DATA_1','AUX_DATA_2','AUX_DATA_3','AUX_DATA_4','AUX_DATA_5',$
                'AUX_DATA_6','AUX_DATA_7','AUX_DATA_8','AUX_DATA_9','AUX_DATA_10' ]

    DB_TYPE=[7,7,7,7, $  
              7,7,3,3,3,3,5, $  
              7,7, $
              3,5,5,5, $
              7,5,5, $
              7,5,5, $
              7,7,3, $
              5,5,5, $
              5,5,5, $
              7,7,7,7,7, $
              7,7,7,7,7 ]
                      
    DB_TEMPLATE={    VERSION        : 1.0                       , $
                     DATASTART      : 1 , $
                     DELIMITER      : ';' , $
                     MISSINGVALUE   : !values.f_NaN, $
                     COMMENTSYMBOL  : ''          , $
                     FIELDCOUNT     : N_ELEMENTS(DB_NAME), $
                     FIELDTYPES     : DB_TYPE, $
                     FIELDNAMES     : DB_NAME, $
                     FIELDLOCATIONS : INDGEN(N_ELEMENTS(DB_NAME)), $
                     FIELDGROUPS    : [INDGEN(N_ELEMENTS(DB_NAME))]}
    ;IF KEYWORD_SET(VERBOSE) THEN HELP,DB_TEMPLATE       
    RETURN, DB_TEMPLATE
  ENDIF

;-----------------------------------------
; IF REQUESTED, DEFINE AND RETURN THE DATABASE FORMAT

  IF KEYWORD_SET(FORMAT) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_TEMPLATE: RETRIEVING DATABASE FORMAT CODE'
     DB_FORMAT = '(6(A,1H;),4(I4,1H;),1(D20.12,1H;),2(A,1H;),'+ $                           ; DIMITRI_DATE to L1_INGESTED_FILENAME
                  '1(I3,1H;),1(D15.1,1H;),2(D6.3,1H;),'+ $                                  ; ROI_STATUS to THETA_R_MEAN
                  '1(A,1H;),1(D6.3,1H;),1(D15.1,1H;),1(A,1H;),1(D6.3,1H;),1(D15.1,1H;),'+ $ ; AUTO_CS_1_NAME to ROI_CS_2_CLEAR_PIX_NUM
                  '1(D6.3,1H;),1(D6.3,1H;),1(I3,1H;),'+ $                                   ; BRDF_CS_MEAN to MANUAL_CS
                  '6(D20.12,1H;),10(A,1H;))'                                                 ; ERA_WIND_SPEED_MEAN to AUX_DATA_10
                  
          
     IF KEYWORD_SET(VERBOSE) THEN HELP,DB_FORMAT   
    RETURN, DB_FORMAT
  ENDIF

;-----------------------------------------
; IF NO KEYWORDS THEN RETURN AN ERROR

  RETURN,-1

END
