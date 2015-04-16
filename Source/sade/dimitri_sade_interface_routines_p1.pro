PRO DIMITRI_SADE_INTERFACE_ROUTINES_P1

;0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
;0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
;
; SECTION 1: SENSOR INTERCOMPARION/INTERCALIBRATION/RECALIBRATION
;
;0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
;0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

;----------------------------
; USAGE
;
; UPDATE THE PARAMETERS BELOW FOR YOUR INTERESTED DIMITRI SCENARIOS, THEN RUN THE PROGRAM (NEED TO RESTORE DIMITRI_V2.SAV)
; ALL NOMINAL DIMITRI OUTPUTS WILL BE PLACED IN THE DEFINED "OFOLDER"
; A LOOP WILL INTERCOMPARE AND RECALIBRATE ANY NUMBER OF DEFINED CALIBRATION SENSORS TO THE DEFINE REFERENCE SENSOR

;----------------------------
; SET UP PARAMETERS

  MAIN_DIR          = GET_DIMITRI_LOCATION('DIMITRI');FULL PATH OF THE MAIN DIMITRI DIRECTORY
  OFOLDER           = FILEPATH('',root_dir = MAIN_DIR, subdir=['Output','VGT_TEST_2']) ; FULL PATH OF THE OUTPUT FOLDER TO BE CREATED
  REGION            = 'Niger2'                            ; VALIDATION SITE NAME
  SENSOR1           = 'MERIS'                             ; REFERENCE SENSOR
  PROC_VER1         = '2nd_Reprocessing'                  ; REFERENCE SENSOR PROCESSING VERSION
  SENSOR2S          = ['MODISA','PARASOL']                  ; CALIBRATION SENSORs - insert as many as you wish
  PROC_VER2S        = ['Collection_5','Calibration_1'] ; CALIBRATION SENSOR PROCESSING VERSIONS
  AMC_THRESHOLD     = 10                                  ; AMC THRESHOLD VALUE
  DAY_OFFSET        = 2                                   ; DAY OFFSET IN INTEGER DAYS
  VZA_MIN           = 0.                                  ; VZA MIN ANGLE (DEGREES)
  VZA_MAX           = 90.                                 ; VZA MAX ANGLE (DEGREES)
  VAA_MIN           = 0.                                  ; VAA MIN ANGLE (DEGREES)
  VAA_MAX           = 360.                                ; VAA MAX ANGLE (DEGREES)
  SZA_MIN           = 0.                                  ; SZA MIN ANGLE (DEGREES)
  SZA_MAX           = 90.                                 ; SZA MAX ANGLE (DEGREES)
  SAA_MIN           = 0.                                  ; SAA MIN ANGLE (DEGREES)
  SAA_MAX           = 360.                                ; SAA MAX ANGLE (DEGREES)
  SADE_DIR          = '/mnt/Projects/MEREMSII/WG_Reference_Dataset_2/distributable_files/' ;CHANGE THIS TO THE LOCATION OF YOUR SADE FILES (NOTE, REGION SUBDIRECTORY IN FILEPATH BELOW

  FOR IVOS=0,N_ELEMENTS(SENSOR2S)-1 DO BEGIN
    SENSOR2   = SENSOR2S[IVOS]
    PROC_VER2 = PROC_VER2S[IVOS]
    SADE1           = FILEPATH(REGION+'_'+SENSOR1+'_'+PROC_VER1+'.SADE',ROOT_DIR=SADE_DIR,SUBDIR=[REGION]); FULL PATH TO THE SADE FILE FOR THE REFERENCE SENSOR
    SADE2           = FILEPATH(REGION+'_'+SENSOR2+'_'+PROC_VER2+'.SADE',ROOT_DIR=SADE_DIR,SUBDIR=[REGION]); FULL PATH TO THE SADE FILE FOR THE CALIBRATION SENSOR
    ;SADE1           = FILEPATH('Niger2_'+SENSOR1+'_'+PROC_VER1+'.SADE',ROOT_DIR=SADE_DIR,SUBDIR=['Niger2']); FULL PATH TO THE SADE FILE FOR THE REFERENCE SENSOR
    ;SADE2           = FILEPATH('Niger2_'+SENSOR2+'_'+PROC_VER2+'.SADE',ROOT_DIR=SADE_DIR,SUBDIR=['Niger2']); FULL PATH TO THE SADE FILE FOR THE CALIBRATION SENSOR


;----------------------------
; DOUBLET EXTRACTION

    RES = EXTRACT_DOUBLETS(OFOLDER,REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,AMC_THRESHOLD,   $
                              DAY_OFFSET,99.0,1.0,                                             $ ; NO NEED TO CHANGE THESE, THEY ARE USED TO SEARCH THROUGH ALL DATA
                              VZA_MIN,VZA_MAX,VAA_MIN,VAA_MAX,SZA_MIN,SZA_MAX,SAA_MIN,SAA_MAX, $
                              SADE1=SADE1,SADE2=SADE2)
  
    IF RES[0] NE 1 THEN BEGIN
      PRINT, '******* ERROR, A PROBLEM OCCURED DURING DOUBLET EXTRACTION ********'
      stop
    ENDIF

;----------------------------
; INTERCOMPARISON

    RES = DIMITRI_INTERFACE_INTERCALIBRATION(OFOLDER,REGION,[SENSOR1],[PROC_VER1],[SENSOR2],[PROC_VER2],INDGEN(30))
    
    IF RES[0] NE 1 THEN BEGIN
      PRINT, '******* ERROR, A PROBLEM OCCURED DURING INTERCALIBRATION ********'
      stop
    ENDIF

;----------------------------
; RECALIBRATION

    RES = RECALIBRATE_DOUBLETS(OFOLDER,REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,$
                               0.99,.01,$
                               VZA_MIN,VZA_MAX,VAA_MIN,VAA_MAX,SZA_MIN,SZA_MAX,SAA_MIN,SAA_MAX,$
                               SADE1=SADE1,SADE2=SADE2)
  
    IF RES[0] NE 1 THEN BEGIN
      PRINT, '******* ERROR, A PROBLEM OCCURED DURING RECALIBRATION ********'
      stop
    ENDIF

  ENDFOR ;LOOP ON CALIBRATION SENSORS

;----------------------------
; CONTANENATE

  RES = CONCATENATE_TOA_REFLECTANCE(OFOLDER,REGION,SENSOR1,PROC_VER1)
  IF RES[0] NE 1 THEN BEGIN
    PRINT, '******* ERROR, A PROBLEM OCCURED DURING CONCATENATION ********'
    STOP
  ENDIF

  PRINT,'******* SUCCESS: COMPLETED SADE/DIMITRI PROCESSING ********'

END