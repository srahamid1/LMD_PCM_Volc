timex = 1

while( timex <= 96)

timex=timex+1

'set mpdraw off'
'set grads off'
'set grid off'

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

'sdfopen diagfi.nc '

'set xlopts 1 5 0.15'
'set ylopts 1 5 0.15'
'set t ' timex
'set clab on'
'set z 15' 

*'set lon 0 360'
'set gxout shaded'
'set digsiz 2'
'set clevs .0001 .001 .002 .003 .004 .005 .006 .007 .008 .009'
'set ccols 0 30 31 32 33 34 35 36 37 38 61 71 15'
'd h2o_ice'

*'set lon -360 0'
*'set gxout shaded'
*'set digsiz 2'
*'set clevs -50 -40 -30 -20 -10 0 10 20 30'
*'set ccols 9 14 4 11 5 13 3 10 7 12 8 2 6'
*'d u'
cbarn.gs
'close 1'

'open surface.ctl'
'set gxout contour'

*'set lon 0 360'
'set clevs -6 -3 0 3 6 9 12 15 18'
'set ccolor 1'
'set clab off'
'd zmol'

*'set lon -360 0'
*'set clevs -6 -3 0 3 6 9 12 15 18'
*'set ccolor 1'
*'set clab off'
*'d zmol'
'close 1'

timextime=timex/2
'draw title H2O Ice Clouds at 45km \ Hours since Meroe eruption start='timextime' \ Spring (Ls=0); column height=45 km; water flux= 10`a9 `nkg/s'
'draw string 10 0.375 kg/kg'


* Final print command

if (timex<10)
'printim img_000'timex'.png x800 y600 white'
endif 

if (timex >= 10 & timex <100)
'printim img_00'timex'.png x800 y600 white'
endif

if (timex >= 100 & timex <1000)
'printim img_0'timex'.png x800 y600 white'
endif

if (timex >= 1000)
'printim img_'timex'.png x800 y600 white'
endif


timex = timex + 1
'clear'

endwhile

'quit'

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


