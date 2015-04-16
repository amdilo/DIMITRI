;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SENSOR_BAND_CONFIG_TEMPLATE       
;* 
;* PURPOSE:
;*      RETURNS THE TEMPLATE REQUIRED FOR READING THE BAND CONFIGURATION DIMITRI FILE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SENSOR_BAND_CONFIG_TEMPLATE()      
;* 
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      INDEX_TEMPLATE  - A TEMPLATE FOR READING THE DIMITRI BAND INDEX FILE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      20 JUN 2014 - PML / MAGELLIUM   - DIMITRI-3 MAG
;*
;* VALIDATION HISTORY:
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*       
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SENSOR_BAND_CONFIG_TEMPLATE,VERBOSE=VERBOSE

    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI BAND NAME TEMPLATE: RETRIEVING TEMPLATE'
    
    TEMP_NAME      = ['BAND_ID','AATSR','AATSR_STD_LABEL','AATSR_REF_LABEL','AATSR_SMAC_FILE','AATSR_RAY_LUT_FILE','AATSR_SUN_LUT_FILE', $
                                'ATSR2','ATSR2_STD_LABEL','ATSR2_REF_LABEL','ATSR2_SMAC_FILE','ATSR2_RAY_LUT_FILE','ATSR2_SUN_LUT_FILE', $
                                'MERIS','MERIS_STD_LABEL','MERIS_REF_LABEL','MERIS_SMAC_FILE','MERIS_RAY_LUT_FILE','MERIS_SUN_LUT_FILE', $
                                'MODISA','MODISA_STD_LABEL','MODISA_REF_LABEL','MODISA_SMAC_FILE','MODISA_RAY_LUT_FILE','MODISA_SUN_LUT_FILE', $
                                'PARASOL','PARASOL_STD_LABEL','PARASOL_REF_LABEL','PARASOL_SMAC_FILE','PARASOL_RAY_LUT_FILE','PARASOL_SUN_LUT_FILE', $
                                'VEGETATION','VEGETATION_STD_LABEL','VEGETATION_REF_LABEL','VEGETATION_SMAC_FILE','VEGETATION_RAY_LUT_FILE','VEGETATION_SUN_LUT_FILE']

    TEMP_TYPE      = [3, 3, 7, 7, 7, 7, 7, $
                         3, 7, 7, 7, 7, 7, $
                         3, 7, 7, 7, 7, 7, $
                         3, 7, 7, 7, 7, 7, $
                         3, 7, 7, 7, 7, 7, $
                         3, 7, 7, 7, 7, 7]

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