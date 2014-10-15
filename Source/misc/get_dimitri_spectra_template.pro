;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_DIMITRI_SPECTRA_TEMPLATE       
;* 
;* PURPOSE:
;*      RETURNS THE DIMITRI TOA SPECTRA FILE TEMPLATE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_DIMITRI_SPECTRA_TEMPLATE()      
;* 
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      SPECTRA_TEMPLATE  - A TEMPLATE FOR READING THE DIMITRI TOA SPECTRA FILE FOR ANY SITE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      21 FEB 2014 - C MAZERAN - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*      21 FEB 2014 - C MAZERAN - LINUX 64-BIT IDL 8.2 NOMINAL COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_DIMITRI_SPECTRA_TEMPLATE,VERBOSE=VERBOSE

 IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI SPECTRA TEMPLATE: RETRIEVING TEMPLATE'
    
 TEMP_NAME         = ['WAVELENGTH','REFLECTANCE','SIGMA']
 TEMP_TYPE         = [4,4,4]
 SPECTRA_TEMPLATE  = {VERSION        : 1.0                       , $
                      DATASTART      : 1 , $
                      DELIMITER      : ';' , $
                      MISSINGVALUE   : !VALUES.F_NAN, $
                      COMMENTSYMBOL  : ''          , $
                      FIELDCOUNT     : N_ELEMENTS(TEMP_NAME), $
                      FIELDTYPES     : TEMP_TYPE, $
                      FIELDNAMES     : TEMP_NAME, $
                      FIELDLOCATIONS : INDGEN(N_ELEMENTS(TEMP_NAME)), $
                      FIELDGROUPS    : [INDGEN(N_ELEMENTS(TEMP_NAME))]}
    
    RETURN, SPECTRA_TEMPLATE

END
