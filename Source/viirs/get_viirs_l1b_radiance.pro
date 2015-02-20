FUNCTION GET_VIIRS_L1B_RADIANCE, FILENAME, IN_BAND, VERBOSE=VERBOSE
;+
; :Name:
;      GET_MODISA_L1B_RADIANCE_LINUX
;
; :Description:
;      returns the l1b radiance for a specific modisa band
;
; :calling sequence:
;      res = get_modisa_l1b_radiance_linux(filename)
;
; :Params:
;      FILENAME :
;        A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR RADIANCE EXTRACTION
;
;* Keywords:
;      VERBOSE :
;           - PROCESSING STATUS OUTPUTS
;
; :Returns:
;      TOA_REFL :
;          - toa radiance for product
;
; :Common blocks:
;      NONE
;
; :History:
;      27 JUN 2013 - D Marrable   - DIMITRI-2 V1.0
;-


; !!! NOTE : For some reason that I don't understand, bands 3, 4, 5 & 13 are stored as floats
; while the others are stored as ints with a scaling factor.    Word around for now. Come back later

;------------------------------------------------
; CHECK KEYWORDS

IF KEYWORD_SET(VERBOSE) THEN PRINT,'VIIRS L1B RADIANCE: STARTING RADIANCE RETRIEVAL'

;------------------------------------------------
; CHECK FILENAME IS PARSED

IF FILENAME EQ '' THEN BEGIN
  PRINT, 'VIIRS L1B radiance: ERROR, INPUT FILENAME INCORRECT'
  RETURN,-1
ENDIF

;------------------------------------------------
; START THE SD INTERFACE AND OPEN THE PRODUCT

IF KEYWORD_SET(VERBOSE) THEN PRINT,'VIIRS L1B radiance: STARTING IDL HDF SD INTERFACE'
MODBAD = 65533  ; file flag ?
HDF_ID = HDF_SD_START(FILENAME,/READ)

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

NUM_BANDS = 11 ; reflectanc bands
TOA_RAD = MAKE_ARRAY(C_DIM, R_DIM, NUM_BANDS, /FLOAT)

FOR I=0, NUM_BANDS-1 DO BEGIN
  SD_NAME = 'Radiance_M' + STRTRIM((I + 1),2)
  
  SDS_ID = HDF_SD_NAMETOINDEX(HDF_ID, SD_NAME)
  SDS_ID = HDF_SD_SELECT(HDF_ID, SDS_ID)
  HDF_SD_GETDATA, SDS_ID, TEMP
  
  TOA_RAD[*,*,I] = TEMP; column, row, band?
  
  ; IF BAND 3,4,5 OR 13 scale factor is set to 1
  ; THERE IS NO NEED TO SCALE (SEE NOTE AT TOP OF FILE)
  IF I EQ 3-1 OR I EQ 4-1 OR I EQ 5-1 OR I EQ 7-1 OR I EQ 13-1 THEN BEGIN
    TOA_RAD_SLOPES = 1
    TOA_RAD_OFFSET = 1
  ENDIF ELSE BEGIN
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Scale')
    HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_RAD_SLOPES
    
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'Offset')
    HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_RAD_OFFSET
    HDF_SD_ENDACCESS, SDS_ID
   ENDELSE
  
  ;-----------------------------------------------
  ; CONVERT UNSCALED VALUES TO radiance
  
  TOA_RAD = FLOAT(TEMPORARY(TOA_RAD))
  TEMP_DIMS = SIZE(TOA_RAD)
  TEMP = TOA_RAD[*,*,I]
  VALID = WHERE(TEMP LT MODBAD,COUNT)
  IF COUNT GT 0 THEN TEMP[VALID] = TOA_RAD_SLOPES*(TEMP[VALID]-TOA_RAD_OFFSET)
  TOA_RAD[*,*,I] = TEMP
  
ENDFOR

;-----------------------------------------------
; RETURN,L1B_RAD ;NOTE, THIS IS RHO*SZA
; 
; REMOVE THE BOWTIE EFFECT.
FLAG = -1000.70
LAT_LON_STRUCTURE = GET_VIIRS_LAT_LON(FILENAME)
BOWTIE_CORRECTION_STRUCTURE = FIX_BOWTIE(TOA_RAD[*, *, IN_BAND], LAT_LON_STRUCTURE.LAT, LAT_LON_STRUCTURE.LON, FLAG)
TOA_RAD = BOWTIE_CORRECTION_STRUCTURE.TOA_REF ;NOTE not reflectance, the data structure is just called that.
;-----------------------------------------------
; RETURN,L1B_RAD ;NOTE, THIS IS RHO*SZA

; WRITE THE REGRIDED LAT AND LON TO A .SAVE FILE SO THAT THE QUICK LOOK ROUTINE CAN FIND IT
; save, a, b, c, filename='junk.save'
SAVE, BOWTIE_CORRECTION_STRUCTURE, FILENAME='LAT_LON_VIIRS_REGRID.SAV' 

RETURN,TOA_RAD[*, *] ;, IN_BAND]

END