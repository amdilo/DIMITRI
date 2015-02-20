FUNCTION GET_VIIRS_EMISSIVE_BTEMP, FILENAME, VERBOSE=VERBOSE
;+
; :Name:
;      GET_MODISA_L1B_EMISSIVE_BTEMP
;
; :Description:
;      returns the l1b emissive radiance brightness temperature.  These are read 
;      straight out of the VIIRS file.
;
; :Calling Sequence:
;      RES = GET_MODISA_L1B_EMISSIVE_BTEMP(FILENAME)
;
; :Params:
;      FILENAME :
;        a string containing the filename of the product for reflectance extraction
;
; :Keywords:
;      VERBOSE :
;          processing status outputs
;
; :Returns:
;      BTEMP  :
;          an array of brightness temperatures in kelvin
;
; :Common blocks:
;      NONE
;
; :History:
;      27 jun 2013 - D Marrable   - DIMITRI-2 V1.0
;-


;------------------------------------------------
; There maybe a way of pulling this out of the file but for now we hardcode the
; emmisive band numbers.  12 - 16
EM_BAND_START = 12
EM_BAND_STOP = 16
NUM_BANDS = EM_BAND_STOP - EM_BAND_START

;------------------------------------------------
; CHECK FILENAME AND IN_BAND ARE NOMINAL

IF FILENAME EQ '' THEN BEGIN
  PRINT, 'MODISA L1B EMISSIVE BRIGTNESS: ERROR, INPUT FILENAME INCORRECT'
  RETURN,-1
ENDIF

;------------------------------------------------
; START THE SD INTERFACE AND OPEN THE PRODUCT

IF KEYWORD_SET(VERBOSE) THEN PRINT,'VIIRS L1B EMISSIVE BRIGHTNESS TEMPERATURE: STARTING IDL HDF SD INTERFACE'
HDF_ID = HDF_SD_START(FILENAME, /READ)

; Pull out the meta data structre so we can query the datafile attributes.
SMETA_ID = HDF_SD_ATTRFIND(HDF_ID,'StructMetadata.0') ; returns structure as a string
HDF_SD_ATTRINFO,HDF_ID, SMETA_ID, DATA=HDF_METADATA_STRING

RES = STRPOS(HDF_METADATA_STRING, 'Along_Track') ; then the next field will be the dimension
C_DIM = STRMID(HDF_METADATA_STRING,RES + 22,4)

RES = STRPOS(HDF_METADATA_STRING, 'Along_Scan')
R_DIM = STRMID(HDF_METADATA_STRING,RES + 21,4)

;------------------------------------------------
; Unlike the VIIRS file, we need to pull out each band individually
; So we setup the number of bands and loop through them pulling each one
; out of the file

BTEMP = MAKE_ARRAY(C_DIM, R_DIM, NUM_BANDS, /FLOAT)

;------------------------------------------------
; LOOPT THROUGH THE EMMISIVE BAND
; NOTE: BAND 13 IS STORED AS A FLOAT AND HAS NO SCALING FACTOR

FOR I = 0, NUM_BANDS -1 DO BEGIN
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'VIIRS L1B EMISSIVE: RETRIEVING DATA'
  SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'BrightnessTemperature_M' + STRTRIM((I + EM_BAND_START),2))
  SDS_ID = HDF_SD_SELECT(HDF_ID, SDS_NAME)
  
  HDF_SD_GETDATA,SDS_ID,TEMP
  BTEMP[*,*,I] = TEMP ; WE NEED I COUNTING FROM 0
  
  IF I NE 13 - 1 THEN BEGIN  ; IE NOT BAND 13
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Scale')
    IF ATTR_INDX GE 0 THEN HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=BTEMP_SLOPES
    
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Offset')
    IF ATTR_INDX GE 0 THEN HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=BTEMP_OFFSET
    
    HDF_SD_ENDACCESS, SDS_ID
    
  ENDIF
  
  IF I EQ 13 - 1 THEN BEGIN
    BTEMP_SLOPES = 1 ;; IE NO SCALING FACTOR
    BTEMP_OFFSET = 1
  ENDIF
  
  
  BTEMP = FLOAT(BTEMP)
  BTEMP_COUNTS = 0
  TEMP_DIMS = SIZE(BTEMP)
  BTEMP[*,*, I] = BTEMP_SLOPES*(BTEMP-BTEMP_OFFSET)
  
  
ENDFOR

;-----------------------------------------------
; CLOSE THE PRODUCT AND SD INTERFACE

IF KEYWORD_SET(VERBOSE) THEN PRINT,'MODISA L1B EMISSIVE: CLOSING PRODUCT AND RETURNING EMISSIVE DATA'
HDF_SD_END,HDF_ID

;-----------------------------------------------
; RETURN,L1B_EMM

RETURN,BTEMP

END