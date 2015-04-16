;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      INGEST_VEGETATION_PRODUCT       
;* 
;* PURPOSE:
;*      INGESTS VEGETATION L1B DATA INTO DIMITRI DATABASE. MULTIPLE PRODUCT 
;*	    EXTRACTION IS AVAILABLE BUT IT EXPECTS ALL FILES TO BE THE SAME REGION/PROCESSING. 
;*      OUTPUTS QUICKLOOK IMAGES, UPDATES DATABASE AND APPENDS DATA TO SAV FILE FOR 
;*      SPECIFIED REGION AND PROCESSING.
;* 
;* CALLING SEQUENCE:
;*      RES = INGEST_VEGETATION_PRODUCT(IFILES)      
;* 
;* INPUTS:
;*      IFILES -  A STRING OR STRING ARRAY OF THE FULL PATH FILENAMES OF PRODUCTS (LOG FILES) 
;*                FOR INGESTION.      
;*
;* KEYWORDS:
;*      INPUT_FOLDER      - A STRING CONTAINING THE FULL PATH OF THE 'INPUT' FOLDER, IF 
;*                          NOT PROVIDED THEN IT IS DERIVED FROM THE FILENAME
;*      ICOORDS           - A FOUR ELEMENT FLOATING-POINT ARRAY CONTAINING THE NORTH, SOUTH, 
;*                          EAST AND WEST COORDINATES OF THE ROI, E.G [50.,45.,10.,0.]
;*      NB_PIX_THRESHOLD  - NUMBER OF PIXELS WITHIN ROI TO BE ACCEPTED
;*      ENDIAN_SZE        - MACHINE ENDIAN SIZE (0: LITTLE, 1: BIG), IF NOT PROVIDED 
;*                          THEN COMPUTED.
;*      COLOUR_TABLE      - USER DEFINED IDL COLOUR TABLE INDEX (DEFAULT IS 39)
;*      PLOT_XSIZE        - WIDTH OF GENERATED PLOTS (DEFAULT IS 700PX)
;*      PLOT_YSIZE        - HEIGHT OF GENERATED PLOTS (DEFAULT IS 400PX)
;*      NO_ZBUFF          - IF SET THEN PLOTS ARE GENERATED IN WINDOWS AND NOT 
;*                          WIHTIN THE Z-BUFFER.
;*      NO_QUICKLOOK      - IF SET THEN QUICKLOOKS ARE NOT GENERATED FOR IFILES.
;*      VERBOSE           - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS  - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION	
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        16 DEC 2010 - C KENT    - DIMITRI-2 V1.0
;*        20 DEC 2010 - C KENT    - UPDATED COMMENTS AND HEADER INFORMATION
;*        10 JAN 2011 - C KENT    - CHANGED SAVED OUTPUT VARIABLE TO SENSOR_L1B_REF 
;*        12 JAN 2011 - C KENT    - OUTPUT RGB QUICKLOOKS AS DEFUALT, UPDATED OUTPUT DATA 
;*                                  WITH SAA AND VAA (REMOVED RAA)
;*        21 MAR 2011 - C KENT    - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*        22 MAR 2011 - C KENT    - ADDED CONFIGURAITON FILE DEPENDENCE
;*        06 APR 2011 - C KENT    - ADD VGT AUTOMATED CLOUD SCREENING
;*        01 JUL 2011 - C KENT    - ADDED ANGLE CORRECTOR
;*        04 JUL 2011 - C KENT    - ADDED AUX INFO TO OUTPUT SAV
;*        08 JUL 2011 - C KENT    - ADDED CATCH ON MISSING BAND DATA   
;*        14 JUL 2011 - C KENT    - UPDATED TIME EXTRACTION SECTION
;*        14 SEP 2011 - C KENT    - UPDATED NETCDF OUTPUT
;*        19 SEP 2011 - C KENT    - FIXED OZONE AND WVAP ARRAY BUG
;*        08 MAR 2012 - C KENT    - ADDED ROI COVERAGE
;*        21 MAR 2012 - C KENT    - ADDED FIX FOR ERRONEOUS VITO D VALUES
;*        09 APR 2012 - C KENT    - IMPLEMENTED CNES CORRECTION FOR VITO REFLECTANCES
;*        12 FEB 2015 - NCG / MAGELLIUM   - UPDATE WITH DIMITRI V4 SPECIFICATION
;*
;* VALIDATION HISTORY:
;*        16 DEC 2010 - C KENT    - WINDOWS 32BIT MACHINE, COMPILATION AND EXECUTION 
;*                                  SUCCESSFUL. TESTED MULTIPLE OPTIONS ON MULTIPLE 
;*                                  PRODUCTS
;*        12 APR 2011 - C KENT    - LINUX 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*        20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*        30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION INGEST_VEGETATION_PRODUCT,IFILES,INPUT_FOLDER=INPUT_FOLDER,ICOORDS=ICOORDS,INGEST_SUNGLINT=INGEST_SUNGLINT,$
         COLOUR_TABLE=COLOUR_TABLE,$
         PLOT_XSIZE=PLOT_XSIZE,PLOT_YSIZE=PLOT_YSIZE,NO_ZBUFF=NO_ZBUFF,NO_QUICKLOOK=NO_QUICKLOOK,$
         VERBOSE=VERBOSE

  FCT_NAME = 'INGEST_VEGETATION_PRODUCT'

	STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
	STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

	;------------------------
	; KEYWORD PARAMETER CHECK - NOTE, ASSUMES ALL PRODUCT ARE RELATED TO THE SAME REGION/PROCESSING

  IF STRCMP(STRING(IFILES[0]),'') THEN BEGIN
    PRINT, FCT_NAME + ' - ERROR, NO INPUT FILES PROVIDED, RETURNING...'
    RETURN, STATUS_ERROR
  ENDIF  
  IF N_ELEMENTS(INPUT_FOLDER) EQ 0 THEN INPUT_FOLDER = GET_DIMITRI_LOCATION('INPUT')

  ; GET THE CONFIGURATION VALUES (THRESHOLDS AND STRING VALUES)
  DL = GET_DIMITRI_LOCATION('DL')
  MISSING_VALUE_FLT=FLOAT(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  MISSING_VALUE_LONG=LONG(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  MIN_PIXEL_NB_INGEST_PROCESS = GET_DIMITRI_LOCATION('MIN_PIXEL_NB_INGEST_PROCESS')
  OUTPUT_FOLDER = GET_DIMITRI_LOCATION('INGESTION_OUTPUT')

  TEMP = STRSPLIT(IFILES[0],DL,/EXTRACT)
  
  TEMP_INF  = WHERE(STRCMP(TEMP,'Input') EQ 1)
  TEMP_INF  = TEMP_INF(N_ELEMENTS(TEMP_INF)-1)
  IREGION   = TEMP[TEMP_INF+1]
  IREGION   = STRMID(IREGION,5,STRLEN(IREGION)) 
  SENSOR    = TEMP[TEMP_INF+2]
  IPROC     = TEMP[TEMP_INF+3]
  IPROC     = STRMID(IPROC,5,STRLEN(IPROC)) 
  CFIG_DATA = GET_DIMITRI_CONFIGURATION()
  SITE_TYPE = GET_SITE_TYPE(IREGION,VERBOSE=VERBOSE) 

  IF N_ELEMENTS(ICOORDS) EQ 0 THEN BEGIN
    PRINT, FCT_NAME + ' - NO ROI COORDINATES PROVIDED, USING DEFAULT OF [90.,-90,180.0,-180.0]'
    ICOORDS = [90.,-90.,180.0,-180.0]
  ENDIF
  IF N_ELEMENTS(COLOUR_TABLE) EQ 0 THEN BEGIN
    PRINT, FCT_NAME + ' - NO COLOR_TABLE SET, USING DEFAULT OF 39'
    COLOUR_TABLE = CFIG_DATA.(1)[2]
  ENDIF
  IF N_ELEMENTS(PLOT_XSIZE) EQ 0 THEN BEGIN
    PRINT, FCT_NAME + ' - PLOT_XSIZE NOT SET, USING DEFAULT OF 700'
    PLOT_XSIZE = CFIG_DATA.(1)[0]
  ENDIF
  IF N_ELEMENTS(PLOT_YSIZE) EQ 0 THEN BEGIN
    PRINT, FCT_NAME + ' - PLOT_YSIZE NOT SET, USING DEFAULT OF 400'
    PLOT_YSIZE = CFIG_DATA.(1)[1]
  ENDIF  

	;------------------------
	; GET NUMBER OF IFILES 

  NB_FILES = N_ELEMENTS(IFILES)

	;-----------------------------------------------
	; GET THE DATABASE STRUCTURE

  DB_DATA = GET_DIMITRI_TEMPLATE(NB_FILES,/DB)
  
	;-----------------------------------------------  
	; ADD DATA OF INGESTION TO DB_DATA

  TEMP = SYSTIME()
  TEMP = STRMATCH(STRMID(TEMP,8,1),' ') ? '0'+STRUPCASE(STRING(STRMID(TEMP,9,1)+'-'+STRMID(TEMP,4,3)+'-'+STRMID(TEMP,20,4))) : STRUPCASE(STRING( STRMID(TEMP,8,2)+'-'+STRMID(TEMP,4,3)+'-'+STRMID(TEMP,20,4)))
  DB_DATA.DIMITRI_DATE = TEMP 

	;-----------------------------------------------
	; ADD REGION, SENSOR AND PROC VERSION TO DB_DATA

  DB_DATA.SITE_NAME = IREGION
  DB_DATA.SITE_TYPE = SITE_TYPE
  DB_DATA.SITE_COORDINATES = 'NONE'
  DB_DATA.SENSOR = SENSOR
  DB_DATA.PROCESSING_VERSION = IPROC
 
	;-----------------------------------------
	; SET INITIAL VALUES 

  DB_DATA.L1_INGESTED_FILENAME = 'NONE'
  DB_DATA.ROI_STATUS = -1
  DB_DATA.ROI_PIX_NUM = -1
  DB_DATA.THETA_N_MEAN = -1
  DB_DATA.THETA_R_MEAN = -1
  DB_DATA.AUTO_CS_1_NAME = GET_DIMITRI_LOCATION('AUTO_CS_1_NAME')
  DB_DATA.AUTO_CS_1_MEAN = -1
  DB_DATA.ROI_CS_1_CLEAR_PIX_NUM = -1
  DB_DATA.AUTO_CS_2_NAME = GET_DIMITRI_LOCATION('AUTO_CS_2_NAME')
  DB_DATA.AUTO_CS_2_MEAN = -1
  DB_DATA.ROI_CS_2_CLEAR_PIX_NUM = -1
  DB_DATA.BRDF_CS_MEAN = -1
  DB_DATA.SSV_CS_MEAN = -1
  DB_DATA.MANUAL_CS = -1 
  DB_DATA.ERA_WIND_SPEED_MEAN = -1
  DB_DATA.ERA_WIND_DIR_MEAN = -1
  DB_DATA.ERA_OZONE_MEAN = -1
  DB_DATA.ERA_PRESSURE_MEAN = -1
  DB_DATA.ERA_WATERVAPOUR_MEAN = -1
  DB_DATA.ESA_CHLOROPHYLL_MEAN = -1

	;----------------------------------
	; DEFINE VEGETATION SPECIFIC PARAMETERS 
  NB_BANDS = SENSOR_BAND_INFO('VEGETATION') 
  NB_BANDS = NB_BANDS[0]
  NB_DIRECTIONS = SENSOR_DIRECTION_INFO(SENSOR)
  
	;----------------------------------
	; DEFINE THE STATISTICAL ARRAYS

	ROI_AVG_TOA_REF  = MAKE_ARRAY(NB_BANDS,NB_FILES,/FLOAT,VALUE=MISSING_VALUE_FLT)
	ROI_STD_TOA_REF  = FLTARR(NB_BANDS,NB_FILES)
	NB_ROI_PX        = FLTARR(NB_FILES)
	GOOD_RECORD      = MAKE_ARRAY(NB_FILES,/INTEGER,VALUE=0)
	IFILE_DATE 	     = DBLARR(5,NB_FILES);CONTAINS YEAR,MONTH,DAY,DOY,DECIMEL_YEAR
	IFILE_VIEW 	     = DBLARR(4,NB_FILES);CONTAINS SENSOR ZENITH,SENSOR AZIMUTH,SOLAR ZENITH,SOLAR AZIMUTH
  IFILE_AUX        = FLTARR(12,NB_FILES);CONTAINS OZONE,PRESSURE,RELHUMIDITY,WIND_ZONAL,WIND_MERID, AND WVAP (MU AND SIGMA)

	;---------------------------------
	; IF ONLY 1 PRODUCT FOR INGESTION THEN REFORM ARRAYS  
  IF NB_FILES EQ 1 THEN BEGIN
    ROI_AVG_TOA_REF  = REFORM(ROI_AVG_TOA_REF,NB_BANDS,NB_FILES)
    ROI_STD_TOA_REF  = REFORM(ROI_STD_TOA_REF,NB_BANDS,NB_FILES)
    IFILE_DATE       = REFORM(IFILE_DATE,5,NB_FILES)
    IFILE_VIEW       = REFORM(IFILE_VIEW,4,NB_FILES)
    IFILE_AUX        = REFORM(IFILE_AUX,12,NB_FILES)
  ENDIF

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    PRINT, FCT_NAME + ' - DEFINITION OF OUTPUT ARRAYS:'
    HELP, ROI_AVG_TOA_REF,ROI_STD_TOA_REF,NB_ROI_PX,GOOD_RECORD,IFILE_DATE,IFILE_VIEW
  ENDIF

	;---------------------------------
	; ADD DATA TO NETCDF OUTPUT STRUCTURE

  NCDF_OUT = GET_DIMITRI_EXTRACT_NCDF_DATA_STRUCTURE(NB_FILES,NB_BANDS,NB_DIRECTIONS)
  NCDF_OUT.ATT_FNAME  = 'Site_'+IREGION+'_'+SENSOR+'_'+'Proc_'+IPROC+'.nc'
  NCDF_OUT.ATT_TOOL   = GET_DIMITRI_LOCATION('TOOL')
  NCDF_OUT.ATT_SENSOR = SENSOR
  NCDF_OUT.ATT_PROCV  = IPROC
  NCDF_OUT.ATT_PRES   = STRTRIM(STRING(SENSOR_PIXEL_SIZE(SENSOR)),2)+' KM'
  NCDF_OUT.ATT_NBANDS = STRTRIM(STRING(NB_BANDS),2)
  NCDF_OUT.ATT_NDIRS  = STRTRIM(STRING(NB_DIRECTIONS[0]),2)
  NCDF_OUT.ATT_SITEN  = IREGION
  NCDF_OUT.ATT_SITEC  = STRJOIN(STRTRIM(STRING(ICOORDS),2),' ')
  NCDF_OUT.ATT_SITET  = SITE_TYPE
 
	;----------------------------------
	; START MAIN LOOP OVER EACH IFILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - STARTING INGESTION LOOP ON MERIS PRODUCTS'
	FOR IN_FNAME=0,NB_FILES-1 DO BEGIN; IN_FNAME IS RESERVED FOR LOOPS WITHIN THE INGESTION ROUTINES

    TEMP = STRSPLIT(IFILES[IN_FNAME],DL,/EXTRACT)
    TEMP1 = N_ELEMENTS(TEMP)
    DB_DATA.L1_FILENAME[IN_FNAME] = STRJOIN(TEMP[TEMP1-3:TEMP1-1],'_') ;MOVED TO WITHIN FILE LOOP

		IF KEYWORD_SET(VERBOSE) THEN BEGIN
			PRINT, FCT_NAME + ' [' + STRTRIM(STRING(IN_FNAME+1),1) + ' / ' + STRTRIM(STRING(NB_FILES),1) + '] : ' + DB_DATA.L1_FILENAME[IN_FNAME]
		ENDIF

		;------------------------------------------
		; RETRIEVE AUX DATA FILENAMES FOR DB_DATA

    IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ' - RETRIEVING HEADER INFORMATION'
    L1B_HEADER = GET_VEGETATION_HEADER_INFO(IFILES[IN_FNAME],VERBOSE=VERBOSE)
       
    TEMP = 'NONE'
    DB_DATA.AUX_DATA_1[IN_FNAME] = L1B_HEADER.PRD_ID
    DB_DATA.AUX_DATA_2[IN_FNAME] = L1B_HEADER.AUX_DEM 
    DB_DATA.AUX_DATA_3[IN_FNAME] = L1B_HEADER.AUX_RAD_EQL 
    DB_DATA.AUX_DATA_4[IN_FNAME] = L1B_HEADER.AUX_RAD_ABS 
    DB_DATA.AUX_DATA_5[IN_FNAME] = L1B_HEADER.AUX_GEO
    DB_DATA.AUX_DATA_6[IN_FNAME] = TEMP 
    DB_DATA.AUX_DATA_7[IN_FNAME] = TEMP 
    DB_DATA.AUX_DATA_8[IN_FNAME] = TEMP 
    DB_DATA.AUX_DATA_9[IN_FNAME] = TEMP 
    DB_DATA.AUX_DATA_10[IN_FNAME] = TEMP 
        
		;----------------------------------
		; RETRIEVE DATE INFORMATION

    IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - RETRIEVING DATE INFORMATION'
    
		ACQ_YEAR  = STRMID(L1B_HEADER.ACQ_DATE,0,4)
		ACQ_MONTH = STRMID(L1B_HEADER.ACQ_DATE,4,2)
		ACQ_DAY   = STRMID(L1B_HEADER.ACQ_DATE,6,2)

    IFILE_DATE[0,IN_FNAME]	= FLOAT(ACQ_YEAR)
    IFILE_DATE[1,IN_FNAME]	= FLOAT(ACQ_MONTH)
    IFILE_DATE[2,IN_FNAME]	= FLOAT(ACQ_DAY)
    IF FLOAT(IFILE_DATE[0,IN_FNAME]) MOD 4 EQ 0 THEN DIY = 366.0 ELSE DIY = 365.0  
    
		DATE_HR  = STRMID(L1B_HEADER.ACQ_TIME,0,2)
		DATE_MIN = STRMID(L1B_HEADER.ACQ_TIME,2,2)
		DATE_SEC = STRMID(L1B_HEADER.ACQ_TIME,4,2)

    THR = FLOAT(DATE_HR)
    TMM = FLOAT(DATE_MIN)
    TSS = FLOAT(DATE_SEC)
    TTIME = DOUBLE((THR/(DIY*24.))+(TMM/(DIY*60.*24.))+TSS/(DIY*60.*60.*24.))

    IFILE_DATE[3,IN_FNAME]	= JULDAY(IFILE_DATE[1,IN_FNAME],IFILE_DATE[2,IN_FNAME],IFILE_DATE[0,IN_FNAME])-JULDAY(1,0,IFILE_DATE[0,IN_FNAME])
    IFILE_DATE[4,IN_FNAME] =  DOUBLE(IFILE_DATE[0,IN_FNAME])+ DOUBLE(IFILE_DATE[3,IN_FNAME]/DIY)+TTIME

		;----------------------------------
		; ADD DATE INFORMATION TO DB_DATA

    DB_DATA.YEAR[IN_FNAME]   = IFILE_DATE[0,IN_FNAME]
    DB_DATA.MONTH[IN_FNAME]  = IFILE_DATE[1,IN_FNAME]
    DB_DATA.DAY[IN_FNAME]    = IFILE_DATE[2,IN_FNAME]
    DB_DATA.DOY[IN_FNAME]    = IFILE_DATE[3,IN_FNAME]
    DB_DATA.DECIMAL_YEAR[IN_FNAME] = IFILE_DATE[4,IN_FNAME]
   
		;-----------------------------------------
		; STORE DATE IN NETCDF STRUCTURE

    NCDF_OUT.VAR_PNAME[IN_FNAME]  = DB_DATA.L1_FILENAME[IN_FNAME] 
    NCDF_OUT.VAR_PTIME[IN_FNAME]  = STRMID(L1B_HEADER.ACQ_DATE,0,8)+' '+STRMID(L1B_HEADER.ACQ_TIME,0,2)+':'+STRMID(L1B_HEADER.ACQ_TIME,2,2)+':'+STRMID(L1B_HEADER.ACQ_TIME,4,2)
    NCDF_OUT.VAR_DTIME[IN_FNAME]  = DB_DATA.DECIMAL_YEAR[IN_FNAME]

		;------------------------------------------
		; CHECK THAT THE REFLECTANCE DATA IS PRESENT

    TMP_FILE1 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'B0.HDF')
    TMP_FILE2 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'MIR.HDF')
    TMP_FILE3 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'B2.HDF')
    TMP_FILE4 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'B3.HDF')
    TMP_FILE5 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'VZA.HDF')
    TMP_FILE6 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'VAA.HDF')
    TMP_FILE7 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'SZA.HDF')
    TMP_FILE8 = STRING(STRMID(IFILES[IN_FNAME],0,STRLEN(IFILES[IN_FNAME])-7)+'SAA.HDF')
    
    IF FILE_TEST(TMP_FILE1) EQ 0 or $
				FILE_TEST(TMP_FILE2) EQ 0 or $
				FILE_TEST(TMP_FILE3) EQ 0 or $
				FILE_TEST(TMP_FILE4) EQ 0 or $
				FILE_TEST(TMP_FILE5) EQ 0 or $
				FILE_TEST(TMP_FILE6) EQ 0 or $
				FILE_TEST(TMP_FILE7) EQ 0 or $
				FILE_TEST(TMP_FILE8) EQ 0 THEN GOTO, NO_BAND_DATA

		;----------------------------------
		; RETRIEVE INPUT FILE L1B RADIANCE 

		IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - RETRIEVING RADIANCE INFORMATION'
    L1B_REF = GET_VEGETATION_L1B_REFLECTANCE(IFILES[IN_FNAME],VERBOSE=VERBOSE)
    
    IF MAX(L1B_REF[*,*,0]) LT 0.00001 THEN GOTO, NO_BAND_DATA

		;----------------------------------
		; RETRIEVE INPUT FILE GEOLOCATION

		IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - RETRIEVING GEOLOCATION INFORMATION'
    L1B_GEO = GET_VEGETATION_LAT_LON(IFILES[IN_FNAME],VERBOSE=VERBOSE)

		;------------------------------------------
		; RETRIEVE VIEWING GEOMETRIES

		IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - RETRIEVING VIEWING GEOMETRIES'
    L1B_VGEO= GET_VEGETATION_VIEWING_GEOMETRIES(IFILES[IN_FNAME],VERBOSE=VERBOSE)
		TEMP_ANGLES = DIMITRI_ANGLE_CORRECTOR(L1B_VGEO[*,*,2],L1B_VGEO[*,*,3],L1B_VGEO[*,*,0],L1B_VGEO[*,*,1])

		;------------------------------------------
		; RETRIEVE INDEX OF NOMINAL DATA WITHIN ROI
 
    IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - RETRIEVING INDEX OF PIXELS WITHIN ROI'
    ROI_INDEX = WHERE($
            L1B_GEO.LAT LT ICOORDS[0] AND $
            L1B_GEO.LAT GT ICOORDS[1] AND $
            L1B_GEO.LON LT ICOORDS[2] AND $
            L1B_GEO.LON GT ICOORDS[3] AND $
            L1B_REF[*,*,0] GT 0.0    , $
            NB_PIX $
            )
 
		; IF NO PIXELS IN ROI THEN DO NOT RETRIEVE TOA REFLECTANCE
		IF NB_PIX EQ 0 THEN BEGIN
			NO_BAND_DATA:
      IFILE_VIEW[*,IN_FNAME]= MISSING_VALUE_FLT
			IFILE_AUX[*,IN_FNAME] = MISSING_VALUE_FLT
			ROI_AVG_TOA_REF(*,IN_FNAME) = MISSING_VALUE_FLT
			ROI_STD_TOA_REF(*,IN_FNAME) = MISSING_VALUE_FLT

			GOTO, NO_ROI ; NEXT FILE     
		ENDIF
		
		IF KEYWORD_SET(VERBOSE) THEN BEGIN
			PRINT, ' SITE AREA FOUND >> RAW PIXELS NB = ' + STRTRIM(STRING(NB_PIX),1)
		ENDIF  

		DB_DATA.ROI_PIX_NUM[IN_FNAME] = NB_PIX
		DB_DATA.SITE_COORDINATES[IN_FNAME] = NCDF_OUT.ATT_SITEC      	     

		;-----------------------------------------
		; CHECK ROI COVERAGE

		IF NB_PIX GT MIN_PIXEL_NB_INGEST_PROCESS THEN BEGIN
			DB_DATA.ROI_STATUS[IN_FNAME] = 1
			IF INGEST_SUNGLINT EQ 0 THEN DB_DATA.ROI_STATUS[IN_FNAME] = CHECK_ROI_COVERAGE(L1B_GEO.LAT,L1B_GEO.LON,ROI_INDEX,ICOORDS,VERBOSE=VERBOSE)
		ENDIF ELSE BEGIN
			DB_DATA.ROI_STATUS[IN_FNAME] = 0
			GOTO, NO_ROI
		ENDELSE  

		GOOD_RECORD[IN_FNAME]=1

    ; GET NCDF INGESTION OUTPUT STRUCTURE
    ;------------------------------------

    NCDF_INGEST_STRUCT = GET_NCDF_INGEST_STRUCT( NB_PIX, NB_DIRECTIONS, NB_BANDS, VERBOSE=VERBOSE)
    NCDF_INGEST_STRUCT.GLOBAL_ATT.SITE_NAME = DB_DATA.SITE_NAME[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.SITE_TYPE = DB_DATA.SITE_TYPE[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.SENSOR = DB_DATA.SENSOR[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.PROCESSING_VERSION = DB_DATA.PROCESSING_VERSION[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.ACQUISITION_DATE = ACQ_YEAR + '-' + ACQ_MONTH + '-' + ACQ_DAY + ' ' + DATE_HR + ':' + DATE_MIN
    NCDF_INGEST_STRUCT.GLOBAL_ATT.L1_FILENAME = DB_DATA.L1_FILENAME[IN_FNAME] 

		;------------------------------------------
		; GENERATE A QUICKLOOK WITH THE ROI OVERLAID
  
		IF N_ELEMENTS(NO_QUICKLOOK) EQ 0 THEN BEGIN

			OUTPUT_QL_FOLDER   = OUTPUT_FOLDER+'Site_'+IREGION+DL+SENSOR+DL+'Proc_'+IPROC+DL+ ACQ_YEAR + DL
			OUTPUT_QL_FILENAME = OUTPUT_QL_FOLDER + IREGION + '_' + SENSOR + '_' + IPROC +  '_' + ACQ_YEAR + ACQ_MONTH + ACQ_DAY + '_' + DATE_HR + DATE_MIN

			OUT_FOLDER_INFO = FILE_INFO(OUTPUT_QL_FOLDER)
			IF OUT_FOLDER_INFO.DIRECTORY EQ 0 THEN BEGIN
				FILE_MKDIR, OUTPUT_QL_FOLDER
				IF KEYWORD_SET(VERBOSE) THEN BEGIN      
					PRINT, FCT_NAME + ' - WARNING, OUTPUT YEAR FOLDER ''' + OUTPUT_QL_FOLDER + ''' NOT FOUND >> CREATED'
				ENDIF
			ENDIF

			IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - GENERATE QUICKLOOK OF PRODUCT'
			OUTPUT_QL_FILENAME = OUTPUT_QL_FILENAME + '.jpg'
			IF FIX(CFIG_DATA.(1)[3]) EQ 1 THEN QL_STATUS =  GET_VEGETATION_QUICKLOOK(IFILES[IN_FNAME],OUTPUT_QL_FILENAME,/ROI,/RGB,ICOORDS=ICOORDS,QL_QUALITY=QL_QUALITY,VERBOSE=VERBOSE) $
																		ELSE QL_STATUS =  GET_VEGETATION_QUICKLOOK(IFILES[IN_FNAME],OUTPUT_QL_FILENAME,/ROI,ICOORDS=ICOORDS,QL_QUALITY=QL_QUALITY,VERBOSE=VERBOSE)

			IF KEYWORD_SET(VERBOSE) THEN $
				IF QL_STATUS EQ -1 THEN PRINT, FCT_NAME + ' - QUICKLOOK GENERATION FAILED - ',IFILES[IN_FNAME] $
													 ELSE PRINT, FCT_NAME + ' - QUICKLOOK GENERATION SUCCESS' 
		ENDIF   
	
		;--------------------------------
		; INDEX OF ROW/COLUM IN THE IMAGE 
		s = SIZE(L1B_GEO.LAT)
		NCOL = s(1)
		CS_COL = ROI_INDEX MOD NCOL
		CS_ROW = ROI_INDEX / NCOL

		;------------------------------------------
		; DEFINE ARRAY TO HOLD CS RHO
		ADDBANDS=2   ; LAT + LON INDICES
		
		CS_RHO = MAKE_ARRAY(NB_PIX,NB_BANDS+ADDBANDS,/FLOAT,VALUE=MISSING_VALUE_FLT)

		;------------------------------------------
		; DEFINE ARRAY TO HOLD LAT/LON
		ADDANG=6  ; LAT/LON + 4 ANGLES (SZA, SAA, VZA, VAA)
		NBCOL_CS_LATLON = NB_BANDS + ADDBANDS + ADDANG

		CS_LATLON = FLTARR(NB_PIX,NBCOL_CS_LATLON)

		CS_LATLON[*,0]=L1B_GEO.LAT(ROI_INDEX)
		CS_LATLON[*,1]=L1B_GEO.LON(ROI_INDEX)
 
		;------------------------------------------
		; RETRIEVE VIEWING/ILLUMINATION GEOMETRIES

		IFILE_VIEW[0,IN_FNAME]=MEAN(TEMP_ANGLES.VZA[ROI_INDEX])
		IFILE_VIEW[1,IN_FNAME]=MEAN(TEMP_ANGLES.VAA[ROI_INDEX])
		IFILE_VIEW[2,IN_FNAME]=MEAN(TEMP_ANGLES.SZA[ROI_INDEX])
		IFILE_VIEW[3,IN_FNAME]=MEAN(TEMP_ANGLES.SAA[ROI_INDEX])

		;----------------------------------   

		CS_LATLON[*,2]=TEMP_ANGLES.SZA[ROI_INDEX] ; SZA  
		CS_LATLON[*,3]=TEMP_ANGLES.SAA[ROI_INDEX] ; SAA   
		CS_LATLON[*,4]=TEMP_ANGLES.VZA[ROI_INDEX] ; VZA   
		CS_LATLON[*,5]=TEMP_ANGLES.VAA[ROI_INDEX] ; VAA  

    TEMP=0
    TEMP_ANGLES = 0

    ;---------------------------------------
    ; RETRIEVE THE AUXILIARY INFORMATION

		IFILE_AUX[*,IN_FNAME] = MISSING_VALUE_FLT

		TEMP = GET_VEGETATION_OZONE(IFILES[IN_FNAME],VERBOSE=VERBOSE)
		IFILE_AUX[0,IN_FNAME] = 1000.*MEAN(TEMP(ROI_INDEX))
		IFILE_AUX[1,IN_FNAME] = 1000.*STDEV(TEMP(ROI_INDEX)) 

		TEMP = GET_VEGETATION_WVAP(IFILES[IN_FNAME],VERBOSE=VERBOSE)  
		IFILE_AUX[10,IN_FNAME] = MEAN(TEMP(ROI_INDEX))
		IFILE_AUX[11,IN_FNAME] = STDEV(TEMP(ROI_INDEX))     
      
;------------------------------------------
; EARTH-SUN FIX FOR VITO VGT DATA - ERRONEOUS D2 VALUE SET ALWAYS TO JAN 1ST

;      JD    = 1+JULDAY(1,1,DB_DATA.YEAR[IN_FNAME])-JULDAY(1,1,1950);JULIAN DAY SINCE 1950
;      T     = JD-10000.
;      D     = ((11.786+12.190749*T) MOD 360.)*!DTOR
;      XLP   = ((134.003+0.9856*T) MOD 360.)*!DTOR
;      DUA   = 1. / (1.+(1672.2*COS(XLP)+28.*COS(2.*XLP)-0.35*COS(D))*1.E-5)
;      DVITO = DUA^2
;      DDIMI = (1.0+0.0167*COS(2.0*!DPI*(DB_DATA.DOY[IN_FNAME]-3.0)/365.))^2
;      DNEW  = DVITO*DDIMI
      
      CF = GET_VGT_CORRECTION_FACTOR(DB_DATA.DOY[IN_FNAME])

		;------------------------------------------
		; LOOP OVER EACH BAND

		IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ' - STARTING LOOP OVER EACH BAND'
		FOR IN_BAND=0,NB_BANDS-1 DO BEGIN
      
      TEMP_REF = L1B_REF[*,*,IN_BAND]*CF  ;/DNEW
      VALID = WHERE(TEMP_REF(ROI_INDEX) GT 0.0 AND TEMP_REF(ROI_INDEX) LT 5.0,COUNT)
      
      IF COUNT GT 0 THEN BEGIN
        ROI_AVG_TOA_REF(IN_BAND,IN_FNAME) = MEAN(TEMP_REF(ROI_INDEX[VALID]))
        IF COUNT GE 2 THEN ROI_STD_TOA_REF(IN_BAND,IN_FNAME) = STDDEV(TEMP_REF(ROI_INDEX[VALID]))
        NCDF_OUT.VAR_PIX[IN_BAND,IN_FNAME,0] = COUNT
      ENDIF
      
      CS_RHO[VALID,IN_BAND] = FLOAT(TEMP_REF(ROI_INDEX[VALID]))
      
    	IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - END OF LOOP ON BAND - ',IN_BAND

    ENDFOR; END OF BAND ANALYSIS
 
		;-----------------------------------------
		; STORE DATA IN NETCDF STRUCTURE

		NCDF_OUT.VAR_VZA[0,IN_FNAME]      = IFILE_VIEW[0,IN_FNAME]
		NCDF_OUT.VAR_VAA[0,IN_FNAME]      = IFILE_VIEW[1,IN_FNAME]
		NCDF_OUT.VAR_SZA[0,IN_FNAME]      = IFILE_VIEW[2,IN_FNAME]
		NCDF_OUT.VAR_SAA[0,IN_FNAME]      = IFILE_VIEW[3,IN_FNAME]

		NCDF_OUT.VAR_RHOMU[*,IN_FNAME,0]    = ROI_AVG_TOA_REF(*,IN_FNAME)
		NCDF_OUT.VAR_RHOSD[*,IN_FNAME,0]    = ROI_STD_TOA_REF(*,IN_FNAME)
		NCDF_OUT.VAR_OZONEMU[IN_FNAME]  = IFILE_AUX[0,IN_FNAME]
		NCDF_OUT.VAR_OZONESD[IN_FNAME]  = IFILE_AUX[1,IN_FNAME]
		NCDF_OUT.VAR_PRESSMU[IN_FNAME]  = IFILE_AUX[2,IN_FNAME]
		NCDF_OUT.VAR_PRESSSD[IN_FNAME]  = IFILE_AUX[3,IN_FNAME]
		NCDF_OUT.VAR_RHUMMU[IN_FNAME]   = IFILE_AUX[4,IN_FNAME]
		NCDF_OUT.VAR_RHUMSD[IN_FNAME]   = IFILE_AUX[5,IN_FNAME]
		NCDF_OUT.VAR_ZONALMU[IN_FNAME]  = IFILE_AUX[6,IN_FNAME]
		NCDF_OUT.VAR_ZONALSD[IN_FNAME]  = IFILE_AUX[7,IN_FNAME]
		NCDF_OUT.VAR_MERIDMU[IN_FNAME]  = IFILE_AUX[8,IN_FNAME]
		NCDF_OUT.VAR_MERIDSD[IN_FNAME]  = IFILE_AUX[9,IN_FNAME]
		NCDF_OUT.VAR_WVAPMU[IN_FNAME]   = IFILE_AUX[10,IN_FNAME]
		NCDF_OUT.VAR_WVAPSD[IN_FNAME]   = IFILE_AUX[11,IN_FNAME]

    ; ADD LAT/LON INDICES
		CS_RHO[*,NB_BANDS]    = CS_COL
		CS_RHO[*,NB_BANDS+1]  = CS_ROW

		CS_LATLON[*,6:NBCOL_CS_LATLON-1]=CS_RHO
 
    ;----------------------------------
    ; APPLY ARGANS CLOUD SCREENING
		CS_METHOD_ARG = 'VGT'
		CS_VGT_ARG = DIMITRI_CLOUD_SCREENING(SENSOR, SITE_TYPE, CS_RHO, CS_LATLON[*,0:5], CS_METHOD_ARG, $
																				CS_CLASSIF_MATRIX=CS_CLASSIF_MATRIX_ARG, VERBOSE=VERBOSE)
    ;----------------------------------
    ; APPLY MAGELLIUM CLOUD SCREENING
    IF STRCMP(SITE_TYPE,'DESERT', /FOLD_CASE) THEN BEGIN
      CS_METHOD_MAG = 'VGT_DESERT'
      CS_VGT_MAG = DIMITRI_CLOUD_SCREENING(SENSOR, SITE_TYPE, CS_RHO, CS_LATLON[*,0:5], CS_METHOD_MAG, $
                                          CS_CLASSIF_MATRIX=CS_CLASSIF_MATRIX_MAG, VERBOSE=VERBOSE, $
                                          SITE_NAME=IREGION)
    ENDIF ELSE BEGIN
      CS_METHOD_MAG = 'VGT'
      CS_VGT_MAG = CS_VGT_ARG
      CS_CLASSIF_MATRIX_MAG = CS_CLASSIF_MATRIX_ARG
    ENDELSE            

		; DETERMINATE PIXEL NUMBER DECLARED AS CS_VALID :: 'cloud screening valid indexes'
		INDX_CS_VALID_PIX_ARG = WHERE(CS_CLASSIF_MATRIX_ARG(*,0) NE MISSING_VALUE_LONG, COUNT_CS_VALID_PIX_ARG)
		INDX_CS_VALID_PIX_MAG = WHERE(CS_CLASSIF_MATRIX_MAG(*,0) NE MISSING_VALUE_LONG, COUNT_CS_VALID_PIX_MAG)
		; DETERMINATE PIXEL NUMBER DECLARED AS CS_CLEAR (NO CLOUD)
		; IN CS_TOTAL_PIXEL_CLASSIF : cloud =1 / clear =0 :: 'final cloud screening classification'
		INDX_CS_CLEAR_PIX_ARG = WHERE(CS_CLASSIF_MATRIX_ARG(*,1) EQ 0, COUNT_CS_CLEAR_PIX_ARG)    
		INDX_CS_CLEAR_PIX_MAG = WHERE(CS_CLASSIF_MATRIX_MAG(*,1) EQ 0, COUNT_CS_CLEAR_PIX_MAG)    

		IF KEYWORD_SET(VERBOSE) THEN BEGIN
			PRINT, ' CS ARGANS    - NB CLEAR PIXELS = ' + STRTRIM(STRING(COUNT_CS_CLEAR_PIX_ARG),1) + '/' + STRTRIM(STRING(COUNT_CS_VALID_PIX_ARG),1)
			PRINT, ' CS MAGELLIUM - NB CLEAR PIXELS = ' + STRTRIM(STRING(COUNT_CS_CLEAR_PIX_MAG),1) + '/' + STRTRIM(STRING(COUNT_CS_VALID_PIX_MAG),1)
		ENDIF

    ;----------------------------------
    ; DATABASE STRUCTURE COMPLETION
    
    DB_DATA.AUTO_CS_1_NAME[IN_FNAME] = DB_DATA.AUTO_CS_1_NAME[IN_FNAME] + ' - ' + CS_METHOD_ARG
    DB_DATA.AUTO_CS_2_NAME[IN_FNAME] = DB_DATA.AUTO_CS_2_NAME[IN_FNAME] + ' - ' + CS_METHOD_MAG
    DB_DATA.AUTO_CS_1_MEAN[IN_FNAME] = CS_VGT_ARG
    DB_DATA.AUTO_CS_2_MEAN[IN_FNAME] = CS_VGT_MAG
    DB_DATA.ROI_CS_1_CLEAR_PIX_NUM[IN_FNAME] = COUNT_CS_CLEAR_PIX_ARG
    DB_DATA.ROI_CS_2_CLEAR_PIX_NUM[IN_FNAME] = COUNT_CS_CLEAR_PIX_MAG
    
    ;----------------------------------
    ; NCDF INGESTION OUTPUT STRUCTURE COMPLETION
    
    NCDF_INGEST_STRUCT.GLOBAL_ATT.SITE_COORDINATES = DB_DATA.SITE_COORDINATES[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.ROI_PIX_NUM = NB_PIX
    NCDF_INGEST_STRUCT.GLOBAL_ATT.AUTO_CS_1_NAME = DB_DATA.AUTO_CS_1_NAME[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.AUTO_CS_1_MEAN = DB_DATA.AUTO_CS_1_MEAN[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.ROI_CS_1_CLEAR_PIX_NUM = DB_DATA.ROI_CS_1_CLEAR_PIX_NUM[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.AUTO_CS_2_NAME = DB_DATA.AUTO_CS_2_NAME[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.AUTO_CS_2_MEAN = DB_DATA.AUTO_CS_2_MEAN[IN_FNAME]
    NCDF_INGEST_STRUCT.GLOBAL_ATT.ROI_CS_2_CLEAR_PIX_NUM = DB_DATA.ROI_CS_2_CLEAR_PIX_NUM[IN_FNAME]
    
    NCDF_INGEST_STRUCT.VARIABLES.ROI_STATUS[0] = 1
    NCDF_INGEST_STRUCT.VARIABLES.ROI_PIXEL_NUMBER[0] = NB_PIX
    
    NCDF_INGEST_STRUCT.VARIABLES.LAT(*, 0) = CS_LATLON[*,0]
    NCDF_INGEST_STRUCT.VARIABLES.LON(*, 0) = CS_LATLON[*,1]
    NCDF_INGEST_STRUCT.VARIABLES.SZA(*, 0) = CS_LATLON[*,2]
    NCDF_INGEST_STRUCT.VARIABLES.SAA(*, 0) = CS_LATLON[*,3]
    NCDF_INGEST_STRUCT.VARIABLES.VZA(*, 0) = CS_LATLON[*,4]
    NCDF_INGEST_STRUCT.VARIABLES.VAA(*, 0) = CS_LATLON[*,5]
    FOR BAND=0, NB_BANDS-1 DO BEGIN
      NCDF_INGEST_STRUCT.VARIABLES.REFL_BAND(*, 0, BAND) = CS_LATLON[*,6+BAND]
    ENDFOR
    NCDF_INGEST_STRUCT.VARIABLES.PIXEL_COLUMN_INDICE(*, 0) = CS_LATLON[*,6+NB_BANDS]
    NCDF_INGEST_STRUCT.VARIABLES.PIXEL_ROW_INDICE(*, 0)    = CS_LATLON[*,6+NB_BANDS+1]
    NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_1_VALID_INDEX(*, 0) = CS_CLASSIF_MATRIX_ARG(*,0)
    NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_1_MASK(*, 0)        = CS_CLASSIF_MATRIX_ARG(*,1)
    NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_2_VALID_INDEX(*, 0) = CS_CLASSIF_MATRIX_MAG(*,0)
    NCDF_INGEST_STRUCT.VARIABLES.AUTO_CS_2_MASK(*, 0)        = CS_CLASSIF_MATRIX_MAG(*,1)
    
    NCDF_INGEST_STRUCT.VARIABLES_ATT.THETA_N_MEAN = DB_DATA.THETA_N_MEAN[IN_FNAME]
    NCDF_INGEST_STRUCT.VARIABLES_ATT.THETA_R_MEAN = DB_DATA.THETA_R_MEAN[IN_FNAME]

    NCDF_INGEST_STRUCT.VARIABLES_ATT.ERA_OZONE_MEAN_L1_AUX[0] = NCDF_OUT.VAR_OZONEMU[IN_FNAME]
    NCDF_INGEST_STRUCT.VARIABLES_ATT.ERA_WATERVAPOUR_MEAN_L1_AUX[0] = NCDF_OUT.VAR_WVAPMU[IN_FNAME]

    ;----------------------------------
    ; METEO AUXILIARY DATA RETREIVING
       
    ACQUI_DATE = JULDAY(ACQ_MONTH,ACQ_DAY,ACQ_YEAR,DATE_HR,DATE_MIN,0)
    STATUS = GET_ALL_METEO_AUX_DATA( ACQUI_DATE[0], CS_LATLON[*,0], CS_LATLON[*,1], AUX_DATA_STRUCT=AUX_DATA_STRUCT, VERBOSE=VERBOSE)
    IF STATUS NE STATUS_OK THEN BEGIN
      ; IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - ERROR WHEN RETRIEVING METEO AUX DATA, DIRECTION SKIPPED'
      ; GOTO, NO_ROI
      IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - ERROR WHEN RETRIEVING METEO AUX DATA >> RETURNING'
      RETURN, STATUS_ERROR
    ENDIF    
    WIND_SPEED     = GET_CHANNEL_STRUCT(AUX_DATA_STRUCT,'WIND_SPEED')
 		WIND_DIRECTION = GET_CHANNEL_STRUCT(AUX_DATA_STRUCT,'WIND_DIRECTION')
	  OZONE          = GET_CHANNEL_STRUCT(AUX_DATA_STRUCT,'OZONE')
	  PRESSURE       = GET_CHANNEL_STRUCT(AUX_DATA_STRUCT,'PRESSURE')
	  WATERVAPOUR    = GET_CHANNEL_STRUCT(AUX_DATA_STRUCT,'WATERVAPOUR')
	  CHLOROPHYLL    = GET_CHANNEL_STRUCT(AUX_DATA_STRUCT,'CHLOROPHYLL')
	  
    NCDF_INGEST_STRUCT.VARIABLES.ERA_WIND_SPEED(*, 0) = WIND_SPEED
    NCDF_INGEST_STRUCT.VARIABLES.ERA_WIND_DIR(*, 0) = WIND_DIRECTION
    NCDF_INGEST_STRUCT.VARIABLES.ERA_OZONE(*, 0) = OZONE
    NCDF_INGEST_STRUCT.VARIABLES.ERA_PRESSURE(*, 0) = PRESSURE
    NCDF_INGEST_STRUCT.VARIABLES.ERA_WATERVAPOUR(*, 0) = WATERVAPOUR
    NCDF_INGEST_STRUCT.VARIABLES.ESA_CHLOROPHYLL(*, 0) = CHLOROPHYLL
    
		DB_DATA.ERA_WIND_SPEED_MEAN[IN_FNAME]  = MEAN(WIND_SPEED)
		DB_DATA.ERA_WIND_DIR_MEAN[IN_FNAME]    = MEAN(WIND_DIRECTION)
		DB_DATA.ERA_OZONE_MEAN[IN_FNAME]       = MEAN(OZONE)
		DB_DATA.ERA_PRESSURE_MEAN[IN_FNAME]    = MEAN(PRESSURE)
		DB_DATA.ERA_WATERVAPOUR_MEAN[IN_FNAME] = MEAN(WATERVAPOUR)
		DB_DATA.ESA_CHLOROPHYLL_MEAN[IN_FNAME] = MEAN(CHLOROPHYLL)

    ;----------------------------------
    ; NCDF INGESTION OUTPUT FILE WRITING

		STATUS = NETCDFWRITE_INGEST_OUTPUT(NCDF_INGEST_STRUCT, NCDF_FILENAME=NCDF_FILENAME, VERBOSE=VERBOSE)
		IF STATUS NE STATUS_OK THEN BEGIN
			IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - ISSUE DURING NCDF INGESTION OUTPUT WRITING'
			RETURN, STATUS_ERROR
		ENDIF     

		DB_DATA.L1_INGESTED_FILENAME[IN_FNAME] = NCDF_FILENAME

		NCDF_OUT.VAR_CLOUD_AUT_1[IN_FNAME] = DB_DATA.AUTO_CS_1_MEAN[IN_FNAME]
		NCDF_OUT.VAR_CLOUD_AUT_2[IN_FNAME] = DB_DATA.AUTO_CS_2_MEAN[IN_FNAME]
		NCDF_OUT.VAR_CLOUD_MAN[IN_FNAME] = -1
		NCDF_OUT.VAR_ROI[IN_FNAME] = DB_DATA.ROI_STATUS[IN_FNAME]

		NO_ROI:; IF ROI IS NOT WITHIN THE PRODUCT OR THERE ARE TOO FEW PIXELS
		
		IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - END OF LOOP ON PRODUCT'
		
	ENDFOR; END OF FILE ANALYSIS

	;------------------------
	; DEFINE REPORT OUTPUT FOLDER

  OUTPUT_DIR_REPORT = STRING(OUTPUT_FOLDER+'Site_'+IREGION+DL+SENSOR+DL+'Proc_'+IPROC+DL+'REPORT'+DL)
  OUT_FOLDER_INFO = FILE_INFO(OUTPUT_DIR_REPORT)
  IF OUT_FOLDER_INFO.DIRECTORY EQ 0 THEN BEGIN
    FILE_MKDIR, OUTPUT_DIR_REPORT
    IF KEYWORD_SET(VERBOSE) THEN BEGIN      
      PRINT, FCT_NAME + ' - WARNING, OUTPUT REPORT FOLDER ''' + OUTPUT_DIR_REPORT + ''' NOT FOUND >> CREATED'
    ENDIF
  ENDIF

	;------------------------------------
	; SAVE DATA TO NETCDF REPORT FILE

  NCDF_MULTIFILE_FILENAME = OUTPUT_DIR_REPORT + IREGION + '_' + SENSOR + '_Proc_' + IPROC + '.nc'
  RES = DIMITRI_INTERFACE_EXTRACT_TOA_NCDF(NCDF_OUT,NCDF_MULTIFILE_FILENAME)  

	;------------------------------------
	; GENERATE PLOTS WITH NEW TIME SERIES DATA

  RES = GET_INGESTION_TIMESERIES_PLOTS(NCDF_MULTIFILE_FILENAME,SENSOR,COLOUR_TABLE=COLOUR_TABLE,PLOT_XSIZE=PLOT_XSIZE,PLOT_YSIZE=PLOT_YSIZE,VERBOSE=VERBOSE)

	;------------------------------------
	; AMEND DATA TO DATABASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ' - SENDING DATA TO UPDATE DATABASE'
  RES = UPDATE_DIMITRI_DATABASE(DB_DATA,/SORT_DB,VERBOSE=VERBOSE)
 
	RETURN, STATUS_OK
END
