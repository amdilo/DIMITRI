;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      NETCDFWRITE_INGEST_OUTPUT       
;* 
;* PURPOSE:
;*      WRITE THE INGESTION OUTPUT NCDF FILE 
;* 
;* CALLING SEQUENCE:
;*      RES = NETCDFWRITE_INGEST_OUTPUT(NCDF_INGEST_STRUCT, /VERBOSE)      
;* 
;* INPUTS:
;*      NCDF_INGEST_STRUCT  = STRUCTURE ASSOCIATED TO THE NCDF INGESTION OUTPUT FILE
;*
;* KEYWORDS:
;*      NCDF_FILENAME  - OUTPUT NCDF FILENAME
;*      VERBOSE        - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS  - CREATION AND WRITING STATUS (0:OK, 1:ERROR)
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      29 JAN 2015 - NCG / MAGELLIUM - CREATION (DIMITRI V4.0)
;*
;* VALIDATION HISTORY:
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION NETCDFWRITE_INGEST_OUTPUT, NCDF_INGEST_STRUCT, NCDF_FILENAME=NCDF_FILENAME, VERBOSE=VERBOSE

  DEBUG_MODE = 0      ; SET TO 1 IF WANT TO DEBUG THIS PROCEDURE
  
  FCT_NAME = 'NETCDFWRITE_INGEST_OUTPUT'
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': START'
  
  STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
  STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

  GLOBAL_ATT     = NCDF_INGEST_STRUCT.GLOBAL_ATT
  DIMENSIONS     = NCDF_INGEST_STRUCT.DIMENSIONS
  VARIABLES      = NCDF_INGEST_STRUCT.VARIABLES
  VARIABLES_ATT  = NCDF_INGEST_STRUCT.VARIABLES_ATT
  
  DL = GET_DIMITRI_LOCATION('DL')
  MISSING_VALUE = GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE')  
  INGESTION_OUTPUT_FOLDER = GET_DIMITRI_LOCATION('INGESTION_OUTPUT')
  
  DATE = STRSPLIT(GLOBAL_ATT.ACQUISITION_DATE,'- :',/EXTRACT)
  ACQ_YEAR   = DATE[0]
  ACQ_MONTH  = DATE[1]
  ACQ_DAY    = DATE[2]
  ACQ_HOUR   = DATE[3]
  ACQ_MINUTE = DATE[4]
  
  ; The folder of the output file observes the following rules:
  ;     Output/INGESTION/[SITE]/[SENSOR]/[COLLECTION]/[ACQ_YEAR]
  ; The name of the NetCDF file observes the following rules:
  ;     [SITE]_[SENSOR]_[COLLECTION]_[ACQ_YEAR][ACQ_MONTH][ACQ_DAY]_[ACQ_HOUR][ACQ_MINUTE].nc
  ; With  [SITE]: Site name
  ;   [SENSOR]: Sensor name
  ;   [COLLECTION]: Collection or processing version of the L1 product
  ;   [ACQ_YEAR][ACQ_MONTH][ACQ_DAY]: acquisition date (YYYYMMDD format)
  ;   [ACQ_HOUR][ACQ_MINUTE]: Acquisition time (HHmm format)
  
  INGESTION_OUTPUT_FOLDER = INGESTION_OUTPUT_FOLDER + DL + 'Site_' + GLOBAL_ATT.SITE_NAME $
                              + DL + GLOBAL_ATT.SENSOR + DL + 'Proc_' + GLOBAL_ATT.PROCESSING_VERSION $
                              + DL + ACQ_YEAR + DL

  OUT_FOLDER_INFO = FILE_INFO(INGESTION_OUTPUT_FOLDER)
  IF OUT_FOLDER_INFO.DIRECTORY EQ 0 THEN BEGIN
      FILE_MKDIR, INGESTION_OUTPUT_FOLDER
      IF KEYWORD_SET(VERBOSE) THEN BEGIN      
        PRINT, FCT_NAME + ': WARNING, OUTPUT YEAR FOLDER ''' + INGESTION_OUTPUT_FOLDER + ''' NOT FOUND'
        PRINT, FCT_NAME + ': OUTPUT YEAR FOLDER ''' + INGESTION_OUTPUT_FOLDER + ''' CREATED'
      ENDIF
  ENDIF
  
  NCDF_FILENAME = GLOBAL_ATT.SITE_NAME + '_' $
                    + GLOBAL_ATT.SENSOR + '_' $
                    + GLOBAL_ATT.PROCESSING_VERSION +  '_' $
                    + ACQ_YEAR + ACQ_MONTH + ACQ_DAY + '_' + ACQ_HOUR + ACQ_MINUTE + '.nc'
                              
  INGESTION_OUTPUT_FILENAME = INGESTION_OUTPUT_FOLDER + NCDF_FILENAME
  
  ; GET THE SENSOR BAND INFORMATION
  BAND_INFO = GET_SENSOR_BAND_INFO(GLOBAL_ATT.SENSOR, VERBOSE=VERBOSE)
  BAND_NUMBER = BAND_INFO.NB_BAND
  BAND_WAVELENGTH = BAND_INFO.BAND_WAVELENGTH
  BAND_REF_LABEL = BAND_INFO.BAND_REF_LABEL
  
  ;--------------------------
  ; CREATE THE NEW NETCDF FILE
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': CREATING NEW NCDF FILE'
  
  ; TEST IF FILE ALREADY EXIST > OVERWRITE
  INGESTION_OUTPUT_FILENAME_INFO = FILE_INFO(INGESTION_OUTPUT_FILENAME)
  IF INGESTION_OUTPUT_FILENAME_INFO.EXISTS EQ 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': NCDF FILE ' + INGESTION_OUTPUT_FILENAME + ' EXIST > OVERWRITE'
  ENDIF
  NCID = NCDF_CREATE(INGESTION_OUTPUT_FILENAME, /CLOBBER)

  ; CREATE GLOBAL ATTIBUTES
  ;----------------------------
  NB_TAGS = N_TAGS(GLOBAL_ATT)
  TAGS_NAME = TAG_NAMES(GLOBAL_ATT)
  FOR NUM=0, NB_TAGS-1 DO BEGIN
    IF DEBUG_MODE EQ 1 THEN PRINT, 'NETCDFWRITE_INGEST_OUTPUT - DEBUG_MODE - TAGS_NAME = ', TAGS_NAME[NUM], ' / VALUE = ', GLOBAL_ATT.(NUM)
    NCDF_ATTPUT, ncid , TAGS_NAME[NUM] , GLOBAL_ATT.(NUM) , /GLOBAL
  ENDFOR

  ; CREATE DIMENSIONS
  ;----------------------------
  DIM_ROI     = NCDF_DIMDEF( ncid, 'ROI_PIXEL_NUMBER', DIMENSIONS.ROI_PIXEL_NUMBER )
  DIM_VIEWDIR = NCDF_DIMDEF( ncid, 'VIEWDIR_NUMBER', DIMENSIONS.VIEWDIR_NUMBER )

  ; CREATE VARIABLES
  ;----------------------------
  varId = NCDF_VARDEF( ncid, 'ROI_STATUS' , [DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ROI coverage status' 
  IF VARIABLES_ATT.THETA_R_MEAN NE -1 THEN NCDF_ATTPUT, ncid , varid , 'theta_R_mean' , VARIABLES_ATT.THETA_R_MEAN, /FLOAT
  IF VARIABLES_ATT.THETA_N_MEAN NE -1 THEN NCDF_ATTPUT, ncid , varid , 'theta_N_mean' , VARIABLES_ATT.THETA_N_MEAN, /FLOAT
  
  varId = NCDF_VARDEF( ncid, 'ROI_PIXEL_NUMBER' , [DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ROI pixel number' 
  
  varId = NCDF_VARDEF( ncid, 'LAT' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Latitude of each pixel of the ROI for each viewing direction' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'degree' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE
  varId = NCDF_VARDEF( ncid, 'LON' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Longitude of each pixel of the ROI for each viewing direction' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'degree' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE
  
  varId = NCDF_VARDEF( ncid, 'SZA' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Sun zenith angle' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'degree' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE
  varId = NCDF_VARDEF( ncid, 'SAA' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Sun azimuth angle' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'degree' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE
  varId = NCDF_VARDEF( ncid, 'VZA' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Viewing zenith angle' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'degree' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE
  varId = NCDF_VARDEF( ncid, 'VAA' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Viewing zenith angle' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'degree' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE
  
  FOR DIR=0, DIMENSIONS.VIEWDIR_NUMBER-1 DO BEGIN
    IF DIR+1 LT 10 THEN DIR_ID = '0' + STRTRIM(STRING(DIR+1),2) $
                   ELSE DIR_ID = STRTRIM(STRING(DIR+1),2)
    NCDF_TAG_NAME = 'viewDir' + DIR_ID + '_mean'
    IF VARIABLES.ROI_PIXEL_NUMBER[DIR] GT 0 THEN BEGIN
      NCDF_ATTPUT, ncid , 'SZA' , NCDF_TAG_NAME , MEAN(VARIABLES.SZA(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR))
      NCDF_ATTPUT, ncid , 'SAA' , NCDF_TAG_NAME , MEAN(VARIABLES.SAA(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR))
      NCDF_ATTPUT, ncid , 'VZA' , NCDF_TAG_NAME , MEAN(VARIABLES.VZA(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR))
      NCDF_ATTPUT, ncid , 'VAA' , NCDF_TAG_NAME , MEAN(VARIABLES.VAA(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR))
    ENDIF ELSE BEGIN
      NCDF_ATTPUT, ncid , 'SZA' , NCDF_TAG_NAME , MISSING_VALUE
      NCDF_ATTPUT, ncid , 'SAA' , NCDF_TAG_NAME , MISSING_VALUE
      NCDF_ATTPUT, ncid , 'VZA' , NCDF_TAG_NAME , MISSING_VALUE
      NCDF_ATTPUT, ncid , 'VAA' , NCDF_TAG_NAME , MISSING_VALUE
    ENDELSE
  ENDFOR

  ; CREATE REFLECTANCE BAND VARIABLES WITH ATTRIBUTES
  FOR BAND=0, BAND_NUMBER-1 DO BEGIN
    
    NCDF_BAND_TAG = 'REFL_' + BAND_REF_LABEL[BAND]
    varId = NCDF_VARDEF( ncid, NCDF_BAND_TAG , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
    NCDF_ATTPUT, ncid , varid , 'long_name' , 'Reflectance values of '+ BAND_REF_LABEL[BAND] + ' on the ROI' 
    NCDF_ATTPUT, ncid , varid , 'wavelength_mean' , BAND_WAVELENGTH[BAND]
    NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE    
        
    FOR DIR=0, DIMENSIONS.VIEWDIR_NUMBER-1 DO BEGIN
      IF DIR+1 LT 10 THEN DIR_ID = '0' + STRTRIM(STRING(DIR+1),2) $
                     ELSE DIR_ID = STRTRIM(STRING(DIR+1),2)
      IF VARIABLES.ROI_PIXEL_NUMBER[DIR] GT 0 THEN BEGIN
        NCDF_ATTPUT, ncid , varid , 'viewDir' + DIR_ID + '_mean'  , MEAN(VARIABLES.REFL_BAND(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR,BAND))
        NCDF_ATTPUT, ncid , varid , 'viewDir' + DIR_ID + '_stdev' , STDDEV(VARIABLES.REFL_BAND(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR,BAND))
      ENDIF ELSE BEGIN
        NCDF_ATTPUT, ncid , varid , 'viewDir' + DIR_ID + '_mean'  , MISSING_VALUE
        NCDF_ATTPUT, ncid , varid , 'viewDir' + DIR_ID + '_stdev' , MISSING_VALUE
      ENDELSE
    ENDFOR

  ENDFOR  

  ; CREATE CLOUD SCREENING VARIABLES WITH ATTRIBUTES
  varId = NCDF_VARDEF( ncid, 'PIXEL_COLUMN_INDICE' , [DIM_ROI, DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Pixel colum indice in the input image' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE, /LONG
  varId = NCDF_VARDEF( ncid, 'PIXEL_ROW_INDICE' , [DIM_ROI, DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Pixel row indice in the input image' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE, /LONG
  varId = NCDF_VARDEF( ncid, 'AUTO_CS_1_VALID_INDEX' , [DIM_ROI, DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Auto cloud screening method 1 valid indexes' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE, /LONG
  varId = NCDF_VARDEF( ncid, 'AUTO_CS_2_VALID_INDEX' , [DIM_ROI, DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Auto cloud screening method 2 valid indexes' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE, /LONG
  varId = NCDF_VARDEF( ncid, 'AUTO_CS_1_MASK' , [DIM_ROI, DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Auto cloud screening method 1 mask' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE, /LONG
  varId = NCDF_VARDEF( ncid, 'AUTO_CS_2_MASK' , [DIM_ROI, DIM_VIEWDIR] , /LONG )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'Auto cloud screening method 2 mask' 
  NCDF_ATTPUT, NCID , varid , 'missing_value', MISSING_VALUE, /LONG
  
  
  ; CREATE METEO AUX DATA VARIABLES WITH ATTRIBUTES
  varId = NCDF_VARDEF( ncid, 'ERA_WIND_SPEED' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ERA wind speed meteo auxiliary data' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'm/s' 
  NCDF_ATTPUT, ncid , varid , 'missing_value', MISSING_VALUE, /FLOAT
  varId = NCDF_VARDEF( ncid, 'ERA_WIND_DIR' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ERA wind direction meteo auxiliary data' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'TBD' 
  NCDF_ATTPUT, ncid , varid , 'missing_value', MISSING_VALUE, /FLOAT
  varId = NCDF_VARDEF( ncid, 'ERA_OZONE' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ERA ozone meteo auxiliary data' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'TBD' 
  NCDF_ATTPUT, ncid , varid , 'missing_value', MISSING_VALUE, /FLOAT
  varId = NCDF_VARDEF( ncid, 'ERA_PRESSURE' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ERA pressure meteo auxiliary data' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'TBD' 
  NCDF_ATTPUT, ncid , varid , 'missing_value', MISSING_VALUE, /FLOAT
  varId = NCDF_VARDEF( ncid, 'ERA_WATERVAPOUR' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ERA watervapour meteo auxiliary data' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'TBD' 
  varId = NCDF_VARDEF( ncid, 'ESA_CHLOROPHYLL' , [DIM_ROI, DIM_VIEWDIR] , /FLOAT )
  NCDF_ATTPUT, ncid , varid , 'long_name' , 'ESA chlorophyll meteo auxiliary data' 
  NCDF_ATTPUT, ncid , varid , 'units' , 'TBD' 
  NCDF_ATTPUT, ncid , varid , 'missing_value', MISSING_VALUE, /FLOAT
  
  FOR DIR=0, DIMENSIONS.VIEWDIR_NUMBER-1 DO BEGIN
    IF DIR+1 LT 10 THEN DIR_ID = '0' + STRTRIM(STRING(DIR+1),2) $
                   ELSE DIR_ID = STRTRIM(STRING(DIR+1),2)
    NCDF_TAG_NAME = 'viewDir' + DIR_ID + '_mean'
    IF VARIABLES.ROI_PIXEL_NUMBER[DIR] GT 0 THEN BEGIN
      NCDF_ATTPUT, ncid , 'ERA_WIND_SPEED' , NCDF_TAG_NAME , MEAN(VARIABLES.ERA_WIND_SPEED(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR)), /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_WIND_DIR' , NCDF_TAG_NAME , MEAN(VARIABLES.ERA_WIND_DIR(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR)), /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_OZONE' , NCDF_TAG_NAME , MEAN(VARIABLES.ERA_OZONE(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR)), /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_PRESSURE' , NCDF_TAG_NAME , MEAN(VARIABLES.ERA_PRESSURE(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR)), /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_WATERVAPOUR' , NCDF_TAG_NAME , MEAN(VARIABLES.ERA_WATERVAPOUR(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR)), /FLOAT
      NCDF_ATTPUT, ncid , 'ESA_CHLOROPHYLL' , NCDF_TAG_NAME , MEAN(VARIABLES.ESA_CHLOROPHYLL(0:VARIABLES.ROI_PIXEL_NUMBER[DIR]-1, DIR)), /FLOAT    
    ENDIF ELSE BEGIN
      NCDF_ATTPUT, ncid , 'ERA_WIND_SPEED' , NCDF_TAG_NAME , MISSING_VALUE, /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_WIND_DIR' , NCDF_TAG_NAME , MISSING_VALUE, /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_OZONE' , NCDF_TAG_NAME , MISSING_VALUE, /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_PRESSURE' , NCDF_TAG_NAME , MISSING_VALUE, /FLOAT
      NCDF_ATTPUT, ncid , 'ERA_WATERVAPOUR' , NCDF_TAG_NAME , MISSING_VALUE, /FLOAT
      NCDF_ATTPUT, ncid , 'ESA_CHLOROPHYLL' , NCDF_TAG_NAME , MISSING_VALUE, /FLOAT
    ENDELSE
    NCDF_ATTPUT, ncid , 'ERA_WIND_SPEED' , NCDF_TAG_NAME+'_L1_aux_data' , VARIABLES_ATT.ERA_WIND_SPEED_MEAN_L1_AUX(DIR), /FLOAT
    NCDF_ATTPUT, ncid , 'ERA_WIND_DIR' , NCDF_TAG_NAME+'_L1_aux_data' , VARIABLES_ATT.ERA_WIND_DIR_MEAN_L1_AUX(DIR), /FLOAT
    NCDF_ATTPUT, ncid , 'ERA_OZONE' , NCDF_TAG_NAME+'_L1_aux_data' , VARIABLES_ATT.ERA_OZONE_MEAN_L1_AUX(DIR), /FLOAT
    NCDF_ATTPUT, ncid , 'ERA_PRESSURE' , NCDF_TAG_NAME+'_L1_aux_data' , VARIABLES_ATT.ERA_PRESSURE_MEAN_L1_AUX(DIR), /FLOAT
    NCDF_ATTPUT, ncid , 'ERA_WATERVAPOUR' , NCDF_TAG_NAME+'_L1_aux_data' , VARIABLES_ATT.ERA_WATERVAPOUR_MEAN_L1_AUX(DIR), /FLOAT
    NCDF_ATTPUT, ncid , 'ESA_CHLOROPHYLL' , NCDF_TAG_NAME+'_L1_aux_data' , VARIABLES_ATT.ESA_CHLOROPHYLL_MEAN_L1_AUX(DIR), /FLOAT
  ENDFOR
  
  
  ; FILLING VARIABLES WITH VALUES
  ;----------------------------
  NCDF_CONTROL, ncid, /ENDEF 
   
  NCDF_VARPUT, ncid, 'ROI_STATUS' , VARIABLES.ROI_STATUS
  NCDF_VARPUT, ncid, 'ROI_PIXEL_NUMBER' , VARIABLES.ROI_PIXEL_NUMBER
  NCDF_VARPUT, ncid, 'LAT' , VARIABLES.LAT
  NCDF_VARPUT, ncid, 'LON' , VARIABLES.LON
  NCDF_VARPUT, ncid, 'SZA' , VARIABLES.SZA
  NCDF_VARPUT, ncid, 'SAA' , VARIABLES.SAA
  NCDF_VARPUT, ncid, 'VZA' , VARIABLES.VZA
  NCDF_VARPUT, ncid, 'VAA' , VARIABLES.VAA
 
  FOR BAND=0, BAND_NUMBER-1 DO BEGIN    
    NCDF_BAND_TAG = 'REFL_' + BAND_REF_LABEL[BAND]
    NCDF_VARPUT, ncid, NCDF_BAND_TAG , VARIABLES.REFL_BAND(*,*,BAND)
  ENDFOR  

  NCDF_VARPUT, ncid, 'PIXEL_COLUMN_INDICE' , VARIABLES.PIXEL_COLUMN_INDICE
  NCDF_VARPUT, ncid, 'PIXEL_ROW_INDICE' , VARIABLES.PIXEL_ROW_INDICE
  NCDF_VARPUT, ncid, 'AUTO_CS_1_VALID_INDEX' , VARIABLES.AUTO_CS_1_VALID_INDEX
  NCDF_VARPUT, ncid, 'AUTO_CS_2_VALID_INDEX' , VARIABLES.AUTO_CS_2_VALID_INDEX
  NCDF_VARPUT, ncid, 'AUTO_CS_1_MASK' , VARIABLES.AUTO_CS_1_MASK
  NCDF_VARPUT, ncid, 'AUTO_CS_2_MASK' , VARIABLES.AUTO_CS_2_MASK
  NCDF_VARPUT, ncid, 'ERA_WIND_SPEED' , VARIABLES.ERA_WIND_SPEED
  NCDF_VARPUT, ncid, 'ERA_WIND_DIR' , VARIABLES.ERA_WIND_DIR
  NCDF_VARPUT, ncid, 'ERA_OZONE' , VARIABLES.ERA_OZONE
  NCDF_VARPUT, ncid, 'ERA_PRESSURE' , VARIABLES.ERA_PRESSURE
  NCDF_VARPUT, ncid, 'ERA_WATERVAPOUR' , VARIABLES.ERA_WATERVAPOUR
  NCDF_VARPUT, ncid, 'ESA_CHLOROPHYLL' , VARIABLES.ESA_CHLOROPHYLL

  NCDF_CLOSE, ncid

  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': END'
  
  RETURN, STATUS_OK
  
END
