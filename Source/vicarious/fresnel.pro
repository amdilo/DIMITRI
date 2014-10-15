;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     FRESNEL
;* 
;* PURPOSE:
;*      COMPUTE FRESNEL REFLECTANCE AT AIR-SEA INTERFACE 
;* 
;* CALLING SEQUENCE:
;*      RES = FRESNEL(RAA, VZA, SZA, WAV)
;* 
;* INPUTS:
;*      RAA      - THE RELATIVE AZIMUTH ANGLE IN DEGREES
;*      VZA      - THE VIEWING ZENITH ANGLE IN DEGREES 
;*      SZA      - THE SOLAR ZENITH ANGLE IN DEGREES
;*      WAV      - THE WAVELENGTH IN NM
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      R        - FRESNEL REFLECTANCE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        20 JAN 2014 - C MAZERAN - FIRST IMPLEMENTATION 
;*
;* VALIDATION HISTORY:
;*        20 JAN 2014 - C MAZERAN - LINUX 64-BIT MACHINE IDL 8.0, NOMINAL COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************
FUNCTION FRESNEL, RAA, VZA, SZA, WAV, VERBOSE=VERBOSE

;-----------------------------------------
; DEFINE NAME OF FUNCTION

 FCT_NAME='FRESNEL'

;---------------------------
; GET AUX FILENAME

 NW_FILE = GET_DIMITRI_LOCATION('REFRACT_INDEX',VERBOSE=VERBOSE)
 RES = FILE_INFO(NW_FILE)
 IF RES.EXISTS EQ 0 THEN BEGIN
   PRINT, FCT_NAME+': ERROR, SEA WATER REFRACTIVE INDEX FILE NOT FOUND'
   RETURN,-1
 ENDIF

 ;-----------------------------------------
 ; OPEN SEA WATER REFRACTIVE INDEX AUX FILE

 IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': OPEN SEA WATER REFRACTIVE INDEX AUX FILE'
 RES=READ_ASCII(NW_FILE, DATA_START=2)
 DATA=FLOAT(RES.FIELD1)

 ;-----------------------------------------
 ; INTERPOLATE

 NW_R = INTERPOL(DATA[1,*], DATA[0,*], WAV)
 NW_I = INTERPOL(DATA[2,*], DATA[0,*], WAV)

;-----------------------------------------
; COMPUTES GEOMETRICAL QUANTITIES 

 COS2OMEGA = COS(SZA*!DTOR)*COS(VZA*!DTOR)+SIN(SZA*!DTOR)*SIN(VZA*!DTOR)*COS(RAA*!DTOR)
 COSOMEGA  = COS(0.5*ACOS(COS2OMEGA))
 SINOMEGA  = SQRT(1. - COSOMEGA*COSOMEGA)

;-----------------------------------------
; FRESNEL REFLECTANCE 

 A1  = ABS(NW_R*NW_R - NW_I*NW_I - SINOMEGA*SINOMEGA)
 A2  = SQRT(A1*A1 + 4.*NW_R*NW_R*NW_I*NW_I)
 U   = sqrt(0.5*(A1 + A2))
 V   = sqrt(0.5*(A2 - A1))
 RR2 = ((COSOMEGA-U)*(COSOMEGA-U) + V*V) / ((COSOMEGA+U)*(COSOMEGA+U) + V*V)
 B1  = (NW_R*NW_R - NW_I*NW_I)*COSOMEGA
 B2  = 2.*NW_R*NW_I*COSOMEGA
 RL2 = ((B1-U)*(B1-U) + (B2+V)*(B2+V))/((B1+U)*(B1+U) + (B2-V)*(B2-V))
 R   = 0.5*(RR2 + RL2)

 RETURN, R

END
