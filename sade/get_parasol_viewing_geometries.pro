;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     GET_PARASOL_VIEWING_GEOMETRIES     
;* 
;* PURPOSE:
;*     RETURNS THE SITE AVERAGE PARASOL VZA AND VAA VALUES FOR EACH BAND AND DIRECTION 
;* 
;* CALLING SEQUENCE:
;*      RES = GET_PARASOL_VIEWING_GEOMETRIES(PNAME,ICOORDS,SITE) 
;* 
;* INPUTS:
;*      PNAME   - THE PARASOL PRODUCT NAME
;*      ICOORDS - THE LAT AND LON COORDINATES OF THE SITE [NLAT,SALT,ELON,WLON]
;*      SITE    - THE SITE NAME
;*      
;* KEYWORDS:
;*
;* OUTPUTS:
;*      COMPANG - THE COMPUTE VZA AND VAA ANGLES FOR EACH BAND AND DIRECTION
;*      
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      16 DEC 2011 - C KENT  - INITIAL DIMITRI VERSION
;*
;* VALIDATION HISTORY:
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_PARASOL_VIEWING_GEOMETRIES,PNAME,ICOORDS,SITE

;--------------------------
; FIND THE DATA PRODUCT

  IFOLDER = get_dimitri_location('INPUT');'/mnt/USB_drive/DIMITRI/DIMITRI_2.0/Input/'
  DL=PATH_SEP()
  FF = IFOLDER+'Site_'+SITE+DL+'PARASOL'+DL+'Proc_Calibration_1'+DL
  NAME = FILE_SEARCH(FF,PNAME)
  COMPANG = MAKE_ARRAY(9,16,2,/FLOAT)
  IF NAME EQ '' THEN STOP

;--------------------------
; READ IN THE DATA

  L1B_DATA = GET_PARASOL_L1B_DATA(NAME[0]) 

;--------------------------
; GET INDEX OF GOOD DATA WITHIN ICOORDS

  FOR INDIRECTION=0,15 DO BEGIN
    ROI_INDEX = WHERE($
                L1B_DATA.LATITUDE LT ICOORDS[0] AND $
                L1B_DATA.LATITUDE GT ICOORDS[1] AND $
                L1B_DATA.LONGITUDE LT ICOORDS[2] AND $
                L1B_DATA.LONGITUDE GT ICOORDS[3] AND $;)
                L1B_DATA.REF_443NP[INDIRECTION] GT 0.0) 
    TEMPIXVZA = MAKE_ARRAY(N_ELEMENTS(ROI_INDEX),9,/FLOAT)
    TEMPIXVAA = MAKE_ARRAY(N_ELEMENTS(ROI_INDEX),9,/FLOAT)
    FOR IPIX = 0,N_ELEMENTS(ROI_INDEX)-1 DO BEGIN
      PVZA = L1B_DATA[ROI_INDEX[IPIX]].VZA[INDIRECTION]
      PRAA = L1B_DATA[ROI_INDEX[IPIX]].RAA[INDIRECTION]
      PDVZC = L1B_DATA[ROI_INDEX[IPIX]].DELTA_AV_COS_A[INDIRECTION]
      PDVZS = L1B_DATA[ROI_INDEX[IPIX]].DELTA_AV_SIN_A[INDIRECTION]
      NEWANGLES = COMPUTE_PARASOL_VIEWING_GEOMETRIES(PVZA,PRAA,PDVZC,PDVZS,/ORDER)
      TEMPIXVZA[IPIX,*] = NEWANGLES.VZA
      TEMPIXVAA[IPIX,*] = NEWANGLES.RAA
    ENDFOR
    FOR IPBAND=0,9-1 DO BEGIN
      NVZA = MEAN(TEMPIXVZA[*,IPBAND])
      NVAA = MEAN(L1B_DATA[ROI_INDEX].SAA-TEMPIXVAA[*,IPBAND])
      TEMP_ANGLES = DIMITRI_ANGLE_CORRECTOR(NVZA,NVAA,0.0,0.0)
      COMPANG[IPBAND,INDIRECTION,0] = TEMP_ANGLES.VZA
      COMPANG[IPBAND,INDIRECTION,1] = TEMP_ANGLES.VAA
    ENDFOR
  ENDFOR

;--------------------------
; RETURN THE DATA
  
  RETURN,COMPANG

END