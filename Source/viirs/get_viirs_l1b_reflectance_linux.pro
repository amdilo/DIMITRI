FUNCTION GET_VIIRS_L1B_REFLECTANCE_LINUX, FILENAME, VERBOSE=VERBOSE, RES_750M=RES_750M
;+
; :Name:
;      GET_viirs_L1B_REFLECTANCE_LINUX
;
; :Description:
;      returns the l1b reflectance for a specific VIIRS band
;
; :Calling sequence:
;      RES = GET_VIIRS_L1B_REFLECTANCE_LINUX(FILENAME)
;
; :Params:
;      FILENAME :
;        a scalar containing the filename of the product for reflectance extraction
;
; :Keywords:
;      VERBOSE :
;        processing status outputs
;      RES_750M :
;        indicates that the in_band index refers to the 1km dataset
;
; :Returns:
;      TOA_REFL :
;        toa reflectance for product following use of scaling factor
;
; COMMON BLOCKS:
;      NONE
;
; :History:
;      27 Jun 2013 - D marrable   - DIMITRI-2 V1.0
;
;-

; NOTE: only working with 750km data righ now.
 

;------------------------------------------------
; CHECK KEYWORDS

IF KEYWORD_SET(VERBOSE) THEN PRINT,'viirs L1B REFLECTANCE: STARTING REFLECTANCE RETRIEVAL'

;------------------------------------------------
; CHECK FILENAME IS PARSED

IF FILENAME EQ '' THEN BEGIN
  PRINT, 'viirs L1B REFLECTANCE: ERROR, INPUT FILENAME INCORRECT'
  RETURN,-1
ENDIF

;------------------------------------------------
; START THE SD INTERFACE AND OPEN THE PRODUCT

IF KEYWORD_SET(VERBOSE) THEN PRINT,'viirs L1B REFLECTANCE: STARTING IDL HDF SD INTERFACE'
MODBAD = 65533  ; file flag ?
HDF_ID = HDF_SD_START(FILENAME,/READ)

; Pull out the meta data structre so we can query the datafile attributes.
SMETA_ID = HDF_SD_ATTRFIND(HDF_ID,'StructMetadata.0') ; returns structure as a string
HDF_SD_ATTRINFO,HDF_ID, SMETA_ID, DATA=HDF_METADATA_STRING

RES = STRPOS(HDF_METADATA_STRING, 'Along_Track') ; then the next field will be the dimension
c_DIM = STRMID(HDF_METADATA_STRING,RES + 22,4)

RES = STRPOS(HDF_METADATA_STRING, 'Along_Scan')
r_DIM = STRMID(HDF_METADATA_STRING,RES + 21,4)

;------------------------------------------------
; Unlike the MODISA file, we need to pull out each band individually
; So we setup the number of bands and loop through them pulling each one
; out of the file

NUM_BANDS = 11 ; reflectanc bands
TOA_REFL = MAKE_ARRAY(C_DIM, R_DIM, NUM_BANDS, /FLOAT)

FOR I=0, NUM_BANDS-1 DO BEGIN
  SD_NAME = 'Reflectance_M' + STRTRIM((I + 1),2)

  SDS_ID = HDF_SD_NAMETOINDEX(HDF_ID, SD_NAME)
  SDS_ID = HDF_SD_SELECT(HDF_ID, SDS_ID)
  HDF_SD_GETDATA, SDS_ID, TEMP
  
  TOA_REFL[*,*,I] = TEMP; column, row, band?
  
  ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Scale')
  HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_REFL_SLOPES
  
  ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Offset')
  HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_REFL_OFFSET
  HDF_SD_ENDACCESS, SDS_ID
  
  ;-----------------------------------------------
  ; CONVERT TO REFLECTANCE
  
  TOA_REFL = FLOAT(TEMPORARY(TOA_REFL))
  TEMP_DIMS = SIZE(TOA_REFL)
  TEMP = TOA_REFL[*,*,I]
  VALID = WHERE(TEMP LT MODBAD,COUNT)
  IF COUNT GT 0 THEN TEMP[VALID] = TOA_REFL_SLOPES*(TEMP[VALID]-TOA_REFL_OFFSET)
  TOA_REFL[*,*,I] = TEMP
    
ENDFOR

;-----------------------------------------------
; RETURN,L1B_RAD ;NOTE, THIS IS RHO*SZA
;
; REMOVE THE BOWTIE EFFECT.
FLAG = 65533.0
LAT_LON_STRUCTURE = GET_VIIRS_LAT_LON(FILENAME)
BOWTIE_CORRECTION_STRUCTURE = FIX_BOWTIE(TOA_RAD[*, *, IN_BAND], LAT_LON_STRUCTURE.LAT, LAT_LON_STRUCTURE.LON, FLAG)
TOA_RAD = BOWTIE_CORRECTION_STRUCTURE.TOA_REF ;NOTE not reflectance, the data structure is just called that.


RETURN,TOA_RAD[*, *] ;, IN_BAND]

END
