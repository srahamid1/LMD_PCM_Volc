!
! $Header$
!
      SUBROUTINE gradiv2(klevel, xcov, ycov, ld, gdx, gdy )
c
c     P. Le Van
c
c   **********************************************************
c                                ld
c       calcul  de  (grad (div) )   du vect. v ....
c
c     xcov et ycov etant les composant.covariantes de v
c   **********************************************************
c     xcont , ycont et ld  sont des arguments  d'entree pour le s-prog
c      gdx   et  gdy       sont des arguments de sortie pour le s-prog
c
c
      IMPLICIT NONE
c

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

c
c     ........    variables en arguments      ........

      INTEGER klevel
      REAL  xcov( ip1jmp1,klevel ), ycov( ip1jm,klevel )
      REAL   gdx( ip1jmp1,klevel ),  gdy( ip1jm,klevel )
c
c     ........       variables locales       .........
c
      REAL div(ip1jmp1,llm)
      REAL signe, nugrads
      INTEGER l,ij,iter,ld
      
c    ........................................................
c
c
      CALL SCOPY( ip1jmp1 * klevel, xcov, 1, gdx, 1 )
      CALL SCOPY(   ip1jm * klevel, ycov, 1, gdy, 1 )
c
c
      signe   = (-1.)**ld
      nugrads = signe * cdivu
c


      CALL    divergf( klevel, gdx,   gdy , div )

      IF( ld.GT.1 )   THEN

        CALL laplacien ( klevel, div,  div     )

c    ......  Iteration de l'operateur laplacien_gam   .......

        DO iter = 1, ld -2
         CALL laplacien_gam ( klevel,cuvscvgam1,cvuscugam1,unsair_gam1,
     *                       unsapolnga1, unsapolsga1,  div, div       )
        ENDDO

      ENDIF


       CALL filtreg( div   , jjp1, klevel, 2, 1, .TRUE., 1 )
       CALL  grad  ( klevel,  div,   gdx,  gdy             )

c
       DO   l = 1, klevel
         DO  ij = 1, ip1jmp1
          gdx( ij,l ) = gdx( ij,l ) * nugrads
         ENDDO
         DO  ij = 1, ip1jm
          gdy( ij,l ) = gdy( ij,l ) * nugrads
         ENDDO
       ENDDO
c
       RETURN
       END

