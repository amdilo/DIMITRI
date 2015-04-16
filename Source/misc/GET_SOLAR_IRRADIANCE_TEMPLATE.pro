;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SOLAR_IRRADIANCE_TEMPLATE       
;* 
;* PURPOSE:
;*      RETURNS THE TEMPLATE REQUIRED FOR READING THE SOLAR IRRADIANCE FILE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SOLAR_IRRADIANCE_TEMPLATE()      
;* 
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      INDEX_TEMPLATE  - A TEMPLATE FOR READING THE SOLAR IRRADIANCE FILE
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
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SOLAR_IRRADIANCE_TEMPLATE,VERBOSE=VERBOSE

    IF KEYWORD_SET(VERBOSE) THEN PRINT,'GET_SOLAR_IRRADIANCE_TEMPLATE: RETRIEVING TEMPLATE'
    
    TEMP_NAME      = ['WAVELENGTH','SOLAR_IRRADIANCE']
    TEMP_TYPE      = [4, 4]
    INDEX_TEMPLATE = {VERSION       : 1.0                       , $
                     DATASTART      : 1 , $
                     DELIMITER      : ';' , $
                     MISSINGVALUE   : !VALUES.F_NAN, $
                     COMMENTSYMBOL  : ''          , $
                     FIELDCOUNT     : N_ELEMENTS(TEMP_NAME), $
                     FIELDTYPES     : TEMP_TYPE, $
                     FIELDNAMES     : TEMP_NAME, $
                     FIELDLOCATIONS : INDGEN(N_ELEMENTS(TEMP_NAME)), $
                     FIELDGROUPS    : [INDGEN(N_ELEMENTS(TEMP_NAME))]}
    
    ;IF KEYWORD_SET(VERBOSE) THEN HELP,INDEX_TEMPLATE       
    RETURN, INDEX_TEMPLATE

END