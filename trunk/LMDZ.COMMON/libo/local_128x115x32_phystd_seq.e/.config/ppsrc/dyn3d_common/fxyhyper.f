










!
! $Header$
!
c
c
       SUBROUTINE fxyhyper ( yzoom, grossy, dzoomy,tauy  ,   
     ,                       xzoom, grossx, dzoomx,taux  ,
     , rlatu,yprimu,rlatv,yprimv,rlatu1,  yprimu1,  rlatu2,  yprimu2  , 
     , rlonu,xprimu,rlonv,xprimv,rlonm025,xprimm025,rlonp025,xprimp025)

       IMPLICIT NONE
c
c      Auteur :  P. Le Van .
c
c      d'apres  formulations de R. Sadourny .
c
c
c     Ce spg calcule les latitudes( routine fyhyp ) et longitudes( fxhyp )
c            par des  fonctions  a tangente hyperbolique .
c
c     Il y a 3 parametres ,en plus des coordonnees du centre du zoom (xzoom
c                      et  yzoom )   :  
c
c     a) le grossissement du zoom  :  grossy  ( en y ) et grossx ( en x )
c     b) l' extension     du zoom  :  dzoomy  ( en y ) et dzoomx ( en x )
c     c) la raideur de la transition du zoom  :   taux et tauy   
c
c  N.B : Il vaut mieux avoir   :   grossx * dzoomx <  pi    ( radians )
c ******
c                  et              grossy * dzoomy <  pi/2  ( radians )
c
!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 128,jjm=115,llm=32,ndm=1)

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


c   .....  Arguments  ...
c
       REAL xzoom,yzoom,grossx,grossy,dzoomx,dzoomy,taux,tauy
       REAL rlatu(jjp1), yprimu(jjp1),rlatv(jjm), yprimv(jjm),
     , rlatu1(jjm), yprimu1(jjm), rlatu2(jjm), yprimu2(jjm)
       REAL rlonu(iip1),xprimu(iip1),rlonv(iip1),xprimv(iip1),
     , rlonm025(iip1),xprimm025(iip1), rlonp025(iip1),xprimp025(iip1)
       REAL(KIND=8)  dxmin, dxmax , dymin, dymax

c   ....   var. locales   .....
c
       INTEGER i,j
c

       CALL fyhyp ( yzoom, grossy, dzoomy,tauy  , 
     ,  rlatu, yprimu,rlatv,yprimv,rlatu2,yprimu2,rlatu1,yprimu1 ,
     ,  dymin,dymax                                               )

       CALL fxhyp(xzoom,grossx,dzoomx,taux,rlonm025,xprimm025,rlonv,
     , xprimv,rlonu,xprimu,rlonp025,xprimp025 , dxmin,dxmax         )


        DO i = 1, iip1
          IF(rlonp025(i).LT.rlonv(i))  THEN
           WRITE(6,*) ' Attention !  rlonp025 < rlonv',i
            STOP
          ENDIF

          IF(rlonv(i).LT.rlonm025(i))  THEN 
           WRITE(6,*) ' Attention !  rlonm025 > rlonv',i
            STOP
          ENDIF

          IF(rlonp025(i).GT.rlonu(i))  THEN
           WRITE(6,*) ' Attention !  rlonp025 > rlonu',i
            STOP
          ENDIF
        ENDDO

        WRITE(6,*) '  *** TEST DE COHERENCE  OK    POUR   FX **** '

c
       DO j = 1, jjm
c
       IF(rlatu1(j).LE.rlatu2(j))   THEN
         WRITE(6,*)'Attention ! rlatu1 < rlatu2 ',rlatu1(j), rlatu2(j),j
         STOP 13
       ENDIF
c
       IF(rlatu2(j).LE.rlatu(j+1))  THEN
        WRITE(6,*)'Attention ! rlatu2 < rlatup1 ',rlatu2(j),rlatu(j+1),j
        STOP 14
       ENDIF
c
       IF(rlatu(j).LE.rlatu1(j))    THEN
        WRITE(6,*)' Attention ! rlatu < rlatu1 ',rlatu(j),rlatu1(j),j
        STOP 15
       ENDIF
c
       IF(rlatv(j).LE.rlatu2(j))    THEN
        WRITE(6,*)' Attention ! rlatv < rlatu2 ',rlatv(j),rlatu2(j),j
        STOP 16
       ENDIF
c
       IF(rlatv(j).ge.rlatu1(j))    THEN
        WRITE(6,*)' Attention ! rlatv > rlatu1 ',rlatv(j),rlatu1(j),j
        STOP 17
       ENDIF
c
       IF(rlatv(j).ge.rlatu(j))     THEN
        WRITE(6,*) ' Attention ! rlatv > rlatu ',rlatv(j),rlatu(j),j
        STOP 18
       ENDIF
c
       ENDDO
c
       WRITE(6,*) '  *** TEST DE COHERENCE  OK    POUR   FY **** '
c
        WRITE(6,18)
        WRITE(6,*) '  Latitudes  '
        WRITE(6,*) ' *********** '
        WRITE(6,18)
        WRITE(6,3)  dymin, dymax
        WRITE(6,*) ' Si cette derniere est trop lache , modifiez les par
     ,ametres  grossism , tau , dzoom pour Y et repasser ! '
c
        WRITE(6,18)
        WRITE(6,*) '  Longitudes  '
        WRITE(6,*) ' ************ '
        WRITE(6,18)
        WRITE(6,3)  dxmin, dxmax
        WRITE(6,*) ' Si cette derniere est trop lache , modifiez les par
     ,ametres  grossism , tau , dzoom pour Y et repasser ! '
        WRITE(6,18)
c
3      Format(1x, ' Au centre du zoom , la longueur de la maille est',
     ,  ' d environ ',f8.2 ,' degres  ',
     , ' alors que la maille en dehors de la zone du zoom est d environ
     , ', f8.2,' degres ' )
18      FORMAT(/)

       RETURN
       END

