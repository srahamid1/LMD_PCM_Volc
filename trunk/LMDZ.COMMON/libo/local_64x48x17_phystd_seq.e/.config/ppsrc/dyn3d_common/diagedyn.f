!
! $Id: diagedyn.F 1279 2009-12-10 09:02:56Z fairhead $
!

C======================================================================
      SUBROUTINE diagedyn(tit,iprt,idiag,idiag2,dtime
     e  , ucov    , vcov , ps, p ,pk , teta , q, ql)
C======================================================================
C
C Purpose:
C    Calcul la difference d'enthalpie et de masse d'eau entre 2 appels,
C    et calcul le flux de chaleur et le flux d'eau necessaire a ces 
C    changements. Ces valeurs sont moyennees sur la surface de tout
C    le globe et sont exprime en W/2 et kg/s/m2
C    Outil pour diagnostiquer la conservation de l'energie
C    et de la masse dans la dynamique.
C
C
c======================================================================
C Arguments: 
C tit-----imput-A15- Comment added in PRINT (CHARACTER*15)
C iprt----input-I-  PRINT level ( <=1 : no PRINT)
C idiag---input-I- indice dans lequel sera range les nouveaux
C                  bilans d' entalpie et de masse
C idiag2--input-I-les nouveaux bilans d'entalpie et de masse 
C                 sont compare au bilan de d'enthalpie de masse de
C                 l'indice numero idiag2 
C                 Cas parriculier : si idiag2=0, pas de comparaison, on
c                 sort directement les bilans d'enthalpie et de masse 
C dtime----input-R- time step (s)
C uconv, vconv-input-R- vents covariants (m/s)
C ps-------input-R- Surface pressure (Pa)
C p--------input-R- pressure at the interfaces
C pk-------input-R- pk= (p/Pref)**kappa
c teta-----input-R- potential temperature (K)
c q--------input-R- vapeur d'eau (kg/kg)
c ql-------input-R- liquid watter (kg/kg)
c aire-----input-R- mesh surafce (m2)
c
C the following total value are computed by UNIT of earth surface
C
C d_h_vcol--output-R- Heat flux (W/m2) define as the Enthalpy 
c            change (J/m2) during one time step (dtime) for the whole 
C            atmosphere (air, watter vapour, liquid and solid)
C d_qt------output-R- total water mass flux (kg/m2/s) defined as the 
C           total watter (kg/m2) change during one time step (dtime),
C d_qw------output-R- same, for the watter vapour only (kg/m2/s)
C d_ql------output-R- same, for the liquid watter only (kg/m2/s)
C d_ec------output-R- Cinetic Energy Budget (W/m2) for vertical air column
C
C
C J.L. Dufresne, July 2002
c======================================================================
 
      USE control_mod, ONLY : planet_type
      USE cpdet_mod, ONLY: cpdet,tpot2t

      IMPLICIT NONE
C

!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 64,jjm=48,llm=17,ndm=1)

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


!#ifdef CPP_EARTH
!#include "../phylmd/YOMCST.h"
!#include "../phylmd/YOETHF.h"
!#endif
! Ehouarn: for now set these parameters to what is in Earth physics...
!          (cf ../phylmd/suphel.h)
!          this should be generalized...
      REAL,PARAMETER :: RCPD=
     &               3.5*(1000.*(6.0221367E+23*1.380658E-23)/28.9644)
      REAL,PARAMETER :: RCPV=
     &               4.*(1000.*(6.0221367E+23*1.380658E-23)/18.0153)
      REAL,PARAMETER :: RCS=RCPV
      REAL,PARAMETER :: RCW=RCPV
      REAL,PARAMETER :: RLSTT=2.8345E+6
      REAL,PARAMETER :: RLVTT=2.5008E+6
!
C
      INTEGER imjmp1
      PARAMETER( imjmp1=iim*jjp1)
c     Input variables
      CHARACTER*15 tit
      INTEGER iprt,idiag, idiag2
      REAL dtime
      REAL vcov(ip1jm,llm),ucov(ip1jmp1,llm) ! vents covariants
      REAL ps(ip1jmp1)                       ! pression  au sol
      REAL p (ip1jmp1,llmp1  )  ! pression aux interfac.des couches
      REAL pk (ip1jmp1,llm  )  ! = (p/Pref)**kappa
      REAL teta(ip1jmp1,llm)                 ! temperature potentielle 
      REAL q(ip1jmp1,llm)               ! champs eau vapeur
      REAL ql(ip1jmp1,llm)               ! champs eau liquide


c     Output variables
      REAL d_h_vcol, d_qt, d_qw, d_ql, d_qs, d_ec
C
C     Local variables
c
      REAL h_vcol_tot, h_dair_tot, h_qw_tot, h_ql_tot
     .  , h_qs_tot, qw_tot, ql_tot, qs_tot , ec_tot
c h_vcol_tot--  total enthalpy of vertical air column 
C            (air with watter vapour, liquid and solid) (J/m2)
c h_dair_tot-- total enthalpy of dry air (J/m2)
c h_qw_tot----  total enthalpy of watter vapour (J/m2)
c h_ql_tot----  total enthalpy of liquid watter (J/m2)
c h_qs_tot----  total enthalpy of solid watter  (J/m2)
c qw_tot------  total mass of watter vapour (kg/m2)
c ql_tot------  total mass of liquid watter (kg/m2)
c qs_tot------  total mass of solid watter (kg/m2)
c ec_tot------  total cinetic energy (kg/m2)
C
      REAL masse(ip1jmp1,llm)                ! masse d'air
      REAL vcont(ip1jm,llm),ucont(ip1jmp1,llm)
      REAL ecin(ip1jmp1,llm)

      REAL zaire(imjmp1)
      REAL zps(imjmp1)
      REAL zairm(imjmp1,llm)
      REAL zecin(imjmp1,llm)
      REAL zpaprs(imjmp1,llm)
      REAL zpk(imjmp1,llm)
      REAL zt(imjmp1,llm)
      REAL zh(imjmp1,llm)
      REAL zqw(imjmp1,llm)
      REAL zql(imjmp1,llm)
      REAL zqs(imjmp1,llm)

      REAL  zqw_col(imjmp1)
      REAL  zql_col(imjmp1)
      REAL  zqs_col(imjmp1)
      REAL  zec_col(imjmp1)
      REAL  zh_dair_col(imjmp1)
      REAL  zh_qw_col(imjmp1), zh_ql_col(imjmp1), zh_qs_col(imjmp1)
C
      REAL      d_h_dair, d_h_qw, d_h_ql, d_h_qs
C
      REAL airetot, zcpvap, zcwat, zcice
C
      INTEGER i, k, jj, ij , l ,ip1jjm1
C
      INTEGER ndiag     ! max number of diagnostic in parallel
      PARAMETER (ndiag=10)
      integer pas(ndiag)
      save pas
      data pas/ndiag*0/
C     
      REAL      h_vcol_pre(ndiag), h_dair_pre(ndiag), h_qw_pre(ndiag)
     $    , h_ql_pre(ndiag), h_qs_pre(ndiag), qw_pre(ndiag)
     $    , ql_pre(ndiag), qs_pre(ndiag) , ec_pre(ndiag)
      SAVE      h_vcol_pre, h_dair_pre, h_qw_pre, h_ql_pre
     $        , h_qs_pre, qw_pre, ql_pre, qs_pre , ec_pre


!#ifdef CPP_EARTH
      IF (planet_type=="earth") THEN
      
c======================================================================
C     Compute Kinetic enrgy
      CALL covcont  ( llm    , ucov    , vcov , ucont, vcont        )
      CALL enercin ( vcov   , ucov  , vcont     , ucont  , ecin  )
      CALL massdair( p, masse )
c======================================================================
C
C
      print*,'MAIS POURQUOI DONC DIAGEDYN NE MARCHE PAS ?'
      return
C     On ne garde les donnees que dans les colonnes i=1,iim
      DO jj = 1,jjp1
        ip1jjm1=iip1*(jj-1)
        DO ij =  1,iim
          i=iim*(jj-1)+ij
          zaire(i)=aire(ij+ip1jjm1)
          zps(i)=ps(ij+ip1jjm1)
        ENDDO 
      ENDDO 
C 3D arrays
      DO l  =  1, llm
        DO jj = 1,jjp1
          ip1jjm1=iip1*(jj-1)
          DO ij =  1,iim
            i=iim*(jj-1)+ij
            zairm(i,l) = masse(ij+ip1jjm1,l)
            zecin(i,l) = ecin(ij+ip1jjm1,l)
            zpaprs(i,l) = p(ij+ip1jjm1,l)
            zpk(i,l) = pk(ij+ip1jjm1,l)
            zh(i,l) = teta(ij+ip1jjm1,l)
            zqw(i,l) = q(ij+ip1jjm1,l)
            zql(i,l) = ql(ij+ip1jjm1,l)
            zqs(i,l) = 0.
          ENDDO 
        ENDDO 
      ENDDO 
C
C     Reset variables
      DO i = 1, imjmp1
        zqw_col(i)=0.
        zql_col(i)=0.
        zqs_col(i)=0.
        zec_col(i) = 0.
        zh_dair_col(i) = 0.
        zh_qw_col(i) = 0.
        zh_ql_col(i) = 0.
        zh_qs_col(i) = 0.
      ENDDO
C
      zcpvap=RCPV
      zcwat=RCW
      zcice=RCS
C
C     Compute vertical sum for each atmospheric column
C     ================================================
! ADAPTATION GCM POUR CP(T)
      call tpot2t(imjmp1*llm,zh,zt,zpk)
      DO k = 1, llm
        DO i = 1, imjmp1
C         Watter mass
          zqw_col(i) = zqw_col(i) + zqw(i,k)*zairm(i,k)
          zql_col(i) = zql_col(i) + zql(i,k)*zairm(i,k)
          zqs_col(i) = zqs_col(i) + zqs(i,k)*zairm(i,k)
C         Cinetic Energy
          zec_col(i) =  zec_col(i)
     $        +zecin(i,k)*zairm(i,k)
C         Air enthalpy
          zh_dair_col(i) = zh_dair_col(i)
! ADAPTATION GCM POUR CP(T)
     $        + cpdet(zt(i,k))*(1.-zqw(i,k)-zql(i,k)-zqs(i,k))
     $                       *zairm(i,k)*zt(i,k)
          zh_qw_col(i) = zh_qw_col(i)
     $        + zcpvap*zqw(i,k)*zairm(i,k)*zt(i,k) 
          zh_ql_col(i) = zh_ql_col(i)
     $        + zcwat*zql(i,k)*zairm(i,k)*zt(i,k) 
     $        - RLVTT*zql(i,k)*zairm(i,k)
          zh_qs_col(i) = zh_qs_col(i)
     $        + zcice*zqs(i,k)*zairm(i,k)*zt(i,k) 
     $        - RLSTT*zqs(i,k)*zairm(i,k)

        END DO
      ENDDO
C
C     Mean over the planete surface
C     =============================
      qw_tot = 0.
      ql_tot = 0.
      qs_tot = 0.
      ec_tot = 0.
      h_vcol_tot = 0.
      h_dair_tot = 0.
      h_qw_tot = 0.
      h_ql_tot = 0.
      h_qs_tot = 0.
      airetot=0.
C
      do i=1,imjmp1
        qw_tot = qw_tot + zqw_col(i)
        ql_tot = ql_tot + zql_col(i)
        qs_tot = qs_tot + zqs_col(i)
        ec_tot = ec_tot + zec_col(i)
        h_dair_tot = h_dair_tot + zh_dair_col(i)
        h_qw_tot = h_qw_tot + zh_qw_col(i)
        h_ql_tot = h_ql_tot + zh_ql_col(i)
        h_qs_tot = h_qs_tot + zh_qs_col(i)
        airetot=airetot+zaire(i)
      END DO
C
      qw_tot = qw_tot/airetot
      ql_tot = ql_tot/airetot
      qs_tot = qs_tot/airetot
      ec_tot = ec_tot/airetot
      h_dair_tot = h_dair_tot/airetot
      h_qw_tot = h_qw_tot/airetot
      h_ql_tot = h_ql_tot/airetot
      h_qs_tot = h_qs_tot/airetot
C
      h_vcol_tot = h_dair_tot+h_qw_tot+h_ql_tot+h_qs_tot
C
C     Compute the change of the atmospheric state compare to the one 
C     stored in "idiag2", and convert it in flux. THis computation
C     is performed IF idiag2 /= 0 and IF it is not the first CALL
c     for "idiag"
C     ===================================
C
      IF ( (idiag2.gt.0) .and. (pas(idiag2) .ne. 0) ) THEN
        d_h_vcol  = (h_vcol_tot - h_vcol_pre(idiag2) )/dtime
        d_h_dair = (h_dair_tot- h_dair_pre(idiag2))/dtime
        d_h_qw   = (h_qw_tot  - h_qw_pre(idiag2)  )/dtime
        d_h_ql   = (h_ql_tot  - h_ql_pre(idiag2)  )/dtime 
        d_h_qs   = (h_qs_tot  - h_qs_pre(idiag2)  )/dtime 
        d_qw     = (qw_tot    - qw_pre(idiag2)    )/dtime
        d_ql     = (ql_tot    - ql_pre(idiag2)    )/dtime
        d_qs     = (qs_tot    - qs_pre(idiag2)    )/dtime
        d_ec     = (ec_tot    - ec_pre(idiag2)    )/dtime
        d_qt = d_qw + d_ql + d_qs
      ELSE 
        d_h_vcol = 0.
        d_h_dair = 0.
        d_h_qw   = 0.
        d_h_ql   = 0.
        d_h_qs   = 0. 
        d_qw     = 0.
        d_ql     = 0.
        d_qs     = 0.
        d_ec     = 0.
        d_qt     = 0.
      ENDIF 
C
      IF (iprt.ge.2) THEN
        WRITE(6,9000) tit,pas(idiag),d_qt,d_qw,d_ql,d_qs
 9000   format('Dyn3d. Watter Mass Budget (kg/m2/s)',A15
     $      ,1i6,10(1pE14.6))
        WRITE(6,9001) tit,pas(idiag), d_h_vcol
 9001   format('Dyn3d. Enthalpy Budget (W/m2) ',A15,1i6,10(F8.2))
        WRITE(6,9002) tit,pas(idiag), d_ec
 9002   format('Dyn3d. Cinetic Energy Budget (W/m2) ',A15,1i6,10(F8.2))
C        WRITE(6,9003) tit,pas(idiag), ec_tot
 9003   format('Dyn3d. Cinetic Energy (W/m2) ',A15,1i6,10(E15.6))
        WRITE(6,9004) tit,pas(idiag), d_h_vcol+d_ec
 9004   format('Dyn3d. Total Energy Budget (W/m2) ',A15,1i6,10(F8.2))
      END IF 
C
C     Store the new atmospheric state in "idiag"
C
      pas(idiag)=pas(idiag)+1
      h_vcol_pre(idiag)  = h_vcol_tot
      h_dair_pre(idiag) = h_dair_tot
      h_qw_pre(idiag)   = h_qw_tot
      h_ql_pre(idiag)   = h_ql_tot
      h_qs_pre(idiag)   = h_qs_tot
      qw_pre(idiag)     = qw_tot
      ql_pre(idiag)     = ql_tot
      qs_pre(idiag)     = qs_tot
      ec_pre (idiag)    = ec_tot
C
!#else
      ELSE
      write(lunout,*)'diagedyn: set to function with Earth parameters'
      ENDIF ! of if (planet_type=="earth")
!#endif
! #endif of #ifdef CPP_EARTH 
      RETURN 
      END 

