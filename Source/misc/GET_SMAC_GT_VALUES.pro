;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SMAC_GT_VALUES
;*
;* PURPOSE:
;*      RETURNS THE SMAC GT (GASEOUS TRANSMISSIONS) VALUES ACCORDING SMAC COEFFICIENTS AND AUX VALUES
;*
;* CALLING SEQUENCE:
;*      GET_SMAC_TG_VALUES
;*
;* INPUTS:
;*      SMAC COEFFICIENTS
;
;* KEYWORDS:
;*      BLUE_COEFFS = BLUE SMAC COEFFS
;*      RVIS_COEFFS = RED VISIBLE SMAC COEFFS
;*      NIR_COEFFS = NEAR INFRA RED SMAC COEFFS
;*      SWIR_COEFFS = SHORT WAVE RED SMAC COEFFS
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      TYPE  - A STRING OF THE VALIDATION SITE TYPE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      29 NOV 2013 - PML / MAGELLIUM - CREATION
;*
;* VALIDATION HISTORY:
;*      17 APR 2014 - PML / MAGELLIUM   - WINDOWS 64-BIT MACHINE IDL 8.2.3 : COMPILATION AND CALLING SUCCESSFUL
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

 FUNCTION GET_SMAC_GT_VALUES, SMAC_COEFFS, THETA_S = THETA_S, THETA_V = THETA_V, $
                                    PRESSURE = PRESSURE, OZONE = UO3, WATERVAPOUR = UH2O, $
                                    RAYLEIGH=RAYLEIGH, VERBOSE=VERBOSE
 
   STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')

   ; CHECK NUMBER OF SMAC COEFFICIENTS
   IF N_ELEMENTS(SMAC_COEFFS) NE 49 THEN BEGIN 
      PRINT, 'GET_SMAC_GT_VALUES : ERROR, INPUT SMAC COEFFICIENTS MUST CONTAIN 49 ELEMENTS AND NOT ' + STRING(STRTRIM(N_ELEMENTS(SMAC_COEFFS),1))
      RETURN, STATUS_ERROR
   ENDIF
   
    AH2O  = SMAC_COEFFS( 0) ;
    NH2O  = SMAC_COEFFS( 1) ;
    AO3   = SMAC_COEFFS( 2) ;
    NO3   = SMAC_COEFFS( 3) ;
    AO2   = SMAC_COEFFS( 4) ;
    NO2   = SMAC_COEFFS( 5) ;
    PO2   = SMAC_COEFFS( 6) ;
    ACO2  = SMAC_COEFFS( 7) ;
    NCO2  = SMAC_COEFFS( 8) ;
    PCO2  = SMAC_COEFFS( 9) ;
    ACH4  = SMAC_COEFFS(10) ;
    NCH4  = SMAC_COEFFS(11) ;
    PCH4  = SMAC_COEFFS(12) ;
    ANO2  = SMAC_COEFFS(13) ;
    NNO2  = SMAC_COEFFS(14) ;
    PNO2  = SMAC_COEFFS(15) ;
    ACO   = SMAC_COEFFS(16) ;
    NCO   = SMAC_COEFFS(17) ;
    PCO   = SMAC_COEFFS(18) ;
    A0S   = SMAC_COEFFS(19) ;
    A1S   = SMAC_COEFFS(20) ;
    A2S   = SMAC_COEFFS(21) ;
    A3S   = SMAC_COEFFS(22) ;
    A0T   = SMAC_COEFFS(23) ;
    A1T   = SMAC_COEFFS(24) ;
    A2T   = SMAC_COEFFS(25) ;
    A3T     = SMAC_COEFFS(26) ;
    TAUR    = SMAC_COEFFS(27) ;
    SR      = SMAC_COEFFS(28) ;
    A0TAUP  = SMAC_COEFFS(29) ;
    A1TAUP  = SMAC_COEFFS(30) ;
    WO      = SMAC_COEFFS(31) ;
    GC      = SMAC_COEFFS(32) ;
    A0P     = SMAC_COEFFS(33) ;
    A1P     = SMAC_COEFFS(34) ;
    A2P     = SMAC_COEFFS(35) ;
    A3P     = SMAC_COEFFS(36) ;
    A4P     = SMAC_COEFFS(37) ;
    REST1   = SMAC_COEFFS(38) ;
    REST2   = SMAC_COEFFS(39) ;
    REST3   = SMAC_COEFFS(40) ;
    REST4   = SMAC_COEFFS(41) ;
    RESR1   = SMAC_COEFFS(42) ;
    RESR2   = SMAC_COEFFS(43) ;
    RESR3   = SMAC_COEFFS(44) ;
    RESA1   = SMAC_COEFFS(45) ;
    RESA2   = SMAC_COEFFS(46) ;
    RESA3   = SMAC_COEFFS(47) ;
    RESA4   = SMAC_COEFFS(48) ;
    
    CDR=!PI/180;
              
; COMPUTE SMAC SURFACE REFLECTANCE 

    US = COS(THETA_S * CDR);
    UV = COS(THETA_V * CDR);
    PEQ= PRESSURE/1013.25 ;
              
;   1) AIR MASS */
    M =  1/US + 1/UV;
              
;   3) GASEOUS TRANSMISSIONS (DOWNWARD AND UPWARD PATHS)

    TO3 = 1.
    TH2O= 1.
    TO2 = 1.
    TCO2= 1.
    TCH4= 1.
    
    UO2 =  PEQ ^ PO2
    UCO2=  PEQ ^ PCO2
    UCH4=  PEQ ^ PCH4
    UNO2=  PEQ ^ PNO2
    UCO =  PEQ ^ PCO
              
;   GASEOUS ABSORPTION IS FINALLY COMPUTED

    TO3   = EXP( (AO3)  * ( (UO3 * M)  ^ (NO3)  ) )
    TH2O  = EXP( (AH2O) * ( (UH2O * M)  ^ (NH2O) ) )
    TO2   = EXP( (AO2)  * ( (UO2 * M)  ^ (NO2)  ) )
    TCO2  = EXP( (ACO2) * ( (UCO2 * M)  ^ (NCO2) ) )
    TCH4  = EXP( (ACH4) * ( (UCH4 * M)  ^ (NCH4) ) )
    TNO2  = EXP( (ANO2) * ( (UNO2 * M)  ^ (NNO2) ) )
    TCO   = EXP( (ACO)  * ( (UCO * M)  ^ (NCO) ) )
                  
    IF KEYWORD_SET(RAYLEIGH) THEN TG = TO3 * TO2 $
                             ELSE TG = TH2O * TO3 * TO2 * TCO2 * TCH4 * TCO * TNO2       
    
    RETURN, TG
    
 END