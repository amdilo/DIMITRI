;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SENSOR_BAND_CONFIG       
;* 
;* PURPOSE:
;*      RETURNS THE BAND CONFIGURATION STRUCTURE INCLUDING ID/LUT FILE/SMAC FILE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SENSOR_BAND_NAME(BN_SENSOR,BN_LABEL)      
;* 
;* INPUTS:
;*      BN_SENSOR    - A STRING OF THE SENSOR NAME (E.G. 'MERIS')
;*      BN_LABEL     - A STRING OF THE BAND NAME (E.G. 'BLUE'/'GREEN'/'NIR'/'VISR'/'SWIR'/'SWIR2')
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      BAND_CONFIG_STRUCT - A STRUCTURE CONFIGURATION FIELDS
;*                                - BAND_ID' :  PRODUCT ID OF THE SELECTED BAND
;*                                - SENSOR': SELECTED SENSOR
;*                                - BAND_LABEL_STD : STANDARD BAND LABEL (E.G. 'BLUE'/'GREEN'/'NIR'/'VISR'/'SWIR'/'SWIR2')
;*                                - BAND_LABEL_NCDF : BAND LABEL IN NCDF FILE (E.G. 'PARASOL_REF_BAND_01'...);
;*                                - BAND_WAVELENGTH : BAND WAVELENGTH CENTRAL VALUE
;*                                - PATH_SMAC : PATH TO THE SENSOR/BAND SMAC FILE
;*                                - SMAC_FILE : NAME OF THE SENSOR/BAND SMAC FILE
;*                                - PATH_LUT' : PATH TO THE LUT FILES
;*                                - DESERT_LUT_FILE' : NAME OF THE SENSOR/BAND DESERT LUT FILE
;*                                - RAYLEIGH_LUT_FILE' : NAME OF THE SENSOR/BAND RAYLEIGH LUT FILE
;*                                - SUNGLINT_LUT_FILE' : NAME OF THE SENSOR/BAND SUNGLINT LUT FILE
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
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SENSOR_BAND_CONFIG, BN_SENSOR, BN_LABEL=BN_LABEL, VERBOSE=VERBOSE

  STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

;------------------------------------
; DEFINE SENSOR FILE
  
  SBI_FILE = GET_DIMITRI_LOCATION('BAND_CONFIG')
  RES = FILE_INFO(SBI_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR INFORMATION FILE NOT FOUND'
    RETURN, STATUS_ERROR
  ENDIF

;------------------------------------
; RETRIEVE TEMPLATE AND READ DATA FILE  
  
  CONFIG_TEMPLATE = GET_SENSOR_BAND_CONFIG_TEMPLATE()
  CONFIG_DATA = READ_ASCII(SBI_FILE,TEMPLATE=CONFIG_TEMPLATE)


  INDX_BANDID = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,'BAND_ID',/FOLD_CASE) EQ 1)
  IF INDX_BANDID[0] EQ -1 OR N_ELEMENTS(INDX_BANDID) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR INDEX RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  BAND_ID = CONFIG_DATA.(INDX_BANDID)
  
;------------------------------------
; FIND INDEX OF INPUT SENSOR
  INDX_SENSOR = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,BN_SENSOR,/FOLD_CASE) EQ 1)
  IF INDX_SENSOR[0] EQ -1 OR N_ELEMENTS(INDX_SENSOR) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR INDEX RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  SENSOR_BANDS = CONFIG_DATA.(INDX_SENSOR)

; FIND SENSOR STANDARD LABEL
  INDX_SENSOR_LABEL = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,BN_SENSOR+'_STD_LABEL',/FOLD_CASE) EQ 1)
  IF INDX_SENSOR_LABEL[0] EQ -1 OR N_ELEMENTS(INDX_SENSOR_LABEL) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR STD LABEL RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  SENSOR_LABEL = CONFIG_DATA.(INDX_SENSOR_LABEL)

  ; FIND SENSOR REF LABEL
  INDX_REF_LABEL = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,BN_SENSOR+'_REF_LABEL',/FOLD_CASE) EQ 1)
  IF INDX_REF_LABEL[0] EQ -1 OR N_ELEMENTS(INDX_REF_LABEL) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR REF LABEL RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  SENSOR_REF_LABEL = CONFIG_DATA.(INDX_REF_LABEL)

  
  ; FIND SENSOR SMAC FILE
  INDX_SENSOR_SMAC = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,BN_SENSOR+'_SMAC_FILE',/FOLD_CASE) EQ 1)
  IF INDX_SENSOR_SMAC[0] EQ -1 OR N_ELEMENTS(INDX_SENSOR_SMAC) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR SMAC FILE RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  SENSOR_SMAC = CONFIG_DATA.(INDX_SENSOR_SMAC)
   
  ; FIND SENSOR RAY LUT FILE
  INDX_SENSOR_RAY_LUT = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,BN_SENSOR+'_RAY_LUT_FILE',/FOLD_CASE) EQ 1)
  IF INDX_SENSOR_RAY_LUT[0] EQ -1 OR N_ELEMENTS(INDX_SENSOR_RAY_LUT) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR RAYLEIGH LUT RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  SENSOR_RAY_LUT = CONFIG_DATA.(INDX_SENSOR_RAY_LUT)
  
  ; FIND SENSOR SUN LUT FILE
  INDX_SENSOR_SUN_LUT = WHERE(STRCMP(CONFIG_TEMPLATE.FIELDNAMES,BN_SENSOR+'_SUN_LUT_FILE',/FOLD_CASE) EQ 1)
  IF INDX_SENSOR_SUN_LUT[0] EQ -1 OR N_ELEMENTS(INDX_SENSOR_SUN_LUT) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: ERROR, SENSOR SUNGLINT LUT RETRIEVAL'
    RETURN, STATUS_ERROR
  ENDIF
  SENSOR_SUN_LUT = CONFIG_DATA.(INDX_SENSOR_SUN_LUT)
  
  ; FIND BN_LABEL IN SENSOR STANDARD LABEL ; GET THE PROPER LINE IN TABLE
  IF KEYWORD_SET(BN_LABEL) THEN BEGIN
    INDX_LINE = WHERE(STRCMP(SENSOR_LABEL,BN_LABEL,/FOLD_CASE) EQ 1)
    IF INDX_LINE[0] EQ -1 THEN BEGIN
      IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_CONFIG: STD_LABEL ' + BN_LABEL + ' NOT AVAILABLE FOR SENSOR ' + BN_SENSOR
      RETURN, STATUS_ERROR
    ENDIF
  ENDIF

  ; BUILD INFORMATION STRUCTURE
  IF KEYWORD_SET(BN_LABEL) THEN BEGIN
    
    ; RETURN THE SENSOR CONFIGURATION OF THE SPECIFIED BAND   
    BAND_CONFIG_STRUCT = CREATE_STRUCT('BAND_ID', BAND_ID(INDX_LINE),$
      'SENSOR',BN_SENSOR,$
      'BAND_LABEL_STD',BN_LABEL,$
      'BAND_WAVELENGTH',SENSOR_BANDS(INDX_LINE),$
      'BAND_REF_LABEL',SENSOR_REF_LABEL(INDX_LINE),$
      'PATH_SMAC',GET_DIMITRI_LOCATION('INPUT_AUX_SMAC')+STRUPCASE(BN_SENSOR)+GET_DIMITRI_LOCATION('DL'),$
      'SMAC_FILE',SENSOR_SMAC(INDX_LINE),$
      'PATH_LUT',GET_DIMITRI_LOCATION('INPUT_AUX_LUT')+STRUPCASE(BN_SENSOR)+GET_DIMITRI_LOCATION('DL'),$
      'RAYLEIGH_LUT_FILE', SENSOR_RAY_LUT(INDX_LINE),$
      'SUNGLINT_LUT_FILE', SENSOR_SUN_LUT(INDX_LINE) )
  
     RETURN, BAND_CONFIG_STRUCT
  
  ENDIF ELSE BEGIN
    
    ; RETURN THE SENSOR CONFIGURATION OF ALL BANDS   
    CONFIG_STRUCT = CREATE_STRUCT('BAND_ID', BAND_ID,$
      'SENSOR',BN_SENSOR,$
      'BAND_LABEL_STD',SENSOR_LABEL,$
      'BAND_WAVELENGTH',SENSOR_BANDS,$
      'BAND_REF_LABEL',SENSOR_REF_LABEL,$
      'PATH_SMAC',GET_DIMITRI_LOCATION('INPUT_AUX_SMAC')+STRUPCASE(BN_SENSOR)+GET_DIMITRI_LOCATION('DL'),$
      'SMAC_FILE',SENSOR_SMAC,$
      'PATH_LUT',GET_DIMITRI_LOCATION('INPUT_AUX_LUT')+STRUPCASE(BN_SENSOR)+GET_DIMITRI_LOCATION('DL'),$
      'RAYLEIGH_LUT_FILE', SENSOR_RAY_LUT,$
      'SUNGLINT_LUT_FILE', SENSOR_SUN_LUT )
  
    RETURN, CONFIG_STRUCT

  ENDELSE
  
END

