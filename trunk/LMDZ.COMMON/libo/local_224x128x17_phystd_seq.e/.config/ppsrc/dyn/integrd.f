!
! $Id: integrd.F 1616 2012-02-17 11:59:00Z emillour $
!
      SUBROUTINE integrd
     $  (  nq,vcovm1,ucovm1,tetam1,psm1,massem1,
     $     dv,du,dteta,dq,dp,vcov,ucov,teta,q,ps,masse,phis !,finvmaold
     &  )

      use control_mod, only : planet_type,force_conserv_tracer
      USE comvert_mod, ONLY: ap,bp
      USE comconst_mod, ONLY: pi
      USE logic_mod, ONLY: leapf
      USE temps_mod, ONLY: dt

      IMPLICIT NONE


c=======================================================================
c
c   Auteur:  P. Le Van
c   -------
c
c   objet:
c   ------
c
c   Incrementation des tendances dynamiques
c
c=======================================================================
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

      PARAMETER (iim= 224,jjm=128,llm=17,ndm=1)

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

      integer,intent(in) :: nq ! number of tracers to handle in this routine
      real,intent(inout) :: vcov(ip1jm,llm) ! covariant meridional wind
      real,intent(inout) :: ucov(ip1jmp1,llm) ! covariant zonal wind
      real,intent(inout) :: teta(ip1jmp1,llm) ! potential temperature
      real,intent(inout) :: q(ip1jmp1,llm,nq) ! advected tracers
      real,intent(inout) :: ps(ip1jmp1) ! surface pressure
      real,intent(inout) :: masse(ip1jmp1,llm) ! atmospheric mass
      real,intent(in) :: phis(ip1jmp1) ! ground geopotential !!! unused
      ! values at previous time step
      real,intent(inout) :: vcovm1(ip1jm,llm)
      real,intent(inout) :: ucovm1(ip1jmp1,llm)
      real,intent(inout) :: tetam1(ip1jmp1,llm)
      real,intent(inout) :: psm1(ip1jmp1)
      real,intent(inout) :: massem1(ip1jmp1,llm)
      ! the tendencies to add
      real,intent(in) :: dv(ip1jm,llm)
      real,intent(in) :: du(ip1jmp1,llm)
      real,intent(in) :: dteta(ip1jmp1,llm)
      real,intent(in) :: dp(ip1jmp1)
      real,intent(in) :: dq(ip1jmp1,llm,nq) !!! unused
!      real,intent(out) :: finvmaold(ip1jmp1,llm) !!! unused

c   Local:
c   ------

      REAL vscr( ip1jm ),uscr( ip1jmp1 ),hscr( ip1jmp1 ),pscr(ip1jmp1)
      REAL massescr( ip1jmp1,llm )
      REAL :: massratio(ip1jmp1,llm)
!      REAL finvmasse(ip1jmp1,llm)
      REAL p(ip1jmp1,llmp1)
      REAL tpn,tps,tppn(iim),tpps(iim)
      REAL qpn,qps,qppn(iim),qpps(iim)
      REAL deltap( ip1jmp1,llm )

      INTEGER  l,ij,iq,i,j

      REAL SSUM

c-----------------------------------------------------------------------

      DO  l = 1,llm
        DO  ij = 1,iip1
         ucov(    ij    , l) = 0.
         ucov( ij +ip1jm, l) = 0.
         uscr(     ij      ) = 0.
         uscr( ij +ip1jm   ) = 0.
        ENDDO
      ENDDO


c    ............    integration  de       ps         ..............

      CALL SCOPY(ip1jmp1*llm, masse, 1, massescr, 1)

      DO ij = 1,ip1jmp1
       pscr (ij)    = ps(ij)
       ps (ij)      = psm1(ij) + dt * dp(ij)
      ENDDO
c
      DO ij = 1,ip1jmp1
        IF( ps(ij).LT.0. ) THEN
         write(lunout,*) "integrd: negative surface pressure ",ps(ij)
         write(lunout,*) " at node ij =", ij
         ! since ij=j+(i-1)*jjp1 , we have
         j=modulo(ij,jjp1)
         i=1+(ij-j)/jjp1
         write(lunout,*) " lon = ",rlonv(i)*180./pi, " deg",
     &                   " lat = ",rlatu(j)*180./pi, " deg"
         write(lunout,*) " psm1(ij)=",psm1(ij)," dt=",dt,
     &                   " dp(ij)=",dp(ij)
         call abort_gcm("integrd", "", 1)
        ENDIF
      ENDDO
c
      DO  ij    = 1, iim
       tppn(ij) = aire(   ij   ) * ps(  ij    )
       tpps(ij) = aire(ij+ip1jm) * ps(ij+ip1jm)
      ENDDO
       tpn      = SSUM(iim,tppn,1)/apoln
       tps      = SSUM(iim,tpps,1)/apols
      DO ij   = 1, iip1
       ps(   ij   )  = tpn
       ps(ij+ip1jm)  = tps
      ENDDO
c
c  ... Calcul  de la nouvelle masse d'air au dernier temps integre t+1 ...
c
      CALL pression ( ip1jmp1, ap, bp, ps, p )
      CALL massdair (     p  , masse         )

! Ehouarn : we don't use/need finvmaold and finvmasse,
!           so might as well not compute them
!      CALL   SCOPY( ijp1llm  , masse, 1, finvmasse,  1      )
!      CALL filtreg( finvmasse, jjp1, llm, -2, 2, .TRUE., 1  )
c

c    ............   integration  de  ucov, vcov,  h     ..............

      DO l = 1,llm

       DO ij = iip2,ip1jm
        uscr( ij )   =  ucov( ij,l )
        ucov( ij,l ) = ucovm1( ij,l ) + dt * du( ij,l )
       ENDDO

       DO ij = 1,ip1jm
        vscr( ij )   =  vcov( ij,l )
        vcov( ij,l ) = vcovm1( ij,l ) + dt * dv( ij,l )
       ENDDO

       DO ij = 1,ip1jmp1
        hscr( ij )    =  teta(ij,l)
        teta ( ij,l ) = tetam1(ij,l) *  massem1(ij,l) / masse(ij,l) 
     &                + dt * dteta(ij,l) / masse(ij,l)
       ENDDO

c   ....  Calcul de la valeur moyenne, unique  aux poles pour  teta    ......
c
c
       DO  ij   = 1, iim
        tppn(ij) = aire(   ij   ) * teta(  ij    ,l)
        tpps(ij) = aire(ij+ip1jm) * teta(ij+ip1jm,l)
       ENDDO
        tpn      = SSUM(iim,tppn,1)/apoln
        tps      = SSUM(iim,tpps,1)/apols

       DO ij   = 1, iip1
        teta(   ij   ,l)  = tpn
        teta(ij+ip1jm,l)  = tps
       ENDDO
c

       IF(leapf)  THEN
         CALL SCOPY ( ip1jmp1, uscr(1), 1, ucovm1(1, l), 1 )
         CALL SCOPY (   ip1jm, vscr(1), 1, vcovm1(1, l), 1 )
         CALL SCOPY ( ip1jmp1, hscr(1), 1, tetam1(1, l), 1 )
       END IF

      ENDDO ! of DO l = 1,llm


c
c   .......  integration de   q   ......
c
c$$$      IF( iadv(1).NE.3.AND.iadv(2).NE.3 )    THEN
c$$$c
c$$$       IF( forward. OR . leapf )  THEN
c$$$        DO iq = 1,2
c$$$        DO  l = 1,llm
c$$$        DO ij = 1,ip1jmp1
c$$$        q(ij,l,iq) = ( q(ij,l,iq)*finvmaold(ij,l) + dtvr *dq(ij,l,iq) )/
c$$$     $                            finvmasse(ij,l)
c$$$        ENDDO
c$$$        ENDDO
c$$$        ENDDO
c$$$       ELSE
c$$$         DO iq = 1,2
c$$$         DO  l = 1,llm
c$$$         DO ij = 1,ip1jmp1
c$$$         q( ij,l,iq ) = q( ij,l,iq ) * finvmaold(ij,l) / finvmasse(ij,l)
c$$$         ENDDO
c$$$         ENDDO
c$$$         ENDDO
c$$$
c$$$       END IF
c$$$c
c$$$      ENDIF

      if (planet_type.eq."earth") then
! Earth-specific treatment of first 2 tracers (water)
        DO l = 1, llm
          DO ij = 1, ip1jmp1
            deltap(ij,l) =  p(ij,l) - p(ij,l+1) 
          ENDDO
        ENDDO

        CALL qminimum( q, nq, deltap )

c
c    .....  Calcul de la valeur moyenne, unique  aux poles pour  q .....
c

       DO iq = 1, nq
        DO l = 1, llm

           DO ij = 1, iim
             qppn(ij) = aire(   ij   ) * q(   ij   ,l,iq)
             qpps(ij) = aire(ij+ip1jm) * q(ij+ip1jm,l,iq)
           ENDDO
             qpn  =  SSUM(iim,qppn,1)/apoln
             qps  =  SSUM(iim,qpps,1)/apols

           DO ij = 1, iip1
             q(   ij   ,l,iq)  = qpn
             q(ij+ip1jm,l,iq)  = qps
           ENDDO

        ENDDO
       ENDDO

! Ehouarn: forget about finvmaold
!      CALL  SCOPY( ijp1llm , finvmasse, 1, finvmaold, 1 )

      endif ! of if (planet_type.eq."earth")

      if (force_conserv_tracer) then
        ! Ehouarn: try to keep total amont of tracers fixed 
        ! by acounting for mass change in each cell
        massratio(1:ip1jmp1,1:llm)=massescr(1:ip1jmp1,1:llm)
     &                             /masse(1:ip1jmp1,1:llm)
        do iq=1,nq
        q(1:ip1jmp1,1:llm,iq)=q(1:ip1jmp1,1:llm,iq)
     &                        *massratio(1:ip1jmp1,1:llm)
        enddo
      endif ! of if (force_conserv_tracer)
c
c
c     .....   FIN  de l'integration  de   q    .......

c    .................................................................


      IF( leapf )  THEN
         CALL SCOPY (    ip1jmp1 ,  pscr   , 1,   psm1  , 1 )
         CALL SCOPY ( ip1jmp1*llm, massescr, 1,  massem1, 1 )
      END IF

      RETURN
      END

