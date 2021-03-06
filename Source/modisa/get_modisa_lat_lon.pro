;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_MODISA_LAT_LON       
;* 
;* PURPOSE:
;*      RETURNS THE INTERPOLATED LATITUDE AND LONGITUDE OF A MODISA IMAGE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_MODISA_LAT_LON(FILENAME)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR GEOLOCAITON EXTRACTION      
;*
;* KEYWORDS:
;*      VERBOSE     - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STRUCT.LAT  - LATITUDE IN DEGREES FOR L1B PRODUCT
;*      STRUCT.LON  - LONGITUDE IN DEGREES FOR L1B PRODUCT	
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*                  - M BOUVET - PROTOTYPE DIMITRI VERSION
;*      02 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      02 DEC 2010 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1: COMPILATION SUCCESSFUL, 
;*                                PIXELS AT IMAGE EDGE HAVE BEEN LINEARLY INTERPOLATED AND 
;*                                HAVE LARGE ERRORS (~1KM DIFFERENT TO SEADAS L2 PROCESSING), 
;*                                PIXELS WITHIN TIEPOINTS WITHIN ~100M OF SEADAS L2 PROCESSING
;*      05 JAN 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL, 
;*                                NO APPARENT DIFFERENCES WHEN COMPARED TO WINDOWS MACHINE 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_MODISA_LAT_LON,FILENAME,VERBOSE=VERBOSE

;------------------------------------------------
; CHECK FILENAME AND IN_BAND ARE NOMINAL

  IF FILENAME EQ '' THEN BEGIN
    PRINT, 'MODISA L1B LAT LON: ERROR, INPUT FILENAME INCORRECT'
    RETURN,-1
  ENDIF
 
;------------------------------------------------
;OPEN THE L1B FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B LAT LON: RETRIEVING GEOLOCATION SDS DATA'
  HDF_ID = HDF_SD_START(FILENAME,/READ)
  SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'Latitude')
  SDS_ID=HDF_SD_SELECT(HDF_ID,SDS_NAME)
  HDF_SD_GETDATA,SDS_ID,LATITUDE
  HDF_SD_ENDACCESS, SDS_ID
  
  SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'Longitude')
  SDS_ID=HDF_SD_SELECT(HDF_ID,SDS_NAME)
  HDF_SD_GETDATA,SDS_ID,Longitude
  HDF_SD_ENDACCESS, SDS_ID
  
;-------------------------------------------------
; CLOSE THE HDF FILE 

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B LAT LON: CLOSING PRODUCT'
  HDF_SD_END,HDF_ID
  
;-------------------------------------------------
; INTERPOLATE GEOLCATION TO RADIANCE GRID 

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B LAT LON: REGRID DATA INTO RADIANCE PRODUCT DIMENSIONS'
  GEO_DIMS  = SIZE(LATITUDE)
  
  ;LATITUDE  = CONGRID(LATITUDE[0:GEO_DIMS[1]-2,*],(GEO_DIMS[1])*5-1,(GEO_DIMS[2])*5,/INTERP)
  ;LONGITUDE = CONGRID(LONGITUDE[0:GEO_DIMS[1]-2,*],(GEO_DIMS[1])*5-1,(GEO_DIMS[2])*5,/INTERP)

;-------------------------------------------------
; INTERPOLATE TIEPOINT DATA

;  LATITUDE  = CONGRID(LATITUDE[0:GEO_DIMS[1]-2,*],(GEO_DIMS[1])*5-4,(GEO_DIMS[2])*5-4,/INTERP)
;  LONGITUDE  = CONGRID(LONGITUDE[0:GEO_DIMS[1]-2,*],(GEO_DIMS[1])*5-4,(GEO_DIMS[2])*5-4,/INTERP)

;-------------------------------------------------
; ADD EXCEPTION FOR FULL SWATH PRODUCTS
  
  IF GEO_DIMS[1] EQ 271. THEN OFFSET = 1 ELSE OFFSET = 0

  LATITUDE  = CONGRID(LATITUDE,(GEO_DIMS[1])*5-OFFSET-4,(GEO_DIMS[2])*5-4,/INTERP)
  LONGITUDE  = CONGRID(LONGITUDE,(GEO_DIMS[1])*5-OFFSET-4,(GEO_DIMS[2])*5-4,/INTERP)

  LAT = MAKE_ARRAY((GEO_DIMS[1])*5-OFFSET,(GEO_DIMS[2])*5,/FLOAT)
  LON = MAKE_ARRAY((GEO_DIMS[1])*5-OFFSET,(GEO_DIMS[2])*5,/FLOAT)
  TEMP_DIMS = SIZE(LAT)
  ;LAT[2:TEMP_DIMS[1]-3,2:TEMP_DIMS[2]-3] = LATITUDE
  LAT[2,2]=LATITUDE
  ;LON[2:TEMP_DIMS[1]-3,2:TEMP_DIMS[2]-3] = LONGITUDE
  LON[2,2]=LONGITUDE

;-------------------------------------------------
; RELEASE MEMORY

  LATITUDE = 0
  LONGITUDE = 0

;-------------------------------------------------
; LINEAR EXTRAPOLATION FOR THE 2 EDGE PIXELS

;  TEMP = [1,0,TEMP_DIMS[2]-2,TEMP_DIMS[2]-1]
;  F1 = [1,1,-1,-1]
;  F2 = [2,2,-2,-2]
;  
;  FOR MODJ = 0,N_ELEMENTS(TEMP)-1 DO BEGIN
;    MODK=TEMP[MODJ]
;    FOR MODI=2,TEMP_DIMS[1]-3 DO BEGIN
;      LAT[MODI,MODK] = LAT[MODI,MODK+F1[MODJ]]+(LAT[MODI,MODK+F1[MODJ]]-LAT[MODI,MODK+F2[MODJ]])
;      LON[MODI,MODK] = LON[MODI,MODK+F1[MODJ]]+(LON[MODI,MODK+F1[MODJ]]-LON[MODI,MODK+F2[MODJ]])
;    ENDFOR
;  ENDFOR
;
;  TEMP = [1,0,TEMP_DIMS[1]-2,TEMP_DIMS[1]-1]
;  FOR MODI = 0,N_ELEMENTS(TEMP)-1 DO BEGIN
;    MODK=TEMP[MODI]
;    FOR MODJ=0,TEMP_DIMS[2]-1 DO BEGIN
;      LAT[MODK,MODJ] = LAT[MODK+F1[MODI],MODJ]+(LAT[MODK+F1[MODI],MODJ]-LAT[MODK+F2[MODI],MODJ])
;      LON[MODK,MODJ] = LON[MODK+F1[MODI],MODJ]+(LON[MODK+F1[MODI],MODJ]-LON[MODK+F2[MODI],MODJ])
;    ENDFOR
;  ENDFOR

;------------------------------------------------
; RETURN LAT AND LON

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B LAT LON: RETURNING LATITUDE AND LONGITUDE'
  RETURN,{LAT:LAT,LON:LON}

END