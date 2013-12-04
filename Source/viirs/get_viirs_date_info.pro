FUNCTION GET_VIIRS_DATE_INFO, FILENAME, VERBOSE=VERBOSE
;+
; :Name:
;      GET_VIIRS_DATE_INFO
;
; :Description
;      returns the date information of a modisa l1b file
;
; :Calling_sequence:
;      RES = GET_VIIRS_date_INFO(FILENAME)
;
; :Params:
;      FILENAME : in, required, type=string or string array
;          a string containing the filename of the product for geolocaiton extraction
;
; :Keywords:
;      VERBOSE :
;         processing status outputs
;
; :Returns:
;      DATE_INFO : a structure containing the year, month, day, day of year and decimel year
;
; COMMON BLOCKS:
;      none
;
; :History:
;      26 JUN 2013 - D MARRABLE   - DIMITRI-2 V1.0
;-

;------------------------------------------------
; CHECK FILENAME IS A NOMINAL INPUT

IF FILENAME EQ '' THEN BEGIN
  PRINT, 'VIIRS DATE INFO: ERROR, INPUT FILENAME INCORRECT'
  RETURN,-1
ENDIF

;------------------------------------------------
; DEFINE OUTPUT STRUCT

IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS DATE INFO: DEFINING DATE_INFO STRUCTURE'
DATE_INFO = {$
  YEAR  :0,$
  MONTH :0,$
  DAY   :0,$
  DOY   :0,$
  DYEAR :DOUBLE(0.0) ,$
  CMD_DATE   :'',$
  CMD_TIME   :'',$
  HOUR  :0,$
  MINUTE:0,$
  SECOND:0 $
}

;------------------------------------------------
; OPEN HDF FILE AND EXTRACT CORE_METADATA

HDF_ID = HDF_SD_START(FILENAME,/READ) ;file pointer
CMETA_ID = HDF_SD_ATTRFIND(HDF_ID,'StartTime')
IF CMETA_ID EQ -1 THEN BEGIN
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS DATE INFO: ERROR, NO COREMETADATA FOUND'
  RETURN,{ERROR:-1}
ENDIF
HDF_SD_ATTRINFO,HDF_ID,CMETA_ID, DATA=HDF_CMD  ; HDF_CMD is now the date as a string eg '2013-06-25 00:30:17.300'

CMD_DATE = STRMID(HDF_CMD,0,10) ; cmd_date was derived from hdf_cmd in modisa.  It's not nesacary here so just rename it.
CMD_TIME = STRMID(HDF_CMD,11,12)

;------------------------------------------------
; CLOSE THE HDF FILE

IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS DATE INFO: RETRIEVED DATA, CLOSING PRODUCT'
HDF_SD_END, HDF_ID

DATE_INFO.YEAR = FIX(STRMID(CMD_DATE,0,4))
DATE_INFO.MONTH= FIX(STRMID(CMD_DATE,5,2))
DATE_INFO.DAY  = FIX(STRMID(CMD_DATE,8,2))
DATE_INFO.DOY  = JULDAY(DATE_INFO.MONTH,DATE_INFO.DAY,DATE_INFO.YEAR)-JULDAY(1,0,DATE_INFO.YEAR)
IF FLOAT(DATE_INFO.YEAR) MOD 4 EQ 0 THEN DIY = 366.0 ELSE DIY = 365.0

THR = FIX(STRMID(CMD_TIME,0,2))
TMM = FIX(STRMID(CMD_TIME,3,2))
TSS = FIX(STRMID(CMD_TIME,6,2))
TTIME = DOUBLE((THR/(DIY*24.))+(TMM/(DIY*60.*24.))+TSS/(DIY*60.*60.*24.))

DATE_INFO.HOUR = THR
DATE_INFO.MINUTE = TMM
DATE_INFO.SECOND = TSS
DATE_INFO.CMD_TIME = CMD_TIME
DATE_INFO.CMD_DATE = CMD_DATE
DATE_INFO.DYEAR  = FLOAT(DATE_INFO.YEAR)+(DOUBLE(DATE_INFO.DOY)/DIY)+TTIME
IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VIIRS DATE INFO: DATE RETRIEVAL COMPLETE'

;---------------------------------------
; RETURN DATE INFORMATION

RETURN,DATE_INFO

END
