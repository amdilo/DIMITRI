pro remove_data_from_database

;load the db data
; find index of all sensors which aren't aatsr or atsr2
; create a new db structure and fill with good values
;sav the new db data as the database


;--------------------------
; LOAD THE DATABASE INTO A COMMON BLOCK

  DB_FILE = GET_DIMITRI_LOCATION('DATABASE')
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DHMI_DB_DATA = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)
  
  res = where(DHMI_DB_DATA.sensor ne 'MERIS' and DHMI_DB_DATA.sensor ne 'MODISA',count)
  new_db_data = GET_DIMITRI_TEMPLATE(count,/db)
  num_tags = n_tags(new_db_data)
   
  for i=0,num_tags-1 do  new_db_data.(i)[*] = DHMI_DB_DATA.(i)[res]
  
  res = SAVE_DIMITRI_DATABASE(new_db_data)
  
  end