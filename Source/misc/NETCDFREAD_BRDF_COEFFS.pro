;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      NETCDFREAD_BRDF_COEFFS       
;* 
;* PURPOSE:
;*		NETCDF FUNCTION TO READ AND INTERPOLATE AUXDATA FROM GLOBAL DATA (LON/LAT) :
;*		- CHECK FOR VALID INPUT PARAMETERS
;*		- OPEN THE NETCDF FILE
;*		- READ NETCDF VARIABLES AND CHECK FOR LON/LAT/TIME VARIABLES (DEFINED IN REGION_STRUCT)
;*		- FIND INDEXES AND FILTER OUT REQUIRED REGION ON DATA_STRUCT TO EXTRACT (DEFINED IN DATA_STRUCT_STRUCT)
;*		- CREATE STRUCTURES BASED ON THE NETCDF DEFINITIONS
;*		- ONCE STRUCTURES ARE DEFINED, THEN READ THE NETCDF VARIABLES AVAILABLE INTO THE STRUCTURE'S DATA
;*		- READ THE ATTRIBUTES INTO A STRING ARRAY
;*		- CLOSE THE NETCDF FILE
;*		- PERFORM DATA INTERPOLATION IF REQUIRED
;* 
;* CALLING SEQUENCE:
;*      RES = NETCDFREAD_BRDF_COEFFS, NCDF_FILENAME, STATUS, INGEST_INFOS_STRUCT, ATTRIBUTES_STRUCT, REGION_STRUCT, DATA_STRUCT, NCDF_LON_VALUES, NCDF_LAT_VALUES, VERBOSE=VERBOSE
;* 
;* INPUTS:
;*      NCDF_FILENAME -  NETCDF FILE TO READ
;*      INGEST_INFOS_STRUCT - INFORMATION STRUCTURE TO READ (ROI DEFINITION(LON/LAT) / INTERPOLATION FLAG / NATURE OF DATA / DATE SLOT / )
;*
;* KEYWORDS:
;*      ATTRIBUTES_STRUCT  - GLOBAL FILE ATTRIBUTE INFORMATIONS STORED IN A STRUCTURE
;*      REGION_STRUCT  - ROI DEFINITION(LON/LAT) / INTERPOLATION FLAG
;*      DATA_STRUCT  - AUX_DATA CHANNELS TO GET IN NETCDF FILES
;*		NCDF_LON_VALUES / NCDF_LAT_VALUES : LON/LAT VALUES IN GLOBAL NETCDF FILE
;*      STATUS  - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION	
;*      VERBOSE           - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*		RES - READ AND INTERPOLATED (OR NOT) AUX_DATA STRUCTURE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        04 DEC 2013 - PML / MAGELLIUM    - CREATION
;*
;* VALIDATION HISTORY:
;*      17 APR 2014 - PML / MAGELLIUM    - WINDOWS 64-BIT MACHINE IDL 8.2.3 : COMPILATION AND CALLING SUCCESSFUL
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION NETCDFREAD_BRDF_COEFFS, NCDF_FILENAME, STATUS, VERBOSE=VERBOSE

	TRUE = 1
	FALSE = 0

	DEBUG_MODE = 0			; SET TO 1 IF WANT TO DEBUG THIS PROCEDURE

	STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
	STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

	STATUS = STATUS_ERROR

	;	CHECK FOR VALID FILENAME
	NCDF_FILENAME_INFO = FILE_INFO(NCDF_FILENAME)
	IF NCDF_FILENAME_INFO.EXISTS EQ 0 THEN BEGIN
			PRINT, 'NETCDFREAD_BRDF_COEFFS: NCDF FILE ' + NCDF_FILENAME + ' DO NOT EXIST'
			RETURN, STATUS_ERROR
	ENDIF 

	;	OPEN THE NETCDF FILE
	FID = NCDF_OPEN(NCDF_FILENAME,/NOWRITE )
	IF FID EQ -1 THEN BEGIN
			PRINT, 'NETCDFREAD_BRDF_COEFFS: NCDF FILE ' + NCDF_FILENAME + ' CAN NOT BE OPEN'
			RETURN, STATUS_ERROR
	ENDIF 

	;	CREATE STRUCTURES BASED ON THE NETCDF DEFINITIONS
	FINQ = NCDF_INQUIRE(FID)		; FINQ /STR = NDIMS, NVARS, NGATTS, RECDIM
	IF N_TAGS(FINQ) LT 4 THEN BEGIN
			PRINT, 'NETCDFREAD_BRDF_COEFFS: NCDF FILE ' + NCDF_FILENAME + ' CONTENT IS NOK OR NOT NCDF FILE'
			NCDF_CLOSE, FID
			RETURN, STATUS_ERROR
	ENDIF 
	; CHECK FOR MANDATORY FIELDS (NDIMS, NVARS, NGATTS, RECDIM)
	FINQ_MANDATORY_FIELDS = ['NDIMS','NVARS','NGATTS','RECDIM']
	FINQ_FIELDS = TAG_NAMES(FINQ)
	VALID_FIELDS = TRUE
	FOR INDX=0,N_ELEMENTS(FINQ_MANDATORY_FIELDS)-1 DO BEGIN
		CUR_FIELD = FINQ_MANDATORY_FIELDS[INDX]
		RES = WHERE(STRMATCH(FINQ_FIELDS,CUR_FIELD,/FOLD_CASE) EQ 1,COUNT)
		IF COUNT EQ 0 THEN BEGIN
			PRINT, 'NETCDFREAD_BRDF_COEFFS: NCDF FILE ' + NCDF_FILENAME + ' : MANDATORY FIELD ' + CUR_FIELD + ' DO NOT EXIST'
			VALID_FIELDS = FALSE
			NCDF_CLOSE, FID 
			RETURN, STATUS_ERROR 
		ENDIF
	ENDFOR

	NCDF_VARGET, FID, NCDF_VARID(FID, 'prodDate'), PRODDATE
	NCDF_VARGET, FID, NCDF_VARID(FID, 'longitude'), LONGITUDE
	NCDF_VARGET, FID, NCDF_VARID(FID, 'latitude'), LATITUDE
	NCDF_VARGET, FID, NCDF_VARID(FID, 'K1'), K1
	NCDF_VARGET, FID, NCDF_VARID(FID, 'K2'), K2
	NCDF_VARGET, FID, NCDF_VARID(FID, 'K3'), K3

	DATA =  CREATE_STRUCT('prodDate', PRODDATE, $
												'longitude', LONGITUDE, $
												'latitude', LATITUDE, $
												'K1', K1, $
												'K2', K2, $
												'K3', K3 )

	;	CLOSE THE NETCDF FILE
	;	9.	NCDF_CLOSE: CLOSE THE FILE.
	NCDF_CLOSE, FID
	STATUS = STATUS_OK

	; RETURN DATA STRUCTURE UPDATED WITH NEW FIELDS
	RETURN, DATA

END
