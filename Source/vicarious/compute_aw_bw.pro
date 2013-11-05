;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     COMPUTE_AW_BW 
;* 
;* PURPOSE:
;*      COMPUTE PURE SEAWATER ABSORPTION AND SCATTERING COEFFICIENT AT GIVEN BAND 
;* 
;* CALLING SEQUENCE:
;*      RES = COMPUTE_AW_BW(WAV)
;* 
;* INPUTS:
;*      WAV              - THE WAVELENGTH E.G. 443 NM
;*
;* KEYWORDS:
;*      VERBOSE          - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      ABW              - 2D-ARRAY WITH ABSORPTION AND SCATTERING COEFFICIENTS 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION.
;*
;**************************************************************************************
;**************************************************************************************
FUNCTION COMPUTE_AW_BW, WAV, VERBOSE=VERBOSE

;-----------------------------------------
; DEFINE NAME OF FUNCTION

 FCT_NAME='COMPUTE_AW_BW'

;---------------------------
; GET AUX FILENAME

  WATER_FILE = GET_DIMITRI_LOCATION('WATER_COEF',VERBOSE=VERBOSE)

  RES = FILE_INFO(WATER_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, PURE SEAWATER COEF FILE NOT FOUND'
    RETURN,-1
  ENDIF

;-----------------------------------------
; OPEN PURE SEAWATER COEFFICIENT AUX FILE

 IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': OPEN PURE SEAWATER COEFFICIENT AUX FILE'
 res  = READ_ASCII(WATER_FILE, data_start=29)
 coef = FLOAT(RES.FIELD1)
 
;-----------------------------------------
; INTERPOLATE TO CURRENT WAVELENGTH

 ABW = [INTERPOL(coef[1,*], coef[0,*], WAV), INTERPOL(coef[2,*], coef[0,*], WAV)]

 RETURN, ABW

END
