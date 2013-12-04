FUNCTION GET_VIIRS_L1B_EMISSIVE, FILENAME, VERBOSE=VERBOSE
;+
; :Name:
;      GET_MODISA_L1B_EMISSIVE
;
; :Description:
;      returns the l1b emissive radiance for a specific modisa band
;
; :Calling Sequence:
;      RES = GET_MODISA_L1B_EMISSIVE(FILENAME,IN_BAND)
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
;      TOA_EMM  :
;          toa reflectance for product following use of scaling factor
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
  PRINT, 'MODISA L1B EMISSIVE: ERROR, INPUT FILENAME INCORRECT'
  RETURN,-1
ENDIF

;------------------------------------------------
; START THE SD INTERFACE AND OPEN THE PRODUCT

IF KEYWORD_SET(VERBOSE) THEN PRINT,'VIIRS L1B EMISSIVE: STARTING IDL HDF SD INTERFACE'
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

TOA_EMM = MAKE_ARRAY(C_DIM, R_DIM, NUM_BANDS, /FLOAT)

;------------------------------------------------
; LOOPT THROUGH THE EMMISIVE BAND
; NOTE: BAND 13 IS STORED AS A FLOAT AND HAS NO SCALING FACTOR

FOR I = 0, NUM_BANDS -1 DO BEGIN
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'VIIRS L1B EMISSIVE: RETRIEVING DATA'
  SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'Radiance_M' + STRTRIM((I + EM_BAND_START),2))
  SDS_ID = HDF_SD_SELECT(HDF_ID, SDS_NAME)
  
  HDF_SD_GETDATA,SDS_ID,TEMP
  TOA_EMM[*,*,I] = TEMP ; WE NEED I COUNTING FROM 0
  
  IF I NE 13 - 1 THEN BEGIN  ; IE NOT BAND 13
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Scale')
    IF ATTR_INDX GE 0 THEN HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_EMM_SLOPES
    
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Offset')
    IF ATTR_INDX GE 0 THEN HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_EMM_OFFSET
    
    HDF_SD_ENDACCESS, SDS_ID
    
  ENDIF
    
  IF I EQ 13 - 1 THEN BEGIN
    TOA_EMM_SLOPES = 1 ;; IE NO SCALING FACTOR 
    TOA_EMM_OFFSET = 1
  ENDIF


  TOA_EMM = FLOAT(TOA_EMM)
  TOA_EMM_COUNTS = 0
  TEMP_DIMS = SIZE(TOA_EMM)
  TOA_EMM[*,*, I] = TOA_EMM_SLOPES*(TOA_EMM-TOA_EMM_OFFSET)
  
  
ENDFOR

;-----------------------------------------------
; CLOSE THE PRODUCT AND SD INTERFACE

IF KEYWORD_SET(VERBOSE) THEN PRINT,'MODISA L1B EMISSIVE: CLOSING PRODUCT AND RETURNING EMISSIVE DATA'
HDF_SD_END,HDF_ID

;-----------------------------------------------
; RETURN,L1B_EMM

RETURN,TOA_EMM

END



















