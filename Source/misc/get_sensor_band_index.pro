;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SENSOR_BAND_INDEX       
;* 
;* PURPOSE:
;*      RETURNS THE BAND ID FOR A GIVEN SENSOR AND DIMITRI BAND ID
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SENSOR_BAND_INDEX(BI_SENSOR,BINDEX)      
;* 
;* INPUTS:
;*      BI_SENSOR - A STRING CONTAINING THE NAME OF THE SENSOR OF INTEREST
;*      BINDEX    - AN INTEGER OF THE DIMITRI BAND INDEX (STARTS AT 1)
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      BID       - AN INTEGER OF THE BAND INDEX RELATING TO THE INPUT SENSOR AND DIMITRI INDEX
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      19 JAN 2011 - C KENT   - DIMITRI-2 V1.0
;*      21 MAR 2011 - C KENT   - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*
;* VALIDATION HISTORY:
;*      14 APR 2011 - C KENT   - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                               COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SENSOR_BAND_INDEX,BI_SENSOR,BINDEX,VERBOSE=VERBOSE

;------------------------------------
; DEFINE SENSOR FILE
  
  SBI_FILE = GET_DIMITRI_LOCATION('BAND_INDEX')

  RES = FILE_INFO(SBI_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'SENSOR BAND INDEX: ERROR, SENSOR INFORMATION FILE NOT FOUND'
    RETURN,-1
  ENDIF

;------------------------------------
; RETRIEVE TEMPLATE AND READ DATA FILE  
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SENSOR BAND INDEX: RETRIEVEING AUX FILE TEMPLATE'  
  TEMP = GET_DIMITRI_BAND_INDEX_TEMPLATE()
  BI_DATA = READ_ASCII(SBI_FILE,TEMPLATE=TEMP)

;------------------------------------
; CHECK INPUT INDEX
 
  IF FIX(BINDEX) EQ 0 THEN BEGIN 
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'SENSOR BAND INDEX: ERROR, BAND INDEX OUT OF RANGE'
    RETURN,-1
  ENDIF

;------------------------------------
;FIND INDEX OF INPUT INDEX

  RES = WHERE(STRCMP(TEMP.FIELDNAMES,BI_SENSOR) EQ 1)
  IF RES[0] EQ -1 OR N_ELEMENTS(RES) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'SENSOR BAND INDEX: ERROR, SENSOR INDEX RETRIEVAL'
    RETURN,-1  
  ENDIF

;------------------------------------
;EXTRACT DIMITRI BAND INDEX

  BID = BI_DATA.(RES[0])[BINDEX-1] ;BINDEX STARTS AT 1

;------------------------------------
;RETURN VALUE

  RETURN,BID

END