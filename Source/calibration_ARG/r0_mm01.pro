;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*    R0_MM01 
;* 
;* PURPOSE:
;*      COMPUTE MOREL AND MARITORENA 2001 MARINE IRRADIANCE REFLECTANCE AT NULL DEPTH (0-)
;*      AS FUNCTION OF CHLOROPHYLL AND SUN ZENITH ANGLE
;* 
;* CALLING SEQUENCE:
;*      RES = R0_MM01(WAV, CHL, SZA)
;* 
;* INPUTS:
;*      WAV  - THE WAVELENGTH IN NM
;*      CHL  - THE CHL CONCENTRATION IN MG/M3
;*      SZA  - THE SOLAR ZENITH ANGLE IN DEGREES
;*
;* KEYWORDS:
;*      VERBOSE       - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      R             - MARINE RADIANCE REFLECTANCE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION.
;*
;**************************************************************************************
FUNCTION R0_MM01, WAV, CHL, SZA, VERBOSE=VERBOSE

;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME

 FCT_NAME = "R0_MM01"

;-----------------------------------------
; CHECK INPUTS CORRESPOND TO
; A ONE-DIMENSIONNAL ARRAY

 S0 = SIZE(CHL,/N_DIMENSIONS)
 S1 = SIZE(SZA,/N_DIMENSIONS)

 IF (S0 NE 1 OR S1 NE 1) THEN BEGIN
   PRINT, FCT_NAME+":ERROR, WORKS ONLY FOR 1D ARRAY"
   RETURN, -1
 ENDIF

;-----------------------------------------
; CHECK INPUTS HAVE THE SAME DIMENSION
 
 N0 = N_ELEMENTS(CHL)
 N1 = N_ELEMENTS(SZA)
 IF N0 NE N1 THEN BEGIN
   PRINT, FCT_NAME+":ERROR, INPUTS DON'T HAVE SAME DIMENSION"
   RETURN, -1
 ENDIF



 ;-----------------------------------------
 ; CHECK CHL RANGE

 INDEX=WHERE(CHL LT 0.01)
 IF INDEX[0] NE -1 THEN BEGIN
   PRINT, FCT_NAME+": WARNING, SOME CHL ARE LOWER THAN 0.01, STICK TO THIS VALUE"
   CHL[INDEX]=0.01
 ENDIF

 ;-----------------------------------------
 ; COMPUTE ABSORPTION AND SCATTERING COEF OF PURE WATER

 ABW = COMPUTE_AW_BW(WAV, VERBOSE=VERBOSE)
 AW  = ABW[0]
 BW  = ABW[1]

 ;-----------------------------------------
 ; COMPUTE MOREL E AND CHI

 ECHI = COMPUTE_E_CHI(WAV, VERBOSE=VERBOSE)
 E    = ECHI[0]
 CHI  = ECHI[1]

 ;-----------------------------------------
 ; COMPUTE KD
 KW = AW + 0.5*BW
 KD = KW + CHI*(CHL^E)

 ;-----------------------------------------
 ; COMPUTE BACKSCATTERING 

 NU = DBLARR(N0)
 INDEX=WHERE(CHL LT 0.02)
 IF INDEX[0] NE -1 THEN NU[INDEX]=-1.
 INDEX = WHERE(CHL GE 0.02 AND CHL LT 2.)
 IF INDEX[0] NE -1 THEN NU[INDEX]=0.5*(ALOG10(CHL[INDEX])-0.3)
 INDEX = WHERE(CHL GE 2.)
 IF INDEX[0] NE -1 THEN NU[INDEX] =0.

 BBP = (0.416*CHL^0.766)*(2.E-3 +1.E-2*(0.5-0.25*ALOG10(CHL))*(WAV/550.)^NU) 
 BB  = 0.5*BW + BBP

 ;IF CHL LT 0.02 THEN NU=-1 ELSE BEGIN
 ;  IF CHL LT 2. THEN NU=0.5*(ALOG10(CHL)-0.3) ELSE NU =0
 ;ENDELSE
 ;BBP = (0.416*CHL^0.766)*(2.E-3 +1.E-2*(0.5-0.25*ALOG10(CHL))*(WAV/550.)^nu) 
 ;BB  = 0.5*BW + BBP


 ;-----------------------------------------
 ; COMPUTE ILLUMINATION CONSTANTS
 
 F   = 0.33
 MUU = 0.4
 MUD = COMPUTE_MUD(WAV,CHL, SZA, VERBOSE=VERBOSE) 

 ;-----------------------------------------
 ; LOOP TO RETRIEVE R(0-)

 U=0.75
 FOR I=0, 2 DO BEGIN

    R0 = F/U*BB/KD
    U  = MUD*(1.-R0)/(1.+MUD/MUU*R0)

 ENDFOR

 RETURN, R0

END
