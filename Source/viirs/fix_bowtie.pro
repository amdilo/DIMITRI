FUNCTION FIX_BOWTIE, TOA_REF, LAT, LON, FLAG

SPATIAL_RESOLUTION=750
OVER_SAMPLE = 0.35
;------------------------------------------------
; Create a new regularly spaced lat lon grid.
; NOTE, Lat Lon dimensions come in transposed compared to TOA for some reason ??
; Transpose them here for consistency and easier looping.?

;FLAG = -1000.70 ; the flag got scaled to this when applying the scaling factor in the 'getter' routine  


;------------------------------------------------
; Get rid of the black stripes that VIIRS adds to the data files
; and the corresponding lat longs

; ASSUMING HERE THAT BECAUSE THE SCAN IS ORTHOGONAL TO THE OBIT, STRIPES
; ARE ALWAYS ALONG THE ROWS.  NEED TO CHECK THIS
; TODOD !

DIM_TOA_REF = SIZE(TOA_REF, /DIMENSIONS)
NUM_COLS = DIM_TOA_REF[1] ; NEED TO STORE THIS TO RESHAPE TOA_REF LATER.  

IND = WHERE(TOA_REF NE FLAG)
TOA_REF = TOA_REF[IND]
LAT = LAT[IND]
LON = LON[IND]

DIM_TOA_REF = SIZE(TOA_REF, /DIMENSIONS) ; IT CHANGED SIZE AFTER REMOVING STRIPES

NUM_NEW_ROWS = DIM_TOA_REF[0]/NUM_COLS

;TOA_REF = REFORM(TOA_REF, NUM_COLS, NUM_NEW_ROWS)
;LAT = REFORM(LAT, NUM_COLS, NUM_NEW_ROWS)
;LON = REFORM(LON, NUM_COLS, NUM_NEW_ROWS)
;DIM_TOA_REF = SIZE(TOA_REF, /DIMENSIONS)
;reform instead of reshape.

;------------------------------------------------
; calculate the distance of the corners of the image. 
; Then divide the total distance by the desired spatial resolution to give the grid size we need

CRN_1 = [MIN(LAT), MIN(LON)]
CRN_2 = [MIN(LAT), MAX(LON)]
CRN_3 = [MAX(LAT), MIN(LON)]
CRN_4 = [MAX(LAT), MAX(LON)]

Y_GRID_DISTANCE = CALC_LAT_LON_DISTANCE([CRN_1[0], CRN_2[0]], [CRN_1[1], CRN_2[1]]); seperate that lats on lons again
X_GRID_DISTANCE = CALC_LAT_LON_DISTANCE([CRN_1[0], CRN_3[0]], [CRN_1[0], CRN_3[0]])


;------------------------------------------------
; THE DIFFERENCE BETWEEN GRID DISTANCE AND IMAGE DISTANCE IS, 
; THE IMAGE MAY BE SMALLER BUT LAY WITHING THE GRID.
; 
; CORNERS ARE
;  ------
;  |1   2|
;  |     |
;  |3   4|
;  -------


Y_IMAGE_DISTANCE = CALC_LAT_LON_DISTANCE([CRN_1[0], CRN_2[0]], [CRN_1[1], CRN_2[1]]); seperate that lats on lons again
X_IMAGE_DISTANCE = CALC_LAT_LON_DISTANCE([CRN_1[0], CRN_3[0]], [CRN_1[0], CRN_3[0]])

NUM_X_GRID = ROUND(X_IMAGE_DISTANCE / SPATIAL_RESOLUTION) 
NUM_Y_GRID = ROUND(Y_IMAGE_DISTANCE / SPATIAL_RESOLUTION)

NUM_X_GRID = NUM_X_GRID * OVER_SAMPLE
NUM_Y_GRID = NUM_Y_GRID * OVER_SAMPLE

MIN_LAT = MIN(LAT)
MIN_LON = MIN(LON)
MAX_LAT = MAX(LAT)
MAX_LON = MAX(LON)

DELTA_LAT = ABS((MAX_LAT - MIN_LAT) / (NUM_X_GRID - 1))
DELTA_LON = ABS((MAX_LON - MIN_LON) / (NUM_Y_GRID - 1))

;------------------------------------------------
; Initialise the grid to have negative -1 so that later we can tell if we put a number in there or not.
GRID = MAKE_ARRAY(NUM_Y_GRID, NUM_X_GRID, VALUE=-1, /FLOAT)
LAT_GRID = MAKE_ARRAY(NUM_Y_GRID, NUM_X_GRID, VALUE=-1, /FLOAT)
LON_GRID = MAKE_ARRAY(NUM_Y_GRID, NUM_X_GRID, VALUE=-1, /FLOAT)

FOR I_ITER=0l, DIM_TOA_REF[0] - 1 DO BEGIN ; ROW 
  ;FOR J_ITER=0l, DIM_TOA_REF[0] - 1 DO BEGIN ; COLUMN?
    ;------------------------------------------------
    ; figure out which index in our grid our lat lon belongs too
    
    ;------------------------------------------------
    ; look to see if we are flagged, if we are we don't add the data point to the new grid
    IF TOA_REF[I_ITER] NE FLAG THEN BEGIN

       X_INDEX = UINT(((LAT[I_ITER] - MIN_LAT) / DELTA_LAT)) ; Subtract 1 becuase we index from 0
       Y_INDEX = UINT(((LON[I_ITER] - MIN_LON) / DELTA_LON))
       
       ;------------------------------------------------
       ; Check if value allready exits.  If it does, average the values together.
       IF GRID[Y_INDEX, X_INDEX] NE -1 THEN BEGIN ; must have a number allready there so average them together
       GRID[Y_INDEX, X_INDEX] = (TOA_REF[I_ITER] + GRID[Y_INDEX, X_INDEX]) / 2.0
       ;------------------------------------------------
       ; update the new lat and long gerd
       LAT_GRID[Y_INDEX, X_INDEX] = LAT[I_ITER]
       LON_GRID[Y_INDEX, X_INDEX] = LON[I_ITER]
       ENDIF ELSE BEGIN
         GRID[Y_INDEX, X_INDEX] = TOA_REF[I_ITER]
         ;------------------------------------------------
         ; update the new lat and long grid
         LAT_GRID[Y_INDEX, X_INDEX] = LAT[I_ITER]
         LON_GRID[Y_INDEX, X_INDEX] = LON[I_ITER]
       ENDELSE
    ENDIF 
  ;ENDFOR
ENDFOR

; GET RID OF -1'S BEFORE RETURNING

;TOA_REF = REFORM(TOA_REF, NUM_COLS, NUM_NEW_ROWS)
;LAT = REFORM(LAT, NUM_COLS, NUM_NEW_ROWS)
;LON = REFORM(LON, NUM_COLS, NUM_NEW_ROWS)

GRID = GRID > 0
LAT_GRID = LAT_GRID > 0 
LON_GRID = LON_GRID > 0

RETURN, {TOA_REF:GRID, LAT:LAT_GRID, LON:LON_GRID}

END