;-----------------------------------------
; NAME:
;  WRITE_MYSTIC_RPV_INPUT
; -------------------------
; PURPOSE:
; WRITES AN INPUT FILE FOR UVSPEC
; -------------------------
; PARAMETERS:(SEE LIBRADTRAN USER MANUAL)
; - FILENAME = NAME OF THE INPUT FILE TO BE WRITTEN BY THE ROUTINE
; - MC_BASENAME : NAME OF THE INTERMEDIATE AND OUTPUT FILES OF THE MYSTIC SOLVER 
; - PHOTON_NB: NB PHOTONS FOR SIMULATIONS
; - WL_MIN : LOWER WAVELENGTHN IN NM
; - WL_MAX : MAX WAVELENGTH IN NM 
; - SZA: SUN ZENITH ANGLE IN DEGREE
; - SAA: SUN AZIMUTH ANGLE IN DEGREE
; - VZA: VIEWING ZENITH ANGLE IN DEGREE
; - VAA: VIEW AZIMUTHM ANGLE IN DEGREE 
; - RPV_RHO_0, RPV_K, RPV_THETA_HG, RPV_OMEGA: VALUES OF THE RPV MODEL
; - O3: TOTAL COLUMNAR OZONE IN DU
; - WV: TOTAL COLUMNAR WATER VAPOUR IN kg/m2
; - AOT_SCALING_FACTOR: AEROSOL OPTICAL SCALING FACTOR THICKNESS
; - AERO_TYPE: 'CONTINENTAL_CLEAN', 'CONTINENTAL_AVERAGE', 'DESERT'
; 
; --------------------------------
; KEYWORDS:
;   /RPV_FILE : FILENAME OF A FILE CONTAINING A SPECTRAL RPV_MODEL
; -------------------------
; EXAMPLE:
; 
; -------------------------
; TROUBLE SHOOTING:
;
; -------------------------
; MODIFICATION HISTORY:
;        21 SEP 2014  - M BOUVET    - FIRST PROTOTYPE
;        15 JAN 2015  - B ALHAMMOUD - FIRST IMPLEMENTATION TO DIMITRI-V3.1A
;        06 FEB 2015  - B ALHAMMOUD - ADDED DATA_FILES_PATH
;
; VALIDATION HISTORY:
;        21 JAN 2015 -  B ALHAMMOUD - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION.
;                                  TESTED FOR PARASOL OVER LIBYA4
;        11 FEB 2015 -  B ALHAMMOUD - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION.
;                                  TESTED FOR PARASOL OVER LIBYA4
; -------------------------

PRO WRITE_MYSTIC_RPV_INPUT, FILENAME, MC_BASENAME, PHOTON_NB, WL_MIN, WL_MAX, SZA, SAA, VZA, VAA, RPV_RHO_0, RPV_K, RPV_THETA_HG, RPV_OMEGA, O3, WV, AOT_SCALING_FACTOR, AERO_TYPE, RPV_FILE=RPV_FILE


GET_LUN, LUN
OPENW, LUN, FILENAME

;;;;;;;;;;;;;;;;
; DEFINE OBSERVATION CONDITIONS
;;;;;;;;;;;;;;;;
PRINTF, LUN, 'zout toa'
PRINTF, LUN, 'sza '+STRING(SZA)
PRINTF, LUN, 'phi0 '+STRING(SAA)
PRINTF, LUN, 'umu '+STRING(COS(VZA*!PI/180.))
PRINTF, LUN, 'phi '+STRING(VAA)

;;;;;;;;;;;;;;;;
; ATMOSPHERIC PROFILE
;;;;;;;;;;;;;;;;
; WE SHOULD DEFINE THE FULL PATH OF LIBRADTRAN-1.7/DATA IN THE INPUT FILE'     
LIBRAD_DATA_DIR  = GET_DIMITRI_LOCATION('libRad_data')
 
PRINTF, LUN, 'data_files_path '+LIBRAD_DATA_DIR 
PRINTF, LUN, 'atmosphere_file midlatitude_summer'
PRINTF, LUN, 'dens_column O3 '+string(O3)
PRINTF, LUN, 'dens_column H2O '+string(WV*3.34272e21) ; HERE WE CONVERT THE VALUE FROM kg/m2 TO THE molecules/cm-2
;PRINTF, LUN, 'DENS_COLUMN NO2 0'
; I COULD USE THE PRESSURE FROM ECMWF HERE...

;;;;;;;;;;;;;;;;
; AEROSOLS
;;;;;;;;;;;;;;;;
PRINTF, LUN, 'aerosol_species_library OPAC'
PRINTF, LUN, 'aerosol_default'
IF AERO_TYPE EQ 'continental_average' THEN PRINTF, LUN, 'aerosol_species_file continental_average'
IF AERO_TYPE eq 'continental_clean' THEN PRINTF, LUN, 'aerosol_species_file continental_clean'
IF AERO_TYPE eq 'desert' THEN PRINTF, LUN, 'aerosol_species_file desert'
PRINTF, LUN, 'aerosol_scale_tau '+STRING(AOT_SCALING_FACTOR)

;;;;;;;;;;;;;;;;;
; SITE
;;;;;;;;;;;;;;;;
;PRINTF, LUN, 'ALTITUDE 0.1'  => DOESN'T WORK.. EXPERIMENT WITH MC_ELEVATION_FILE IF NOT POSSIBLE, PLAY WITH THE PRESSURE


;;;;;;;;;;;;;;;;
; SOLAR SPECTRUM
;;;;;;;;;;;;;;;;
PRINTF, LUN, 'solar_file kurudz_1.0nm.dat'
PRINTF, LUN, 'wavelength '+STRING(WL_MIN)+' '+STRING(WL_MAX)

;;;;;;;;;;;;;;;;
; ABSORPTION PARAMETERISATION
;;;;;;;;;;;;;;;;
PRINTF, LUN, 'correlated_k lowtran'
;PRINTF, LUN, 'MC_SPECTRAL_IS'; DO NOT USE UNLESS THE SPECTRAL ALBEDO IS CONSTANT OVER THE CHOSEN SPECTRAL INTERVAL!!!
;
;;;;;;;;;;;;;;;;;;;
; SOLVER 
;;;;;;;;;;;;;;;;;;;
PRINTF, LUN, 'rte_solver mystic'
PRINTF, LUN, 'mc_polarisation'
PRINTF, LUN, 'mc_backward'
PRINTF, LUN, 'mc_vroom on'
;PRINTF, LUN, 'mc_spherical' ; USING THIS OPTION MIGHT TAKE SOME TESTING... I FOUND WORSE FIT TO THE MERIS DATA AND CONVERGENCE ISSUES I DON'T HAVE WITH THE PPA

PRINTF, LUN, 'mc_photons '+STRING(PHOTON_NB)
PRINTF, LUN, 'mc_std'
PRINTF, LUN, 'mc_basename '+MC_BASENAME
PRINTF, LUN, 'mc_escape'

;;;;;;;;;;;;;;;;;;;
; OUTPUT SHOULD BE REFLECTANCE
;;;;;;;;;;;;;;;;;;;
PRINTF, LUN, 'reflectivity'

;;;;;;;;;;;;;;;;;;;
;  RPV PARAMS
;;;;;;;;;;;;;;;;;;;
IF KEYWORD_SET(RPV_FILE) THEN PRINTF, LUN, 'rpv_file '+RPV_FILE ELSE BEGIN
	PRINTF, LUN, 'rpv_rho0 '+STRING(RPV_RHO_0*RPV_OMEGA) ; !!!! IN THE MYSTIC IMPLEMENTATION, THE rho_c (AS PER RAMI DESCRIPTION) IS FORCED TO rpv_rho0. HERE WE HAVE USED rho_c=omega x rho_0
	PRINTF, LUN, 'rpv_k '+STRING(RPV_K)
	PRINTF, LUN, 'rpv_theta '+STRING(RPV_THETA_HG)
	PRINTF, LUN, 'rpv_scale '+STRING(1./RPV_OMEGA); !!!! IN THE MYSTIC IMPLEMENTATION, THE rho_0 (AS PER RAMI DESCRIPTION) IS THE PRODUCT OF rpv_rho0 and rpv_scale
endelse


PRINTF, LUN, 'quiet'


FREE_LUN, LUN



END
