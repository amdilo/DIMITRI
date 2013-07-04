;**************************************************************************************
;**************************************************************************************
;+
;* NAME:
;*      GET_AATSR_L1B_RADIANCE       
;* 
;* PURPOSE:
;*      RETURNS THE L1B RADIANCE FOR A SPECIFIC AATSR BAND AND DIRECTION
;* 
;* CALLING SEQUENCE:
;*      RES = GET_AATSR_L1B_REFLECTANCE(FILENAME,IN_BAND,L1B_DIR)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR RADIANCE EXTRACTION 
;*      IN_BAND  - THE INDEX OF RADIANCE BAND TO BE RETURNED, STARTS FROM 0   
;*      L1B_DIR  - A STRING OF THE DIRECTION REQUIRED, EITHER 'NADIR' OR 'FWARD'
;*
;* KEYWORDS:
;*      ENDIAN_SIZE - MACHINE ENDIAN SIZE (0: LITTLE, 1: BIG)
;*      VERBOSE     - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      L1B_REF     - TOA REFLECTANCE FOR IN_BAND. NOTE, THE REFLECTANCE AT POINT [0,0] 
;*                    IS EQUAL TO THE TOP RIGHT PIXEL IN BEAM.  
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      17 NOV 2005 - M BOUVET - PROTOTYPE DIMITRI VERSION
;*      10 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*      14 DEC 2010 - C KENT   - MINOR TIDYING OF CODE, REMOVAL OF OLD COMMENTS
;*
;* VALIDATION HISTORY:
;*      12 DEC 2010 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1: COMPILATION SUCCESSFUL,
;*                                BAND REFLECTANCE EQUAL TO BEAM VISAT FOR AATSR L1B DATA
;*      06 JAN 2010 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL,
;*                                VALUES EQUAL TO WINDOWS 32-BIT MACHINE
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_AATSR_L1B_REFLECTANCE,FILENAME,IN_BAND,L1B_DIR,ENDIAN_SIZE=ENDIAN_SIZE,VERBOSE=VERBOSE

;------------------------------------------------
; CHECK FILENAME DIRECTION AND IN_BAND ARE NOMINAL

  IF FILENAME EQ '' THEN BEGIN
    PRINT, 'AATSR L1B REFLECTANCE: ERROR, INPUT FILENAME INCORRECT'
    RETURN,-1
  ENDIF
 
  IF N_ELEMENTS(IN_BAND) NE 1 OR $
      IN_BAND[0] LT 0 OR $
      IN_BAND[0] GT 6 THEN BEGIN
    PRINT, 'AATSR L1B REFLECTANCE: ERROR, INPUT IN_BAND INCORRECT'
    RETURN,-1
  ENDIF 
   
;------------------------------------------------
; IF ENDIAN SIZE NOT PROVIDED THEN GET VALUE

  IF N_ELEMENTS(ENDIAN_SIZE) EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN BEGIN
      PRINT, 'AATSR L1B REFLECTANCE: NO ENDIAN SIZE PROVIDED, RETRIEVING...'
      ENDIAN_SIZE = GET_ENDIAN_SIZE(/VERBOSE)
    ENDIF ELSE ENDIAN_SIZE = GET_ENDIAN_SIZE()
  ENDIF

;------------------------------------------------
;DEFINE HEADER VARIABLES

  MPH_SIZE = 1247
  SPH_SIZE = 12830
  FILE_MPH = BYTARR(MPH_SIZE)
  FILE_SPH = BYTARR(SPH_SIZE)
  
;-----------------------------------------------
; CONVERT IN_BAND NUMBER TO STRING AND DEFINE BAND NAMES

  IN_BAND_NAME=['00545_00565','00649_00669','00855_00875','01580_01640','03505_03895','10400_11300','11500_12500']
  
;-----------------------------------------------
; OPEN THE FILE AND EXTRACT HEADER

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'AATSR L1B REFLECTANCE: OPENING PRODUCT'
  OPENR,PRD_REF,FILENAME,/GET_LUN
  READU,PRD_REF,FILE_MPH
  READU,PRD_REF,FILE_SPH

;-----------------------------------------------
; RETRIEVE: POSITION OF DSD, DSD,OFFSET,DS_SIZE,NUMBER OF RECORDS, RECORD SIZE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'AATSR L1B REFLECTANCE: RETRIEVING DSD INFORMATION'
  REF_DSD_POS =STRPOS(FILE_SPH,'DS_NAME="'+IN_BAND_NAME[IN_BAND]+'_NM_'+L1B_DIR+'_TOA_MDS"')
  REF_DSD=STRMID(FILE_SPH, REF_DSD_POS,280)
  REF_OFFSET = STRMID(REF_DSD, strpos(REF_DSD, 'DS_OFFSET=+')+10,21)+0L
  REF_SIZE = STRMID(REF_DSD, strpos(REF_DSD, 'DS_SIZE=+')+8,21)+0L
  REF_DSR_NUMBER = STRMID(REF_DSD, strpos(REF_DSD, 'NUM_DSR=+')+8,11)+0L
  REF_DSR_SIZE = STRMID(REF_DSD, strpos(REF_DSD, 'DSR_SIZE=+')+9,11)+0L

;---------------------------------------------
; DEFINE VARIABLE FOR HOLDING THE L1B DATA AND 
; THE TEMPORARY VARIABLE FOR CONTAINING THE DATA 
; WITHIN THE READING LOOP

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'AATSR L1B REFLECTANCE: DEFINING DATA ARRAYS FOR OUTPUT'
  L1B_REF     = uINTARR((REF_DSR_SIZE-20)/2,REF_DSR_NUMBER)
  L1B_REF_REC = uINTARR((REF_DSR_SIZE-20)/2)
  NODATA      = BYTARR(20)

;---------------------------------------------
; POINT TO THE L1B RADIANCE DATA

  POINT_LUN, PRD_REF, REF_OFFSET
  
;---------------------------------------------
; LOOP OVER EACH RECORD AND EXTRACT DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'AATSR L1B REFLECTANCE: STARTING LOOP FOR DATA EXTRACTION'
  FOR RREC=0,REF_DSR_NUMBER-1 DO BEGIN
    READU,PRD_REF,NODATA
    READU,PRD_REF,L1B_REF_REC

;----------------------------------------
; SWAP ENDIAN IF NEEDED - AATSR DATA IS BIG ENDIAN
  
    IF ENDIAN_SIZE EQ 0 THEN L1B_REF_REC = SWAP_ENDIAN(L1B_REF_REC)
    
    L1B_REF[*,RREC]=L1B_REF_REC
    
  ENDFOR ; END OF LOOP OVER REFLECTANCE RECORDS


;---------------------------------------
; CLOSE THE FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'AATSR L1B REFLECTANCE: CLOSING PRODUCTS AND RELEASING THE LUN'
  CLOSE, PRD_REF
  FREE_LUN, PRD_REF

;---------------------------------------
; APPLY THE SCALING FACTOR AND RETURN DATA - values between 0 - 100%

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'AATSR L1B REFLECTANCE: APPLYING SCALING FACTOR AND RETURNING BAND RADIANCE'
  L1B_REF=L1B_REF*0.01
  IF IN_BAND LE 3 THEN TEMP = WHERE(L1B_REF LE 0.0 OR L1B_REF GT 100.0) ELSE TEMP = WHERE(L1B_REF LE 0.0 or L1B_REF GE 500.0)
  IF TEMP[0] GT -1 THEN L1B_REF[TEMP] = 0.0
 
  RETURN,L1B_REF
  
END
