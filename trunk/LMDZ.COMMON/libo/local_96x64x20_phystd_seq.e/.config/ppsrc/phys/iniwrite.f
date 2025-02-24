












      SUBROUTINE iniwrite(nid,idayref,phis,area,nbplon,nbplat)

      use comsoil_h, only: mlayer, nsoilmx
      USE comcstfi_mod, only: g, mugaz, omeg, rad, rcp, pi 
      USE vertical_layers_mod, ONLY: ap,bp,aps,bps,pseudoalt
!      USE logic_mod, ONLY: fxyhypb,ysinus
!      USE serre_mod, ONLY: clon,clat,grossismx,grossismy,dzoomx,dzoomy
      USE time_phylmdz_mod, ONLY: daysec, dtphys
!      USE ener_mod, ONLY: etot0,ptot0,ztot0,stot0,ang0
      USE regular_lonlat_mod, ONLY: lon_reg, lat_reg
      USE mod_grid_phy_lmdz, ONLY: nbp_lon, nbp_lat, nbp_lev
      IMPLICIT NONE

c=======================================================================
c
c   Auteur:  L. Fairhead  ,  P. Le Van, Y. Wanherdrick, F. Forget
c   -------
c
c   Objet:
c   ------
c
c   'Initialize' the diagfi.nc file: write down dimensions as well
c   as time-independent fields (e.g: geopotential, mesh area, ...)
c
c=======================================================================
c-----------------------------------------------------------------------
c   Declarations:
c   -------------

      include "netcdf.inc"

c   Arguments:
c   ----------

      integer,intent(in) :: nid        ! NetCDF file ID
      INTEGER*4,intent(in) :: idayref  ! date (initial date for this run)
      real,intent(in) :: phis(nbplon,nbp_lat) ! surface geopotential
      real,intent(in) :: area(nbplon,nbp_lat) ! mesh area (m2)
      integer,intent(in) :: nbplon,nbplat ! sizes of area and phis arrays

c   Local:
c   ------
      INTEGER length,l
      parameter (length = 100)
      REAL tab_cntrl(length) ! run parameters are stored in this array
      INTEGER ierr
      REAl,ALLOCATABLE :: lon_reg_ext(:) ! extended longitudes

      integer :: nvarid,idim_index,idim_rlonv
      integer :: idim_rlatu,idim_llmp1,idim_llm
      integer :: idim_nsoilmx ! "subsurface_layers" dimension ID #
      integer, dimension(2) :: id  
c-----------------------------------------------------------------------

      IF (nbp_lon*nbp_lat==1) THEN
        ! 1D model
        ALLOCATE(lon_reg_ext(1))
      ELSE
        ! 3D model
        ALLOCATE(lon_reg_ext(nbp_lon+1))
      ENDIF

      DO l=1,length
         tab_cntrl(l)=0.
      ENDDO
      tab_cntrl(1)  = real(nbp_lon)
      tab_cntrl(2)  = real(nbp_lat-1)
      tab_cntrl(3)  = real(nbp_lev)
      tab_cntrl(4)  = real(idayref)
      tab_cntrl(5)  = rad
      tab_cntrl(6)  = omeg
      tab_cntrl(7)  = g
      tab_cntrl(8)  = mugaz
      tab_cntrl(9)  = rcp
      tab_cntrl(10) = daysec
      tab_cntrl(11) = dtphys
!      tab_cntrl(12) = etot0
!      tab_cntrl(13) = ptot0
!      tab_cntrl(14) = ztot0
!      tab_cntrl(15) = stot0
!      tab_cntrl(16) = ang0
c
c    ..........    P.Le Van  ( ajout le 8/04/96 )    .........
c         .....        parametres  pour le zoom          ......   
!      tab_cntrl(17)  = clon
!      tab_cntrl(18)  = clat
!      tab_cntrl(19)  = grossismx
!      tab_cntrl(20)  = grossismy
c
c     .....   ajout  le 6/05/97 et le 15/10/97  .......
c
!      IF ( fxyhypb )   THEN
!        tab_cntrl(21) = 1.
!        tab_cntrl(22) = dzoomx
!        tab_cntrl(23) = dzoomy
!      ELSE
!        tab_cntrl(21) = 0.
!        tab_cntrl(22) = dzoomx
!        tab_cntrl(23) = dzoomy
!        tab_cntrl(24) = 0.
!        IF( ysinus )  tab_cntrl(24) = 1.
!      ENDIF

c    .........................................................

! Define dimensions
    
      ierr = NF_REDEF (nid)

      ierr = NF_DEF_DIM (nid, "index", length, idim_index)
!      ierr = NF_DEF_DIM (nid, "rlonu", iip1, idim_rlonu)
      ierr = NF_DEF_DIM (nid, "latitude", nbp_lat, idim_rlatu)
      IF (nbp_lon*nbp_lat==1) THEN
        ierr = NF_DEF_DIM (nid, "longitude", 1, idim_rlonv)
      ELSE
        ierr = NF_DEF_DIM (nid, "longitude", nbp_lon+1, idim_rlonv)
      ENDIF
!      ierr = NF_DEF_DIM (nid, "rlatv", jjm, idim_rlatv)
      ierr = NF_DEF_DIM (nid, "interlayer", (nbp_lev+1), idim_llmp1)
      ierr = NF_DEF_DIM (nid, "altitude", nbp_lev, idim_llm)
      ierr = NF_DEF_DIM (nid,"subsurface_layers",nsoilmx,idim_nsoilmx)
c
      ierr = NF_ENDDEF(nid)

c  Contol parameters for this run
      ierr = NF_REDEF (nid)
      ierr = NF_DEF_VAR (nid, "controle", NF_DOUBLE, 1, 
     .       idim_index,nvarid)
      ierr = NF_PUT_ATT_TEXT (nid,nvarid,"title", 18,
     .                       "Control parameters")
      ierr = NF_ENDDEF(nid)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,tab_cntrl)

c --------------------------
c  longitudes and latitudes
!
!      ierr = NF_REDEF (nid)
!#ifdef 1
!      ierr = NF_DEF_VAR (nid, "rlonu", NF_DOUBLE, 1, idim_rlonu,nvarid)
!#else
!      ierr = NF_DEF_VAR (nid, "rlonu", NF_FLOAT, 1, idim_rlonu,nvarid)
!#endif
!      ierr = NF_PUT_ATT_TEXT (nid,nvarid,"title", 21,
!     .                       "Longitudes at u nodes")
!      ierr = NF_ENDDEF(nid)
!#ifdef 1
!      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,rlonu/pi*180)
!#else
!      ierr = NF_PUT_VAR_REAL (nid,nvarid,rlonu/pi*180)
!#endif
c
c --------------------------
      ierr = NF_REDEF (nid)
      ierr =NF_DEF_VAR(nid, "latitude", NF_DOUBLE, 1, idim_rlatu,nvarid)
      ierr =NF_PUT_ATT_TEXT(nid,nvarid,'units',13,"degrees_north")
      ierr = NF_PUT_ATT_TEXT (nid,nvarid,"long_name", 14,
     .      "North latitude")
      ierr = NF_ENDDEF(nid)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,lat_reg/pi*180)
c
c --------------------------
      
      lon_reg_ext(1:nbp_lon)=lon_reg(1:nbp_lon)
      IF (nbp_lon*nbp_lat/=1) THEN
        ! In 3D, add extra redundant point (180 degrees,
        ! since lon_reg starts at -180)
        lon_reg_ext(nbp_lon+1)=-lon_reg_ext(1)
      ENDIF

      ierr = NF_REDEF (nid)
      ierr =NF_DEF_VAR(nid,"longitude", NF_DOUBLE, 1, idim_rlonv,nvarid)
      ierr = NF_PUT_ATT_TEXT (nid,nvarid,"long_name", 14,
     .      "East longitude")
      ierr = NF_PUT_ATT_TEXT(nid,nvarid,'units',12,"degrees_east")
      ierr = NF_ENDDEF(nid)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,lon_reg_ext/pi*180)
c
c --------------------------
      ierr = NF_REDEF (nid)
      ierr = NF_DEF_VAR (nid, "altitude", NF_DOUBLE, 1, 
     .       idim_llm,nvarid)
      ierr = NF_PUT_ATT_TEXT (nid,nvarid,"long_name",10,"pseudo-alt")
      ierr = NF_PUT_ATT_TEXT (nid,nvarid,'units',2,"km")
      ierr = NF_PUT_ATT_TEXT (nid,nvarid,'positive',2,"up")

      ierr = NF_ENDDEF(nid)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,pseudoalt)
c
c --------------------------
!      ierr = NF_REDEF (nid)
!#ifdef 1
!      ierr = NF_DEF_VAR (nid, "rlatv", NF_DOUBLE, 1, idim_rlatv,nvarid)
!#else
!      ierr = NF_DEF_VAR (nid, "rlatv", NF_FLOAT, 1, idim_rlatv,nvarid)
!#endif
!      ierr = NF_PUT_ATT_TEXT (nid,nvarid,"title", 20,
!     .                       "Latitudes at v nodes")
!      ierr = NF_ENDDEF(nid)
!#ifdef 1
!      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,rlatv/pi*180)
!#else
!      ierr = NF_PUT_VAR_REAL (nid,nvarid,rlatv/pi*180)
!#endif
c
c --------------------------
c  Vertical levels
      call def_var(nid,"aps","hybrid pressure at midlayers ","Pa",
     .            1,idim_llm,nvarid,ierr)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,aps)

      call def_var(nid,"bps","hybrid sigma at midlayers"," ",
     .            1,idim_llm,nvarid,ierr)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,bps)

      call def_var(nid,"ap","hybrid pressure at interlayers","Pa",
     .            1,idim_llmp1,nvarid,ierr)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,ap)

      call def_var(nid,"bp","hybrid sigma at interlayers"," ",
     .            1,idim_llmp1,nvarid,ierr)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,bp)

!-------------------------------
! (soil) depth variable mlayer() (known from comsoil_h)
!-------------------------------
      ierr=NF_REDEF (nid) ! Enter NetCDF (re-)define mode
      ! define variable
      ierr=NF_DEF_VAR(nid,"soildepth",NF_DOUBLE,1,idim_nsoilmx,nvarid)
      ierr=NF_PUT_ATT_TEXT (nid,nvarid,"long_name", 20,
     .                        "Soil mid-layer depth")
      ierr=NF_PUT_ATT_TEXT (nid,nvarid,"units",1,"m")
      ierr=NF_PUT_ATT_TEXT (nid,nvarid,"positive",4,"down")
      ierr=NF_ENDDEF(nid) ! Leave NetCDF define mode
      ! write variable
      ierr=NF_PUT_VAR_DOUBLE (nid,nvarid,mlayer)

c
c --------------------------
c  Mesh area and conversion coefficients cov. <-> contra. <--> natural

!      id(1)=idim_rlonu
!      id(2)=idim_rlatu
c
!      ierr = NF_REDEF (nid)
!#ifdef 1
!      ierr = NF_DEF_VAR (nid, "cu", NF_DOUBLE, 2, id,nvarid)
!#else
!      ierr = NF_DEF_VAR (nid, "cu", NF_FLOAT, 2, id,nvarid)
!#endif
!      ierr = NF_PUT_ATT_TEXT (nid, nvarid, "title", 40,
!     .             "Conversion coefficients cov <--> natural")
!      ierr = NF_ENDDEF(nid)
!#ifdef 1
!      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,cu)
!#else
!      ierr = NF_PUT_VAR_REAL (nid,nvarid,cu)
!#endif
c
!      id(1)=idim_rlonv
!      id(2)=idim_rlatv
c
c --------------------------
!      ierr = NF_REDEF (nid)
!#ifdef 1
!      ierr = NF_DEF_VAR (nid, "cv", NF_DOUBLE, 2, id,nvarid)
!#else
!      ierr = NF_DEF_VAR (nid, "cv", NF_FLOAT, 2, id,nvarid)
!#endif
!      ierr = NF_PUT_ATT_TEXT (nid, nvarid, "title", 40,
!     .             "Conversion coefficients cov <--> natural")
!      ierr = NF_ENDDEF(nid)
!#ifdef 1
!      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,cv)
!#else
!      ierr = NF_PUT_VAR_REAL (nid,nvarid,cv)
!#endif
c
      id(1)=idim_rlonv
      id(2)=idim_rlatu
c
c --------------------------
      ierr = NF_REDEF (nid)
      ierr = NF_DEF_VAR (nid, "aire", NF_DOUBLE, 2, id,nvarid)
      ierr = NF_PUT_ATT_TEXT (nid, nvarid, "title", 9,
     .                       "Mesh area")
      ierr = NF_ENDDEF(nid)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,area)
c
c  Surface geopotential
      id(1)=idim_rlonv
      id(2)=idim_rlatu
c
      ierr = NF_REDEF (nid)
      ierr = NF_DEF_VAR (nid, "phisinit", NF_DOUBLE, 2, id,nvarid)
      ierr = NF_PUT_ATT_TEXT (nid, nvarid, "title", 27,
     .                       "Geopotential at the surface")
      ierr = NF_ENDDEF(nid)
      ierr = NF_PUT_VAR_DOUBLE (nid,nvarid,phis)
c

      write(*,*)'iniwrite: nbp_lon,nbp_lat,nbp_lev,idayref',
     & nbp_lon,nbp_lat,nbp_lev,idayref
      write(*,*)'iniwrite: rad,omeg,g,mugaz,rcp',
     & rad,omeg,g,mugaz,rcp
      write(*,*)'iniwrite: daysec,dtphys',daysec,dtphys

      END
