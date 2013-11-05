;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     TAUR_HT74
;* 
;* PURPOSE:
;*      COMPUTE HANSEN & TRAVIS 1974 RAYLEIGH OPTICAL THICKNESS AT GIVEN BAND.
;*      NO CORRECTION FOR PRESSURE. DEPOLARISATION FACTOR IS DELTA=0.029 (YOUNG 1980)
;* 
;* CALLING SEQUENCE:
;*      RES = TAUR_HT74(WAV)
;* 
;* INPUTS:
;*      WAV  - THE WAVELENGTH IN NM
;*
;* KEYWORDS:
;*      VERBOSE          - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      TAUR             - RAYLEIGH OPTICAL THICKNESS
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - WINDOWS 32-BIT MACHINE IDL 8.0 AND LINUX 64-BIT MACHINE 
;*                                  IDL 8.0, NOMINAL COMPILATION AND OPERATION.
;*
;**************************************************************************************

FUNCTION TAUR_HT74, WAV

;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME

 FCT_NAME = "TAUR_HT74"

;-----------------------------------------
; COMPUTE TAUR

 WAV_ = WAV/1000 ; CONVERT IN MICROM
 TAUR = 8.524E-3*WAV_^(-4) + 9.63E-5*WAV_^(-6)+1.1E-6*WAV_^(-8)

RETURN, TAUR
END
