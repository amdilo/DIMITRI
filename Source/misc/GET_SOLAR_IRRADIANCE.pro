;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SOLAR_IRRADIANCE       
;* 
;* PURPOSE:
;*      RETURNS THE SOLAR IRRADIANCE STRUCTURE 
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SOLAR_IRRADIANCE()      
;* 
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      BAND_CONFIG_STRUCT - A STRUCTURE CONFIGURATION FIELDS
;*                                - WAVELENGTH' :  Wavelength
;*                                - SOLAR_IRRADIANCE': Solar irradiance value
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      17 OCT 2014 - NCG / MAGELLIUM   - DIMITRI-3 MAG
;*
;* VALIDATION HISTORY:
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SOLAR_IRRADIANCE, VERBOSE=VERBOSE

	STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

;------------------------------------
; DEFINE SENSOR FILE
  
  SI_FILE = GET_DIMITRI_LOCATION('SOLAR_IRRADIANCE')
  RES = FILE_INFO(SI_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SOLAR_IRRADIANCE: ERROR, SENSOR INFORMATION FILE NOT FOUND'
    RETURN, STATUS_ERROR
  ENDIF

;------------------------------------
; RETRIEVE TEMPLATE AND READ DATA FILE  
  
  SOLAR_TEMPLATE = GET_SOLAR_IRRADIANCE_TEMPLATE()
  SOLAR_DATA = READ_ASCII(SI_FILE,TEMPLATE=SOLAR_TEMPLATE)

  RETURN, SOLAR_DATA
 
END


