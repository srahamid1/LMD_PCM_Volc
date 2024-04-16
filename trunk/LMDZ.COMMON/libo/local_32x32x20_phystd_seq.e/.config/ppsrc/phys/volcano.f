












      SUBROUTINE volcano(ngrid,nlay,pplev,wu,wv,pt,zzlev,
     &                    ssource,nq,massarea,cell_area)

      use tracer_h
      use comgeomfi_h
      use comcstfi_mod, only: pi, g
      use geometry_mod, only: longitude, latitude ! in radians
      IMPLICIT NONE

c=======================================================================
c   Explosive volcanic eruptions (for running in serial)
c
c   To use the model :
c     1) LOOK FOR THE FLAG CALLED "volcano_setup" IN initracer.F :
c       a. SET THE callvolcano LOGICAL TO .true.
c       b. DEFINE THE CLAST SIZES (radius), NAMES (noms), AND
c       DENSITIES (rho_q) AT THE SAME PLACE IN initracer.F.
c     2) IN volcano.F, FILL IN THE SECTION CALLED "Parameters".
c
c   Description :
c       Formation of tephras and accretionary lapilli and dispersal by
c       the LMD/GCM.
c
c     Author : Lionel Wilson
c     Adapted for the LMD/GCM by Laura Kerber and J.-B. Madeleine
c
c   Reference :
c       @ARTICLE{2007JVGR..163...83W,
c       author = {{Wilson}, L. and {Head}, J.~W.},
c       title = "{Explosive volcanic eruptions on Mars: Tephra and
c       accretionary lapilli formation, dispersal and recognition in the
c       geologic record}",
c       journal = {Journal of Volcanology and Geothermal Research},
c       year = 2007,
c       month = jun,
c       volume = 163}
c=======================================================================

c     Variable statement
c     __________________________________________________________________

!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 32,jjm=32,llm=20,ndm=1)

!-----------------------------------------------------------------------
!#include "dimphys.h"
!#include "comcstfi.h"

c Parameters
c ----------

c PLEASE DEFINE THE LOCATION OF THE ERUPTION BELOW :
c =============================================
c     Coordinate of the volcano (degrees) :
c       ex : Apollinaris Patera lon=174.4 and lat=-9.3
      REAL, parameter :: lon_volc = 174.4
      REAL, parameter :: lat_volc = -9.3 
c       ex : Elysium Mons lon=147 and lat=24.8
c       ex : Cerberus lon=176.6 and lat=9.0
c       ex : Olympus Mons lon=-133.9 and lat=18.7
c       ex : Arsia Mons lon=-120.46 and lat=-9.14
c       ex : Pavonis Mons lon=-112.85 and lat= 0.662
c       ex : Ascraeus Mons lon=-104.37 and lat= 11.1
c       ex : Syrtis Major lon=66.4 and lat= 9.85
c       ex : Tyrrhenia Patera lon=106.55 and lat= -21.32
c       ex : Hadriaca Patera lon=92.18 and lat= -30.44
c       ex : Peneus Patera lon=60.76 and lat= -58.05
c       ex : Alba Patera lon=-111.11 and lat= 39.19
c       ex : Amphritites lon=52.66 and lat= -58.00
c       ex : Hecates lon=150.08 and lat=31.68
c       ex : Pityusa Patera lon=36.87 and lat=-66.77
c       ex : Malea Patera lon=50.96 and lat=-63.09
c       ex : Electris volcano lon=-173.21 and lat =-37.35
c     Source flux (kg/s)
       REAL, parameter :: mmsource = 1.E8  !Mastin et al. 2009
      REAL, parameter :: wsource = 1.E6 ! 1wt% magma water content(Greeley 1987)
       REAL, parameter :: sulfsource = 1.E9
c =============================================
c Local variables
c ---------------

      INTEGER :: i, j, l
      INTEGER :: iq                     ! Tracer identifier
      INTEGER :: ig
      REAL :: dlon(iim), dlat(jjm+1), cell_area, massarea(ngrid,nlay)
      REAL :: msource(nq)
      INTEGER,SAVE :: ivolc            ! volcano grid point
      LOGICAL :: firstcall
      DATA firstcall/.true./
      SAVE :: firstcall
      CHARACTER(LEN=20) :: tracername  ! to temporarily store text
c Inputs
c ------

      INTEGER :: nq               ! Number of tracers
      INTEGER :: ngrid            ! Number of grid points
      INTEGER ::  nlay            ! Number of vertical levels
      REAL :: pplev(ngrid,nlay+1) ! Pressure between the layers (Pa)
      REAL :: zzlev(ngrid,nlay+1) ! height between the layers (km)
      REAL :: wv(ngrid,nlay+1)    ! wind
      REAL :: wu(ngrid,nlay+1)    ! wind
      REAL :: pt(ngrid,nlay+1)    ! temp

c Outputs
c -------
      REAL :: ssource(ngrid,nlay,nq)    ! Source tendency (kg.kg-1.s-1)
      REAL :: index(nq)              ! Drop height usage: zzlev(index) 
c     Initialization
c     __________________________________________________________________
   
c      call zerophys(ngrid*nlay*nq, ssource)

c Nearest Grid Point: Find grid point closest to volcano.
c ------------------


      IF (firstcall) THEN
	  WRITE(*,*) 'Modifying ivolc'
c         Difference along the longitudinal axis
          DO i=1,iim
            dlon(i) = abs(longitude(i+1)*180/pi-lon_volc)
          ENDDO
c         Difference along the latitudinal axis
          dlat(1) = abs(latitude(1)*180/pi-lat_volc)
          DO j=2,jjm+1
            dlat(j) = abs(latitude( (j-2)*iim+2 )*180/pi-lat_volc)
          ENDDO
c         Grid point calculation : ivolc = [1:ngrid]
          IF (minloc(dlat,1).eq.1) THEN
            ivolc = 1
          ELSE IF (minloc(dlat,1).eq.(jjm+1)) THEN
            ivolc = ngrid
          ELSE
            ivolc = 1 + (minloc(dlat,1)-2)*iim + minloc(dlon,1)
          ENDIF
          write(*,*) 'Volcanism :'
          write(*,*) 'Coordinate nearest to the volcano:'
          write(*,*) ivolc,':LAT=',latitude(ivolc)*180/pi,
     &           'xLON=',longitude(ivolc)*180/pi
          firstcall=.false.
      ENDIF



c This part of the code distributes mass flux in the grid square
c (mass flux/mass of air in grid square), resulting in kg/kg/s tendency.
c -----------------------
c Specify the levels at which each class of clasts falls,
c rounded to the nearest GCM level, either from the Wilson model or from
c a fixed height. 
c Fixed height values: Glaze and Baloga 2002 & Kerber et al., 2013
c 610Pa = 10km; level 11-12(~8.9-13.5 km)
c 50mb = 18km; level 13(18.9 km)
c 0.5bar = 22.5km; level 14(25.1 km)
c 1bar = 31km; level 15(31.5 km)
     
      l= 12                             ! for a fixed height. 
      write(*,*) 'noms ',noms
      DO iq=1, nq
        tracername=noms(iq)
        if (tracername(1:4).eq."volc") then

!____________________________________________________________________

c        FIXED MASS SOURCE (DETERMINED BY USER)
      	write(*,*) 'volcano grid point= ', ivolc
	WRITE(*,*) 'ash dropheight', l
	WRITE(*,*) 'ash flux (kg/s)', mmsource
	
	ssource(ivolc,l,iq) = mmsource/massarea(ivolc,l)
	WRITE(*,*) 'ash ssource calculation=', ssource(ivolc,l,iq)
	

c        ssource(ivolc,l,iq) = mmsource*g/
c     &    ( massarea*(pplev(ivolc,l)-pplev(ivolc,l+1)) )

         endif  ! volc tracers
!___________________________________________________________________

c        WATER SOURCE
         if (tracername.eq."h2o_vap") then
   	WRITE(*,*) 'water is on'
	WRITE(*,*) 'water dropheight', l
	WRITE(*,*) 'water flux (kg/s)', wsource
	
	ssource(ivolc,l,iq) = wsource/massarea(ivolc,l)
	WRITE(*,*) 'water ssource calculation=', ssource(ivolc,l,iq)    

c        ssource(ivolc,l,iq) =  wsource*g/
c     &      ( massarea*(pplev(ivolc,l)-pplev(ivolc,l+1)) )

c Note: Water mass-balance calculations are in WATERCLOUD.F
c      WRITE(*,*) 'zdqvolc', ssource(ivolc,l,noms)
c      WRITE(*,*) 'cell_area(ivolc)', cell_area(ivolc)

         endif ! volcanic water
!__________________________________________________________________     

c       SULFATE SOURCE
c       
        if (tracername.eq."h2so4") then
        write(*,*) 'onto sulfur' 
	WRITE(*,*) 'sulfur flux (kg/s)', sulfsource
	WRITE(*,*) 'sulfur dropheight', l
	
	ssource(ivolc,l,iq) = sulfsource/massarea(ivolc,l)       
 	WRITE(*,*) 'sulfur ssource calculation=', ssource(ivolc,l,iq) 

c 	ssource(ivolc,l,iq) = sulfsource*g/
c    &    ( massarea(ivolc,l)*pplev(ivolc,l)-pplev(ivolc,l+1) )
        endif 
!__________________________________________________________________
      ENDDO
      
      WRITE(*,*) 'ending ssource=', ssource(ivolc,l,iq)
      WRITE(*,*) 'ivolc =', ivolc
      WRITE(*,*) 'l =', l
      RETURN
      END

c     Comment : Volcanic tracers are initialized in initracer.F
    

