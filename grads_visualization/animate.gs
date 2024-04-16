timex = 1

while( timex <= 5352)

timex=timex+7

'set mpdraw off'
'set grid off'
'set display white'
'clear'
'set grads off'
'set xlopts 1 5 0.2'
'set ylopts 1 5 0.20'
'set clab on'
'set digsiz 3'

*-----PCM DATA-----*
'sdfopen diagfi.nc '

'set t ' timex
'set lat -90 90'
'set lon 0'
'set z 1 15'

'set gxout shaded'
'set clevs -14 -12 -10 -8 -6 -4 -2 0 2 4 6 8 10 12'
'set ccols 9 14 4 11 5 13 3 10 7 12 8 2 6'
'd ave(v,lon=-180,lon=180)'
cbarn.gs

'set gxout contour'
'd ave(v,lon=-180,lon=180)'
'set clevs 1e-7 2.5e-7 5e-7 7.5e-7 1e-6 2e-6 3e-6 4e-6 5e-6 6e-6 7e-6 8e-6 9e-6'
'set ccolor 0'
'd ave(h2o_ice,lon=-180,lon=180)'

'close 1'

*-----TITLE & LABELS-----*
'draw string 9.75 0.25 m/s'
'draw string 0.4 4.75 km'

if (timex<1552)
'draw title Merid. Winds & Ice Clouds(kg/kg); 6.1 mb;Spring; Day 'timex/8''
endif 

if (timex >= 1552 & timex <2976)
'draw title Merid. Winds & Ice Clouds(kg/kg); 6.1 mb;Summer; Day 'timex/8''
endif 

if (timex >= 2976 & timex <4120)
'draw title Merid. Winds & Ice Clouds(kg/kg); 6.1 mb;Fall; Day 'timex/8''
endif 

if (timex >= 4120 & timex <=5352)
'draw title Merid. Winds & Ice Clouds(kg/kg); 6.1 mb;Winter; Day 'timex/8''
endif 


*-----PRINT-----*

if (timex<10)
'printim img_000'timex'.png x1100 y700 white'
endif 

if (timex >= 10 & timex <100)
'printim img_00'timex'.png x1100 y700 white'
endif

if (timex >= 100 & timex <1000)
'printim img_0'timex'.png x1100 y700 white'
endif

if (timex >= 1000)
'printim img_'timex'.png x1100 y700 white'
endif


timex = timex + 1
'clear'

endwhile

'quit'

*-----SAVED CLEVS & CCOLS-----*

*updated ice
*set ccols 0 4 11 5 13 3 10 7 12 8 2 6

*Temperature/Ice
*set clevs 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215'
*'set ccols 9 14 4 11 5 13 3 10 7 12 8 2 6'

*Ash
*'set clevs 2 5 10 15 20 25 30 35 40 45 50'
*'set ccols 0 17 19 21 22 8 23 24 27 26 25 2 6

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

*superscript example 10`a5 `nkg/s Eruption
*degree symbol [value]`3.

