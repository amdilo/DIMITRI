;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_EOS_SENSOR_AND_6S_TEMPLATE       
;* 
;* PURPOSE:
;*      RETURNS THE TEMPLATE REQUIRED FOR READING THE EOS FILE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_EOS_SENSOR_AND_6S_TEMPLATE()      
;* 
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      INDEX_TEMPLATE  - A TEMPLATE FOR READING THE EOS FILE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      16 DEC 2014 - NCG / MAGELLIUM   - DIMITRI-3.0 MAG
;;*
;* VALIDATION HISTORY:
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*       
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_EOS_SENSOR_AND_6S_TEMPLATE, SENSOR,VERBOSE=VERBOSE

    IF KEYWORD_SET(VERBOSE) THEN PRINT,'GET_EOS_SENSOR_AND_6S_TEMPLATE: RETRIEVING TEMPLATE'
        
    TEMP_NAME = [ 'SENSOR', 'BAND_NUMBER', 'CENTRAL_WV', 'EOS_SENSOR', 'EOS_6S' ]
    TEMP_TYPE = [ 7, 2, 2, 4, 4 ]
    
    INDEX_TEMPLATE = {VERSION       : 1.0                       , $
                     DATASTART      : 1 , $  ; ONE HEADER LINE 
                     DELIMITER      : ' ' , $
                     MISSINGVALUE   : !VALUES.F_NAN, $
                     COMMENTSYMBOL  : ''          , $
                     FIELDCOUNT     : N_ELEMENTS(TEMP_NAME), $
                     FIELDTYPES     : TEMP_TYPE, $
                     FIELDNAMES     : TEMP_NAME, $
                     FIELDLOCATIONS : INDGEN(N_ELEMENTS(TEMP_NAME)), $
                     FIELDGROUPS    : INDGEN(N_ELEMENTS(TEMP_NAME))} 
    
    ;IF KEYWORD_SET(VERBOSE) THEN HELP,INDEX_TEMPLATE       
    RETURN, INDEX_TEMPLATE

END