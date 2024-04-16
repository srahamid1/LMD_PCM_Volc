      Module volcano_mod
        IMPLICIT NONE
      INTEGER, SAVE:: ivolc=0 ! volcano grid point. SAVE keeps value. Can access from outside. ivolc=0 no volcano on that domain/grid point for that volcano
      CONTAINS
      SUBROUTINE volcano(ngrid,nlay,pplev,wu,wv,pt,zzlev,
     &                    ssource,nq,massarea) !,cell_area !cell_area is redundant)

      use callkeys_mod, only: lon_volc,lat_volc,dropheight,
     & mmsource,wsource,h2so4source,rho_volc !specify which variables you want in callphys.def
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
c   Description :
c       Dispersal of volcanic products by the LMD/PCM.
c
c     Author : Lionel Wilson
c     Adapted for the LMD/PCM by Laura Kerber, J.-B. Madeleine, and 
c     Saira Hamid
c
c   Reference documenting most recent changes:
c       Hamid et al. 2024 Icarus
c=======================================================================

c     Variable statement
c     __________________________________________________________________


c Parameters
c ----------

c PLEASE DEFINE THE LOCATION OF THE ERUPTION BELOW :
c =============================================
c     Coordinate of the volcano (degrees) commented out because lat/lon is now modified in callphys.def:
c      REAL, parameter :: lon_volc = 178 
c      REAL, parameter :: lat_volc = -8.5
c       ex : Alba Patera lon=-111.11 and lat= 39.19
c       ex : Albor Tholus lon=150.4 and lat= 19.0 (Robbins2011)
c       ex : Amphritites lon=52.66 and lat= -58.00
c       ex : Apollinaris Patera lon=174.4 and lat=-9.3/-8.5
c       ex : Apollinaris Patera high res lon=178 and lat=-8.5
c       ex : Arsia Mons lon=-120.46 and lat= -9.14
c       ex : Ascraeus Mons lon=-104.37 and lat= 11.1
c       ex : Cerberus Fossae lon= 160.0 and lat= 10.0, (old lon=176.6, lat=9)
c       ex : Electris volcano lon=-173.21 and lat = -37.35
c       ex : Elysium Mons lon=147 and lat= 24.8
c       ex : Hadriacus Mons lon=92.18 and lat= -30.44
c       ex : Hecates Tholus lon=150.08 and lat= 31.68
c       ex : Malea Patera lon=50.96 and lat= -63.09
c       ex : Olympus Mons lon=-133.9 and lat =18.7
c       ex : Pavonis Mons lon=-112.85 and lat= 0.662
c       ex : Peneus Patera lon=60.76 and lat= -58.05
c       ex : Pityusa Patera lon= 36.87 and lat= -66.77
c       ex : Syrtis Major lon=66.4 and lat= 9.85
c       ex : Tyrrhenia Mons lon=106.55 and lat= -21.32
c     Source flux (kg/s) is commented out because these are now changed in callphys.def
c       REAL, parameter :: mmsource = 1E8
c      REAL, parameter :: wsource = 1.E6 
c       REAL, parameter :: h2so4source = 1.E5
c =============================================
c Local variables
c ---------------

      INTEGER :: i, j !dropheight
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
   
      ssource(1:ngrid,1:nlay,1:nq)=0 !all arrays=zero b/c this local variable within the routine needs to be initialized
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
c Specify the levels at which each volcanic product falls,
c rounded to the nearest GCM level at a fixed height. 

      IF (ivolc==0) THEN !Tendencies will=0 & leave the routine
       RETURN
      endif

c      l= 14                            ! for a fixed height. Commented out because this is now changed in callphys.def
      write(*,*) 'tracer names',noms
      DO iq=1, nq
        tracername=noms(iq)
        if (tracername(1:4).eq."volc") then

!____________________________________________________________________

c        FIXED MASS SOURCE (DETERMINED BY USER)
      	write(*,*) 'Volcano Grid Point= ', ivolc
	WRITE(*,*) 'Longitude of Volcano', lon_volc
	WRITE(*,*) 'Latitude of Volcano', lat_volc
	WRITE(*,*) 'Volcanic ash density (kg/m3)', rho_volc
	WRITE(*,*) 'Ash Flux (kg/s)', mmsource
	WRITE(*,*) 'Ash Dropheight', dropheight
	
	ssource(ivolc,dropheight,iq)=mmsource/massarea(ivolc,dropheight)

         endif  ! volc tracers
!___________________________________________________________________

c        WATER SOURCE
         if (tracername.eq."h2o_vap") then
   	WRITE(*,*) 'On to Water'
	WRITE(*,*) 'Water flux (kg/s)', wsource
	WRITE(*,*) 'Water dropheight', dropheight

	ssource(ivolc,dropheight,iq)=wsource/massarea(ivolc,dropheight)


         endif ! volcanic water
!__________________________________________________________________     

c       SULFURIC ACID SOURCE
c       
        if (tracername.eq."h2so4") then
        write(*,*) 'On to H2SO4' 
	WRITE(*,*) 'H2SO4 Flux (kg/s)', h2so4source
	WRITE(*,*) 'H2SO4 Dropheight', dropheight
	WRITE(*,*) 'Volcanic H2SO4 density (kg/m3)', rho_h2so4	

	ssource(ivolc,dropheight,iq) =h2so4source/
     &    ( massarea(ivolc,dropheight) )       

        endif 
!__________________________________________________________________
      ENDDO
      
      RETURN
      END
      END MODULE volcano_mod

