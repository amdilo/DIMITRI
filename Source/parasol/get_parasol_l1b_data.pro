;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_PARASOL_L1B_DATA       
;* 
;* PURPOSE:
;*      RETURNS THE IMAGE DATA FOR A SPECIFIC PARASOL PRODUCT
;* 
;* CALLING SEQUENCE:
;*      RES = GET_PARASOL_L1B_DATA(FILENAME)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR RADIANCE EXTRACTION 
;*
;* KEYWORDS:
;*      ENDIAN_SIZE - MACHINE ENDIAN SIZE (0: LITTLE, 1: BIG)
;*      VERBOSE     - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      L1B_DATA     - A STRUCTURE OF THE IMAGE DATA INCLUDING REFLECTANCES VIEWING GEOMETRIES ETC 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*             2005 - M BOUVET - PROTOTYPE DIMITRI VERSION
;*      15 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*      29 FEB 2012 - C KENT   - ADDED SEQUENCE NUMBER EXTRACTION
;*      08 MAR 2012 - C KENT   - UPDATED SATURATION/DUMMY VALUES CHECK
;*
;* VALIDATION HISTORY:
;*      10 JAN 2011 - C KENT   - WINDOWS 32 BIT MACHINE, IDL 7.1: RESULTS EQUAL TO ANAPOL, 
;*                               EXCEPT SAA (ANAPOL USED SLOPE=1.42, WE USE 1.4 AS DETAILED 
;*                               IN THE L1 PRODUCT FORMAT DOCUMENT)
;*                             - LINUX 64-BIT MACHINE, IDL 8.0: COMPILATION SUCESSFUL, 
;*                               RESULTS EQUAL TO WINDOWS MACHINE 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_PARASOL_L1B_DATA,FILENAME,ENDIAN_SIZE=ENDIAN_SIZE,VERBOSE=VERBOSE

;------------------------
; KEYWORD PARAMETER CHECK

  IF STRCMP(FILENAME,'') THEN BEGIN
    PRINT, 'PARASOL L1B DATA: NO INPUT FILES PROVIDED, RETURNING...'
    RETURN,-1
  ENDIF  
  
;-----------------------------------------------
; CHECK FILENAME OS A PARASOL DATA FILE

  TEMP = STRMATCH(FILENAME,'*P3L1TBG*D*')
  IF TEMP EQ 0 THEN BEGIN
    PRINT, 'PARASOL L1B DATA: ERROR, INPUT FILE NOT A PARASOL DATA FILE'
    RETURN,-1
  ENDIF

;------------------------------------------------
; CHECK THAT THE FILE EXISTS

  TEMP = FILE_INFO(FILENAME)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, 'PARASOL L1B DATA: ERROR, INPUT FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF

;------------------------------------------------
; IF ENDIAN SIZE NOT PROVIDED THEN GET VALUE

   IF N_ELEMENTS(ENDIAN_SIZE) EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN BEGIN
      PRINT, 'PARASOL L1B DATA: NO ENDIAN SIZE PROVIDED, RETRIEVING...'
      ENDIAN_SIZE = GET_ENDIAN_SIZE(/VERBOSE)
    ENDIF ELSE ENDIAN_SIZE = GET_ENDIAN_SIZE()
  ENDIF

;------------------------------------------------
; OPEN THE PRODUCT AND READ NUMBER AND SIZE OF RECORDS

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: OPENING AND READING THE PRODUCT LOG'
  OPENR,IN_PARA,FILENAME,/GET_LUN
  TEMP = BYTARR(52)
  NUM_RECS = ULONG(1)
  REC_SIZE = ULONG(1)
  READU,IN_PARA,TEMP
  READU,IN_PARA,NUM_RECS
  READU,IN_PARA,REC_SIZE 

;------------------------------------------------
; SWAP ENDIAN IF NEEDED - DATA IS BIG ENDIAN

  IF ENDIAN_SIZE EQ 0 THEN BEGIN
    NUM_RECS = SWAP_ENDIAN(NUM_RECS)
    REC_SIZE = SWAP_ENDIAN(REC_SIZE)
  ENDIF

;------------------------------------------------
; GET THE PIXEL STRUCTURE
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: RETRIEVING PIXEL STRUCTURE'
  L1B_PIXELS = GET_PARASOL_L1B_PIXEL_STRUCTURE(NUM_RECS)
  L1B_PIXEL  = GET_PARASOL_L1B_PIXEL_STRUCTURE(1)

;------------------------------------------------
; DEFINE TEMPORARY VARIABLES FOR READING

  TEMP_HDR = 180
  TEMP_SSI = INTARR(1)
  TEMP_USI = UINTARR(1)
  TEMP_ULI = ULONARR(1)
  TEMP_BYT = BYTARR(1)
  TEMP_REF = INTARR(15)

;------------------------------------------------
; LOOP OVER EACH RECORD AND RETRIEVE DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: STARTING READING LOOP'
  FOR IN_REC=0L,NUM_RECS-1 DO BEGIN
  
;------------------------------------------------
; RETRIEVE LINE AND COLUMN INDEX
    
    POINT_LUN,IN_PARA,TEMP_HDR+REC_SIZE*IN_REC+6
    READU,IN_PARA,TEMP_USI
      IF ENDIAN_SIZE EQ 0 THEN TEMP_USI = SWAP_ENDIAN(TEMP_USI)
    L1B_PIXELS[IN_REC].LINE=TEMP_USI
    READU,IN_PARA,TEMP_USI
      IF ENDIAN_SIZE EQ 0 THEN TEMP_USI = SWAP_ENDIAN(TEMP_USI)
    L1B_PIXELS[IN_REC].COLUMN=TEMP_USI

;-----------------------------------------------
; COMPUTE GEOLOCATION FROM LINE AND COLUMN INDEX

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: COMPUTING PIXEL GEOLOCATION'
    L1B_PIXELS[IN_REC].LATITUDE=90.0-(L1B_PIXELS[IN_REC].LINE-0.5)/18.0
    N_i=round(3240.0*cos(L1B_PIXELS[IN_REC].LATITUDE*!DTOR))*1.0
    L1B_PIXELS[IN_REC].LONGITUDE=180./N_i*(L1B_PIXELS[IN_REC].COLUMN-3240.5)

;-----------------------------------------------
; RETRIEVE SAA AND NUMBER OF VIEWING DIRECTIONS

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: RETRIEVING SAA AND NUMBER OF DIRECTIONS'
    POINT_LUN,IN_PARA,TEMP_HDR+REC_SIZE*IN_REC+46
    READU,IN_PARA,TEMP_BYT
      IF ENDIAN_SIZE EQ 0 THEN TEMP_BYT = SWAP_ENDIAN(TEMP_BYT)    
    L1B_PIXELS[IN_REC].SAA = TEMP_BYT*1.42
    READU,IN_PARA,TEMP_BYT
      IF ENDIAN_SIZE EQ 0 THEN TEMP_BYT = SWAP_ENDIAN(TEMP_BYT)    
    L1B_PIXELS[IN_REC].NUM_DIR = TEMP_BYT

;----------------------------------------------
; IF NO DIRECTIONS AVAILABLE THEN SKIP PIXEL

    IF L1B_PIXELS[IN_REC].NUM_DIR LT 1 THEN GOTO,NO_DIR

;----------------------------------------------
; LOOP OVER THE DIRECTIONS

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: LOOPING OVER DIRECTIONS'
    ;FOR IN_DIR = 0,L1B_PIXELS[IN_REC].NUM_DIR-1 DO BEGIN
    FOR IN_DIR = 0,15 DO BEGIN

;-----------------------------------------------
; RETRIEVE SEQUENCE NUMBER

      POINT_LUN,IN_PARA,TEMP_HDR+REC_SIZE*IN_REC+43*IN_DIR+50
      READU,IN_PARA,TEMP_BYT
        IF ENDIAN_SIZE EQ 0 THEN TEMP_BYT = SWAP_ENDIAN(TEMP_BYT)    
      L1B_PIXELS[IN_REC].SEQ_NUMBER[IN_DIR] = TEMP_BYT

      POINT_LUN,IN_PARA,TEMP_HDR+REC_SIZE*IN_REC+43*IN_DIR+55 
      READU,IN_PARA,TEMP_USI
       IF ENDIAN_SIZE EQ 0 THEN TEMP_USI = SWAP_ENDIAN(TEMP_USI)     
      L1B_PIXELS[IN_REC].SZA[IN_DIR] = TEMP_USI*1.5e-3
 
      READU,IN_PARA,TEMP_USI
       IF ENDIAN_SIZE EQ 0 THEN TEMP_USI = SWAP_ENDIAN(TEMP_USI)     
      L1B_PIXELS[IN_REC].VZA[IN_DIR] = TEMP_USI*1.5e-3
 
      READU,IN_PARA,TEMP_USI
       IF ENDIAN_SIZE EQ 0 THEN TEMP_USI = SWAP_ENDIAN(TEMP_USI)     
      L1B_PIXELS[IN_REC].RAA[IN_DIR] = TEMP_USI*6.0e-3
  
      READU,IN_PARA,TEMP_BYT
      IF TEMP_BYT GT 127 THEN BEGIN
      L1B_PIXELS[IN_REC].DELTA_AV_COS_A[IN_DIR]=(TEMP_BYT-256)*1.6E-3
      ENDIF ELSE L1B_PIXELS[IN_REC].DELTA_AV_COS_A[IN_DIR]=TEMP_BYT*1.6E-3

      READU,IN_PARA,TEMP_BYT
      IF TEMP_BYT GT 127 THEN BEGIN
      L1B_PIXELS[IN_REC].DELTA_AV_SIN_A[IN_DIR]=(TEMP_BYT-256)*1.6E-3
      ENDIF ELSE L1B_PIXELS[IN_REC].DELTA_AV_SIN_A[IN_DIR]=TEMP_BYT*1.6E-3

;---------------------------------------------           
; READ THE REFLECTANCES

      TEMP_REF = INTARR(15)
      READU,IN_PARA,TEMP_REF 
      IF ENDIAN_SIZE EQ 0 THEN TEMP_REF=SWAP_ENDIAN(TEMP_REF)
      REF_SF = 1E-4
      
      TT = WHERE(TEMP_REF GE 32767 OR TEMP_REF LE -32767,COUNT)
      IF COUNT GT 0 THEN TEMP_REF[TT] = 0
      
      TEMP_REF = TEMP_REF*REF_SF
      
      L1B_PIXELS[IN_REC].REF_443NP[IN_DIR]  = TEMP_REF[0];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_490P[IN_DIR]   = TEMP_REF[1];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_1020NP[IN_DIR] = TEMP_REF[2];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_565NP[IN_DIR]  = TEMP_REF[3];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_670P[IN_DIR]   = TEMP_REF[4];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_763NP[IN_DIR]  = TEMP_REF[5];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_765NP[IN_DIR]  = TEMP_REF[6];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_865P[IN_DIR]   = TEMP_REF[7];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_910NP[IN_DIR]  = TEMP_REF[8];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_490P_Q[IN_DIR] = TEMP_REF[9];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_670P_Q[IN_DIR] = TEMP_REF[10];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_865P_Q[IN_DIR] = TEMP_REF[11];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_490P_U[IN_DIR] = TEMP_REF[12];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_670P_U[IN_DIR] = TEMP_REF[13];*REF_SF);>0.0
      L1B_PIXELS[IN_REC].REF_865P_U[IN_DIR] = TEMP_REF[14];*REF_SF);>0.0   
   
    ENDFOR ;END OF DIRECTION LOOP
   NO_DIR:
   ENDFOR;END OF PIXEL LOOP

;------------------------------------
; CLOSE THE PRODUCT

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL L1B DATA: CLOSING PRODUCT'
  FREE_LUN,IN_PARA

;-------------------------------------
; CURRENT DIMITRI METHOD FOR GENERATING THE IMAGE

  MIN_LON_PIX=MIN(L1B_PIXELS.COLUMN)
  MAX_LON_PIX=MAX(L1B_PIXELS.COLUMN)
  MIN_LAT_PIX=MIN(L1B_PIXELS.LINE)
  MAX_LAT_PIX=MAX(L1B_PIXELS.LINE)
  DIM_X_IMAGE=MAX_LON_PIX-MIN_LON_PIX+1
  DIM_Y_IMAGE=MAX_LAT_PIX-MIN_LAT_PIX+1

;-------------------------------------
;GENERATE L1B_IMAGE TO BE POPULATED
  
  L1B_IMAGE=REPLICATE(L1B_PIXEL[0], DIM_X_IMAGE, DIM_Y_IMAGE)

  COL_ID = L1B_PIXELS.COLUMN-MIN_LON_PIX
  ROW_ID = L1B_PIXELS.LINE-MIN_LAT_PIX
  L1B_IMAGE[COL_ID,ROW_ID]=L1B_PIXELS

;  FOR I=0l,DIM_X_IMAGE-1 DO BEGIN
;    FOR J=0l,DIM_Y_IMAGE-1 DO BEGIN
;      RES = WHERE(L1B_PIXELS.COLUMN-MIN_LON_PIX EQ I AND L1B_PIXELS.LINE-MIN_LAT_PIX EQ J)
;      IF RES[0] GT -1 AND N_ELEMENTS(RES) EQ 1 THEN L1B_IMAGE[I,J]=L1B_PIXELS[RES]
;    ENDFOR
;  ENDFOR

;--------------------------------------
; RETURN DATA

  RETURN,L1B_IMAGE

END