C======================================================================
      PROGRAM newstart
c=======================================================================
c
c
c   Auteur:   Christophe Hourdin/Francois Forget/Yann Wanherdrick
c   ------
c             Derniere modif : 12/03
c
c
c   Objet:  Create or modify the initial state for the LMD Mars GCM
c   -----           (fichiers NetCDF start et startfi)
c
c
c=======================================================================

      use mod_phys_lmdz_para, only: is_parallel, is_sequential,
     &                              is_mpi_root, is_omp_root,
     &                              is_master
      use infotrac, only: infotrac_init, nqtot, tname
      USE tracer_h, ONLY: igcm_co2_ice, igcm_h2o_vap, igcm_h2o_ice
      USE comsoil_h, ONLY: nsoilmx, layer, mlayer, inertiedat
      USE surfdat_h, ONLY: phisfi, albedodat,
     &                     zmea, zstd, zsig, zgam, zthe
      use datafile_mod, only: datadir, surfdir
      use ioipsl_getin_p_mod, only: getin_p
      use control_mod, only: day_step, iphysiq, anneeref, planet_type
      use phyredem, only: physdem0, physdem1
      use iostart, only: open_startphy
      use slab_ice_h, only:noceanmx
      use filtreg_mod, only: inifilr
      USE mod_const_mpi, ONLY: COMM_LMDZ
      USE comvert_mod, ONLY: ap,bp,aps,bps,pa,preff
      USE comconst_mod, ONLY: lllm,daysec,dtvr,dtphys,cpp,kappa,
     .                        rad,omeg,g,r,pi
      USE serre_mod, ONLY: alphax
      USE temps_mod, ONLY: day_ini
      USE ener_mod, ONLY: etot0,ptot0,ztot0,stot0,ang0
      use tabfi_mod, only: tabfi
      use iniphysiq_mod, only: iniphysiq
      use phyetat0_mod, only: phyetat0
      implicit none

      include "dimensions.h"
      integer, parameter :: ngridmx = (2+(jjm-1)*iim - 1/jjm) 
      include "paramet.h"
      include "comgeom2.h"
      include "comdissnew.h"
      include "netcdf.inc"

c=======================================================================
c   Declarations
c=======================================================================

c Variables dimension du fichier "start_archive"
c------------------------------------
      CHARACTER        relief*3


c Variables pour les lectures NetCDF des fichiers "start_archive" 
c--------------------------------------------------
      INTEGER nid_dyn, nid_fi,nid,nvarid
      INTEGER length
      parameter (length = 100)
      INTEGER tab0
      INTEGER   NB_ETATMAX
      parameter (NB_ETATMAX = 100)

      REAL  date
      REAL p_rad,p_omeg,p_g,p_cpp,p_mugaz,p_daysec

c Variable histoire 
c------------------
      REAL vcov(iip1,jjm,llm),ucov(iip1,jjp1,llm) ! vents covariants
      REAL phis(iip1,jjp1)
      REAL,ALLOCATABLE :: q(:,:,:,:)               ! champs advectes

c autre variables dynamique nouvelle grille
c------------------------------------------
      REAL pks(iip1,jjp1)
      REAL w(iip1,jjp1,llm+1)
      REAL pbaru(ip1jmp1,llm),pbarv(ip1jm,llm)
!      REAL dv(ip1jm,llm),du(ip1jmp1,llm)
!      REAL dh(ip1jmp1,llm),dp(ip1jmp1)
      REAL phi(iip1,jjp1,llm)

      integer klatdat,klongdat
      PARAMETER (klatdat=180,klongdat=360)

c Physique sur grille scalaire 
c----------------------------
      real zmeaS(iip1,jjp1),zstdS(iip1,jjp1)
      real zsigS(iip1,jjp1),zgamS(iip1,jjp1),ztheS(iip1,jjp1)

c variable physique
c------------------
      REAL tsurf(ngridmx)        ! surface temperature
      REAL,ALLOCATABLE :: tsoil(:,:) ! soil temperature
!      REAL co2ice(ngridmx)        ! CO2 ice layer
      REAL emis(ngridmx)        ! surface emissivity
      real emisread             ! added by RW
      REAL,ALLOCATABLE :: qsurf(:,:)
      REAL q2(ngridmx,llm+1)
!      REAL rnaturfi(ngridmx)
      real alb(iip1,jjp1),albfi(ngridmx) ! albedos
      real,ALLOCATABLE :: ith(:,:,:),ithfi(:,:) ! thermal inertia (3D)
      real surfith(iip1,jjp1),surfithfi(ngridmx) ! surface thermal inertia (2D)
      REAL latfi(ngridmx),lonfi(ngridmx),airefi(ngridmx)

      INTEGER i,j,l,isoil,ig,idum
      real mugaz ! molar mass of the atmosphere

      integer ierr 

      REAL rnat(ngridmx)
      REAL,ALLOCATABLE :: tslab(:,:) ! slab ocean temperature
      REAL pctsrf_sic(ngridmx) ! sea ice cover
      REAL tsea_ice(ngridmx) ! temperature sea_ice
      REAL sea_ice(ngridmx) ! mass of sea ice (kg/m2)

c Variables on the new grid along scalar points 
c------------------------------------------------------
!      REAL p(iip1,jjp1)
      REAL t(iip1,jjp1,llm)
      REAL tset(iip1,jjp1,llm)
      real phisold_newgrid(iip1,jjp1)
      REAL :: teta(iip1, jjp1, llm)
      REAL :: pk(iip1,jjp1,llm)
      REAL :: pkf(iip1,jjp1,llm)
      REAL :: ps(iip1, jjp1)
      REAL :: masse(iip1,jjp1,llm)
      REAL :: xpn,xps,xppn(iim),xpps(iim)
      REAL :: p3d(iip1, jjp1, llm+1)
      REAL :: beta(iip1,jjp1,llm)
!      REAL dteta(ip1jmp1,llm)

c Variable de l'ancienne grille 
c------------------------------
      real time
      real tab_cntrl(100)
      real tab_cntrl_bis(100)

c variables diverses
c-------------------
      real choix_1,pp
      character*80      fichnom
      character*250  filestring
      integer Lmodif,iq
      character modif*20
      real z_reel(iip1,jjp1)
      real tsud,albsud,alb_bb,ith_bb,Tiso,Tabove
      real ptoto,pcap,patm,airetot,ptotn,patmn,psea
!      real ssum
      character*1 yes
      logical :: flagtset=.false. ,  flagps0=.false.
      real val, val2, val3, val4 ! to store temporary variables
      real :: iceith=2000 ! thermal inertia of subterranean ice

      INTEGER :: itau
      
      character(len=20) :: txt ! to store some text
      character(len=50) :: surfacefile ! "surface.nc" (or equivalent file)
      character(len=150) :: longline
      integer :: count
      real :: profile(llm+1) ! to store an atmospheric profile + surface value

!     added by BC for equilibrium temperature startup
      real teque

!     added by BC for cloud fraction setup
      REAL hice(ngridmx),cloudfrac(ngridmx,llm)
      REAL totalfrac(ngridmx)


!     added by RW for nuketharsis
      real fact1
      real fact2


c sortie visu pour les champs dynamiques
c---------------------------------------
!      INTEGER :: visuid
!      real :: time_step,t_ops,t_wrt
!      CHARACTER*80 :: visu_file

      cpp    = 0.
      preff  = 0.
      pa     = 0. ! to ensure disaster rather than minor error if we don`t
                  ! make deliberate choice of these values elsewhere.

      planet_type="generic"

! initialize "serial/parallel" related stuff
! (required because we call tabfi() below, before calling iniphysiq)
      is_sequential=.true.
      is_parallel=.false.
      is_mpi_root=.true.
      is_omp_root=.true.
      is_master=.true.
      
! Load tracer number and names:
      call infotrac_init
! allocate arrays
      allocate(q(iip1,jjp1,llm,nqtot))
      allocate(qsurf(ngridmx,nqtot))
      
! get value of nsoilmx and allocate corresponding arrays
      ! a default value of nsoilmx is set in comsoil_h
      call getin_p("nsoilmx",nsoilmx)
      
      allocate(tsoil(ngridmx,nsoilmx))
      allocate(ith(iip1,jjp1,nsoilmx),ithfi(ngridmx,nsoilmx))
      allocate(tslab(ngridmx,nsoilmx))
      
c=======================================================================
c   Choice of the start file(s) to use
c=======================================================================
      write(*,*) 'From which kind of files do you want to create new',
     .  'start and startfi files'
      write(*,*) '    0 - from a file start_archive'
      write(*,*) '    1 - from files start and startfi'
      write(*,*) "the datadir is ", datadir 
c-----------------------------------------------------------------------
c   Open file(s) to modify (start or start_archive)
c-----------------------------------------------------------------------

      DO
         read(*,*,iostat=ierr) choix_1
         if ((choix_1 /= 0).OR.(choix_1 /=1)) EXIT
      ENDDO

c     Open start_archive
c     ~~~~~~~~~~~~~~~~~~~~~~~~~~
      if (choix_1.eq.0) then

        write(*,*) 'Creating start files from:'
        write(*,*) './start_archive.nc'
        write(*,*)
        fichnom = 'start_archive.nc'
        ierr = NF_OPEN (fichnom, NF_NOWRITE,nid)
        IF (ierr.NE.NF_NOERR) THEN
          write(6,*)' Problem opening file:',fichnom
          write(6,*)' ierr = ', ierr
          CALL ABORT
        ENDIF
        tab0 = 50 
        Lmodif = 1

c     OR open start and startfi files
c     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      else
        write(*,*) 'Creating start files from:'
        write(*,*) './start.nc and ./startfi.nc'
        write(*,*)
        fichnom = 'start.nc'
        ierr = NF_OPEN (fichnom, NF_NOWRITE,nid_dyn)
        IF (ierr.NE.NF_NOERR) THEN
          write(6,*)' Problem opening file:',fichnom
          write(6,*)' ierr = ', ierr
          CALL ABORT
        ENDIF
 
        fichnom = 'startfi.nc'
        ierr = NF_OPEN (fichnom, NF_NOWRITE,nid_fi)
        IF (ierr.NE.NF_NOERR) THEN
          write(6,*)' Problem opening file:',fichnom
          write(6,*)' ierr = ', ierr
          CALL ABORT
        ENDIF

        tab0 = 0 
        Lmodif = 0

      endif


c=======================================================================
c  INITIALISATIONS DIVERSES
c=======================================================================

! Initialize global tracer indexes (stored in tracer.h)
! ... this has to be done before phyetat0
      call initracer(ngridmx,nqtot,tname)

! Take care of arrays in common modules
      ! ALLOCATE ARRAYS in surfdat_h (if not already done, e.g. when using start_archive)
      IF (.not. ALLOCATED(albedodat)) ALLOCATE(albedodat(ngridmx))
      IF (.not. ALLOCATED(phisfi)) ALLOCATE(phisfi(ngridmx))
      IF (.not. ALLOCATED(zmea)) ALLOCATE(zmea(ngridmx))
      IF (.not. ALLOCATED(zstd)) ALLOCATE(zstd(ngridmx))
      IF (.not. ALLOCATED(zsig)) ALLOCATE(zsig(ngridmx))
      IF (.not. ALLOCATED(zgam)) ALLOCATE(zgam(ngridmx))
      IF (.not. ALLOCATED(zthe)) ALLOCATE(zthe(ngridmx))

c-----------------------------------------------------------------------
c Lecture du tableau des parametres du run (pour la dynamique)
c-----------------------------------------------------------------------
      if (choix_1.eq.0) then

        write(*,*) 'reading tab_cntrl START_ARCHIVE'
c
        ierr = NF_INQ_VARID (nid, "controle", nvarid)

        ierr = NF_GET_VAR_DOUBLE(nid, nvarid, tab_cntrl)



c
      else if (choix_1.eq.1) then

        write(*,*) 'reading tab_cntrl START'
c
        ierr = NF_INQ_VARID (nid_dyn, "controle", nvarid)

        ierr = NF_GET_VAR_DOUBLE(nid_dyn, nvarid, tab_cntrl)



c
        write(*,*) 'reading tab_cntrl STARTFI'
c
        ierr = NF_INQ_VARID (nid_fi, "controle", nvarid)

        ierr = NF_GET_VAR_DOUBLE(nid_fi, nvarid, tab_cntrl_bis)



c
        do i=1,50
          tab_cntrl(i+50)=tab_cntrl_bis(i)
        enddo
        write(*,*) 'printing tab_cntrl', tab_cntrl
        do i=1,100
          write(*,*) i,tab_cntrl(i)
        enddo
        
        write(*,*) 'Reading file START'
        fichnom = 'start.nc'
        CALL dynetat0(fichnom,vcov,ucov,teta,q,masse,
     .       ps,phis,time)

        CALL iniconst
        CALL inigeom

! Initialize the physics
         CALL iniphysiq(iim,jjm,llm,
     &                  (jjm-1)*iim+2,comm_lmdz,
     &                  daysec,day_ini,dtphys,
     &                  rlatu,rlatv,rlonu,rlonv,
     &                  aire,cu,cv,rad,g,r,cpp,
     &                  1)

        ! Lmodif set to 0 to disable modifications possibility in phyeta0                           
        Lmodif=0
        write(*,*) 'Reading file STARTFI'
        fichnom = 'startfi.nc'
        CALL phyetat0(.true.,ngridmx,llm,fichnom,tab0,Lmodif,nsoilmx,
     .        nqtot,day_ini,time,
     .        tsurf,tsoil,emis,q2,qsurf,   !) ! temporary modif by RDW
     .        cloudfrac,totalfrac,hice,rnat,pctsrf_sic,tslab,tsea_ice,
     .        sea_ice)

        ! copy albedo and soil thermal inertia on (local) physics grid
        do i=1,ngridmx
          albfi(i) = albedodat(i)
          do j=1,nsoilmx
           ithfi(i,j) = inertiedat(i,j)
          enddo
        ! build a surfithfi(:) using 1st layer of ithfi(:), which might
        ! be needed later on if reinitializing soil thermal inertia
          surfithfi(i)=ithfi(i,1)
        enddo
        ! also copy albedo and soil thermal inertia on (local) dynamics grid
        ! so that options below can manipulate either (but must then ensure
        ! to correctly recast things on physics grid)
        call gr_fi_dyn(1,ngridmx,iip1,jjp1,albfi,alb)
        call gr_fi_dyn(nsoilmx,ngridmx,iip1,jjp1,ithfi,ith)
        call gr_fi_dyn(1,ngridmx,iip1,jjp1,surfithfi,surfith)
      
      endif
c-----------------------------------------------------------------------
c                Initialisation des constantes dynamique
c-----------------------------------------------------------------------

      kappa = tab_cntrl(9) 
      etot0 = tab_cntrl(12)
      ptot0 = tab_cntrl(13)
      ztot0 = tab_cntrl(14)
      stot0 = tab_cntrl(15)
      ang0 = tab_cntrl(16)
      write(*,*) "Newstart: kappa,etot0,ptot0,ztot0,stot0,ang0"
      write(*,*) kappa,etot0,ptot0,ztot0,stot0,ang0

      ! for vertical coordinate
      preff=tab_cntrl(18) ! reference surface pressure
      pa=tab_cntrl(17)  ! reference pressure at which coord is purely pressure
      !NB: in start_archive files tab_cntrl(17)=tab_cntrl(18)=0
      write(*,*) "Newstart: preff=",preff," pa=",pa
      yes=' '
      do while ((yes.ne.'y').and.(yes.ne.'n'))
        write(*,*) "Change the values of preff and pa? (y/n)"
        write(*,*) "datadir is:", datadir
        read(*,fmt='(a)') yes
      end do
      if (yes.eq.'y') then
        write(*,*)"New value of reference surface pressure preff?"
        write(*,*)"   (for Mars, typically preff=610)"
        read(*,*) preff
        write(*,*)"New value of reference pressure pa for purely"
        write(*,*)"pressure levels (for hybrid coordinates)?"
        write(*,*)"   (for Mars, typically pa=20)"
        read(*,*) pa
      endif
c-----------------------------------------------------------------------
c   Lecture du tab_cntrl et initialisation des constantes physiques
c  - pour start:  Lmodif = 0 => pas de modifications possibles
c                  (modif dans le tabfi de readfi + loin)
c  - pour start_archive:  Lmodif = 1 => modifications possibles
c-----------------------------------------------------------------------
      if (choix_1.eq.0) then
         ! tabfi requires that input file be first opened by open_startphy(fichnom)
         write(*,*) "the datadir is at line 422 ", datadir
         fichnom = 'start_archive.nc'
         call open_startphy(fichnom)
         call tabfi (ngridmx,nid,Lmodif,tab0,day_ini,lllm,p_rad,
     .            p_omeg,p_g,p_cpp,p_mugaz,p_daysec,time)
      else if (choix_1.eq.1) then
         fichnom = 'startfi.nc'
         call open_startphy(fichnom)
         Lmodif=1 ! Lmodif set to 1 to allow modifications in phyeta0                           
         call tabfi (ngridmx,nid_fi,Lmodif,tab0,day_ini,lllm,p_rad,
     .            p_omeg,p_g,p_cpp,p_mugaz,p_daysec,time)
      endif

      if (p_omeg .eq. -9999.) then
        p_omeg = 8.*atan(1.)/p_daysec
        print*,"new value of omega",p_omeg
      endif

      rad = p_rad
      omeg = p_omeg
      g = p_g
      cpp = p_cpp
      mugaz = p_mugaz
      daysec = p_daysec

      if (p_omeg .eq. -9999.) then
        p_omeg = 8.*atan(1.)/p_daysec
        print*,"new value of omega",p_omeg
      endif

      kappa = 8.314*1000./(p_mugaz*p_cpp) ! added by RDW

c=======================================================================
c  INITIALISATIONS DIVERSES
c=======================================================================
! Load parameters from run.def file
      write(*,*) "the datadir is at line 458 ", datadir
      CALL defrun_new( 99, .TRUE. )
      write(*,*) "the datadir is at line 460 ", datadir
! Initialize dynamics geometry and co. (which, when using start.nc may 
! have changed because of modifications (tabi, preff, pa) above)
      CALL iniconst 
      CALL inigeom
      idum=-1
      idum=0

! Initialize the physics for start_archive only
      IF (choix_1.eq.0) THEN
         CALL iniphysiq(iim,jjm,llm,
     &                  (jjm-1)*iim+2,comm_lmdz,
     &                  daysec,day_ini,dtphys,
     &                  rlatu,rlatv,rlonu,rlonv,
     &                  aire,cu,cv,rad,g,r,cpp,
     &                  1)
      ENDIF
      write(*,*) "the datadir is ", datadir," after call iniphysiq"
c=======================================================================
c   lecture topographie, albedo, inertie thermique, relief sous-maille
c=======================================================================

      if (choix_1.eq.0) then  ! for start_archive files, 
                              ! where an external "surface.nc" file is needed

c do while((relief(1:3).ne.'mol').AND.(relief(1:3).ne.'pla'))
c       write(*,*)
c       write(*,*) 'choix du relief (mola,pla)'
c       write(*,*) '(Topographie MGS MOLA, plat)'
c       read(*,fmt='(a3)') relief
        relief="mola"
c     enddo

!    First get the correct value of datadir, if not already done:
        ! default 'datadir' is set in "datafile_mod"
        write(*,*) "the datadir is ", datadir," before getin_p"
        !call getin_p("datadir",datadir)
        write(*,*) "the datadir is ", datadir
        write(*,*) 'Available surface data files are:'
        filestring='ls '//trim(datadir)//'/'//
     &                    trim(surfdir)//' | grep .nc'
        call system(filestring)
        ! but in ye old days these files were in datadir, so scan it as well
        ! for the sake of retro-compatibility
        filestring='ls '//trim(datadir)//'/'//' | grep .nc'
        call system(filestring)

        write(*,*) ''
        write(*,*) 'Please choose the relevant file',
     &  ' (e.g. "surface_mars.nc")'
        write(*,*) ' or "none" to not use any (and set planetary'
        write(*,*) '  albedo and surface thermal inertia)'
        read(*,fmt='(a50)') surfacefile

        if (surfacefile.ne."none") then

          CALL datareadnc(relief,surfacefile,phis,alb,surfith,
     &          zmeaS,zstdS,zsigS,zgamS,ztheS)
        else
        ! specific case when not using a "surface.nc" file
          phis(:,:)=0
          zmeaS(:,:)=0
          zstdS(:,:)=0
          zsigS(:,:)=0
          zgamS(:,:)=0
          ztheS(:,:)=0
          
          write(*,*) "Enter value of albedo of the bare ground:"
          read(*,*) alb(1,1)
          alb(:,:)=alb(1,1)
          
          write(*,*) "Enter value of thermal inertia of soil:"
          read(*,*) surfith(1,1)
          surfith(:,:)=surfith(1,1)
        
        endif ! of if (surfacefile.ne."none")

        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,surfith,surfithfi)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,zmeaS,zmea)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,zstdS,zstd)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,zsigS,zsig)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,zgamS,zgam)
        CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,ztheS,zthe)

      endif ! of if (choix_1.eq.0)


c=======================================================================
c  Lecture des fichiers (start ou start_archive)
c=======================================================================

      if (choix_1.eq.0) then

        write(*,*) 'Reading file START_ARCHIVE'
        CALL lect_start_archive(ngridmx,llm,
     &   date,tsurf,tsoil,emis,q2,
     &   t,ucov,vcov,ps,teta,phisold_newgrid,q,qsurf,
     &   surfith,nid,
     &   rnat,pctsrf_sic,tslab,tsea_ice,sea_ice)
        write(*,*) "OK, read start_archive file"
        ! copy soil thermal inertia
        ithfi(:,:)=inertiedat(:,:)
        
        ierr= NF_CLOSE(nid)

      else if (choix_1.eq.1) then 
         !do nothing, start and startfi have already been read
      else 
        CALL exit(1)
      endif

      dtvr   = daysec/FLOAT(day_step)
      dtphys   = dtvr * FLOAT(iphysiq)

c=======================================================================
c 
c=======================================================================

      do ! infinite loop on list of changes

      write(*,*)
      write(*,*)
      write(*,*) 'List of possible changes :'
      write(*,*) '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
      write(*,*)
      write(*,*) 'flat : no topography ("aquaplanet")'
      write(*,*) 'set_ps_to_preff : used if changing preff with topo'
      write(*,*) 'nuketharsis : no Tharsis bulge'
      write(*,*) 'bilball : uniform albedo and thermal inertia'
      write(*,*) 'coldspole : cold subsurface and high albedo at S.pole'
      write(*,*) 'qname : change tracer name'
      write(*,*) 't=profile  : read temperature profile in profile.in'
      write(*,*) 'q=0 : ALL tracer =zero'
      write(*,*) 'q=x : give a specific uniform value to one tracer'
      write(*,*) 'qs=x : give a uniform value to a surface tracer'
      write(*,*) 'q=profile    : specify a profile for a tracer'
!      write(*,*) 'ini_q : tracers initialisation for chemistry, water an
!     $d ice   '
!      write(*,*) 'ini_q-H2O : tracers initialisation for chemistry and 
!     $ice '
!      write(*,*) 'ini_q-iceH2O : tracers initialisation for chemistry on
!     $ly '
      write(*,*) 'noglacier : Remove tropical H2O ice if |lat|<45'
      write(*,*) 'watercapn : H20 ice on permanent N polar cap '
      write(*,*) 'watercaps : H20 ice on permanent S polar cap '
      write(*,*) 'noacglac  : H2O ice across Noachis Terra'
      write(*,*) 'oborealis : H2O ice across Vastitas Borealis'
      write(*,*) 'iceball   : Thick ice layer all over surface'
      write(*,*) 'supercontinent: Create a continent of given Ab and TI'
      write(*,*) 'wetstart  : start with a wet atmosphere'
      write(*,*) 'isotherm  : Isothermal Temperatures, wind set to zero'
      write(*,*) 'radequi   : Earth-like radiative equilibrium temperature
     $ profile (lat-alt) and winds set to zero'
      write(*,*) 'coldstart : Start X K above the CO2 frost point and 
     $set wind to zero (assumes 100% CO2)'
      write(*,*) 'co2ice=0 : remove CO2 polar cap'
      write(*,*) 'ptot : change total pressure'
      write(*,*) 'emis : change surface emissivity'
      write(*,*) 'therm_ini_s : Set soil thermal inertia to reference sur
     &face values'
      write(*,*) 'slab_ocean_0 : initialisation of slab 
     $ocean variables'
      write(*,*) 'chemistry_ini : initialisation of chemical profiles'

        write(*,*)
        write(*,*) 'Change to perform ?'
        write(*,*) '   (enter keyword or return to end)'
        write(*,*)

        read(*,fmt='(a20)') modif
        if (modif(1:1) .eq. ' ')then
         exit ! exit loop on changes
        endif

        write(*,*)
        write(*,*) trim(modif) , ' : '

c       'flat : no topography ("aquaplanet")'
c       -------------------------------------
        if (trim(modif) .eq. 'flat') then
c         set topo to zero 
          z_reel(1:iip1,1:jjp1)=0
          phis(1:iip1,1:jjp1)=g*z_reel(1:iip1,1:jjp1)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)
          write(*,*) 'topography set to zero.'
          write(*,*) 'WARNING : the subgrid topography parameters',
     &    ' were not set to zero ! => set calllott to F'                    

c        Choice of surface pressure
         yes=' '
         do while ((yes.ne.'y').and.(yes.ne.'n'))
            write(*,*) 'Do you wish to choose homogeneous surface',
     &                 'pressure (y) or let newstart interpolate ',
     &                 ' the previous field  (n)?'
             read(*,fmt='(a)') yes
         end do
         if (yes.eq.'y') then
           flagps0=.true.
           write(*,*) 'New value for ps (Pa) ?'
 201       read(*,*,iostat=ierr) patm
            if(ierr.ne.0) goto 201
            write(*,*) patm
            if (patm.eq.-9999.) then
              patm = preff
              write(*,*) "we set patm = preff", preff
            endif
             write(*,*)
             write(*,*) ' new ps everywhere (Pa) = ', patm
             write(*,*)
             do j=1,jjp1
               do i=1,iip1
                 ps(i,j)=patm
               enddo
             enddo
         end if

c       'set_ps_to_preff' : used if changing preff with topo  
c       ----------------------------------------------------
        else if (trim(modif) .eq. 'set_ps_to_preff') then
          do j=1,jjp1
           do i=1,iip1
             ps(i,j)=preff
           enddo
          enddo

c       'nuketharsis : no tharsis bulge for Early Mars'
c       ---------------------------------------------
        else if (trim(modif) .eq. 'nuketharsis') then

           DO j=1,jjp1        
              DO i=1,iim
                 ig=1+(j-2)*iim +i
                 if(j.eq.1) ig=1
                 if(j.eq.jjp1) ig=ngridmx

                 fact1=(((rlonv(i)*180./pi)+100)**2 + 
     &                (rlatu(j)*180./pi)**2)/65**2 
                 fact2=exp( -fact1**2.5 )

                 phis(i,j) = phis(i,j) - (phis(i,j)+4000.*g)*fact2

!                 if(phis(i,j).gt.2500.*g)then
!                    if(rlatu(j)*180./pi.gt.-80.)then ! avoid chopping south polar cap
!                       phis(i,j)=2500.*g
!                    endif
!                 endif

              ENDDO
           ENDDO
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)


c       bilball : uniform albedo, thermal inertia
c       -----------------------------------------
        else if (trim(modif) .eq. 'bilball') then
          write(*,*) 'constante albedo and iner.therm:'
          write(*,*) 'New value for albedo (ex: 0.25) ?'
 101      read(*,*,iostat=ierr) alb_bb
          if(ierr.ne.0) goto 101
          write(*,*)
          write(*,*) ' uniform albedo (new value):',alb_bb
          write(*,*)

          write(*,*) 'New value for thermal inertia (eg: 247) ?'
 102      read(*,*,iostat=ierr) ith_bb
          if(ierr.ne.0) goto 102
          write(*,*) 'uniform thermal inertia (new value):',ith_bb
          DO j=1,jjp1
             DO i=1,iip1
                alb(i,j) = alb_bb        ! albedo
                do isoil=1,nsoilmx
                  ith(i,j,isoil) = ith_bb        ! thermal inertia
                enddo
             END DO
          END DO
!          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)

c       coldspole : sous-sol de la calotte sud toujours froid
c       -----------------------------------------------------
        else if (trim(modif) .eq. 'coldspole') then
          write(*,*)'new value for the subsurface temperature',
     &   ' beneath the permanent southern polar cap ? (eg: 141 K)'
 103      read(*,*,iostat=ierr) tsud
          if(ierr.ne.0) goto 103
          write(*,*)
          write(*,*) ' new value of the subsurface temperature:',tsud
c         nouvelle temperature sous la calotte permanente
          do l=2,nsoilmx
               tsoil(ngridmx,l) =  tsud
          end do


          write(*,*)'new value for the albedo',
     &   'of the permanent southern polar cap ? (eg: 0.75)'
 104      read(*,*,iostat=ierr) albsud
          if(ierr.ne.0) goto 104
          write(*,*)

c         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c         Option 1:  only the albedo of the pole is modified :    
          albfi(ngridmx)=albsud
          write(*,*) 'ig=',ngridmx,'   albedo perennial cap ',
     &    albfi(ngridmx)

c         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
c          Option 2 A haute resolution : coordonnee de la vrai calotte ~    
c           DO j=1,jjp1
c             DO i=1,iip1
c                ig=1+(j-2)*iim +i
c                if(j.eq.1) ig=1
c                if(j.eq.jjp1) ig=ngridmx
c                if ((rlatu(j)*180./pi.lt.-84.).and.
c     &            (rlatu(j)*180./pi.gt.-91.).and.
c     &            (rlonv(i)*180./pi.gt.-91.).and.
c     &            (rlonv(i)*180./pi.lt.0.))         then
cc    albedo de la calotte permanente fixe a albsud
c                   alb(i,j)=albsud
c                   write(*,*) 'lat=',rlatu(j)*180./pi,
c     &                      ' lon=',rlonv(i)*180./pi
cc     fin de la condition sur les limites de la calotte permanente
c                end if
c             ENDDO
c          ENDDO
c      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

c         CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)


c       ptot : Modification of the total pressure: ice + current atmosphere 
c       -------------------------------------------------------------------
        else if (trim(modif).eq.'ptot') then

          ! check if we have a co2_ice surface tracer:
          if (igcm_co2_ice.eq.0) then
            write(*,*) " No surface CO2 ice !"
            write(*,*) " only atmospheric pressure will be considered!"
          endif
c         calcul de la pression totale glace + atm actuelle
          patm=0.
          airetot=0.
          pcap=0.
          DO j=1,jjp1
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx
                patm = patm + ps(i,j)*aire(i,j)
                airetot= airetot + aire(i,j)
                if (igcm_co2_ice.ne.0) then
                  !pcap = pcap + aire(i,j)*co2ice(ig)*g
                  pcap = pcap + aire(i,j)*qsurf(ig,igcm_co2_ice)*g
                endif
             ENDDO
          ENDDO
          ptoto = pcap + patm

          print*,'Current total pressure at surface (co2 ice + atm) ',
     &       ptoto/airetot

          print*,'new value?'
          read(*,*) ptotn
          ptotn=ptotn*airetot
          patmn=ptotn-pcap
          print*,'ptoto,patm,ptotn,patmn'
          print*,ptoto,patm,ptotn,patmn
          print*,'Mult. factor for pressure (atm only)', patmn/patm
          do j=1,jjp1
             do i=1,iip1
                ps(i,j)=ps(i,j)*patmn/patm
             enddo
          enddo



c        Correction pour la conservation des traceurs
         yes=' '
         do while ((yes.ne.'y').and.(yes.ne.'n'))
            write(*,*) 'Do you wish to conserve tracer total mass (y)',
     &              ' or tracer mixing ratio (n) ?'
             read(*,fmt='(a)') yes
         end do

         if (yes.eq.'y') then
           write(*,*) 'OK : conservation of tracer total mass'
           DO iq =1, nqtot
             DO l=1,llm
               DO j=1,jjp1
                  DO i=1,iip1
                    q(i,j,l,iq)=q(i,j,l,iq)*patm/patmn
                  ENDDO
               ENDDO
             ENDDO
           ENDDO
          else
            write(*,*) 'OK : conservation of tracer mixing ratio'
          end if

c        Correction pour la pression au niveau de la mer
         yes=' '
         do while ((yes.ne.'y').and.(yes.ne.'n'))
            write(*,*) 'Do you wish fix pressure at sea level (y)',
     &              ' or not (n) ?'
             read(*,fmt='(a)') yes
         end do

         if (yes.eq.'y') then
           write(*,*) 'Value?'
                read(*,*,iostat=ierr) psea
             DO i=1,iip1
               DO j=1,jjp1
                    ps(i,j)=psea

                  ENDDO
               ENDDO
                write(*,*) 'psea=',psea
          else
            write(*,*) 'no'
          end if


c       emis : change surface emissivity (added by RW)
c       ----------------------------------------------
        else if (trim(modif).eq.'emis') then

           print*,'new value?'
           read(*,*) emisread

           do i=1,ngridmx
              emis(i)=emisread
           enddo

c       qname : change tracer name
c       --------------------------
        else if (trim(modif).eq.'qname') then
         yes='y'
         do while (yes.eq.'y')
          write(*,*) 'Which tracer name do you want to change ?'
          do iq=1,nqtot
            write(*,'(i3,a3,a20)')iq,' : ',trim(tname(iq))
          enddo
          write(*,'(a35,i3)')
     &            '(enter tracer number; between 1 and ',nqtot
          write(*,*)' or any other value to quit this option)'
          read(*,*) iq
          if ((iq.ge.1).and.(iq.le.nqtot)) then
            write(*,*)'Change tracer name ',trim(tname(iq)),' to ?'
            read(*,*) txt
            tname(iq)=txt
            write(*,*)'Do you want to change another tracer name (y/n)?'
            read(*,'(a)') yes 
          else
! inapropiate value of iq; quit this option
            yes='n'
          endif ! of if ((iq.ge.1).and.(iq.le.nqtot))
         enddo ! of do while (yes.ne.'y')

c       q=0 : set tracers to zero
c       -------------------------
        else if (trim(modif).eq.'q=0') then
c          mise a 0 des q (traceurs)
          write(*,*) 'Tracers set to 0 (1.E-30 in fact)'
           DO iq =1, nqtot
             DO l=1,llm
               DO j=1,jjp1
                  DO i=1,iip1
                    q(i,j,l,iq)=1.e-30
                  ENDDO
               ENDDO
             ENDDO
           ENDDO

c          set surface tracers to zero
           DO iq =1, nqtot
             DO ig=1,ngridmx
                 qsurf(ig,iq)=0.
             ENDDO
           ENDDO

c       q=x : initialise tracer manually 
c       --------------------------------
        else if (trim(modif).eq.'q=x') then
             write(*,*) 'Which tracer do you want to modify ?'
             do iq=1,nqtot
               write(*,*)iq,' : ',trim(tname(iq))
             enddo
             write(*,*) '(choose between 1 and ',nqtot,')'
             read(*,*) iq 
             write(*,*)'mixing ratio of tracer ',trim(tname(iq)),
     &                 ' ? (kg/kg)'
             read(*,*) val
             DO l=1,llm
               DO j=1,jjp1
                  DO i=1,iip1
                    q(i,j,l,iq)=val
                  ENDDO
               ENDDO
             ENDDO
             write(*,*) 'SURFACE value of tracer ',trim(tname(iq)),
     &                   ' ? (kg/m2)'
             read(*,*) val
             DO ig=1,ngridmx
                 qsurf(ig,iq)=val
             ENDDO
             
c       qs=x : initialise surface tracer manually 
c       --------------------------------
        else if (trim(modif).eq.'qs=x') then
             write(*,*) 'Which tracer do you want to modify ?'
             do iq=1,nqtot
               write(*,*)iq,' : ',trim(tname(iq))
             enddo
             write(*,*) '(choose between 1 and ',nqtot,')'
             read(*,*) iq 
             write(*,*) 'SURFACE value of tracer ',trim(tname(iq)),
     &                   ' ? (kg/m2)'
             read(*,*) val
             DO ig=1,ngridmx
                 qsurf(ig,iq)=val
             ENDDO

c       t=profile : initialize temperature with a given profile
c       -------------------------------------------------------
        else if (trim(modif) .eq. 't=profile') then
             write(*,*) 'Temperature profile from ASCII file'
             write(*,*) "'profile.in' e.g. 1D output"
             write(*,*) "(one value per line in file; starting with"
             write(*,*) "surface value, the 1st atmospheric layer"
             write(*,*) "followed by 2nd, etc. up to top of atmosphere)"
             txt="profile.in"
             open(33,file=trim(txt),status='old',form='formatted',
     &            iostat=ierr)
             if (ierr.eq.0) then
               ! OK, found file 'profile_...', load the profile
               do l=1,llm+1
                 read(33,*,iostat=ierr) profile(l)
                 write(*,*) profile(l)
                 if (ierr.ne.0) then ! something went wrong
                   exit ! quit loop
                 endif
               enddo
               if (ierr.eq.0) then
                 tsurf(1:ngridmx)=profile(1)
                 tsoil(1:ngridmx,1:nsoilmx)=profile(1)
                 do l=1,llm
                   Tset(1:iip1,1:jjp1,l)=profile(l+1)
                   flagtset=.true.
                 enddo
                 ucov(1:iip1,1:jjp1,1:llm)=0.
                 vcov(1:iip1,1:jjm,1:llm)=0.
                 q2(1:ngridmx,1:llm+1)=0.
               else
                 write(*,*)'problem reading file ',trim(txt),' !'
                 write(*,*)'No modifications to temperature'
               endif
             else
               write(*,*)'Could not find file ',trim(txt),' !'
               write(*,*)'No modifications to temperature'
             endif

c       q=profile : initialize tracer with a given profile
c       --------------------------------------------------
        else if (trim(modif) .eq. 'q=profile') then
             write(*,*) 'Tracer profile will be sought in ASCII file'
             write(*,*) "'profile_tracer' where 'tracer' is tracer name"
             write(*,*) "(one value per line in file; starting with"
             write(*,*) "surface value, the 1st atmospheric layer"
             write(*,*) "followed by 2nd, etc. up to top of atmosphere)"
             write(*,*) 'Which tracer do you want to set?'
             do iq=1,nqtot
               write(*,*)iq,' : ',trim(tname(iq))
             enddo
             write(*,*) '(choose between 1 and ',nqtot,')'
             read(*,*) iq 
             if ((iq.lt.1).or.(iq.gt.nqtot)) then
               ! wrong value for iq, go back to menu
               write(*,*) "wrong input value:",iq
               cycle
             endif
             ! look for input file 'profile_tracer'
             txt="profile_"//trim(tname(iq))
             open(41,file=trim(txt),status='old',form='formatted',
     &            iostat=ierr)
             if (ierr.eq.0) then
               ! OK, found file 'profile_...', load the profile
               do l=1,llm+1
                 read(41,*,iostat=ierr) profile(l)
                 if (ierr.ne.0) then ! something went wrong
                   exit ! quit loop
                 endif
               enddo
               if (ierr.eq.0) then
                 ! initialize tracer values
                 qsurf(:,iq)=profile(1)
                 do l=1,llm
                   q(:,:,l,iq)=profile(l+1)
                 enddo
                 write(*,*)'OK, tracer ',trim(tname(iq)),' initialized '
     &                    ,'using values from file ',trim(txt)
               else
                 write(*,*)'problem reading file ',trim(txt),' !'
                 write(*,*)'No modifications to tracer ',trim(tname(iq))
               endif
             else
               write(*,*)'Could not find file ',trim(txt),' !'
               write(*,*)'No modifications to tracer ',trim(tname(iq))
             endif
             

c      wetstart : wet atmosphere with a north to south gradient
c      --------------------------------------------------------
       else if (trim(modif) .eq. 'wetstart') then
        ! check that there is indeed a water vapor tracer
        if (igcm_h2o_vap.eq.0) then
          write(*,*) "No water vapour tracer! Can't use this option"
          stop
        endif
          DO l=1,llm
            DO j=1,jjp1
              DO i=1,iip1
                q(i,j,l,igcm_h2o_vap)=150.e-6 * (rlatu(j)+pi/2.) / pi
              ENDDO
            ENDDO
          ENDDO

         write(*,*) 'Water mass mixing ratio at north pole='
     *               ,q(1,1,1,igcm_h2o_vap)
         write(*,*) '---------------------------south pole='
     *               ,q(1,jjp1,1,igcm_h2o_vap)

c      noglacier : remove tropical water ice (to initialize high res sim)
c      --------------------------------------------------
        else if (trim(modif) .eq. 'noglacier') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif
           do ig=1,ngridmx
             j=(ig-2)/iim +2
              if(ig.eq.1) j=1
              write(*,*) 'OK: remove surface ice for |lat|<45'
              if (abs(rlatu(j)*180./pi).lt.45.) then
                   qsurf(ig,igcm_h2o_ice)=0.
              end if
           end do


c      watercapn : H20 ice on permanent northern cap
c      --------------------------------------------------
        else if (trim(modif) .eq. 'watercapn') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif

           DO j=1,jjp1        
              DO i=1,iim
                 ig=1+(j-2)*iim +i
                 if(j.eq.1) ig=1
                 if(j.eq.jjp1) ig=ngridmx

                 if (rlatu(j)*180./pi.gt.80.) then
                    qsurf(ig,igcm_h2o_ice)=2e6 !was 3.4e3. 2e6 kg/m2 gives 2km
                    !thick h2o ice cap Carr & Head,2003, Phillips et al 2008
                    !do isoil=1,nsoilmx
                    !   ith(i,j,isoil) = 18000. ! thermal inertia
                    !enddo
                   write(*,*)'     ==> Ice mesh North boundary (deg)= ',
     &                   rlatv(j-1)*180./pi
                 end if
              ENDDO
           ENDDO
           CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)

c$$$           do ig=1,ngridmx
c$$$             j=(ig-2)/iim +2
c$$$              if(ig.eq.1) j=1
c$$$              if (rlatu(j)*180./pi.gt.80.) then
c$$$
c$$$                   qsurf(ig,igcm_h2o_ice)=1.e5
c$$$                   qsurf(ig,igcm_h2o_vap)=0.0!1.e5
c$$$
c$$$                   write(*,*) 'ig=',ig,'    H2O ice mass (kg/m2)= ',
c$$$     &              qsurf(ig,igcm_h2o_ice)
c$$$
c$$$                   write(*,*)'     ==> Ice mesh South boundary (deg)= ',
c$$$     &              rlatv(j)*180./pi
c$$$                end if
c$$$           enddo

c      watercaps : H20 ice on permanent southern cap
c      -------------------------------------------------
        else if (trim(modif) .eq. 'watercaps') then
           if (igcm_h2o_ice.eq.0) then
              write(*,*) "No water ice tracer! Can't use this option"
              stop
           endif

           DO j=1,jjp1        
              DO i=1,iim
                 ig=1+(j-2)*iim +i
                 if(j.eq.1) ig=1
                 if(j.eq.jjp1) ig=ngridmx

                 if (rlatu(j)*180./pi.lt.-80.) then
                    qsurf(ig,igcm_h2o_ice)=2e6 !was 3.4e3. 2e6 kg/m2 gives 2km
                    !thick h2o ice cap Carr & Head,2003, Phillips et al 2008
                    !do isoil=1,nsoilmx
                    !   ith(i,j,isoil) = 18000. ! thermal inertia
                    !enddo
                   write(*,*)'     ==> Ice mesh South boundary (deg)= ',
     &                   rlatv(j-1)*180./pi
                 end if
              ENDDO
           ENDDO
           CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)

c$$$           do ig=1,ngridmx
c$$$               j=(ig-2)/iim +2
c$$$               if(ig.eq.1) j=1
c$$$               if (rlatu(j)*180./pi.lt.-80.) then
c$$$                  qsurf(ig,igcm_h2o_ice)=1.e5
c$$$                  qsurf(ig,igcm_h2o_vap)=0.0 !1.e5
c$$$
c$$$                  write(*,*) 'ig=',ig,'   H2O ice mass (kg/m2)= ',
c$$$     &                 qsurf(ig,igcm_h2o_ice)
c$$$                  write(*,*)'     ==> Ice mesh North boundary (deg)= ',
c$$$     &                 rlatv(j-1)*180./pi
c$$$               end if
c$$$           enddo


c       noacglac : H2O ice across highest terrain
c       --------------------------------------------
        else if (trim(modif) .eq. 'noacglac') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif
          DO j=1,jjp1        
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx

                if(phis(i,j).gt.1000.*g)then
                    alb(i,j) = 0.5 ! snow value
                    do isoil=1,nsoilmx
                       ith(i,j,isoil) = 18000. ! thermal inertia
                       ! this leads to rnat set to 'ocean' in physiq.F90
                       ! actually no, because it is soil not surface
                    enddo
                endif
             ENDDO
          ENDDO
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)



c       oborealis : H2O oceans across Vastitas Borealis
c       -----------------------------------------------
        else if (trim(modif) .eq. 'oborealis') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif
          DO j=1,jjp1        
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx

                if(phis(i,j).lt.-4000.*g)then
!                if( (phis(i,j).lt.-4000.*g)
!     &               .and. (rlatu(j)*180./pi.lt.0.) )then ! south hemisphere only
!                    phis(i,j)=-8000.0*g ! proper ocean
                    phis(i,j)=-4000.0*g ! scanty ocean

                    alb(i,j) = 0.07 ! oceanic value
                    do isoil=1,nsoilmx
                       ith(i,j,isoil) = 18000. ! thermal inertia
                       ! this leads to rnat set to 'ocean' in physiq.F90
                       ! actually no, because it is soil not surface
                    enddo
                endif
             ENDDO
          ENDDO
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)

c       iborealis : H2O ice in Northern plains
c       --------------------------------------
        else if (trim(modif) .eq. 'iborealis') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif
          DO j=1,jjp1        
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx

                if(phis(i,j).lt.-4000.*g)then
                   !qsurf(ig,igcm_h2o_ice)=1.e3
                   qsurf(ig,igcm_h2o_ice)=241.4 ! to make total 33 kg m^-2
                endif
             ENDDO
          ENDDO
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)


c       oceanball : H2O liquid everywhere
c       ----------------------------
        else if (trim(modif) .eq. 'oceanball') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif
          DO j=1,jjp1        
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx

                qsurf(ig,igcm_h2o_vap)=0.0    ! for ocean, this is infinite source
                qsurf(ig,igcm_h2o_ice)=0.0
                alb(i,j) = 0.07 ! ocean value

                do isoil=1,nsoilmx
                   ith(i,j,isoil) = 18000. ! thermal inertia
                   !ith(i,j,isoil) = 50. ! extremely low for test
                   ! this leads to rnat set to 'ocean' in physiq.F90
                enddo

             ENDDO
          ENDDO
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,phis,phisfi)

c       iceball : H2O ice everywhere
c       ----------------------------
        else if (trim(modif) .eq. 'iceball') then
           if (igcm_h2o_ice.eq.0) then
             write(*,*) "No water ice tracer! Can't use this option"
             stop
           endif
          DO j=1,jjp1        
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx

                qsurf(ig,igcm_h2o_vap)=-50.    ! for ocean, this is infinite source
                qsurf(ig,igcm_h2o_ice)=50.     ! == to 0.05 m of oceanic ice
                alb(i,j) = 0.6 ! ice albedo value

                do isoil=1,nsoilmx
                   !ith(i,j,isoil) = 18000. ! thermal inertia
                   ! this leads to rnat set to 'ocean' in physiq.F90
                enddo

             ENDDO
          ENDDO
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)

c       supercontinent : H2O ice everywhere
c       ----------------------------
        else if (trim(modif) .eq. 'supercontinent') then
          write(*,*) 'Minimum longitude (-180,180)'
          read(*,*) val
          write(*,*) 'Maximum longitude (-180,180)'
          read(*,*) val2
          write(*,*) 'Minimum latitude (-90,90)'
          read(*,*) val3
          write(*,*) 'Maximum latitude (-90,90)'
          read(*,*) val4

          do j=1,jjp1
            do i=1,iip1
              ig=1+(j-2)*iim +i
              if(j.eq.1) ig=1
              if(j.eq.jjp1) ig=ngridmx

c             Supercontinent:
              if (((rlatu(j)*180./pi.le.val4).and.
     &            (rlatu(j)*180./pi.ge.val3).and.
     &            (rlonv(i)*180./pi.le.val2).and.
     &            (rlonv(i)*180./pi.ge.val))) then

                rnat(ig)=1.
                alb(i,j) = 0.3
                do isoil=1,nsoilmx
                  ith(i,j,isoil) = 2000.
                enddo
c             Ocean:
              else
                rnat(ig)=0.
                alb(i,j) = 0.07
                do isoil=1,nsoilmx
                  ith(i,j,isoil) = 18000.
                enddo
              end if

            enddo
          enddo
          CALL gr_dyn_fi(nsoilmx,iip1,jjp1,ngridmx,ith,ithfi)
          CALL gr_dyn_fi(1,iip1,jjp1,ngridmx,alb,albfi)

c       isotherm : Isothermal temperatures and no winds
c       -----------------------------------------------
        else if (trim(modif) .eq. 'isotherm') then

          write(*,*)'Isothermal temperature of the atmosphere, 
     &           surface and subsurface'
          write(*,*) 'Value of this temperature ? :'
 203      read(*,*,iostat=ierr) Tiso
          if(ierr.ne.0) goto 203

          tsurf(1:ngridmx)=Tiso
          
          tsoil(1:ngridmx,1:nsoilmx)=Tiso
          
          Tset(1:iip1,1:jjp1,1:llm)=Tiso
          flagtset=.true.

          t(1:iip1,1:jjp1,1:llm)=Tiso
          !! otherwise hydrost. integrations below
          !! use the wrong temperature
          !! -- NB: Tset might be useless
        
          ucov(1:iip1,1:jjp1,1:llm)=0
          vcov(1:iip1,1:jjm,1:llm)=0
          q2(1:ngridmx,1:llm+1)=0

c       radequi : Radiative equilibrium profile of temperatures and no winds
c       --------------------------------------------------------------------
        else if (trim(modif) .eq. 'radequi') then

          write(*,*)'radiative equilibrium temperature profile'       

          do ig=1, ngridmx
             teque= 335.0-60.0*sin(latfi(ig))*sin(latfi(ig))-
     &            10.0*cos(latfi(ig))*cos(latfi(ig))
             tsurf(ig) = MAX(220.0,teque)
          end do
          do l=2,nsoilmx
             do ig=1, ngridmx
                tsoil(ig,l) = tsurf(ig)
             end do
          end do
          DO j=1,jjp1
             DO i=1,iim
                Do l=1,llm
                   teque=335.-60.0*sin(rlatu(j))*sin(rlatu(j))-
     &                  10.0*cos(rlatu(j))*cos(rlatu(j))
                   Tset(i,j,l)=MAX(220.0,teque)
                end do
             end do
          end do
          flagtset=.true.
          ucov(1:iip1,1:jjp1,1:llm)=0
          vcov(1:iip1,1:jjm,1:llm)=0
          q2(1:ngridmx,1:llm+1)=0

c       coldstart : T set 1K above CO2 frost point and no winds
c       ------------------------------------------------
        else if (trim(modif) .eq. 'coldstart') then

          write(*,*)'set temperature of the atmosphere,' 
     &,'surface and subsurface how many degrees above CO2 frost point?'
 204      read(*,*,iostat=ierr) Tabove
          if(ierr.ne.0) goto 204

            DO j=1,jjp1
             DO i=1,iim
                ig=1+(j-2)*iim +i
                if(j.eq.1) ig=1
                if(j.eq.jjp1) ig=ngridmx
            tsurf(ig) = (-3167.8)/(log(.01*ps(i,j))-23.23)+Tabove
             END DO
            END DO
          do l=1,nsoilmx
            do ig=1, ngridmx
              tsoil(ig,l) = tsurf(ig)
            end do
          end do
          DO j=1,jjp1
           DO i=1,iim
            Do l=1,llm
               pp = aps(l) +bps(l)*ps(i,j) 
               Tset(i,j,l)=(-3167.8)/(log(.01*pp)-23.23)+Tabove
            end do
           end do
          end do

          flagtset=.true.
          ucov(1:iip1,1:jjp1,1:llm)=0
          vcov(1:iip1,1:jjm,1:llm)=0
          q2(1:ngridmx,1:llm+1)=0


c       co2ice=0 : remove CO2 polar ice caps'
c       ------------------------------------------------
        else if (trim(modif) .eq. 'co2ice=0') then
         ! check that there is indeed a co2_ice tracer ...
          if (igcm_co2_ice.ne.0) then
           do ig=1,ngridmx
              !co2ice(ig)=0
              qsurf(ig,igcm_co2_ice)=0
              emis(ig)=emis(ngridmx/2)
           end do
          else
            write(*,*) "Can't remove CO2 ice!! (no co2_ice tracer)"
          endif
        
!       therm_ini_s: (re)-set soil thermal inertia to reference surface values
!       ----------------------------------------------------------------------

        else if (trim(modif) .eq. 'therm_ini_s') then
!          write(*,*)"surfithfi(1):",surfithfi(1)
          do isoil=1,nsoilmx
            inertiedat(1:ngridmx,isoil)=surfithfi(1:ngridmx)
          enddo
          write(*,*)'OK: Soil thermal inertia has been reset to referenc
     &e surface values'
!          write(*,*)"inertiedat(1,1):",inertiedat(1,1)
          ithfi(:,:)=inertiedat(:,:)
         ! recast ithfi() onto ith()
         call gr_fi_dyn(nsoilmx,ngridmx,iip1,jjp1,ithfi,ith)
! Check:
!         do i=1,iip1
!           do j=1,jjp1
!             do isoil=1,nsoilmx
!               write(77,*) i,j,isoil,"  ",ith(i,j,isoil)
!             enddo
!           enddo
!         enddo



c       slab_ocean_initialisation
c       ------------------------------------------------
        else if (trim(modif) .eq. 'slab_ocean_0') then
        write(*,*)'OK: initialisation of slab ocean' 

      DO ig=1, ngridmx
         rnat(ig)=1.
         tslab(ig,1)=0.
         tslab(ig,2)=0.
         tsea_ice(ig)=0.
         sea_ice(ig)=0.
         pctsrf_sic(ig)=0.
         
         if(ithfi(ig,1).GT.10000.)then
           rnat(ig)=0.
           phisfi(ig)=0.
           tsea_ice(ig)=273.15-1.8
           tslab(ig,1)=tsurf(ig)
           tslab(ig,2)=tsurf(ig)!*2./3.+(273.15-1.8)/3.
          endif

      ENDDO
          CALL gr_fi_dyn(1,ngridmx,iip1,jjp1,phisfi,phis)


c       chemistry_initialisation
c       ------------------------------------------------
        else if (trim(modif) .eq. 'chemistry_ini') then
        write(*,*)'OK: initialisation of chemical profiles'


          call inichim_newstart(ngridmx, nqtot, q, qsurf, ps,
     &                          1, 0)

         ! We want to have the very same value at lon -180 and lon 180
          do l = 1,llm
             do j = 1,jjp1
                do iq = 1,nqtot
                   q(iip1,j,l,iq) = q(1,j,l,iq)
                end do
             end do
          end do


        else
          write(*,*) '       Unknown (misspelled?) option!!!'
        end if ! of if (trim(modif) .eq. '...') elseif ...



       enddo ! of do ! infinite loop on liste of changes

 999  continue

 
c=======================================================================
c   Initialisation for cloud fraction and oceanic ice (added by BC 2010)
c=======================================================================
      DO ig=1, ngridmx
         totalfrac(ig)=0.5
         DO l=1,llm
            cloudfrac(ig,l)=0.5
         ENDDO
! Ehouarn, march 2012: also add some initialisation for hice
         hice(ig)=0.0
      ENDDO
      
c========================================================

!      DO ig=1,ngridmx
!         IF(tsurf(ig) .LT. 273.16-1.8) THEN
!            hice(ig)=(273.16-1.8-tsurf(ig))/(273.16-1.8-240)*1.
!            hice(ig)=min(hice(ig),1.0)
!         ENDIF
!      ENDDO




c=======================================================================
c   Correct pressure on the new grid (menu 0)
c=======================================================================


      if ((choix_1.eq.0).and.(.not.flagps0)) then
        r = 1000.*8.31/mugaz

        do j=1,jjp1
          do i=1,iip1
             ps(i,j) = ps(i,j) *
     .            exp((phisold_newgrid(i,j)-phis(i,j)) /
     .                                  (t(i,j,1) * r))
          end do
        end do

c periodicite de ps en longitude
        do j=1,jjp1
          ps(1,j) = ps(iip1,j)
        end do
      end if

         
c=======================================================================
c=======================================================================

c=======================================================================
c    Initialisation de la physique / ecriture de newstartfi :
c=======================================================================


      CALL inifilr 
      CALL pression(ip1jmp1, ap, bp, ps, p3d)

c-----------------------------------------------------------------------
c   Initialisation  pks:
c-----------------------------------------------------------------------

      CALL exner_hyb(ip1jmp1, ps, p3d, beta, pks, pk, pkf)
! Calcul de la temperature potentielle teta

      if (flagtset) then
          DO l=1,llm
             DO j=1,jjp1
                DO i=1,iim
                   teta(i,j,l) = Tset(i,j,l) * cpp/pk(i,j,l)
                ENDDO
                teta (iip1,j,l)= teta (1,j,l)
             ENDDO
          ENDDO
      else if (choix_1.eq.0) then
         DO l=1,llm
            DO j=1,jjp1
               DO i=1,iim
                  teta(i,j,l) = t(i,j,l) * cpp/pk(i,j,l)
               ENDDO
               teta (iip1,j,l)= teta (1,j,l)
            ENDDO
         ENDDO
      endif

C Calcul intermediaire
c
      if (choix_1.eq.0) then
         CALL massdair( p3d, masse  )
c
         print *,' ALPHAX ',alphax

         DO  l = 1, llm
           DO  i    = 1, iim
             xppn(i) = aire( i, 1   ) * masse(  i     ,  1   , l )
             xpps(i) = aire( i,jjp1 ) * masse(  i     , jjp1 , l )
           ENDDO
             xpn      = SUM(xppn)/apoln
             xps      = SUM(xpps)/apols
           DO i   = 1, iip1
             masse(   i   ,   1     ,  l )   = xpn
             masse(   i   ,   jjp1  ,  l )   = xps
           ENDDO
         ENDDO
      endif
      phis(iip1,:) = phis(1,:)

      itau=0
      if (choix_1.eq.0) then
         day_ini=int(date)
      endif
c
      CALL geopot  ( ip1jmp1, teta  , pk , pks,  phis  , phi   )

      CALL caldyn0( itau,ucov,vcov,teta,ps,masse,pk,phis ,
     *                phi,w, pbaru,pbarv,day_ini+time )

          
      CALL dynredem0("restart.nc",day_ini,phis)
      CALL dynredem1("restart.nc",0.0,vcov,ucov,teta,q,masse,ps) 
C
C Ecriture etat initial physique
C

      call physdem0("restartfi.nc",lonfi,latfi,nsoilmx,ngridmx,llm,
     &              nqtot,dtphys,real(day_ini),0.0,
     &              airefi,albfi,ithfi,zmea,zstd,zsig,zgam,zthe)
      call physdem1("restartfi.nc",nsoilmx,ngridmx,llm,nqtot,
     &                dtphys,real(day_ini),
     &                tsurf,tsoil,emis,q2,qsurf,
     &                cloudfrac,totalfrac,hice,
     &                rnat,pctsrf_sic,tslab,tsea_ice,sea_ice)

c=======================================================================
c        Formats 
c=======================================================================

   1  FORMAT(//10x,'la valeur de im =',i4,2x,'lue sur le fichier de dema
     *rrage est differente de la valeur parametree iim =',i4//)
   2  FORMAT(//10x,'la valeur de jm =',i4,2x,'lue sur le fichier de dema
     *rrage est differente de la valeur parametree jjm =',i4//)
   3  FORMAT(//10x,'la valeur de lllm =',i4,2x,'lue sur le fichier demar
     *rage est differente de la valeur parametree llm =',i4//)

      write(*,*) "newstart: All is well that ends well."

      end


