;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_CSV_CALIB_REPORT_STRUCT       
;* 
;* PURPOSE:
;*      GET THE STRUCTURE WHICH CORRESPONDS TO THE OUTPUT CSV REPORT FILE OF THE SUNGLINT, 
;*      RAYLEIGH OR DESERT SENSOR TO SIMULATION COMPARISON PROCESSES 
;* 
;* CALLING SEQUENCE:
;*      RES = GET_CSV_CALIB_REPORT_STRUCT(VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, VERBOSE=VERBOSE)      
;* 
;* INPUTS:
;*      VIEWDIR_NUMBER    = VIEWING DIRECTION NUMBER OF THE SENSOR
;*      BAND_NUMBER       = BAND NUMBER OF THE SENSOR
;*      NB_FILES          = NUMBER OF FILES
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STRUCTURE ASSOCIATED TO THE CSV CALIBRATION REPORT OUTPUT FILE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      02 MAR 2015 - NCG / MAGELLIUM - CREATION (DIMITRI V4.0)
;*
;* VALIDATION HISTORY:
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_CSV_CALIB_REPORT_FORMAT, BAND_NUMBER

   CSV_FORMAT = '3(A,1H;),'+ $           ; NCDF_FILENAME / L1_FILENAME / VIEWING_DIRECTION
                '5(I4,1H;),'+ $           ; YEAR / MONTH / DAY / HOUR / MINUTES
                '1(D20.12,1H;),'+ $       ; DECIMAL_YEAR
                '8(D12.6,1H;),'+ $         ; 8 ANGLES (SZA,SAA,VZA,VAA)x2
                '12(D12.6,1H;)'           ; 12 METEO DATA MEAN/STD
   
   CSV_BAND_FORMAT = '1(I10,1H;),4(D12.6,1H;)'   ; 5 BAND INFOS        
   FOR NUM_BAND=0, BAND_NUMBER-1 DO BEGIN
     CSV_FORMAT = CSV_FORMAT + ',' + CSV_BAND_FORMAT
   ENDFOR        
   
   CSV_FORMAT = '('+CSV_FORMAT+')'     
   
   RETURN, CSV_FORMAT

END


FUNCTION GET_CSV_CALIB_REPORT_STRUCT, VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, VERBOSE=VERBOSE

  FCT_NAME = 'GET_CSV_CALIB_REPORT_STRUCT'
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': START'
  
  MISSING_VALUE = FLOAT(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  
  FIELDS = { $
                  NCDF_FILENAME           : MAKE_ARRAY(NB_FILES, /STRING, VALUE='-1'), $
                  L1_FILENAME             : MAKE_ARRAY(NB_FILES, /STRING, VALUE='-1'), $
                  VIEWING_DIRECTION       : MAKE_ARRAY(VIEWDIR_NUMBER, /LONG, VALUE=MISSING_VALUE), $
                  YEAR                    : MAKE_ARRAY(NB_FILES, /LONG, VALUE=MISSING_VALUE), $
                  MONTH                   : MAKE_ARRAY(NB_FILES, /LONG, VALUE=MISSING_VALUE), $
                  DAY                     : MAKE_ARRAY(NB_FILES, /LONG, VALUE=MISSING_VALUE), $
                  HOUR                    : MAKE_ARRAY(NB_FILES, /LONG, VALUE=MISSING_VALUE), $
                  MINUTES                 : MAKE_ARRAY(NB_FILES, /LONG, VALUE=MISSING_VALUE), $
                  DECIMAL_YEAR            : MAKE_ARRAY(NB_FILES, /FLOAT, VALUE=MISSING_VALUE), $

                  SZA_MEAN                : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  SZA_STD                 : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  SAA_MEAN                : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  SAA_STD                 : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  VZA_MEAN                : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  VZA_STD                 : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  VAA_MEAN                : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  VAA_STD                 : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $

                  ERA_WIND_SPEED_MEAN           : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_WIND_SPEED_STD            : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_WIND_DIR_MEAN             : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_WIND_DIR_STD              : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_OZONE_MEAN                : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_OZONE_STD                 : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_PRESSURE_MEAN             : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_PRESSURE_STD              : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_WATERVAPOUR_MEAN          : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ERA_WATERVAPOUR_STD           : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ESA_CHLOROPHYLL_MEAN          : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $
                  ESA_CHLOROPHYLL_STD           : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, NB_FILES), $

                  BAND_REF_TO_SIM_RATIO_PIX_NUM : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, /LONG, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES), $
                  BAND_REF_TO_SIM_RATIO_MEAN    : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES), $
                  BAND_REF_TO_SIM_RATIO_STD     : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES), $
                  BAND_RHO_SIM_UNCERT_MEAN      : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES), $
                  BAND_RHO_SIM_UNCERT_STD       : REFORM(MAKE_ARRAY(VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES, /FLOAT, VALUE=MISSING_VALUE),VIEWDIR_NUMBER, BAND_NUMBER, NB_FILES) }
                  
  COMPLEMENT = { $
                  REFL_BAND_IDS                 : MAKE_ARRAY(BAND_NUMBER, /STRING, VALUE='-1') } 
                  
  CSV_REPORT_STRUCT = { FIELDS : FIELDS , COMPLEMENT : COMPLEMENT }
    
  IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': END'
  
  RETURN, CSV_REPORT_STRUCT
  
END

