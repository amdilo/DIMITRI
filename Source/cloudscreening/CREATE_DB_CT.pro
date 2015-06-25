;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      CREATE_DB_CT            
;* 
;* PURPOSE:
;*      CREATES OR UPDATE THE DATABASE OF CLOUD TRAINNING FILES FROM DIMITRI DATABASE TO BE USED
;*      IN THE INPUT OF SSV AND BRDF  
;*
;*      RESTORES DIMITRI DATABASE AND OUTPUTS A CSV FILES
;* 
;*     NOTE: IT IS VERY USEFUL TO RUN THE SSV AFTER THE MANUAL CLOUD SCREENING
;* 
;* CALLING SEQUENCE:
;*       RES=CREATE_BD_CT( REGION, SENSOR, PROC_VER,VERBOSE=VERBOSE)       
;* 
;* INPUTS:
;*      REGION             - A STRING OF THE DIMITRI VALIDATION SITE
;*      SENSOR             - A STRING OF THE SENSOR TO BE UTILISED
;*      PROC_VER           - A STRING OF THE SENSOR PROCESSING VERSION TO BE UTILISED
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*   CREATES AND UPDATE THE THREE FILES CSV (CLEAR, PARTIALLY_CLOUDY and CLOUDY)
;*    CLASSES OF CLOUD TRAINNING INTO THE INPUT OF EACH SENSOR AND EACH SITE   
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      17 NOV 2014 - B. ALHAMMOUD   - DIMITRI-V3.1.1  PREVIOUSLY CALLED 3.1a
;*      05 DEC 2014 - B. ALHAMMOUD   - UPDATED HEADER INFORMATION AND
;*                     ADDED THE UPDATING DB_CT PART TO THE ROUTINE 
;*      04 JUN 2015 - NCG / MAGELLIUM - UPDATE OF DATABASE FIELDS WITH DIMITRI V4 SPECIFICATIONS
;*                                      STORE CLOUD DATABASE CSV FILES UNDER INGESTION OUTPUT FOLDER INSTEAD OF INPUT FOLDER
;*
;* VALIDATION HISTORY:
;*      10 DEC 2014 - B ALHAMMOUD - LINUX 64BIT MACHINE IDL 8.2: COMPILATION AND OPERATION SUCCESSFUL
;*
;*  FLAGS USED FOR CLOUD_TRAINING_CLASS (0:CLEAR, 1:PARTIALLY_CLOUDY and 2:CLOUDY)

;**************************************************************************************
;**************************************************************************************
FUNCTION CREATE_DB_CT, REGION, SENSOR, PROC_VER,VERBOSE=VERBOSE 

;------------------------
; DEFINE CURRENT FUNCTION NAME

  FCT_NAME = "CREATE_DB_CT"

;------------------------
; DEFINE SETUP

  LUNF=22
  CP_LIMIT  = 0.
  RP_LIMIT  = 1.
  ROICOVER  = 1
  PX_THRESH = 1  

;------------------------------
; CHECK DIMITRI DATABASE EXISTS
  DB_FILE   = GET_DIMITRI_LOCATION('DATABASE')
;  IFOLDER   = GET_DIMITRI_LOCATION('INPUT')
  IFOLDER   = GET_DIMITRI_LOCATION('INGESTION_OUTPUT')
  DL        = PATH_SEP()

  TEMP = FILE_INFO(DB_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
     PRINT, FCT_NAME+': ERROR, DIMITRI DATABASE FILE DOES NOT EXIST'
  ENDIF
;------------------------
; READ DATABASE AND RETRIEVING FORMAT,HEADER, TEMPLATE AND N_ELEMENTS'

  DB_FORMAT = GET_DIMITRI_TEMPLATE(1,/FORMAT,VERBOSE=VERBOSE)
  DB_HEADER = GET_DIMITRI_TEMPLATE(1,/HDR,VERBOSE=VERBOSE)
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE,VERBOSE=VERBOSE)
  DB_DATA   = READ_ASCII(DB_FILE,TEMPLATE=GET_DIMITRI_TEMPLATE(1,/TEMPLATE))
  DB_ITER   = N_ELEMENTS(DB_DATA.(0))

;------------------------ 
; UPDATE CLOUD_TRAINING FILES
; IF IT EXISTS, IF NOT CREATE IT
;------------------------ 
; LOOP OVER EACH CLOUD_TRAINING_CLASS (CLEAR, PARTIALLY_CLOUDY and CLOUDY)
  FOR ICLS=0,2  DO BEGIN
     CASE ICLS OF
        0: BEGIN
           CCLS='CLASS1_CLEAR'
           CLS_INDX=0
        END
        1: BEGIN
           CCLS='CLASS2_PARTIALLY_CLOUDY'
           CLS_INDX=1
        END
        2: BEGIN
           CCLS='CLASS3_CLOUDY'
           CLS_INDX=2
        END
     ENDCASE
           
     TRNNG_IFILE = STRING(IFOLDER+'Site_'+REGION+DL+SENSOR+DL+'Proc_'+PROC_VER+DL+'DIMITRI_DATABASE_CLOUD_TRAINING_'+CCLS+'.CSV')
     IF NOT FILE_TEST(TRNNG_IFILE) THEN BEGIN
        IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': DIMITRI DATABASE: CREATE DIMITRI_DATABASE_CLOUD_TRAINING_'+CCLS+'.CSV'
        OPENW,LUNF,TRNNG_IFILE,/GET_LUN
;        PRINT,TRNNG_IFILE
        PRINTF,LUNF,DB_HEADER

; FIND ALL DATA WHICH IS CLASSED AS CLOUD FREE AND ROI COVERED     
        RES = WHERE(STRCMP(DB_DATA.SITE_NAME,REGION)               EQ 1 AND $
                    STRCMP(DB_DATA.SENSOR,SENSOR)               EQ 1 AND $
                    STRCMP(DB_DATA.PROCESSING_VERSION,PROC_VER) EQ 1 AND $
                    DB_DATA.ROI_STATUS  GE ROICOVER                 AND $
                    DB_DATA.ROI_PIX_NUM GE PX_THRESH                AND $
                    DB_DATA.MANUAL_CS  EQ CLS_INDX)
        
        RES_ITER   = N_ELEMENTS(RES)
        IF (RES_ITER GT 0) THEN BEGIN
;---------------------------------------
; OPEN THE DATABASE CLOUD_TRAINING FILE AND APPEND DATA
           
           IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': DIMITRI DATABASE CLOUD_TRAINING: PRINTING DATA'  
           FOR DBI = 0L,RES_ITER-1 DO BEGIN
              PRINTF,LUNF,FORMAT=DB_FORMAT,$
                     DB_DATA.DIMITRI_DATE[RES[DBI]],$
                     DB_DATA.SITE_NAME[RES[DBI]],$
                     DB_DATA.SITE_TYPE[RES[DBI]],$
                     DB_DATA.SITE_COORDINATES[RES[DBI]],$
                     DB_DATA.SENSOR[RES[DBI]],$
                     DB_DATA.PROCESSING_VERSION[RES[DBI]],$
                     DB_DATA.YEAR[RES[DBI]],$
                     DB_DATA.MONTH[RES[DBI]],$
                     DB_DATA.DAY[RES[DBI]],$
                     DB_DATA.DOY[RES[DBI]],$
                     DB_DATA.DECIMAL_YEAR[RES[DBI]],$
                     DB_DATA.L1_FILENAME[RES[DBI]],$
                     DB_DATA.L1_INGESTED_FILENAME[RES[DBI]],$
                     DB_DATA.ROI_STATUS[RES[DBI]],$
                     DB_DATA.ROI_PIX_NUM[RES[DBI]],$
                     DB_DATA.THETA_N_MEAN[RES[DBI]],$
                     DB_DATA.THETA_R_MEAN[RES[DBI]],$
                     DB_DATA.AUTO_CS_1_NAME[RES[DBI]],$
                     DB_DATA.AUTO_CS_1_MEAN[RES[DBI]],$
                     DB_DATA.ROI_CS_1_CLEAR_PIX_NUM[RES[DBI]],$
                     DB_DATA.AUTO_CS_2_NAME[RES[DBI]],$
                     DB_DATA.AUTO_CS_2_MEAN[RES[DBI]],$
                     DB_DATA.ROI_CS_2_CLEAR_PIX_NUM[RES[DBI]],$
                     DB_DATA.BRDF_CS_MEAN[RES[DBI]],$
                     DB_DATA.SSV_CS_MEAN[RES[DBI]],$
                     DB_DATA.MANUAL_CS[RES[DBI]],$
                     DB_DATA.ERA_WIND_SPEED_MEAN[RES[DBI]],$
                     DB_DATA.ERA_WIND_DIR_MEAN[RES[DBI]],$
                     DB_DATA.ERA_OZONE_MEAN[RES[DBI]],$
                     DB_DATA.ERA_PRESSURE_MEAN[RES[DBI]],$
                     DB_DATA.ERA_WATERVAPOUR_MEAN[RES[DBI]],$
                     DB_DATA.ESA_CHLOROPHYLL_MEAN[RES[DBI]],$
                     DB_DATA.AUX_DATA_1[RES[DBI]],$
                     DB_DATA.AUX_DATA_2[RES[DBI]],$
                     DB_DATA.AUX_DATA_3[RES[DBI]],$
                     DB_DATA.AUX_DATA_4[RES[DBI]],$
                     DB_DATA.AUX_DATA_5[RES[DBI]],$
                     DB_DATA.AUX_DATA_6[RES[DBI]],$
                     DB_DATA.AUX_DATA_7[RES[DBI]],$
                     DB_DATA.AUX_DATA_8[RES[DBI]],$
                     DB_DATA.AUX_DATA_9[RES[DBI]],$
                     DB_DATA.AUX_DATA_10[RES[DBI]]
           ENDFOR 
;----------------------
; CLOSE THE DATABASE CLOUD_TRAINING FILE
           close,LUNF
           FREE_LUN,LUNF
        ENDIF ELSE BEGIN
           PRINT, RES_ITER, CCLS+' AQUISITION IS FOUND IN DIMITRI DB FOR'+' '+SENSOR+' Proc_'+PROC_VER+' IN SITE_'+REGION
           close,LUNF
           FREE_LUN,LUNF
        ENDELSE
        
     ENDIF ELSE BEGIN
;------------------------ 
; DATABASE CLOUD_TRAINING FILE UPDATE
        IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': DIMITRI DATABASE: UPDATE DIMITRI_DATABASE_CLOUD_TRAINING_'+CCLS+'.CSV'
        OPENU,LUNF,TRNNG_IFILE,/GET_LUN,/APPEND
        
; FIND ALL DATA WHICH IS CLASSED AS CLOUD FREE AND ROI COVERED       
        RES = WHERE(STRCMP(DB_DATA.SITE_NAME,REGION)               EQ 1 AND $
                    STRCMP(DB_DATA.SENSOR,SENSOR)             EQ 1 AND $
                    STRCMP(DB_DATA.PROCESSING_VERSION,PROC_VER) EQ 1 AND $
                    DB_DATA.ROI_STATUS  GE ROICOVER                 AND $
                    DB_DATA.ROI_PIX_NUM GE PX_THRESH                AND $
                    DB_DATA.MANUAL_CS  EQ CLS_INDX)
        
        RES_ITER   = N_ELEMENTS(RES)
        IF (RES_ITER GT 0) THEN BEGIN
           IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': DIMITRI DATABASE CLOUD_TRAINING: PRINTING DATA'  
           FOR DBI = 0L,RES_ITER-1 DO BEGIN
              PRINTF,LUNF,FORMAT=DB_FORMAT,$
                     DB_DATA.DIMITRI_DATE[RES[DBI]],$
                     DB_DATA.SITE_NAME[RES[DBI]],$
                     DB_DATA.SITE_TYPE[RES[DBI]],$
                     DB_DATA.SITE_COORDINATES[RES[DBI]],$
                     DB_DATA.SENSOR[RES[DBI]],$
                     DB_DATA.PROCESSING_VERSION[RES[DBI]],$
                     DB_DATA.YEAR[RES[DBI]],$
                     DB_DATA.MONTH[RES[DBI]],$
                     DB_DATA.DAY[RES[DBI]],$
                     DB_DATA.DOY[RES[DBI]],$
                     DB_DATA.DECIMAL_YEAR[RES[DBI]],$
                     DB_DATA.L1_FILENAME[RES[DBI]],$
                     DB_DATA.L1_INGESTED_FILENAME[RES[DBI]],$
                     DB_DATA.ROI_STATUS[RES[DBI]],$
                     DB_DATA.ROI_PIX_NUM[RES[DBI]],$
                     DB_DATA.THETA_N_MEAN[RES[DBI]],$
                     DB_DATA.THETA_R_MEAN[RES[DBI]],$
                     DB_DATA.AUTO_CS_1_NAME[RES[DBI]],$
                     DB_DATA.AUTO_CS_1_MEAN[RES[DBI]],$
                     DB_DATA.ROI_CS_1_CLEAR_PIX_NUM[RES[DBI]],$
                     DB_DATA.AUTO_CS_2_NAME[RES[DBI]],$
                     DB_DATA.AUTO_CS_2_MEAN[RES[DBI]],$
                     DB_DATA.ROI_CS_2_CLEAR_PIX_NUM[RES[DBI]],$
                     DB_DATA.BRDF_CS_MEAN[RES[DBI]],$
                     DB_DATA.SSV_CS_MEAN[RES[DBI]],$
                     DB_DATA.MANUAL_CS[RES[DBI]],$
                     DB_DATA.ERA_WIND_SPEED_MEAN[RES[DBI]],$
                     DB_DATA.ERA_WIND_DIR_MEAN[RES[DBI]],$
                     DB_DATA.ERA_OZONE_MEAN[RES[DBI]],$
                     DB_DATA.ERA_PRESSURE_MEAN[RES[DBI]],$
                     DB_DATA.ERA_WATERVAPOUR_MEAN[RES[DBI]],$
                     DB_DATA.ESA_CHLOROPHYLL_MEAN[RES[DBI]],$
                     DB_DATA.AUX_DATA_1[RES[DBI]],$
                     DB_DATA.AUX_DATA_2[RES[DBI]],$
                     DB_DATA.AUX_DATA_3[RES[DBI]],$
                     DB_DATA.AUX_DATA_4[RES[DBI]],$
                     DB_DATA.AUX_DATA_5[RES[DBI]],$
                     DB_DATA.AUX_DATA_6[RES[DBI]],$
                     DB_DATA.AUX_DATA_7[RES[DBI]],$
                     DB_DATA.AUX_DATA_8[RES[DBI]],$
                     DB_DATA.AUX_DATA_9[RES[DBI]],$
                     DB_DATA.AUX_DATA_10[RES[DBI]]
           ENDFOR 
;----------------------
; CLOSE THE DATABASE CLOUD_TRAINING FILE
           close,LUNF
           FREE_LUN,LUNF
        ENDIF ELSE BEGIN
           PRINT, RES_ITER, CCLS+' AQUISITION IS FOUND IN DIMITRI DB FOR'+' '+SENSOR+' Proc_'+PROC_VER+' IN SITE_'+REGION
           close,LUNF
           FREE_LUN,LUNF
        ENDELSE 
     ENDELSE      
;------------------------------------------
; SORT THE DATA BASED ON THE GENERATED STRINGS

        DB_CT_DATA = 0 
        DB_CT_DATA = READ_ASCII(TRNNG_IFILE,TEMPLATE=GET_DIMITRI_TEMPLATE(1,/TEMPLATE))
        DB_CT_ITER = N_ELEMENTS(DB_CT_DATA.(0))
        TEMP    = STRARR(DB_CT_ITER)
        FOR DBI = 0L,DB_CT_ITER-1 DO BEGIN
           TEMP_YEAR =  STRTRIM(STRING(DB_CT_DATA.YEAR[DBI]),2) ;STRING(DB_CT_DATA.YEAR[DBI],FORMAT='I4.4')
           TEMP_MONTH = DB_CT_DATA.MONTH[DBI] LE 9 ? '0'+STRTRIM(STRING(DB_CT_DATA.MONTH[DBI]),2) : STRTRIM(STRING(DB_CT_DATA.MONTH[DBI]),2)
           TEMP_DAY =   DB_CT_DATA.DAY[DBI]   LE 9 ? '0'+STRTRIM(STRING(DB_CT_DATA.DAY[DBI]),2) : STRTRIM(STRING(DB_CT_DATA.DAY[DBI]),2)
           TEMP[DBI] = STRING(DB_CT_DATA.SITE_NAME[DBI]+DB_CT_DATA.SENSOR[DBI]+DB_CT_DATA.PROCESSING_VERSION[DBI]+TEMP_YEAR+TEMP_MONTH+TEMP_DAY) 
        ENDFOR
        
;------------------------------------------
; SORT THE DATA BASED ON THE GENERATED STRINGS
        
         DB_CT_INDX=UNIQ(DB_CT_DATA.DECIMAL_YEAR, SORT(DB_CT_DATA.DECIMAL_YEAR))
;        DB_CT_INDX = UNIQ(TEMP, SORT(TEMP))
 ;       DB_CT_INDX = SORT(TEMP)
        DB_CT_ITER = N_ELEMENTS(DB_CT_INDX)       
;------------------------------------------
; OPEN A TEMPORARY DATABASE CLOUD_TRAINING FILE AND PRINT SORTED DATA
        
        IF KEYWORD_SET(VERBOSE) THEN PRINT, 'DIMITRI DATABASE CLOUD_TRAINING UPDATE: OPENING A TEMPORARY DATABASE FILE'  
        TEMP_DB_CT = TRNNG_IFILE+'.TEMP'   
        OPENW,LUNF,TEMP_DB_CT,/GET_LUN
        PRINTF,LUNF,DB_HEADER   
        IF KEYWORD_SET(VERBOSE) THEN PRINT, 'DIMITRI DATABASE CLOUD_TRAINING UPDATE: UPDATING TEMPORARY DATABASE FILE'  
        FOR DBI = 0L,DB_CT_ITER-1 DO BEGIN
              PRINTF,LUNF,FORMAT=DB_FORMAT,$
                     DB_CT_DATA.DIMITRI_DATE[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.SITE_NAME[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.SITE_TYPE[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.SITE_COORDINATES[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.SENSOR[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.PROCESSING_VERSION[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.YEAR[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.MONTH[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.DAY[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.DOY[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.DECIMAL_YEAR[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.L1_FILENAME[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.L1_INGESTED_FILENAME[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ROI_STATUS[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ROI_PIX_NUM[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.THETA_N_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.THETA_R_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUTO_CS_1_NAME[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUTO_CS_1_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ROI_CS_1_CLEAR_PIX_NUM[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUTO_CS_2_NAME[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUTO_CS_2_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ROI_CS_2_CLEAR_PIX_NUM[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.BRDF_CS_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.SSV_CS_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.MANUAL_CS[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ERA_WIND_SPEED_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ERA_WIND_DIR_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ERA_OZONE_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ERA_PRESSURE_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ERA_WATERVAPOUR_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.ESA_CHLOROPHYLL_MEAN[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_1[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_2[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_3[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_4[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_5[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_6[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_7[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_8[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_9[DB_CT_INDX[DBI]],$
                     DB_CT_DATA.AUX_DATA_10[DB_CT_INDX[DBI]]
        ENDFOR    
        
;----------------------------------------
; CLOSE THE TEMPORARY CLOUD_TRAINING DATABASE, CHECK THAT IT EXISTS, 
; DELETE THE OLD CLOUD_TRAINING DATABASE AND REPLACE WITH THE SORTED VERSION    
        
        IF KEYWORD_SET(VERBOSE) THEN PRINT, 'DIMITRI DATABASE CLOUD_TRAINING UPDATE: FREEING LUN, IF TEMPORARY FILE SUCCESSFULLY GENERATED THEN REPLACE OLD FILE'     
        FREE_LUN,LUNF
        TEMP = FILE_INFO(TRNNG_IFILE+'.TEMP')
        IF TEMP.EXISTS EQ 1 THEN BEGIN
           FILE_DELETE,TRNNG_IFILE
           FILE_COPY,TRNNG_IFILE+'.TEMP',TRNNG_IFILE
           FILE_DELETE,TRNNG_IFILE+'.TEMP'
        ENDIF ELSE PRINT, 'DIMITRI DATABASE CLOUD_TRAINING UPDATE: ERROR, TEMPORARY CLOUD_TRAINING DATABASE DOES NOT EXIST, DATABASE NOT SORTED'
        
     
     
  ENDFOR                        ; OVER ICLS: CLOUD_TRAINING_CLASS
  
  RETURN, 1
  
END