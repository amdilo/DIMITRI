;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     COMPUTE_E_CHI
;* 
;* PURPOSE:
;*      COMPUTE MOREL AND MARITORENA 2001 E AND CHI COEFFICIENT TO RETRIEVE MARINE REFLECTANCE
;*      AS A FUNCTION OF CHLOROPHYLL 
;* 
;* CALLING SEQUENCE:
;*      RES = COMPUTE_E_CHI(WAV)
;* 
;* INPUTS:
;*      WAV              - THE WAVELENGTH E.G. 443 NM
;*
;* KEYWORDS:
;*      VERBOSE          - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      ECHI             - 2D-ARRAY WITH E AND CHI COEFFICIENTS 
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
FUNCTION COMPUTE_E_CHI, WAV, VERBOSE=VERBOSE


;-----------------------------------------
; DEFINE NAME OF FUNCTION

 FCT_NAME='COMPUTE_E_CHI'

;---------------------------
; GET AUX FILENAME

  ECHI_FILE = GET_DIMITRI_LOCATION('MM01_ECHI',VERBOSE=VERBOSE)

  RES = FILE_INFO(ECHI_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    PRINT, FCT_NAME+': ERROR, MM01 E-CHI FILE NOT FOUND'
    RETURN,-1
  ENDIF

 ;-----------------------------------------
 ; OPEN MOREL E-CHI AUX FILE

 IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': OPEN PURE SEAWATER COEFFICIENT AUX FILE'
 res=READ_ASCII(ECHI_FILE, DATA_START=1)
 coef=FLOAT(RES.FIELD1)
 
 ;-----------------------------------------
 ; INTERPOLATE

 ECHI = [INTERPOL(coef[1,*], coef[0,*], WAV), INTERPOL(coef[2,*], coef[0,*], WAV)]

 RETURN, ECHI

END
