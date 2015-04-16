;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SMAC_VALUES
;*
;* PURPOSE:
;*      RETURNS THE SMAC VALUES ACCORDING SMAC COEFFICIENTS AND AUX VALUES
;*
;* CALLING SEQUENCE:
;*      GET_SMAC_TG_VALUES
;*
;* INPUTS:
;*      R_SURF
;*      SMAC COEFFICIENTS
;*
;* KEYWORDS:
;*      BLUE_COEFFS = BLUE SMAC COEFFS
;*      RVIS_COEFFS = RED VISIBLE SMAC COEFFS
;*      NIR_COEFFS = NEAR INFRA RED SMAC COEFFS
;*      SWIR_COEFFS = SHORT WAVE RED SMAC COEFFS
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      R_TOA_TG  - REFLECTANCE TOA / GAZEOUS TRANSMISSION
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

 FUNCTION GET_SMAC_VALUES, R_SURF, SMAC_COEFFS, THETA_S = THETA_S, THETA_V = THETA_V, PHI_S = PHI_S, PHI_V = PHI_V, $
                                    TAUP = TAUP550, PRESSURE = PRESSURE, OZONE = UO3, WATERVAPOUR = UH2O, VERBOSE=VERBOSE
 
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
    CRD=180/!PI;
              
; COMPUTE SMAC SURFACE REFLECTANCE 

    US = COS(THETA_S * CDR);
    UV = COS(THETA_V * CDR);
    PEQ= PRESSURE/1013.25 ;
              
;   1) AIR MASS */
    M =  1/US + 1/UV;
    
    
;   2) AEROSOL OPTICAL DEPTH IN THE SPECTRAL BAND, TAUP
    TAUP = (A0TAUP + A1TAUP) * TAUP550 ;    
              
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
    
    UH2OZ = UH2O*(0.729758 - 2.929542 * PEQ + 3.200206 *PEQ*PEQ);      
        
;   GASEOUS ABSORPTION IS FINALLY COMPUTED
      TO3   = EXP( (AO3)  * ( (UO3 * M)  ^ (NO3)  ) )
      TH2O  = EXP( (AH2O) * ( (UH2OZ * M)  ^ (NH2O) ) )
      TO2   = EXP( (AO2)  * ( (UO2 * M)  ^ (NO2)  ) )
      TCO2  = EXP( (ACO2) * ( (UCO2 * M)  ^ (NCO2) ) )
      TCH4  = EXP( (ACH4) * ( (UCH4 * M)  ^ (NCH4) ) )
      TNO2  = EXP( (ANO2) * ( (UNO2 * M)  ^ (NNO2) ) )
      TCO   = EXP( (ACO)  * ( (UCO * M)  ^ (NCO) ) )
             
    TG    = TH2O * TO3 * TO2 * TCO2 * TCH4 * TCO * TNO2
              
;   5) TOTAL SCATTERING TRANSMISSION
    TTETAS = (A0T) + (A1T)*TAUP550/US + ((A2T)*PEQ + (A3T))/(1.+US) ; %/* DOWNWARD */
    TTETAV = (A0T) + (A1T)*TAUP550/UV + ((A2T)*PEQ + (A3T))/(1.+UV) ; %/* UPWARD   */

;   6) SPHERICAL ALBEDO OF THE ATMOSPHERE
    S = (A0S) * PEQ +  (A3S) + (A1S)*TAUP550 + (A2S) * (TAUP550 ^ 2) ;
    
;   7) SCATTERING ANGLE COSINE
    CKSI = - ( (US*UV) + (SQRT(1. - US*US) * SQRT (1. - UV*UV)*COS((PHI_S-PHI_V) * CDR) ) );
    
    INDX_CKSI_NEG=WHERE(CKSI LT -1, COUNT_CKSI_NEG)
    IF COUNT_CKSI_NEG GT 0 THEN CKSI(INDX_CKSI_NEG) = -1.0

;   8) SCATTERING ANGLE IN DEGREE
    KSID = CRD*ACOS(CKSI) ;
  
;   9) RAYLEIGH ATMOSPHERIC REFLECTANCE
    RAY_PHASE = 0.7190443 * (1. + (CKSI*CKSI))  + 0.0412742 ;
    TAURZ=(TAUR)*PEQ;
    RAY_REF   = ( TAURZ*RAY_PHASE ) / (4.*US*UV) ;
  
;   10) RESIDU RAYLEIGH
    RES_RAY= RESR1 + RESR2 * TAUR*RAY_PHASE / (US*UV) $
                   + RESR3 * ( (TAUR*RAY_PHASE/(US*UV)) ^ 2);
  
;   11) AEROSOL ATMOSPHERIC REFLECTANCE
    AER_PHASE = A0P + A1P*KSID + A2P*KSID*KSID +A3P*(KSID^3) + A4P*(KSID^4);
  
    AK2 = (1. - WO)*(3. - WO*3*GC) ;
    AK  = SQRT(AK2) ;
    E   = -3.*US*US*WO /  (4.*(1. - AK2*US*US) ) ;
    F   = -(1. - WO)*3.*GC*US*US*WO / (4.*(1. - AK2*US*US) ) ;
    DP  = E / (3.*US) + US*F ;
    D   = E + F ;
    B   = 2.*AK / (3. - WO*3*GC);
    DEL = EXP( AK*TAUP )*(1. + B)*(1. + B) - EXP(-AK*TAUP)*(1. - B)*(1. - B) ;
    WW  = WO/4.;
    SS  = US / (1. - AK2*US*US) ;
    Q1  = 2. + 3.*US + (1. - WO)*3.*GC*US*(1. + 2.*US) ;
    Q2  = 2. - 3.*US - (1. - WO)*3.*GC*US*(1. - 2.*US) ;
    Q3  = Q2*EXP( -TAUP/US ) ;
    C1  =  ((WW*SS) / DEL) * ( Q1*EXP(AK*TAUP)*(1. + B) + Q3*(1. - B) ) ;
    C2  = -((WW*SS) / DEL) * (Q1*EXP(-AK*TAUP)*(1. - B) + Q3*(1. + B) ) ;
    CP1 =  C1*AK / ( 3. - WO*3.*GC ) ;
    CP2 = -C2*AK / ( 3. - WO*3.*GC ) ;
    Z   = D - WO*3.*GC*UV*DP + WO*AER_PHASE/4. ;
    X   = C1 - WO*3.*GC*UV*CP1 ;
    Y   = C2 - WO*3.*GC*UV*CP2 ;
    AA1 = UV / (1. + AK*UV) ;
    AA2 = UV / (1. - AK*UV) ;
    AA3 = US*UV / (US + UV) ;
  
    AER_REF = X*AA1* (1. - EXP( -TAUP/AA1 ) ) ;
    AER_REF = AER_REF + Y*AA2*( 1. - EXP( -TAUP / AA2 )  ) ;
    AER_REF = AER_REF + Z*AA3*( 1. - EXP( -TAUP / AA3 )  ) ;
    AER_REF = AER_REF / ( US*UV );
  
;  12) RESIDU AEROSOL
   RES_AER= ( RESA1 + RESA2 * ( TAUP * M *CKSI ) + RESA3 * ( (TAUP*M*CKSI ) ^ 2) ) + RESA4 * ( (TAUP*M*CKSI) ^ 3);
  
;  13)  TERME DE COUPLAGE MOLECULE / AEROSOL
   TAUTOT=TAUP+TAUR;
   RES_6S= ( REST1 + REST2 * ( TAUTOT * M *CKSI ) + REST3 * ( (TAUTOT*M*CKSI) ^ 2) ) + REST4 * ( (TAUTOT*M*CKSI) ^ 3);
  
;  14) TOTAL ATMOSPHERIC REFLECTANCE
   ATM_REF = RAY_REF - RES_RAY + AER_REF - RES_AER + RES_6S;
  
;  15) SURFACE REFLECTANCE
;   R_TOA_TG = (ATM_REF + TTETAS * TTETAV * R_SURF) / (1 -(R_SURF * S) );
   R_TOA_TG = ( R_SURF * TG * TTETAS * TTETAV ) / (1 -(R_SURF * S) ) + ATM_REF * TG;
  
  RETURN, R_TOA_TG
  
 END