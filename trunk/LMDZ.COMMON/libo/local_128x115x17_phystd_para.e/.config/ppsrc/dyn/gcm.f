!
! $Id: gcm.F 1446 2010-10-22 09:27:25Z emillour $
!
c
c
      PROGRAM gcm






      USE mod_const_mpi, ONLY: init_const_mpi
      USE parallel_lmdz
      USE infotrac
!#ifdef 1
!      USE mod_interface_dyn_phys
!#endif
      USE mod_hallo
      USE Bands
      USE getparam
      USE filtreg_mod
      USE control_mod, only: planet_type,nday,day_step,iperiod,iphysiq,
     &                       raz_date,anneeref,starttime,dayref,
     &                       ok_dyn_ins,ok_dyn_ave,iecri,periodav,
     &                       less1day,fractday,ndynstep,nsplit_phys
      use cpdet_mod, only: ini_cpdet


! Ehouarn: the following are needed with (parallel) physics:

      USE iniphysiq_mod, ONLY: iniphysiq
      USE mod_grid_phy_lmdz
!      USE mod_phys_lmdz_para, ONLY : klon_mpi_para_nb
      USE mod_phys_lmdz_omp_data, ONLY: klon_omp 
      USE dimphy

      USE comconst_mod, ONLY: daysec,dtvr,dtphys,rad,g,r,cpp
      USE logic_mod
      USE temps_mod, ONLY: calend,start_time,annee_ref,day_ref,
     .		itau_dyn,itau_phy,day_ini,jD_ref,jH_ref,day_end,
     .		dt,hour_ini,itaufin
      IMPLICIT NONE

c      ......   Version  du 10/01/98    ..........

c             avec  coordonnees  verticales hybrides 
c   avec nouveaux operat. dissipation * ( gradiv2,divgrad2,nxgraro2 )

c=======================================================================
c
c   Auteur:  P. Le Van /L. Fairhead/F.Hourdin
c   -------
c
c   Objet:
c   ------
c
c   GCM LMD nouvelle grille
c
c=======================================================================
c
c  ... Dans inigeom , nouveaux calculs pour les elongations  cu , cv
c      et possibilite d'appeler une fonction f(y)  a derivee tangente
c      hyperbolique a la  place de la fonction a derivee sinusoidale.
c  ... Possibilite de choisir le schema pour l'advection de
c        q  , en modifiant iadv dans traceur.def  (MAF,10/02) .
c
c      Pour Van-Leer + Vapeur d'eau saturee, iadv(1)=4. (F.Codron,10/99)
c      Pour Van-Leer iadv=10
c
c-----------------------------------------------------------------------
c   Declarations:
c   -------------


!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 128,jjm=115,llm=17,ndm=1)

!-----------------------------------------------------------------------

!
! $Header$
!
!
!  ATTENTION!!!!: ce fichier include est compatible format fixe/format libre
!                 veillez  n'utiliser que des ! pour les commentaires
!                 et  bien positionner les & des lignes de continuation
!                 (les placer en colonne 6 et en colonne 73)
!
!
!-----------------------------------------------------------------------
!   INCLUDE 'paramet.h'

      INTEGER  iip1,iip2,iip3,jjp1,llmp1,llmp2,llmm1
      INTEGER  kftd,ip1jm,ip1jmp1,ip1jmi1,ijp1llm
      INTEGER  ijmllm,mvar
      INTEGER jcfil,jcfllm

      PARAMETER( iip1= iim+1,iip2=iim+2,iip3=iim+3                       &
     &    ,jjp1=jjm+1-1/jjm)
      PARAMETER( llmp1 = llm+1,  llmp2 = llm+2, llmm1 = llm-1 )
      PARAMETER( kftd  = iim/2 -ndm )
      PARAMETER( ip1jm  = iip1*jjm,  ip1jmp1= iip1*jjp1 )
      PARAMETER( ip1jmi1= ip1jm - iip1 )
      PARAMETER( ijp1llm= ip1jmp1 * llm, ijmllm= ip1jm * llm )
      PARAMETER( mvar= ip1jmp1*( 2*llm+1) + ijmllm )
      PARAMETER( jcfil=jjm/2+5, jcfllm=jcfil*llm )

!-----------------------------------------------------------------------

!
! $Id: comdissnew.h 1319 2010-02-23 21:29:54Z fairhead $
!
!
!  ATTENTION!!!!: ce fichier include est compatible format fixe/format libre
!                 veillez � n'utiliser que des ! pour les commentaires
!                 et � bien positionner les & des lignes de continuation 
!                 (les placer en colonne 6 et en colonne 73)
!
!-----------------------------------------------------------------------
! INCLUDE 'comdissnew.h'

      COMMON/comdissnew/ lstardis,nitergdiv,nitergrot,niterh,tetagdiv,  &
     &                   tetagrot,tetatemp,coefdis, vert_prof_dissip

      LOGICAL lstardis
      INTEGER nitergdiv, nitergrot, niterh

! For the Earth model:
      integer vert_prof_dissip ! vertical profile of horizontal dissipation
!     Allowed values:
!     0: rational fraction, function of pressure
!     1: tanh of altitude

      REAL     tetagdiv, tetagrot,  tetatemp, coefdis

!
! ... Les parametres de ce common comdissnew sont  lues par defrun_new 
!              sur le fichier  run.def    ....
!
!-----------------------------------------------------------------------

!
! $Header$
!
!CDK comgeom
      COMMON/comgeom/                                                   &
     & cu(ip1jmp1),cv(ip1jm),unscu2(ip1jmp1),unscv2(ip1jm),             &
     & aire(ip1jmp1),airesurg(ip1jmp1),aireu(ip1jmp1),                  &
     & airev(ip1jm),unsaire(ip1jmp1),apoln,apols,                       &
     & unsairez(ip1jm),airuscv2(ip1jm),airvscu2(ip1jm),                 &
     & aireij1(ip1jmp1),aireij2(ip1jmp1),aireij3(ip1jmp1),              &
     & aireij4(ip1jmp1),alpha1(ip1jmp1),alpha2(ip1jmp1),                &
     & alpha3(ip1jmp1),alpha4(ip1jmp1),alpha1p2(ip1jmp1),               &
     & alpha1p4(ip1jmp1),alpha2p3(ip1jmp1),alpha3p4(ip1jmp1),           &
     & fext(ip1jm),constang(ip1jmp1),rlatu(jjp1),rlatv(jjm),            &
     & rlonu(iip1),rlonv(iip1),cuvsurcv(ip1jm),cvsurcuv(ip1jm),         &
     & cvusurcu(ip1jmp1),cusurcvu(ip1jmp1),cuvscvgam1(ip1jm),           &
     & cuvscvgam2(ip1jm),cvuscugam1(ip1jmp1),                           &
     & cvuscugam2(ip1jmp1),cvscuvgam(ip1jm),cuscvugam(ip1jmp1),         &
     & unsapolnga1,unsapolnga2,unsapolsga1,unsapolsga2,                 &
     & unsair_gam1(ip1jmp1),unsair_gam2(ip1jmp1),unsairz_gam(ip1jm),    &
     & aivscu2gam(ip1jm),aiuscv2gam(ip1jm),xprimu(iip1),xprimv(iip1)

!
        REAL                                                            &
     & cu,cv,unscu2,unscv2,aire,airesurg,aireu,airev,unsaire,apoln     ,&
     & apols,unsairez,airuscv2,airvscu2,aireij1,aireij2,aireij3,aireij4,&
     & alpha1,alpha2,alpha3,alpha4,alpha1p2,alpha1p4,alpha2p3,alpha3p4 ,&
     & fext,constang,rlatu,rlatv,rlonu,rlonv,cuvscvgam1,cuvscvgam2     ,&
     & cvuscugam1,cvuscugam2,cvscuvgam,cuscvugam,unsapolnga1,unsapolnga2&
     & ,unsapolsga1,unsapolsga2,unsair_gam1,unsair_gam2,unsairz_gam    ,&
     & aivscu2gam ,aiuscv2gam,cuvsurcv,cvsurcuv,cvusurcu,cusurcvu,xprimu&
     & , xprimv
!

!!!!!!!!!!!#include "control.h"
!#include "com_io_dyn.h"

!
! $Header$
!
!
! gestion des impressions de sorties et de d�bogage
! lunout:    unit� du fichier dans lequel se font les sorties 
!                           (par defaut 6, la sortie standard)
! prt_level: niveau d'impression souhait� (0 = minimum)
!
      INTEGER lunout, prt_level
      COMMON /comprint/ lunout, prt_level

!
! $Header$
!
      common /tracstoke/istdyn,istphy,unittrac
      integer istdyn,istphy,unittrac



      REAL zdtvr

c   variables dynamiques
      REAL vcov(ip1jm,llm),ucov(ip1jmp1,llm) ! vents covariants
      REAL teta(ip1jmp1,llm)                 ! temperature potentielle 
      REAL, ALLOCATABLE, DIMENSION(:,:,:):: q! champs advectes
      REAL ps(ip1jmp1)                       ! pression  au sol
c      REAL p (ip1jmp1,llmp1  )               ! pression aux interfac.des couches
c      REAL pks(ip1jmp1)                      ! exner au  sol
c      REAL pk(ip1jmp1,llm)                   ! exner au milieu des couches
c      REAL pkf(ip1jmp1,llm)                  ! exner filt.au milieu des couches
      REAL masse(ip1jmp1,llm)                ! masse d'air
      REAL phis(ip1jmp1)                     ! geopotentiel au sol
c      REAL phi(ip1jmp1,llm)                  ! geopotentiel
c      REAL w(ip1jmp1,llm)                    ! vitesse verticale

c variables dynamiques intermediaire pour le transport

c   variables pour le fichier histoire
      REAL dtav      ! intervalle de temps elementaire

      REAL time_0

      LOGICAL lafin
c      INTEGER ij,iq,l,i,j
      INTEGER i,j


      real time_step, t_wrt, t_ops


!      LOGICAL call_iniphys
!      data call_iniphys/.true./

c      REAL alpha(ip1jmp1,llm),beta(ip1jmp1,llm)
c+jld variables test conservation energie
c      REAL ecin(ip1jmp1,llm),ecin0(ip1jmp1,llm)
C     Tendance de la temp. potentiel d (theta)/ d t due a la 
C     tansformation d'energie cinetique en energie thermique
C     cree par la dissipation
c      REAL dhecdt(ip1jmp1,llm)
c      REAL vcont(ip1jm,llm),ucont(ip1jmp1,llm)
c      REAL      d_h_vcol, d_qt, d_qw, d_ql, d_ec
c      CHARACTER (len=15) :: ztit
c-jld 


      character (len=80) :: dynhist_file, dynhistave_file
      character (len=20) :: modname
      character (len=80) :: abort_message
! locales pour gestion du temps
      INTEGER :: an, mois, jour
      REAL :: heure


c-----------------------------------------------------------------------
c    variables pour l'initialisation de la physique :
c    ------------------------------------------------
!      INTEGER ngridmx
!      PARAMETER( ngridmx = 2+(jjm-1)*iim - 1/jjm   )
!      REAL zcufi(ngridmx),zcvfi(ngridmx)
!      REAL latfi(ngridmx),lonfi(ngridmx)
!      REAL airefi(ngridmx)
!      SAVE latfi, lonfi, airefi
      
      INTEGER :: ierr


c-----------------------------------------------------------------------
c   Initialisations:
c   ----------------

      abort_message = 'last timestep reached'
      modname = 'gcm'
      lafin    = .FALSE.
      dynhist_file = 'dyn_hist'
      dynhistave_file = 'dyn_hist_ave'



c----------------------------------------------------------------------
c  lecture des fichiers gcm.def ou run.def
c  ---------------------------------------
c
! Ehouarn: dump possibility of using defrun
!#ifdef CPP_IOIPSL
      CALL conf_gcm( 99, .TRUE. )
      if (mod(iphysiq, iperiod) /= 0) call abort_gcm("conf_gcm",
     s "iphysiq must be a multiple of iperiod", 1)
!#else
!      CALL defrun( 99, .TRUE. , clesphy0 )
!#endif
c
c
c------------------------------------
c   Initialisation partie parallele
c------------------------------------

      CALL init_const_mpi
      call init_parallel
      call Read_Distrib

!#ifdef 1
!        CALL init_phys_lmdz(iim,jjp1,llm,mpi_size,distrib_phys)
!#endif
!      CALL set_bands
!#ifdef 1
!      CALL Init_interface_dyn_phys
!#endif
      CALL barrier

      CALL set_bands
      if (mpi_rank==0) call WriteBands
      call SetDistrib(jj_Nb_Caldyn)

c$OMP PARALLEL
      call Init_Mod_hallo
c$OMP END PARALLEL


!c$OMP PARALLEL
!      call initcomgeomphy
!c$OMP END PARALLEL 


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Initialisation de XIOS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


c
c Initialisations pour Cp(T) Venus
      call ini_cpdet
c
c-----------------------------------------------------------------------
c   Choix du calendrier
c   -------------------

c      calend = 'earth_365d'


c-----------------------------------------------------------------------
c   Initialisation des traceurs
c   ---------------------------
c  Choix du nombre de traceurs et du schema pour l'advection
c  dans fichier traceur.def, par default ou via INCA
      call infotrac_init

c Allocation de la tableau q : champs advectes   
      ALLOCATE(q(ip1jmp1,llm,nqtot))

c-----------------------------------------------------------------------
c   Lecture de l'etat initial :
c   ---------------------------

c  lecture du fichier start.nc
      if (read_start) then
      ! we still need to run iniacademic to initialize some
      ! constants & fields, if we run the 'newtonian' or 'SW' cases:
        if (iflag_phys.ne.1) then
          CALL iniacademic(vcov,ucov,teta,q,masse,ps,phis,time_0)
        endif

        CALL dynetat0("start.nc",vcov,ucov,
     &              teta,q,masse,ps,phis, time_0)
       
        ! Load relaxation fields (simple nudging). AS 09/2013
        ! ---------------------------------------------------
        if (planet_type.eq."generic") then
         if (ok_guide) then
           CALL relaxetat0("relax.nc")
         endif
        endif
 
c       write(73,*) 'ucov',ucov
c       write(74,*) 'vcov',vcov
c       write(75,*) 'teta',teta
c       write(76,*) 'ps',ps
c       write(77,*) 'q',q

      endif ! of if (read_start)

c le cas echeant, creation d un etat initial
      IF (prt_level > 9) WRITE(lunout,*)
     .              'GCM: AVANT iniacademic AVANT AVANT AVANT AVANT'
      if (.not.read_start) then
         CALL iniacademic(vcov,ucov,teta,q,masse,ps,phis,time_0)
      endif


c-----------------------------------------------------------------------
c   Lecture des parametres de controle pour la simulation :
c   -------------------------------------------------------
c  on recalcule eventuellement le pas de temps

      IF(MOD(day_step,iperiod).NE.0) THEN
        abort_message = 
     .  'Il faut choisir un nb de pas par jour multiple de iperiod'
        call abort_gcm(modname,abort_message,1)
      ENDIF

      IF(MOD(day_step,iphysiq).NE.0) THEN
        abort_message = 
     * 'Il faut choisir un nb de pas par jour multiple de iphysiq'
        call abort_gcm(modname,abort_message,1)
      ENDIF

      zdtvr    = daysec/REAL(day_step)
        IF(dtvr.NE.zdtvr) THEN
         WRITE(lunout,*)
     .    'WARNING!!! changement de pas de temps',dtvr,'>',zdtvr
        ENDIF

C
C on remet le calendrier � zero si demande
c
      IF (start_time /= starttime) then
        WRITE(lunout,*)' GCM: Attention l''heure de depart lue dans le'
     &,' fichier restart ne correspond pas � celle lue dans le run.def'
        IF (raz_date == 1) then
          WRITE(lunout,*)'Je prends l''heure lue dans run.def'
          start_time = starttime
        ELSE
          call abort_gcm("gcm", "'Je m''arrete'", 1)
        ENDIF
      ENDIF
      IF (raz_date == 1) THEN
        annee_ref = anneeref
        day_ref = dayref
        day_ini = dayref
        itau_dyn = 0
        itau_phy = 0
        time_0 = 0.
        write(lunout,*)
     .   'GCM: On reinitialise a la date lue dans gcm.def'
      ELSE IF (annee_ref .ne. anneeref .or. day_ref .ne. dayref) THEN
        write(lunout,*)
     .  'GCM: Attention les dates initiales lues dans le fichier'
        write(lunout,*)
     .  ' restart ne correspondent pas a celles lues dans '
        write(lunout,*)' gcm.def'
        write(lunout,*)' annee_ref=',annee_ref," anneeref=",anneeref
        write(lunout,*)' day_ref=',day_ref," dayref=",dayref
        write(lunout,*)' Pas de remise a zero'
      ENDIF

c      if (annee_ref .ne. anneeref .or. day_ref .ne. dayref) then
c        write(lunout,*)
c     .  'GCM: Attention les dates initiales lues dans le fichier'
c        write(lunout,*)
c     .  ' restart ne correspondent pas a celles lues dans '
c        write(lunout,*)' gcm.def'
c        write(lunout,*)' annee_ref=',annee_ref," anneeref=",anneeref
c        write(lunout,*)' day_ref=',day_ref," dayref=",dayref
c        if (raz_date .ne. 1) then
c          write(lunout,*)
c     .    'GCM: On garde les dates du fichier restart'
c        else
c          annee_ref = anneeref
c          day_ref = dayref
c          day_ini = dayref
c          itau_dyn = 0
c          itau_phy = 0
c          time_0 = 0.
c          write(lunout,*)
c     .   'GCM: On reinitialise a la date lue dans gcm.def'
c        endif
c      ELSE
c        raz_date = 0
c      endif


! Ehouarn: we still need to define JD_ref and JH_ref
! and since we don't know how many days there are in a year
! we set JD_ref to 0 (this should be improved ...)
      jD_ref=0
      jH_ref=0


      if (iflag_phys.eq.1) then
      ! these initialisations have already been done (via iniacademic)
      ! if running in SW or Newtonian mode
c-----------------------------------------------------------------------
c   Initialisation des constantes dynamiques :
c   ------------------------------------------
        dtvr = zdtvr
        CALL iniconst

c-----------------------------------------------------------------------
c   Initialisation de la geometrie :
c   --------------------------------
        CALL inigeom

c-----------------------------------------------------------------------
c   Initialisation du filtre :
c   --------------------------
        CALL inifilr
      endif ! of if (iflag_phys.eq.1)
c
c-----------------------------------------------------------------------
c   Initialisation de la dissipation :
c   ----------------------------------

      CALL inidissip( lstardis, nitergdiv, nitergrot, niterh   ,
     *                tetagdiv, tetagrot , tetatemp, vert_prof_dissip)

c-----------------------------------------------------------------------
c   Initialisation des I/O :
c   ------------------------


      if (nday>=0) then ! standard case
        day_end=day_ini+nday
      else ! special case when nday <0, run -nday dynamical steps
        day_end=day_ini-nday/day_step
      endif
      if (less1day) then
        day_end=day_ini+floor(time_0+fractday)
      endif
      if (ndynstep.gt.0) then
        day_end=day_ini+floor(time_0+float(ndynstep)/float(day_step))
      endif
      
      WRITE(lunout,'(a,i7,a,i7)')
     &             "run from day ",day_ini,"  to day",day_end




c-----------------------------------------------------------------------
c   Initialisation de la physique :
c   -------------------------------

      IF ((iflag_phys==1).or.(iflag_phys>=100)) THEN
! Physics

         CALL iniphysiq(iim,jjm,llm,
     &                distrib_phys(mpi_rank),comm_lmdz,
     &                daysec,day_ini,dtphys/nsplit_phys,
     &                rlatu,rlatv,rlonu,rlonv,aire,cu,cv,rad,g,r,cpp,
     &                iflag_phys)

!         call_iniphys=.false.
      ENDIF ! of IF (call_iniphys.and.(iflag_phys==1.or.iflag_phys>=100))


      if (planet_type=="mars") then
         ! For Mars we transmit day_ini
        CALL dynredem0_p("restart.nc", day_ini, phis)
      else
        CALL dynredem0_p("restart.nc", day_end, phis)
      endif
      ecripar = .TRUE.


! #endif of #ifdef CPP_IOIPSL

c  Choix des frequences de stokage pour le offline
c      istdyn=day_step/4     ! stockage toutes les 6h=1jour/4
c      istdyn=day_step/12     ! stockage toutes les 2h=1jour/12
      istdyn=day_step/4     ! stockage toutes les 6h=1jour/12
      istphy=istdyn/iphysiq     


c
c-----------------------------------------------------------------------
c   Integration temporelle du modele :
c   ----------------------------------

c       write(78,*) 'ucov',ucov
c       write(78,*) 'vcov',vcov
c       write(78,*) 'teta',teta
c       write(78,*) 'ps',ps
c       write(78,*) 'q',q

!c$OMP PARALLEL DEFAULT(SHARED) COPYIN(/temps/,/logici/,/logicl/)
!variable temps no longer exists
c$OMP PARALLEL DEFAULT(SHARED)
c	Copy all threadprivate variables from temps_mod
c$OMP1 COPYIN(dt,jD_ref,jH_ref,start_time,hour_ini,day_ini,day_end)
c$OMP1 COPYIN(annee_ref,day_ref,itau_dyn,itau_phy,itaufin,calend)
c	Copy all threadprivate variables from logic_mod
c$OMP1 COPYIN(purmats,forward,leapf,apphys,statcl,conser,apdiss,apdelq)
c$OMP1 COPYIN(saison,ecripar,fxyhypb,ysinus,read_start,ok_guide)
c$OMP1 COPYIN(ok_strato,tidal,ok_gradsfile,ok_limit,ok_etat0)
c$OMP1 COPYIN(iflag_phys,iflag_trac)


      CALL leapfrog_p(ucov,vcov,teta,ps,masse,phis,q,
     .              time_0)
c$OMP END PARALLEL


      END


