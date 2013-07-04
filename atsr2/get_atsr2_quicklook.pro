;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_ATSR2_QUICKLOOK       
;* 
;* PURPOSE:
;*      OUTPUTS A GRAYSCALE/RGB ATSR2 QUICKLOOK WITH ROI OVERLAY IF REQUESTED
;* 
;* CALLING SEQUENCE:
;*      RES = GET_ATSR2_QUICKLOOK(FILENAME)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR QUICKLOOK GENERATION 
;*
;* KEYWORDS:
;*     RGB          -  PROGRAM GENERATES AN RGB COLOUR QUICKLOOK (DEFAULT IS GRAYSCALE)
;*     ROI          -  OVERLAY COORDINATES OF AN ROI IN RED (REQUIRES ICOORDS)
;*     ICOORDS      -  A 4-ELEMENT ARRAY OF ROI GEOLOCATION (N,S,E,W) 
;*     QL_QUALITY   -  QUALITY OF JPEG GENERATED (100 = MAX, 0 = LOWEST)
;*     ENDIAN_SIZE  -  MACHINE ENDIAN SIZE (0: LITTLE, 1: BIG)
;*     VERBOSE      -  PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*     STATUS       - 1: NOMINAL, (-1) OR 0: ERROR
;*     JPESG ARE AUTOMATICALLY SAVED IN FILENAME FOLDER    
;*
;* COMMON BLOCKS:
;*     NONE 
;*
;* MODIFICATION HISTORY:
;*      13 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      13 DEC 2010 - C KENT   - WINDOWS 32-BIT MACHINE IDL 7.1, COMPILATION SUCCESSFUL. ALL KEYWORD 
;*                               COMBINATIONS TESTED FOR A PRODUCT OVER SIO
;*      05 JAN 2011 - C KENT   - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL, 
;*                               NO APPARENT DIFFERENCES WITH WINDOWS OUTPUT
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_ATSR2_QUICKLOOK,FILENAME,RGB=RGB,ROI=ROI,ICOORDS=ICOORDS,QL_QUALITY=QL_QUALITY,ENDIAN_SIZE=ENDIAN_SIZE,VERBOSE=VERBOSE

;------------------------------------------------
; CHECK FILENAME IS NOMINAL

  IF FILENAME EQ '' THEN BEGIN
    PRINT, 'ATSR2 L1B QUICKLOOK: ERROR, INPUT FILENAME INCORRECT'
    RETURN,-1
  ENDIF

;------------------------------------------------
; IF ENDIAN SIZE NOT PROVIDED THEN GET VALUE

  IF N_ELEMENTS(ENDIAN_SIZE) EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN BEGIN
      PRINT, 'ATSR2 L1B QUICKLOOK: NO ENDIAN SIZE PROVIDED, RETRIEVING...'
      ENDIAN_SIZE = GET_ENDIAN_SIZE(/VERBOSE)
    ENDIF ELSE ENDIAN_SIZE = GET_ENDIAN_SIZE()
  ENDIF
  
;------------------------------------------------
; SET JPEG QUALITY IF NOT PROVIDED

  IF N_ELEMENTS(QL_QUALITY) EQ 0 THEN QL_QUALITY = 90
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: JPEG QUALITY = ',QL_QUALITY
  
;------------------------------------------------
; CHECK KEYWORD COMBINATIONS

  IF KEYWORD_SET(ROI) AND N_ELEMENTS(ICOORDS) LT 4 THEN BEGIN
    PRINT,'ATSR2 L1B QUICKLOOK: ERROR, ROI KEYWORD IS SET BUT COORDINATES INCORRECT'
    RETURN,-1
  ENDIF

;------------------------------------------------
; DERIVE THE OUTPUT JPEG FILENAME

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: COMPUTING OUTPUT FILENAME'
  QL_POS = STRPOS(FILENAME,'.',/REVERSE_SEARCH)
  QL_ATSR2_JPG = FILENAME
  STRPUT,QL_ATSR2_JPG,'_',QL_POS
  QL_ATSR2_JPG = STRING(QL_ATSR2_JPG+'.jpg')

;------------------------------------------------
; GET ATSR2 L1B RADIANCE DATA AND DERIVE QUICKLOOK IMAGE

  QL_DIR = 'NADIR'

  IF KEYWORD_SET(RGB) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: RGB JPEG SELECTED'
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: RETRIEVING RGB REFLECTANCE DATA'
    QL_DATAR = REVERSE(GET_ATSR2_L1B_REFLECTANCE(FILENAME,2,QL_DIR,ENDIAN_SIZE=ENDIAN_SIZE),1)
    QL_DATAG = REVERSE(GET_ATSR2_L1B_REFLECTANCE(FILENAME,1,QL_DIR,ENDIAN_SIZE=ENDIAN_SIZE),1)
    QL_DATAB = REVERSE(GET_ATSR2_L1B_REFLECTANCE(FILENAME,0,QL_DIR,ENDIAN_SIZE=ENDIAN_SIZE),1)
  ENDIF ELSE BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: RETRIEVING RADIANCE 13 DATA'
    QL_DATAR  = REVERSE(GET_ATSR2_L1B_REFLECTANCE(FILENAME,2,QL_DIR,ENDIAN_SIZE=ENDIAN_SIZE),1)<1.0
  ENDELSE
  
  IF QL_DATAr[0] EQ -1 THEN BEGIN
    PRINT,'ATSR2 L1B QUICKLOOK: ERROR, PROBLEM ENCOUNTERED DURING L1B RADIANCE RETRIEVAL, CHECK PRODUCTS IS A ATSR2 L1B PRODUCT'
    RETURN,-1
  ENDIF

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: GET PRODUCT DIMENSIONS AND DEFINE IMAGE ARRAY'
  QL_DIMS  = SIZE(QL_DATAR)
  QL_IMAGE = BYTARR(3,QL_DIMS[1],QL_DIMS[2])
  
;-----------------------------------------------
; POPULATE THE QUICKLOOK IMAGE ARRAY  

  TVAL = 220
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: ADD RADIANCE DATA TO IMAGE ARRAY CHANNELS'
  IF KEYWORD_SET(RGB) THEN BEGIN 
   
    TMP_MAX = MAX([MAX(QL_DATAR),MAX(QL_DATAG),MAX(QL_DATAB)])
    QL_IMAGE[0,*,*]=BYTSCL(QL_DATAR,MAX=TMP_MAX,TOP=TVAL)
    QL_IMAGE[1,*,*]=BYTSCL(QL_DATAG,MAX=TMP_MAX,TOP=TVAL)
    QL_IMAGE[2,*,*]=BYTSCL(QL_DATAB,MAX=TMP_MAX,TOP=TVAL)

;----------------------------------------------
; RELEASE MEMORY FOR GREEN AND BLUE CHANNELS
    
    QL_DATAG = 0
    QL_DATAB = 0
    
  ENDIF ELSE BEGIN
    TMP_MAX = MAX(QL_DATAR)
    QL_IMAGE[0,*,*]=BYTSCL(QL_DATAR,TOP=TVAL)
    QL_IMAGE[1,*,*]=BYTSCL(QL_DATAR,TOP=TVAL)
    QL_IMAGE[2,*,*]=BYTSCL(QL_DATAR,TOP=TVAL)
  ENDELSE

;---------------------------------------------------
; GET LAT/LON DATA FOR ROI PIXEL INDEX IF REQUESTED

  IF KEYWORD_SET(ROI) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: OVERLAY OF ROI SELECTED'
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: RETRIEVING PRODUCT GEOLOCATION'
    QL_GEO = GET_ATSR2_LAT_LON(FILENAME,QL_DIR,QL_DIMS[2],QL_DIMS[1])
    
;---------------------------------------------------
; REVERSE GEOLOCATION ARRAYS INTO SAME ORIENTAITON AS REFLECTANCE

    QL_GEO.LAT = REVERSE(QL_GEO.LAT)
    QL_GEO.LON = REVERSE(QL_GEO.LON)
           
    QL_ROI_IDX = WHERE($
          QL_GEO.LAT LT ICOORDS[0] AND $
          QL_GEO.LAT GT ICOORDS[1] AND $
          QL_GEO.LON LT ICOORDS[2] AND $
          QL_GEO.LON GT ICOORDS[3] )

;---------------------------------------------------
; CONVERT ROI PIXELS TO A LIGHT RED OVERLAY

    IF QL_ROI_IDX[0] GT -1 THEN BEGIN
          IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: MODIFYING RED CHANNEL FOR ROI OVERLAY'
          ;QL_DATAR = BYTSCL(QL_DATAR,MAX=TMP_MAX,TOP=TVAL)
          ;QL_DATAR[QL_ROI_IDX]=250
          ;QL_IMAGE[0,*,*] = QL_DATAR
            QL_DATAR = QL_IMAGE[0,*,*]
            QL_DATAG = QL_IMAGE[1,*,*]
            QL_DATAB = QL_IMAGE[2,*,*]
          
            QL_DATAR[QL_ROI_IDX]=250
            QL_DATAG[QL_ROI_IDX]=bytscl(QL_DATAG[QL_ROI_IDX],top=75)
            QL_DATAB[QL_ROI_IDX]=bytscl(QL_DATAb[QL_ROI_IDX],top=75)
            QL_IMAGE[0,*,*] = QL_DATAR
            QL_IMAGE[1,*,*] = QL_DATAG
            QL_IMAGE[2,*,*] = QL_DATAB
    ENDIF
  ENDIF

;---------------------------------------------------
; OUTPUT QUICKLOOK AS JPEG

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'ATSR2 L1B QUICKLOOK: WRITING IMAGE TO JPEG'
  WRITE_JPEG ,QL_ATSR2_JPG,QL_IMAGE,TRUE=1,/ORDER
  
;---------------------------------------------------
; RETURN A POSITIVE VALUE INDICATING QL GENERATION OK

  RETURN, 1

END
