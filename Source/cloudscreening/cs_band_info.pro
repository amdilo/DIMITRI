;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      CS_BAND_INFO       
;* 
;* PURPOSE:
;*      THIS FUNCTION RETURNS THE DIMITRI BAND INDEXES FOR A GIVEN CLOUD SCREENING ALGORITHM.
;* 
;* CALLING SEQUENCE:
;*      RES = CS_BAND_INFO(CS_ALGO)    
;* 
;* INPUTS:
;*      CS_ALGO  - A STRING OF THE CLOUD SCREENING ALGORITHMS NAME
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      CS_BANDS - A INTEGER ARRAY OF DIMITRI BAND INDEXES REQUIRED
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      07 APR 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      12 APR 2011 - C KENT   - NOMINAL COMPILATION AND OPERATION ON WINDOWS 32BIT 
;*                               IDL 7.1 AND LINUX 64BIT IDL 8.0
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION CS_BAND_INFO,CS_ALGO,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'CS_BAND_INFO: RETURNING BAND INDEXES FOR CS ALGORITHM - ',STRUPCASE(CS_ALGO)
  CASE STRUPCASE(CS_ALGO) OF
    'VGT'         : CS_BANDS = [2,9,16,26]
    'VGT_DESERT'  : CS_BANDS = [2,9,16,26]
    
    ; BBT ADDED 2 BANDS 'GLOBCARBON'  : CS_BANDS = [2,11,12,18]
    'GLOBCARBON'  : CS_BANDS = [2,11,12,18]
    'MERIS_DESERT'  : CS_BANDS = [2,9,11,12,13,18]
    'MERIS_OCEAN'   : CS_BANDS = [2,9,11,12,13,18]
    
    'GLOBCARBON_P': CS_BANDS = [2,9,14,18]
    'PARASOL_OCEAN': CS_BANDS = [2,9,14,18]
    'PARASOL_DESERT': CS_BANDS = [2,9,14,18]
    
    'LCCA'        : CS_BANDS = [7,9,18,26,30]
    'ATSR_DESERT' : CS_BANDS = [7,9,18,26,30]
    'ATSR_OCEAN'  : CS_BANDS = [7,9,18,26,30]
    
    'MODIS_OCEAN' : CS_BANDS = [7,9,18,26,30,31,16]
    'MODIS_OCEAN'  : CS_BANDS = [7,9,18,26,30,31,16,15]
    'MODIS_DESERT' : CS_BANDS = [7,9,18,26,30,31,16,15]
    
    ELSE          : CS_BANDS = [-1]
  ENDCASE

  RETURN,CS_BANDS
END