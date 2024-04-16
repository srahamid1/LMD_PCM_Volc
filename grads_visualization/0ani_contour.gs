*---SET COLORS---*
'set rgb 17 255 239 223'
'set rgb 19 255 203 151'
'set rgb 21 255 151 47'
'set rgb 22 251 125 0'
'set rgb 23 204 102 0'
'set rgb 24 117  58 0'
'set rgb 25 220  36 16'
'set rgb 26 147  24 11'
'set rgb 27 101  17 7'
'set rgb 30 218 239 255'
'set rgb 31 193 216 248'
'set rgb 32 180 196 229'
'set rgb 33 155 180 220'
'set rgb 34 139 155 206'
'set rgb 35 110 137 188'
'set rgb 36 79 104 174'
'set rgb 37 59 105 178'
'set rgb 38 55 87 165'
'set rgb 39 192 214 228'
'set rgb 40 168 193 210'
'set rgb 41 144 171 193'
'set rgb 42 121 151 175'
'set rgb 43 99 130 158'
'set rgb 44 77 110 142'
'set rgb 45 56 91 125'
'set rgb 46 34 72 109' 
'set rgb 47 30 61 255' 
'set rgb 48 121 43 238' 
'set rgb 49 162 15 219'
'set rgb 50 190 0 200'
'set rgb 51 210 0 181'
'set rgb 52 224 0 163'
'set rgb 53 234 0 146'
'set rgb 54 240 0 130'
'set rgb 55 210 254 255'
'set rgb 56 255 252 189'
'set rgb 57 255 189 102'
'set rgb 58 245 169 56'
'set rgb 59 32 95 154'
'set rgb 60 6 82 129'
'set rgb 61 0 63 92'
'set rgb 62 12 17 34'
'set rgb 63 255 252 63'
'set rgb 64 255 240 51'
'set rgb 65 255 228 39'
'set rgb 66 255 215 28'
'set rgb 67 255 203 18'
'set rgb 68 255 191 8'
'set rgb 69 255 178 1'
'set rgb 70 255 166 0'
'set rgb 71 1 34 40'

*_______________________________________________________________________________

*---GRADS STUFF---*
'set mpdraw off'
'set grid off'
'set display white'
'clear'
'set grads off' 

*---LOAD PCM DATA---*
'sdfopen diagfi.nc'

'set xlopts 1 5 0.15'
'set ylopts 1 5 0.15'
'set grads off'
'set gxout shaded'
'set digsiz 2'
'set t 48'

*_______________________________________________________________________________

*---SET LAT/LON (LEFT)---*
'set lon 0 360'
*'set lon 140 180'
*'set lat -25 5'

*---ASH IN COLUMN---*
*'set clevs 0 .0001 .001 .01 .1 1 5 10 15 25 50 75 100 115 119'
*'set ccols 0 0 17 19 21 22 8 23 24 27 26 25 2 6 15'
*'d volc_1_col+volc_2_col+volc_3_col+volc_4_col+volc_5_col+volc_6_col'

*---SURFACE ASH---*
*'set clevs 0 .001 .01 .1 1 5 10 16 25 50 75 100 150 175 185'
*'set ccols 0 0 17 19 21 22 8 23 24 27 26 25 2 6 15'
*'d volc_1_surf+volc_2_surf+volc_3_surf+volc_4_surf+volc_5_surf+volc_6_surf'

*---SNOW---*
*'set clevs 0 .0001 .0003 .0006 .0009 .0012 .0015 .0018 .0021 .0024 .0027 .003'
*'set ccols 0 0 30 31 32 33 34 35 36 37 38 61 71 15'
*'d snow'

*---AVG SNOW---*
'set clevs 0 1e-5 2e-5 3e-5 4e-5 5e-5 6e-5 7e-5 8e-5 1e-4 1e-3 3e-3'
*'set clevs 0 .0001 .0003 .0006 .0009 .0012 .0015 .0018 .0021 .0024 .0027 .003'
'set ccols 0 0 30 31 32 33 34 35 36 37 38 61 71 15'
'd ave(snow,t=1,t=48)'

*---SURFACE ICE---*
*'set clevs 0 .01 .1 1 5 10 25 75 150 200 240 270'
*'set ccols 0 0 30 31 32 33 34 35 36 61 71 15'
*'set ccols 0 0 30 31 32 33 34 35 36 37 38 61 71 15'
*'d h2o_ice_surf'

*---AVG RH---*
*'set clevs 0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1'
*'set ccols 0 0 47 48 49 50 51 52 53 54 2'
*'d ave(rh,t=1,t=48)'


*_______________________________________________________________________________

*---SET LAT/LON (RIGHT)---*
'set lon -360 0'
*'set lon -180 -162'
*'set lat -20 5'

*---ASH IN COLUMN---*
*'set clevs 0 .0001 .001 .01 .1 1 5 10 15 25 50 75 100 115 119'
*'set ccols 0 0 17 19 21 22 8 23 24 27 26 25 2 6 15'
*'d volc_1_col+volc_2_col+volc_3_col+volc_4_col+volc_5_col+volc_6_col'

*---SURFACE ASH---*
*'set clevs 0 .001 .01 .1 1 5 10 16 25 50 75 100 150 175 185'
*'set ccols 0 0 17 19 21 22 8 23 24 27 26 25 2 6 15'
*'d volc_1_surf+volc_2_surf+volc_3_surf+volc_4_surf+volc_5_surf+volc_6_surf'

*---SNOW---*
*'set clevs 0 .0001 .0003 .0006 .0009 .0012 .0015 .0018 .0021 .0024 .0027 .003'
*'set ccols 0 0 30 31 32 33 34 35 36 37 38 61 71 15'
*'d snow'

*---AVG SNOW---*
'set clevs 0 1e-5 2e-5 3e-5 4e-5 5e-5 6e-5 7e-5 8e-5'
*'set clevs 0 .0001 .0003 .0006 .0009 .0012 .0015 .0018 .0021 .0024 .0027 .003'
'set ccols 0 0 30 31 32 33 34 35 36 37 38 61 71 15'
'd ave(snow,t=1,t=48)'

*---SURFACE ICE---*
*'set clevs 0 .01 .1 1 5 10 25 75 150 200 240 270'
*'set ccols 0 0 30 31 32 33 34 35 36 61 71 15'
*'set ccols 0 0 30 31 32 33 34 35 36 37 38 61 71 15'
*'d h2o_ice_surf'

*---AVG RH---*
*'set clevs 0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1'
*'set ccols 0 0 47 48 49 50 51 52 53 54 2'
*'d ave(rh,t=1,t=48)'

cbar
'close 1'

*_______________________________________________________________________________


*---MOLA---*
'open surface.ctl'
'set xlopts 1 5 0.15'
'set ylopts 1 5 0.15'
'set gxout contour'
'set clab off'

*---ZOOMED IN (LEFT)---*
*'set lon 140 180'

*---ZOOMED IN (RIGHT)---*
*'set lon -180 -160'

*'set lat -25 5'
*'set clevs -3 -2.5 -2 -1.5 -1 -0.5 0 0.5 1'
*'set ccolor 1'
*'set clab off'
*'d zmol'

*---ZOOMED OUT---*
'set lon 0 360'
'set clevs -6 -3 0 3 6 9 12 15 18'
'set ccolor 1'
'set clab off'
'd zmol'

'set lon -360 0'
'set clevs -6 -3 0 3 6 9 12 15 18'
'set ccolor 1'
'set clab off'
'd zmol'

'close 1'

*_______________________________________________________________________________


*---TITLE & LABELS---*
*'draw title Surface Ice 10`a8 `nkg/s Eruption'
*'draw title Surface Ash Following 1 Day 10`a8 `nkg/s Eruption'
*'draw title 10`a8 `nkg/s Apollinaris 1 Day Eruption \ Snow'
'draw title Apollinaris Mons \ Average Rate of Snowfall \ 1-Day Eruption; Water flux = 10`a8 `nkg/s; Column height=35km'
*'draw title 10`a8 `nkg/s 1 Day Eruption \ Average Relative Humidity'

*'draw string 9.9 .39 mm/s'
'draw string 5.5 .29 mm/s'

*---SAVE---*
*create vector file*
*'gxprint _ash_surf_all_sizes_10^8.eps'
*'gxprint _10^8_ice_surf_right.eps'
*'gxprint _10^8_ice_surf_left.eps'
'gxprint _10^8_avg_snow_35km.eps'
*'gxprint _10^8_avg_snow_left.eps'
*'gxprint _10^8_avg_snow_right.eps'
*'gxprint _10^8_rh_left.eps'
*'gxprint _10^8_rh_right.eps'
*'gxprint _contours_left.eps'
*'gxprint _contours_right.eps'

*'quit'

*_______________________________________________________________________________


*---COLORS---*

*updated ice
*set ccols 0 4 11 5 13 3 10 7 12 8 2 6
*set ccols 0 47 48 49 50 21 52 53 54


*Temperature/Ice
*set clevs 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215'
*'set ccols 9 14 4 11 5 13 3 10 7 12 8 2 6'

*Ash
*'set clevs 2 5 10 15 20 25 30 35 40 45 50'
*'set ccols 0 17 19 21 22 8 23 24 27 26 25 2 6'

*blue–red from Forget et al 2006
*use random #'s above 15 then set in ccols
*set rgb 16 210 254 255 *gives light blue
*set rgb 17 255 252 189 *light yellow 
*set rgb 18 255 189 102 *light orange
*set rgb 19 245 169 56 *bold orange
*set ccols 0 16 17 18 19 8 2

*blue gradient from Forget et al 2006
*'set rgb 30 218 239 255'
*'set rgb 31 193 216 248'
*'set rgb 32 180 196 229'
*'set rgb 33 155 180 220'
*'set rgb 34 139 155 206'
*'set rgb 35 110 137 188'
*'set rgb 36 79 104 174'
*'set rgb 37 59 105 178'
*'set rgb 38 55 87 165'
*set ccols 0 30 31 32 33 34 35 36 37 38
*extra dark blue
*'set rgb 0 63 92'

*Blue to hot pink
*'set rgb 47 30 61 255' 
*'set rgb 48 121 43 238' 
*'set rgb 49 162 15 219'
*'set rgb 50 190 0 200'
*'set rgb 51 210 0 181'
*'set rgb 52 224 0 163'
*'set rgb 53 234 0 146'
*'set rgb 54 240 0 130'

*sulfur yellow
*'set rgb 63 255 252 63'
*'set rgb 64 255 240 51'
*'set rgb 65 255 228 39'
*'set rgb 66 255 215 28'
*'set rgb 67 255 203 18'
*'set rgb 68 255 191 8'
*'set rgb 69 255 178 1'
*'set rgb 70 255 166 0'

*---EXTRA---*
*superscript example 10`a5 `nkg/s Eruption

