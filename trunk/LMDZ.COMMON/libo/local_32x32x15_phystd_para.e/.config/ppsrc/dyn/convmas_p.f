      SUBROUTINE convmas_p (pbaru, pbarv, convm )
c
      USE parallel_lmdz
      IMPLICIT NONE

c=======================================================================
c
c   Auteurs:  P. Le Van , F. Hourdin  .
c   -------
c
c   Objet:
c   ------
c
c   ********************************************************************
c   .... calcul de la convergence du flux de masse aux niveaux p ...
c   ********************************************************************
c
c
c     pbaru  et  pbarv  sont des arguments d'entree pour le s-pg  ....
c      .....  convm      est  un argument de sortie pour le s-pg  ....
c
c    le calcul se fait de haut en bas, 
c    la convergence de masse au niveau p(llm+1) est egale a 0. et
c    n'est pas stockee dans le tableau convm .
c
c
c=======================================================================
c
c   Declarations:
c   -------------


!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 32,jjm=32,llm=15,ndm=1)

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


      REAL pbaru( ip1jmp1,llm ),pbarv( ip1jm,llm )
      REAL, target :: convm(  ip1jmp1,llm )
      INTEGER   l,ij

      INTEGER ijb,ije,jjb,jje
 
      
c-----------------------------------------------------------------------
c    ....  calcul de - (d(pbaru)/dx + d(pbarv)/dy ) ......

      CALL  convflu_p( pbaru, pbarv, llm, convm )

c-----------------------------------------------------------------------
c   filtrage:
c   ---------
       
       jjb=jj_begin
       jje=jj_end+1
       if (pole_sud) jje=jj_end
 
       CALL filtreg_p( convm, jjb, jje, jjp1, llm, 2, 2, .true., 1 )

c    integration de la convergence de masse de haut  en bas ......
       ijb=ij_begin
       ije=ij_end+iip1
       if (pole_sud) ije=ij_end
            
      DO      l      = llmm1, 1, -1
        DO    ij     = ijb, ije
         convm(ij,l) = convm(ij,l) + convm(ij,l+1)
        ENDDO
      ENDDO
c
      RETURN
      END

