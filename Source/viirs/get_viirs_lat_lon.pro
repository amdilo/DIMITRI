FUNCTION GET_VIIRS_LAT_LON, FILENAME, VERBOSE=VERBOSE
;+
; :Name:
;      GET_VIIRS_LAT_LON
;
; :Description
;      returns the interpolated latitude and longitude of a viirs image
;
; :Calling_sequence:
;      RES = GET_VIIRS_LAT_LON(FILENAME)
;
; :Params:
;      FILENAME : in, required, type=string or string array
;          a string containing the filename of the product for geolocaiton extraction
;
; :Keywords:
;      VERBOSE :
;         PROCESSING STATUS OUTPUTS
;
; :Returns:
;      STRUCT.LAT : 
;         LATITUDE IN DEGREES FOR L1B PRODUCT
;      STRUCT.LON :
;         LONGITUDE IN DEGREES FOR L1B PRODUCT
;
; COMMON BLOCKS:
;      NONE
;
; :History:
;      26 JUN 2013 - D MARRABLE   - DIMITRI-2 V1.0
;-


;------------------------------------------------
; CHECK FILENAME IS PARSED

IF FILENAME EQ '' THEN BEGIN
  PRINT, 'VIIRS L1B LAT LON: ERROR, INPUT FILENAME INCORRECT'
  RETURN,-1
ENDIF

;------------------------------------------------
;OPEN THE L1B FILE

IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS L1B LAT LON: RETRIEVING GEOLOCATION SDS DATA'

HDF_ID = HDF_SD_START(FILENAME,/READ) ; File pointer

SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'Latitude') ; Index in the HDF file that points to dataset
SDS_ID = HDF_SD_SELECT(HDF_ID,SDS_NAME)
HDF_SD_GETDATA, SDS_ID, LAT
HDF_SD_ENDACCESS, SDS_ID

SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'Longitude')
SDS_ID = HDF_SD_SELECT(HDF_ID,SDS_NAME)
HDF_SD_GETDATA, SDS_ID, LON
HDF_SD_ENDACCESS, SDS_ID

;-------------------------------------------------
; CLOSE THE HDF FILE

IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS L1B LAT LON: CLOSING PRODUCT'
HDF_SD_END,HDF_ID

;------------------------------------------------
; RETURN LAT AND LON

IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS L1B LAT LON: RETURNING LATITUDE AND LONGITUDE'
RETURN,{LAT:LAT,LON:LON}

END

