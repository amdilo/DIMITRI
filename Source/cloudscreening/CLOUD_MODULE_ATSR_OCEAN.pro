;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      CLOUD_MODULE_ATSR_OCEAN       
;* 
;* PURPOSE:
;*      THIS FUNCTION PERFORMS THE LANDSAT 7 AUTOMATED CLOUD CLEARING ALGORITHIM (LCCA). 
;*      IT UTILISES THERMAL DATA AND PERFORMS 2 PASSESS. THE FIRST PASS INCLUDES 8 FILTERS 
;*      TO MAKE INITIAL ESTIMATIONS ON PIXELS, THE SECOND PASS USES A CLOUD POPULATION 
;*      ESTIMATED FROM PASS 1 TO CLASSIFY ALL AMBIGUOUS DATA POINTS.
;* 
;* CALLING SEQUENCE:
;*      RES = CLOUD_MODULE_LCCA(LCCA_REF)    
;* 
;* INPUTS:
;*      LCCA_REF   - A FLOAT ARRAY CONTAINING THE TOA REFLECTANCE AT 555NM,660NM,870NM,
;*                   1.6MICRON AND 11 MICRON WAVELENGTHS [NB_PIXELS,REF_BANDS].
;*                   THE 11 MICRON BAND SHOULD BE IN TOA TEMPERATURE (KELVIN).
;*
;* KEYWORDS:
;*      VERBOSE    - PROCESSING STATUS OUTPUTS
;*      MODISA     - UTILISES COEFICIENTS INTENDED FOR USE WITH MODISA DATA
;*		SUNGLINT_STATUS  - INPUT SUNGLINT FOR SPECIFIC PROCESS
;*		CS_CLASSIF_MATRIX - ALL CLASSIFICATION STEP MATRIX : CS_MASK1..3 / SPATIAL_CONSISTENCY / DILATE_MASK / COLUMN & LINE INDEXES
;*
;* OUTPUTS:
;*      PIXEL_CLASSIFICATION - AN INTEGER ARRAY OF NUM_PIXELS, 0 MEANS CLEAR PIXEL, 
;*                              1 MEANS CLOUDY
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      18 NOV 2014 - NCG / MAGELLIUM   - DIMITRI-MAG V3.0
;*
;* VALIDATION HISTORY:
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION CLOUD_MODULE_ATSR_OCEAN, LCCA_REF_ALL, CS_ANG, SUNGLINT_STATUS=SUNGLINT_STATUS, CS_CLASSIF_MATRIX=CS_CLASSIF_MATRIX,VERBOSE=VERBOSE

  DEBUG_MODE = 0			; SET TO 1 IF WANT TO DEBUG THIS PROCEDURE
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'CLOUD_MODULE_ATSR_OCEAN: STARTING CLOUD SCREENING'

  STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
  STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

  MISSING_VALUE_LONG = LONG(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  MISSING_VALUE_FLT  = FLOAT(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))

  ;---------------------------------------------
  ; SUNGLINT_STATUS DEFAULT VALUE IF NOT DEFINED
  
  IF KEYWORD_SET(SUNGLINT_STATUS) EQ 0 THEN SUNGLINT_STATUS = 0 

  ;----------------------------
  ; DEFINE BAND INDEXES
  
  B2 = 0 ; 7  0.550
  B3 = 1 ; 9  0.670
  B4 = 2 ;18  0.870
  B5 = 3 ;26  1.6
  B7 = 4 ;30  BT12
  

  ;----------------------------
  ; INITIALIZE OUTPUT DATA

  NB_PIXELS_ALL     = N_ELEMENTS(LCCA_REF_ALL[*,0])
  NBVALID           = LONARR(NB_PIXELS_ALL)
  
  ;----------------------------
  CS_CLASSIF_MATRIX= MAKE_ARRAY(NB_PIXELS_ALL,2,/LONG,VALUE=MISSING_VALUE_LONG)

  IDX_VALID  = WHERE ( LCCA_REF_ALL[*,B7] NE MISSING_VALUE_LONG AND $ 
                       LCCA_REF_ALL[*,B3] NE MISSING_VALUE_LONG AND $
                       LCCA_REF_ALL[*,B4] NE MISSING_VALUE_LONG, NB_PIXELS)
                       
  IF NB_PIXELS EQ 0 THEN BEGIN
    PRINT,'CLOUD_MODULE_ATSR_OCEAN: ERROR, NO VALID PIXELS !!!'
    RETURN, STATUS_ERROR
  ENDIF
   
  CS_CLASSIF_MATRIX[IDX_VALID,0] = IDX_VALID

  ;----------------------------
  ; PROCESS VALID PIXELS
  ;
  LCCA_REF   = LCCA_REF_ALL(IDX_VALID,*)
  
  TOTAL_PIXEL_CLASSIFICATION= MAKE_ARRAY(NB_PIXELS,/LONG,VALUE=MISSING_VALUE_LONG)
   
  COL_IND= LCCA_REF_ALL(*,5)
  LIG_IND= LCCA_REF_ALL(*,6)
  
  THETAS=CS_ANG(IDX_VALID,0)
  PHIS  =CS_ANG(IDX_VALID,1)
  THETAV=CS_ANG(IDX_VALID,2)
  PHIV  =CS_ANG(IDX_VALID,3)
  
  ;----------------------------
  ; DEFINE IDENTIFIERS AND NB OF PIXELS
  NOSELECT_ID = 0
  PX_CLEAR = 0
  PX_CLOUD = 1

  ;----------------------------
  ; DEFINE ARRAY TO HOLD PIXEL CLASSIFICATION

  NBTEST=5
  
  PIXEL_CLASSIFICATION= MAKE_ARRAY(NBTEST,NB_PIXELS,/LONG,VALUE=MISSING_VALUE_LONG)
  TOTAL_PIXEL_CLASSIFICATION = MAKE_ARRAY(NB_PIXELS,/LONG,VALUE=MISSING_VALUE_LONG)
  
  P1F1_THRESHOLD_SUNGLINT=MAKE_ARRAY(NB_PIXELS,/FLOAT,VALUE=MISSING_VALUE_FLT)

  ;----------------------------
  ; DEFINE THRESHOLDS

  P1F1_THRESHOLD = 0.045
  ;
  ; BBT  P1F5_THRESHOLD = 2.0
  P1F5_THRESHOLD = 0.85
  ; ADDED BTT Threshold BT11
  P1F9_THRESHOLD = 273.0
  ; ADDED BTT Threshold cirrus  
  P1F10_THRESHOLD = 0.03
  
  IF SUNGLINT_STATUS EQ 1 OR SUNGLINT_STATUS EQ 2 THEN BEGIN
  
    COSTHETAR=SIN(THETAS*!DTOR)*SIN(THETAV*!DTOR) * COS((PHIS-PHIV+180)*!DTOR) + COS(THETAS*!DTOR)*COS(THETAV*!DTOR);
    IMG_THETAR=ACOS(COSTHETAR)*!RADEG
     
    ; THRESHOLDS MODIFIED BBT 24/10/2013
    ID1 = WHERE( IMG_THETAR LT 10,P1F1_COUNT,COMPLEMENT=NIDX_BIT20, NCOMPLEMENT=NP1F1_COUNT)
    ; IF P1F1_COUNT  NE 0 THEN P1F1_THRESHOLD_SUNGLINT(ID1)=0.19
    IF P1F1_COUNT  NE 0 THEN P1F1_THRESHOLD_SUNGLINT(ID1)=INTERPOL([0.4,0.19],[0,10],IMG_THETAR(ID1))  
    ID2 = WHERE( IMG_THETAR GE 10 AND IMG_THETAR LT 20,P1F1_COUNT,COMPLEMENT=NIDX_BIT20, NCOMPLEMENT=NP1F1_COUNT)
    IF P1F1_COUNT  NE 0 THEN P1F1_THRESHOLD_SUNGLINT(ID2)=INTERPOL([0.19,0.085],[10,20],IMG_THETAR(ID2))
    ID3 = WHERE( IMG_THETAR GE 20 AND IMG_THETAR LT 36,P1F1_COUNT,COMPLEMENT=NIDX_BIT20, NCOMPLEMENT=NP1F1_COUNT)
    IF P1F1_COUNT  NE 0 THEN P1F1_THRESHOLD_SUNGLINT(ID3)=INTERPOL([0.085,0.045],[20,36],IMG_THETAR(ID3))
    ID4 = WHERE( IMG_THETAR GE 36 ,P1F1_COUNT,COMPLEMENT=NIDX_BIT20, NCOMPLEMENT=NP1F1_COUNT)
    IF P1F1_COUNT  NE 0 THEN P1F1_THRESHOLD_SUNGLINT(ID4)=0.045

    ; BBT  P1F5_THRESHOLD = 2.0
    P1F5_THRESHOLD = 1.05 ; 1.025  ; 0.95 publi modis
    
  ENDIF
    
  ;----------------------------
  ; GROUP III
  ;

  ;-----------------------------------------------------------------
  ; PASS1, FILTER 1: BRIGHTNESS THRESHOLD - BAND 4 COMPARED TO 0.045
  IF SUNGLINT_STATUS EQ 1 OR SUNGLINT_STATUS EQ 2 THEN BEGIN
    PIXEL_CLASSIFICATION[0,*]  = LCCA_REF[*,B4] GT P1F1_THRESHOLD_SUNGLINT
  ENDIF ELSE BEGIN  
    IDX_BIT20 = WHERE( LCCA_REF[*,B4] GT P1F1_THRESHOLD,P1F1_COUNT,COMPLEMENT=NIDX_BIT20, NCOMPLEMENT=NP1F1_COUNT)
    IF P1F1_COUNT  NE 0 THEN PIXEL_CLASSIFICATION[0,IDX_BIT20]  = PX_CLOUD
    IF NP1F1_COUNT NE 0 THEN PIXEL_CLASSIFICATION[0,NIDX_BIT20] = PX_CLEAR
  
    IF DEBUG_MODE THEN PRINT, 'DEBUG_MODE - P1F1_THRESHOLD = ', P1F1_THRESHOLD, ' - P1F1_COUNT = ', P1F1_COUNT, ' - NP1F1_COUNT = ', NP1F1_COUNT
  ENDELSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'CLOUD_MODULE_ATSR_OCEAN: P1_F1 NUMBER = ', P1F1_COUNT

  ;----------------------------
  ; PASS1, FILTER 5: B4/3 RATIO - B4/B3 COMPARED TO 1
  
  IDX_BIT21 = WHERE(LCCA_REF[*,B4]/LCCA_REF[*,B3] GT P1F5_THRESHOLD,P1F5_COUNT,COMPLEMENT=NIDX_BIT21, NCOMPLEMENT=NP1F5_COUNT)
  
  IF P1F5_COUNT   NE 0 THEN   PIXEL_CLASSIFICATION[1,IDX_BIT21]  = PX_CLOUD
  IF NP1F5_COUNT  NE 0 THEN   PIXEL_CLASSIFICATION[1,NIDX_BIT21] = PX_CLEAR
  
  IF DEBUG_MODE THEN PRINT, 'DEBUG_MODE - P1F5_THRESHOLD = ', P1F5_THRESHOLD, ' - P1F5_COUNT = ', P1F5_COUNT, ' - NP1F5_COUNT = ', NP1F5_COUNT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'CLOUD_MODULE_ATSR_OCEAN: P1_F5 NUMBER = ',P1F5_COUNT

  ;----------------------------
  ; PASS1, FILTER 3: TEMP THRESHOLD - B7 VERSUS 273K

  IDX_BIT13 = WHERE(LCCA_REF[*,B7] LT P1F9_THRESHOLD,P1F3_COUNT,COMPLEMENT=NIDX_BIT13, NCOMPLEMENT=NP1F3_COUNT)
  
  IF P1F3_COUNT   NE 0 THEN PIXEL_CLASSIFICATION[2,IDX_BIT13]  = PX_CLOUD
  IF NP1F3_COUNT  NE 0 THEN PIXEL_CLASSIFICATION[2,NIDX_BIT13] = PX_CLEAR
   
  IF DEBUG_MODE THEN PRINT, 'DEBUG_MODE - P1F9_THRESHOLD = ', P1F9_THRESHOLD, ' - P1F3_COUNT = ', P1F3_COUNT, ' - NP1F3_COUNT = ', NP1F3_COUNT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'CLOUD_MODULE_ATSR_OCEAN: P1_F3 NUMBER = ',P1F3_COUNT
   
  ; SPATIAL COHERENCY TEST ON NIR
  NBCOL=MAX(COL_IND)-MIN(COL_IND)+1
  NBLIG=MAX(LIG_IND)-MIN(LIG_IND)+1

  COLO=FIX(COL_IND-MIN(COL_IND))
  LIG=FIX(LIG_IND-MIN(LIG_IND))
    
  ARRAY_SPATIALCOH = MAKE_ARRAY(NBCOL,NBLIG,/FLOAT,VALUE=0)
  ; FILL THE ARRAY WITH B4
  FOR J = 0L,  NB_PIXELS-1 DO BEGIN
     ARRAY_SPATIALCOH[COLO[IDX_VALID[J]], LIG[IDX_VALID[J]]]=LCCA_REF_ALL[IDX_VALID[J],B4]
  ENDFOR 

  ; CHECK THAT THERE ARE AT LEAST 3X3 PIXELS
  DIM_SPACOH = SIZE(ARRAY_SPATIALCOH)
  IF (DIM_SPACOH[0] LE 1 OR  DIM_SPACOH[1] LE 2 OR  DIM_SPACOH[2] LE 2 ) THEN RETURN, STATUS_OK
                
  ; Apply a SZ x SZ window
  SZ=3   
  SPATIALCOH=CLOUD_LOCALSTD(ARRAY_SPATIALCOH,SZ)
  SIGMA_ARRAY=REFORM(SPATIALCOH[1,*,*])
  AVG_ARRAY  =REFORM(SPATIALCOH[0,*,*])
    
  IF SUNGLINT_STATUS EQ 1 OR SUNGLINT_STATUS EQ 2 THEN BEGIN
    THRESHOLD_SIGMA=0.015
    THRESHOLD_AVG=0.015
  ENDIF ELSE BEGIN
    THRESHOLD_SIGMA=0.01
    THRESHOLD_AVG=0.01   
  ENDELSE
    
  SPATIALCOH_MASK = SIGMA_ARRAY GE THRESHOLD_SIGMA OR ABS(ARRAY_SPATIALCOH-AVG_ARRAY) GT THRESHOLD_AVG 
  FOR IPIX=0L,NB_PIXELS-1 DO BEGIN     
    TOTAL_PIXEL_CLASSIFICATION[IPIX]=(1-PIXEL_CLASSIFICATION[0,IPIX])*(1-PIXEL_CLASSIFICATION[1,IPIX])* $
                                       (1-PIXEL_CLASSIFICATION[2,IPIX])
  ENDFOR
      
  ARRAY_OTHERS_MASK = MAKE_ARRAY(NBCOL, NBLIG,/FLOAT,VALUE=0)
  FOR IPIX=0L,NB_PIXELS-1 DO BEGIN           
      ARRAY_OTHERS_MASK[COLO[IDX_VALID[IPIX]], LIG[IDX_VALID[IPIX]]]=TOTAL_PIXEL_CLASSIFICATION[[IPIX]]
  ENDFOR    
          
  NEW_MASK= MAKE_ARRAY(NBCOL, NBLIG,/FLOAT,VALUE=0)       
  NEW_MASK=ARRAY_OTHERS_MASK*(1.0-FLOAT(SPATIALCOH_MASK))

  S= REPLICATE(1, 3, 3)  
  NEW_MASK_DILATE=DILATE(1-NEW_MASK,S)    

  FOR IPIX=0L,NB_PIXELS-1 DO BEGIN
    PIXEL_CLASSIFICATION[3,IPIX]=SPATIALCOH_MASK[COLO[IDX_VALID[IPIX]], LIG[IDX_VALID[IPIX]]]
    PIXEL_CLASSIFICATION[4,IPIX]=NEW_MASK_DILATE[COLO[IDX_VALID[IPIX]], LIG[IDX_VALID[IPIX]]]
  ENDFOR
 
  RES = WHERE(PIXEL_CLASSIFICATION EQ MISSING_VALUE_LONG, COUNT)
  IF COUNT GT 0 THEN BEGIN
    PRINT,'CLOUD_MODULE_ATSR_OCEAN: ERROR, SOME PIXELS NOT CLASSIFIED!!!', ' NUM PIX = ',COUNT
    RETURN, STATUS_ERROR
  ENDIF

  FOR IPIX=0L,NB_PIXELS-1 DO BEGIN     
    TOTAL_PIXEL_CLASSIFICATION[IPIX]=(1-PIXEL_CLASSIFICATION[4,IPIX])
  ENDFOR
  
  ID_CLOUD = WHERE(TOTAL_PIXEL_CLASSIFICATION EQ 0,CLD_COUNT,COMPLEMENT=ID_CLEAR, NCOMPLEMENT=NCLD_COUNT)
  IF CLD_COUNT   NE 0 THEN TOTAL_PIXEL_CLASSIFICATION[ID_CLOUD]  = 1 ; CLOUDY PIXEL
  IF NCLD_COUNT  NE 0 THEN TOTAL_PIXEL_CLASSIFICATION[ID_CLEAR]  = 0 ; CLEAR PIXEL

  CS_CLASSIF_MATRIX[IDX_VALID,0]=IDX_VALID
  CS_CLASSIF_MATRIX[IDX_VALID,1]=TOTAL_PIXEL_CLASSIFICATION

  RETURN, STATUS_OK
END