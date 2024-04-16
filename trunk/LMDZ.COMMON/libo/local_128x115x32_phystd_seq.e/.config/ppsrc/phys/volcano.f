










      Module volcano_mod
        IMPLICIT NONE
      INTEGER, SAVE:: ivolc=0 ! volcano grid point. SAVE keeps value. Can access from outside. ivolc=0 no volcano on that domain/grid point for that volcano
      CONTAINS
      SUBROUTINE volcano(ngrid,nlay,pplev,wu,wv,pt,zzlev,
     &                    ssource,nq,massarea) !,cell_area !cell_area is redundant)

      use tracer_h
      use comgeomfi_h
      use comcstfi_mod, only: pi, g
      use geometry_mod, only: boundslon,boundslat !longitude, latitude ! in radians !instead of using lon/lat we use boundslon/lat for running in parallel
      use regular_lonlat_mod, only: north_east,north_west,
     & south_west,south_east !in radians !Same as above - instead of using lon/lat we use NE/SE/NW/SW to locate grid dimensions for running in parallel
        IMPLICIT NONE

c=======================================================================
c   Explosive volcanic eruptions (updated to run in parallel)
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

!#include "dimensions.h"
!#include "dimphys.h"
!#include "comcstfi.h"

c Parameters
c ----------

c PLEASE DEFINE THE LOCATION OF THE ERUPTION BELOW :
c =============================================
c     Coordinate of the volcano (degrees) :
c       ex : Apollinaris Patera lon=174.4 and lat=-9.3
      REAL, parameter :: lon_volc = 178 
      REAL, parameter :: lat_volc = -8.5
c       ex : Elysium Mons lon=147 and lat=24.8
c       ex : Cerberus lon= 160 and lat= 10.0
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
c       ex : Hecates Tholus lon=150.08 and lat=31.68
c       ex : Albor Tholus lon=150.4 and lat=19.0 (Robbins2011)
c       ex : Pityusa Patera lon=36.87 and lat=-66.77
c       ex : Malea Patera lon=50.96 and lat=-63.09
c       ex : Electris volcano lon=-173.21 and lat =-37.35
c     Source flux (kg/s)
       REAL, parameter :: mmsource = 1E8  !Mastin et al. 2009, Glaze and Baloga 2002
      REAL, parameter :: wsource = 1.E5 ! 1wt% magma water content(Greeley 1987)
       REAL, parameter :: sulfsource = 1.E9
c =============================================
c Local variables
c ---------------

      INTEGER :: i, j, l
      INTEGER :: iq                     ! Tracer identifier
      INTEGER :: ig
c      REAL :: dlon(iim), dlat(jjm+1) !commented out b/c I'm using locating the volcano grid point in a way that's suitable for parallel simulations
      REAL :: msource(nq)
c      INTEGER,SAVE :: ivolc=0            ! volcano grid point. SAVE keeps value from one to next. Commented out b/c I added it to top of file
      LOGICAL :: firstcall
      DATA firstcall/.true./
      SAVE :: firstcall
      CHARACTER(LEN=20) :: tracername  ! to temporarily store text
c Inputs
c ------

      INTEGER, intent(in) :: nq               ! Number of tracers
      INTEGER, intent(in) :: ngrid            ! Number of grid points
      INTEGER,intent(in) ::  nlay            ! Number of vertical levels
      REAL,intent(in) :: pplev(ngrid,nlay+1) ! Pressure between the layers (Pa)
      REAL,intent(in) :: zzlev(ngrid,nlay+1) ! height between the layers (km)
      REAL,intent(in) :: wv(ngrid,nlay+1)    ! wind
      REAL,intent(in) :: wu(ngrid,nlay+1)    ! wind
      REAL,intent(in) :: pt(ngrid,nlay+1)    ! temp
      REAL,intent(in) :: massarea(ngrid,nlay)

c Outputs
c -------
      REAL, intent(out) :: ssource(ngrid,nlay,nq)    ! Source tendency (kg.kg-1.s-1)
      REAL :: index(nq)              ! Drop height usage: zzlev(index) 
c     Initialization
c     __________________________________________________________________
   
      ssource(1:ngrid,1:nlay,1:nq)=0 !all arrays=zero since it's a local variable within routine that need to be initialized
c Nearest Grid Point: Find grid point closest to volcano.
c ------------------

c Find the boundaries of the cell and convert to degrees
      IF (firstcall) THEN
	  WRITE(*,*) 'Modifying ivolc'
c	  WRITE(*,*) 'boundslon',180/pi*boundslon(449,:) !Test to check if model running in parallel is correctly locating volcano grid point
c          WRITE(*,*) 'boundslat',180/pi*boundslat(449,:)
       DO i=1,ngrid 
c        WRITE(*,*)'i=',i, 'boundslat',180/pi*boundslat(i,:)
c        WRITE(*,*)'i=',i, 'boundslon',180/pi*boundslon(i,:) 
c       if (boundslon(i,1)*180/pi<=lon_volc) THEN
c        WRITE(*,*)'lon_volc>bounds'
c       ENDIF 
c       if (lon_volc<boundslon(i,2)*180/pi) THEN
c        WRITE(*,*)'lon_volc<bounds'
c       ENDIF
       if ((boundslon(i,1)*180/pi<=lon_volc).and.
     &       (lon_volc<boundslon(i,2)*180/pi).and.
     &       (boundslat(i,4)*180/pi<=lat_volc).and.
     &       (lat_volc<boundslat(i,1)*180/pi)) THEN
	   		ivolc=i 
	 
         ENDIF
	ENDDO
        WRITE(*,*) 'ivolc=',ivolc
      ENDIF	


c This part of the code distributes mass flux in the grid square
c (mass flux/mass of air in grid square), resulting in kg/kg/s tendency.
c -----------------------
c Specify the levels at which each class of clasts falls,
c rounded to the nearest GCM level, either from the Wilson model or from
c a fixed height. 
c Explosive eruptions fixed height values: Glaze and Baloga 2002 & Kerber et al., 2013
c 610Pa = 10km; level 11(~8.9km)
c 50mb = 18km; level 13(18.966 km)
c 0.5bar = 22.5km; level 14(25.1 km)
c 1bar = 31km; level 15(31.5 km). Try level 18 (50km Wilson & Head 2007)
c Passive degassing: l=1 for Cerberus, l=12 Elysium (14.1 km, Plescia 2004), l=9 Apollinaris 
c (~3.2 km, Plescia 2004), l=1 Hadriaca (-0.5km, Plescia 2004),Pityusa l=1 (Williams et al. 2009)
      IF (ivolc==0) THEN !leave the routine if there's no volcano handled by this process. Tendencies will=0 
       RETURN
      endif

      l= 10                            ! for a fixed height. 
      write(*,*) 'noms ',noms
      DO iq=1, nq
        tracername=noms(iq)
        if (tracername(1:4).eq."volc") then

!____________________________________________________________________

c        FIXED MASS SOURCE (DETERMINED BY USER)
      	write(*,*) 'volcano grid point= ', ivolc
	WRITE(*,*) 'ash dropheight', l
	WRITE(*,*) 'ash flux (kg/s)', mmsource
	WRITE(*,*) 'massarea', massarea(ivolc,l)
	
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

c	wsource_counter = wsource_counter + wsource
c	WRITE(*,*) 'wsource_counter (kg)', wsource_counter

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
        write(*,*) 'on to sulfur' 
	WRITE(*,*) 'sulfur flux (kg/s)', sulfsource
	WRITE(*,*) 'sulfur dropheight', l
	
	ssource(ivolc,l,iq) = sulfsource/massarea(ivolc,l)       
 	WRITE(*,*) 'sulfur ssource calculation=', ssource(ivolc,l,iq) 

c 	ssource(ivolc,l,iq) = sulfsource*g/
c    &    ( massarea(ivolc,l)*pplev(ivolc,l)-pplev(ivolc,l+1) )
        endif 
!__________________________________________________________________
      ENDDO
      
c      WRITE(*,*) 'ending ssource=', ssource(ivolc,l,iq)
      WRITE(*,*) 'ivolc =', ivolc
      WRITE(*,*) 'l =', l
      RETURN
      END
      END MODULE volcano_mod

