function test_calc_lat_lon_distance

  perth_lat = -31.95224
  perth_lon = 115.8614
  
  sydney_lat = -33.86148
  sydney_lon = 151.20548
  
  lat = [perth_lat, sydney_lat]
  lon = [perth_lon, sydney_lon]
  
  perth_sydney_distance = 3293872
  
  distance = calc_lat_lon_distance(lat, lon)

  if round(perth_sydney_distance) eq round(distance) then return, 1 else return, 0

end