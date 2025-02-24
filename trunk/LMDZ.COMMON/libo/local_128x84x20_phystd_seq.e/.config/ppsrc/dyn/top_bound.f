












!
! $Id: top_bound.F 1793 2013-07-18 07:13:18Z emillour $
!
      SUBROUTINE top_bound(vcov,ucov,teta,masse,dt,ducov)

      USE comvert_mod, ONLY: presnivs,scaleheight,preff
      USE comconst_mod, ONLY: iflag_top_bound,tau_top_bound,
     .			mode_top_bound

      IMPLICIT NONE
c
!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 128,jjm=84,llm=20,ndm=1)

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
! $Header$
!
!CDK comgeom2
      COMMON/comgeom/                                                   &
     & cu(iip1,jjp1),cv(iip1,jjm),unscu2(iip1,jjp1),unscv2(iip1,jjm)  , &
     & aire(iip1,jjp1),airesurg(iip1,jjp1),aireu(iip1,jjp1)           , &
     & airev(iip1,jjm),unsaire(iip1,jjp1),apoln,apols                 , &
     & unsairez(iip1,jjm),airuscv2(iip1,jjm),airvscu2(iip1,jjm)       , &
     & aireij1(iip1,jjp1),aireij2(iip1,jjp1),aireij3(iip1,jjp1)       , &
     & aireij4(iip1,jjp1),alpha1(iip1,jjp1),alpha2(iip1,jjp1)         , &
     & alpha3(iip1,jjp1),alpha4(iip1,jjp1),alpha1p2(iip1,jjp1)        , &
     & alpha1p4(iip1,jjp1),alpha2p3(iip1,jjp1),alpha3p4(iip1,jjp1)    , &
     & fext(iip1,jjm),constang(iip1,jjp1), rlatu(jjp1),rlatv(jjm),      &
     & rlonu(iip1),rlonv(iip1),cuvsurcv(iip1,jjm),cvsurcuv(iip1,jjm)  , &
     & cvusurcu(iip1,jjp1),cusurcvu(iip1,jjp1)                        , &
     & cuvscvgam1(iip1,jjm),cuvscvgam2(iip1,jjm),cvuscugam1(iip1,jjp1), &
     & cvuscugam2(iip1,jjp1),cvscuvgam(iip1,jjm),cuscvugam(iip1,jjp1) , &
     & unsapolnga1,unsapolnga2,unsapolsga1,unsapolsga2                , &
     & unsair_gam1(iip1,jjp1),unsair_gam2(iip1,jjp1)                  , &
     & unsairz_gam(iip1,jjm),aivscu2gam(iip1,jjm),aiuscv2gam(iip1,jjm)  &
     & , xprimu(iip1),xprimv(iip1)


      REAL                                                               &
     & cu,cv,unscu2,unscv2,aire,airesurg,aireu,airev,apoln,apols,unsaire &
     & ,unsairez,airuscv2,airvscu2,aireij1,aireij2,aireij3,aireij4     , &
     & alpha1,alpha2,alpha3,alpha4,alpha1p2,alpha1p4,alpha2p3,alpha3p4 , &
     & fext,constang,rlatu,rlatv,rlonu,rlonv,cuvscvgam1,cuvscvgam2     , &
     & cvuscugam1,cvuscugam2,cvscuvgam,cuscvugam,unsapolnga1           , &
     & unsapolnga2,unsapolsga1,unsapolsga2,unsair_gam1,unsair_gam2     , &
     & unsairz_gam,aivscu2gam,aiuscv2gam,cuvsurcv,cvsurcuv,cvusurcu    , &
     & cusurcvu,xprimu,xprimv


c ..  DISSIPATION LINEAIRE A HAUT NIVEAU, RUN MESO,
C     F. LOTT DEC. 2006
c                                 (  10/12/06  )

c=======================================================================
c
c   Auteur:  F. LOTT  
c   -------
c
c   Objet:
c   ------
c
c   Dissipation lin�aire (ex top_bound de la physique)
c
c=======================================================================

! top_bound sponge layer model:
! Quenching is modeled as: A(t)=Am+A0*exp(-lambda*t)
! where Am is the zonal average of the field (or zero), and lambda the inverse
! of the characteristic quenching/relaxation time scale
! Thus, assuming Am to be time-independent, field at time t+dt is given by:
! A(t+dt)=A(t)-(A(t)-Am)*(1-exp(-lambda*dt))
! Moreover lambda can be a function of model level (see below), and relaxation
! can be toward the average zonal field or just zero (see below).

! NB: top_bound sponge is only called from leapfrog if ok_strato=.true.

! sponge parameters: (loaded/set in conf_gcm.F ; stored in comconst_mod)
!    iflag_top_bound=0 for no sponge
!    iflag_top_bound=1 for sponge over 4 topmost layers
!    iflag_top_bound=2 for sponge from top to ~1% of top layer pressure
!    mode_top_bound=0: no relaxation
!    mode_top_bound=1: u and v relax towards 0
!    mode_top_bound=2: u and v relax towards their zonal mean
!    mode_top_bound=3: u,v and pot. temp. relax towards their zonal mean
!    tau_top_bound : inverse of charactericstic relaxation time scale at
!                       the topmost layer (Hz)


!
! $Header$
!
!  Attention : ce fichier include est compatible format fixe/format libre
!                 veillez à n'utiliser que des ! pour les commentaires
!                 et à bien positionner les & des lignes de continuation 
!                 (les placer en colonne 6 et en colonne 73)
!-----------------------------------------------------------------------
! INCLUDE comdissipn.h

      REAL  tetaudiv, tetaurot, tetah, cdivu, crot, cdivh
!
      COMMON/comdissipn/ tetaudiv(llm),tetaurot(llm),tetah(llm)   ,     &
     &                        cdivu,      crot,         cdivh

!
!    Les parametres de ce common proviennent des calculs effectues dans 
!             Inidissip  .
!
!-----------------------------------------------------------------------
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

c   Arguments:
c   ----------

      real,intent(inout) :: ucov(iip1,jjp1,llm) ! covariant zonal wind
      real,intent(inout) :: vcov(iip1,jjm,llm) ! covariant meridional wind
      real,intent(inout) :: teta(iip1,jjp1,llm) ! potential temperature
      real,intent(in) :: masse(iip1,jjp1,llm) ! mass of atmosphere 
      real,intent(in) :: dt ! time step (s) of sponge model
      real,intent(out) :: ducov(iip1,jjp1,llm) ! increment on ucov due to sponge

c   Local:
c   ------

      REAL massebx(iip1,jjp1,llm),masseby(iip1,jjm,llm),zm
      REAL uzon(jjp1,llm),vzon(jjm,llm),tzon(jjp1,llm)
      
      integer i
      REAL,SAVE :: rdamp(llm) ! quenching coefficient
      real,save :: lambda(llm) ! inverse or quenching time scale (Hz)

      LOGICAL,SAVE :: first=.true.

      INTEGER j,l
      
      if (first) then
         if (iflag_top_bound.eq.1) then
! sponge quenching over the topmost 4 atmospheric layers
             lambda(:)=0.
             lambda(llm)=tau_top_bound
             lambda(llm-1)=tau_top_bound/2.
             lambda(llm-2)=tau_top_bound/4.
             lambda(llm-3)=tau_top_bound/8.
         else if (iflag_top_bound.eq.2) then
! sponge quenching over topmost layers down to pressures which are
! higher than 100 times the topmost layer pressure
             lambda(:)=tau_top_bound
     s       *max(presnivs(llm)/presnivs(:)-0.01,0.)
         endif

! quenching coefficient rdamp(:)
!         rdamp(:)=dt*lambda(:) ! Explicit Euler approx.
         rdamp(:)=1.-exp(-lambda(:)*dt)

         write(lunout,*)'TOP_BOUND mode',mode_top_bound
         write(lunout,*)'Sponge layer coefficients'
         write(lunout,*)'p (Pa)  z(km)  tau(s)   1./tau (Hz)'
         do l=1,llm
           if (rdamp(l).ne.0.) then
             write(lunout,'(6(1pe12.4,1x))')
     &        presnivs(l),log(preff/presnivs(l))*scaleheight,
     &           1./lambda(l),lambda(l)
           endif
         enddo
         first=.false.
      endif ! of if (first)

      CALL massbar(masse,massebx,masseby)

      ! compute zonal average of vcov and u
      if (mode_top_bound.ge.2) then
       do l=1,llm
        do j=1,jjm
          vzon(j,l)=0.
          zm=0.
          do i=1,iim
! NB: we can work using vcov zonal mean rather than v since the
! cv coefficient (which relates the two) only varies with latitudes 
            vzon(j,l)=vzon(j,l)+vcov(i,j,l)*masseby(i,j,l)
            zm=zm+masseby(i,j,l)
          enddo
          vzon(j,l)=vzon(j,l)/zm
        enddo
       enddo

       do l=1,llm
        do j=2,jjm ! excluding poles
          uzon(j,l)=0.
          zm=0.
          do i=1,iim
            uzon(j,l)=uzon(j,l)+massebx(i,j,l)*ucov(i,j,l)/cu(i,j)
            zm=zm+massebx(i,j,l)
          enddo
          uzon(j,l)=uzon(j,l)/zm
        enddo
       enddo
      else ! ucov and vcov will relax towards 0
        vzon(:,:)=0.
        uzon(:,:)=0.
      endif ! of if (mode_top_bound.ge.2)

      ! compute zonal average of potential temperature, if necessary
      if (mode_top_bound.ge.3) then
       do l=1,llm
        do j=2,jjm ! excluding poles
          zm=0.
          tzon(j,l)=0.
          do i=1,iim
            tzon(j,l)=tzon(j,l)+teta(i,j,l)*masse(i,j,l)
            zm=zm+masse(i,j,l)
          enddo
          tzon(j,l)=tzon(j,l)/zm
        enddo
       enddo
      endif ! of if (mode_top_bound.ge.3)

      if (mode_top_bound.ge.1) then
       ! Apply sponge quenching on vcov:
       do l=1,llm
        do i=1,iip1
          do j=1,jjm
            vcov(i,j,l)=vcov(i,j,l)
     &                  -rdamp(l)*(vcov(i,j,l)-vzon(j,l))
          enddo
        enddo
       enddo

       ! Apply sponge quenching on ucov:
       do l=1,llm
        do i=1,iip1
          do j=2,jjm ! excluding poles
            ducov(i,j,l)=-rdamp(l)*(ucov(i,j,l)-cu(i,j)*uzon(j,l))
            ucov(i,j,l)=ucov(i,j,l)
     &                  +ducov(i,j,l)
          enddo
        enddo
       enddo
      endif ! of if (mode_top_bound.ge.1)

      if (mode_top_bound.ge.3) then
       ! Apply sponge quenching on teta:
       do l=1,llm
        do i=1,iip1
          do j=2,jjm ! excluding poles
            teta(i,j,l)=teta(i,j,l)
     &                  -rdamp(l)*(teta(i,j,l)-tzon(j,l))
          enddo
        enddo
       enddo
      endif ! of if (mode_top_bound.ge.3)
    
      END
