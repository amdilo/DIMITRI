;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_DIMITRI_LOCATION 
;* 
;* PURPOSE:
;*      PROVIDES THE HARD CODED LOCATION OF DIMITRI FOLDERS AND FILES RELATIVE TO 
;*      THE MAIN DIMITRI FOLDER.
;* 
;* CALLING SEQUENCE:
;*      RES = GET_DIMITRI_LOCATION(LOCATION)      
;* 
;* INPUTS:
;*      LOCATION - A STRING OF THE LOCATION CASE REQUIRED (E.G. 'INPUT' FOR THE INPUT FOLDER)     
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      RESULT   - THE FULL PATH OF THE LOCATIONS PATH, OR IF NOT FOUND THEN 'ERROR' 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        21 MAR 2011 - C KENT    - DIMITRI-2 V1.0
;*        23 AUG 2011 - C KENT    - ADDED TOOL NAME VARIABLE
;*        01 NOV 2013 - C MAZERAN - ADDED MARINE FILES AND RTM FOLDER
;*        20 JAN 2014 - C MAZERAN - ADDED WATER REFRACTIVE INDEX FILE
;*        17 FEB 2014 - C MAZERAN - ADDED CLOUD PNG
;*        15 JAN 2015 - B ALHAMMOUD - ADDED "ECMWF_ERA" FOLDER
;*        21 JAN 2015 - B ALHAMMOUD - CHANGED DIMITRI V3.1 TO DIMITRI V3.1.1 PREVIOUSLY CALLED V3.1a
;*        26 JAN 2015 - B ALHAMMOUD - ADDED POS1 POS2 
;*        09 FEB 2015 - B ALHAMMOUD - ADDED P2MP1 
;*        13 FEB 2015 - B ALHAMMOUD - ADDED DIMITRI_VERSION AS VARIABLE 
;*
;* VALIDATION HISTORY:
;*        14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                  COMPILATION AND OPERATION       
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_DIMITRI_LOCATION,LOCATION,VERBOSE=VERBOSE

;----------------------
; IDENTIFIY CURRENT DIRECTORY AND INPUT FOLDER
  DIMITRI_VERSION='3.1.1'  ;BAH SET DIMITRI VERSION, STILL HARD-CODED
  IF KEYWORD_SET(VERBOSE) THEN PRINT, ' DIMITRI VERSION IS: ',DIMITRI_VERSION


  CD, CURRENT=CURRENT_DIR
  DL = PATH_SEP();STRMID(CURRENT_DIR,POS-1,1)
  POS1 = STRPOS(CURRENT_DIR,'DIMITRI_',/REVERSE_SEARCH)

  CURRENT_DIR=STRING(STRMID(CURRENT_DIR,0,POS1+17)) ; BAH: SUPOSE THAT DIMITRI FOLDER NAME DOES NOT EXEED 17 CHARACTERS
  POS2 = STRPOS(CURRENT_DIR,DL,/REVERSE_SEARCH)
  PATH_LEN=STRLEN(CURRENT_DIR)
  IF POS1 EQ -1 THEN BEGIN
    PRINT, 'ERROR, DIMITRI FOLDER NOT FOUND'
    RETURN,'ERROR'
  ENDIF

  IF (POS1 GT POS2) THEN BEGIN
     P2MP1=PATH_LEN-POS1
  ENDIF ELSE BEGIN  
     P2MP1=POS2-POS1 
  ENDELSE
  CENTRAL_FOLDER = STRING(STRMID(CURRENT_DIR,0,POS1+P2MP1)+DL)
 ; PRINT, 'CENTRAL_FOLDER = ',CENTRAL_FOLDER

  CASE LOCATION OF
  
;----------------------
; FOLDERS
  
  'DL'            : RESULT = DL 
  'DIMITRI'       : RESULT = CENTRAL_FOLDER
  'INPUT'         : RESULT = CENTRAL_FOLDER+'Input'+DL
  'OUTPUT'        : RESULT = CENTRAL_FOLDER+'Output'+DL
  'AUX'           : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL
  'RSR'           : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'spectral_response'+DL
  'RSR_DIM'       : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'spectral_response'+DL+'DIMITRI_Sites'+DL  
  'RSR_USR'       : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'spectral_response'+DL+'USER_Sites'+DL
  'MARINE'        : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'marine'+DL
  'RTM'           : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'RTM'+DL
  'BIN'           : RESULT = CENTRAL_FOLDER+'Bin'+DL
  'DB_BACKUP'     : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DB_backup'+DL
  'SOURCE'        : RESULT = CENTRAL_FOLDER+'Source'+DL
  'BITMAPS'       : RESULT = CENTRAL_FOLDER+'Source'+DL+'bitmaps'+DL
  'PNG_IMAGES'    : RESULT = CENTRAL_FOLDER+'Source'+DL+'png'+DL
  'ECMWF_ERA'     : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'ECMWF_ERA_Interim'+DL
  'libRad'        : RESULT = CENTRAL_FOLDER+'libRadtran-1.7'+DL
  'libRad_data'   : RESULT = CENTRAL_FOLDER+'libRadtran-1.7'+DL+'data'+DL

;----------------------
; FILES
  
  'AATSR_DRIFT'   : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'AATSR_VIS_DRIFT_V02-01.DAT'
  'MERIS_IM2004'  : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'MERIS_Irradiances_Model2004.txt'
  'CONFIG'        : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_CONFIGURATION.txt'
  'BAND_INDEX'    : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_Band_Centre_Index.txt'
  'BAND_NAME'     : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_Band_Names.txt'
  'DATABASE'      : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_DATABASE.CSV'
  'SENSOR_DATA'   : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_SENSOR_DATA.txt'
  'SITE_DATA'     : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_SITE_DATA.txt'
  'SITE_TYPES'    : RESULT = CENTRAL_FOLDER+'Bin'+DL+'DIMITRI_SITE_TYPES.txt'
  'TITLE_PNG'     : RESULT = CENTRAL_FOLDER+'Source'+DL+'png'+DL+'dimitri_title.png'
  'INGEST_PNG'    : RESULT = CENTRAL_FOLDER+'Source'+DL+'png'+DL+'ingest.png'
  'CLOUD_PNG'     : RESULT = CENTRAL_FOLDER+'Source'+DL+'png'+DL+'cloud.png'
  'PROCESS_PNG'   : RESULT = CENTRAL_FOLDER+'Source'+DL+'png'+DL+'process.png'
  'VISU_PNG'      : RESULT = CENTRAL_FOLDER+'Source'+DL+'png'+DL+'visualise.png'
  'BRIGHT_LUT'    : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'CLOUD_SCREENING_Bright_Threshold_LUT.dat'
  'OZONE_TRANS'   : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'transmission'+dl+'Transmission_O3.txt'
  'WVAP_TRANS'    : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'transmission'+dl+'Transmission_H2O.txt'
  'GAS_TRANS'     : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'transmission'+dl+'Transmission_O2_trace_gases.txt'
  'VGT_CORRECTION': RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'VGT2_CNES_Earth_Sun_correction.txt'
  'MM01_ECHI'     : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'marine'+dl+'Morel-e-chi-coef-2001.txt'
  'MOREL_MUD'     : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'marine'+dl+'Morel-mud.txt'
  'WATER_COEF'    : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'marine'+dl+'water_coef.txt'
  'REFRACT_INDEX' : RESULT = CENTRAL_FOLDER+'AUX_DATA'+DL+'marine'+dl+'water_refractive_index.txt'
  'SUM'           : RESULT = CENTRAL_FOLDER+'User_Manual.pdf'

;----------------------
; VALUES

  'TOOL'          : RESULT = 'DIMITRI V'+DIMITRI_VERSION
  'D_VERSION'     : RESULT = DIMITRI_VERSION
    
  ELSE            : BEGIN
                      PRINT, 'ERROR, LOCATION CASE NOT FOUND'
                      RETURN,'ERROR'
                    END
  ENDCASE

;----------------------
; RETURN PATH FOUND

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'RETRIEVED LOCATION : ',RESULT
  RETURN, RESULT
stop
END
