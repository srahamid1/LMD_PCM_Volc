        INTEGER nfilun, nfilus, nfilvn, nfilvs
!
! 48 32 19 non-zoom:
!       PARAMETER (nfilun=30,nfilus=30,nfilvn=30,nfilvs=30)
!        PARAMETER (nfilun=6, nfilus=5, nfilvn=5, nfilvs=5)
!         PARAMETER (nfilun=15, nfilus=8, nfilvn=14, nfilvs=8)
!        PARAMETER (nfilun=24, nfilus=23, nfilvn=24, nfilvs=24)
!maf -debug  PARAMETER (nfilun=2, nfilus=1, nfilvn=2, nfilvs=2)
!
!
! 96 49 11 non-zoom:
!cc      PARAMETER (nfilun=9, nfilus=8, nfilvn=8, nfilvs=8)
!
!
! 144 73 11 non-zoom:
!cc      PARAMETER (nfilun=13, nfilus=12, nfilvn=12, nfilvs=12)
!
! 192 143 19 non-zoom:
!             PARAMETER (nfilun=13, nfilus=12, nfilvn=13, nfilvs=13)
!      PARAMETER (nfilun=15, nfilus=14, nfilvn=14, nfilvs=14) !!NO fxyhyper
!      PARAMETER (nfilun=18, nfilus=17, nfilvn=17, nfilvs=17) !!NO fxyhyper
!!        PARAMETER (nfilun=9,nfilus=8,nfilvn=8,nfilvs=8)
        PARAMETER (nfilun=9,nfilus=9,nfilvn=9,nfilvs=9)
! 96 72 19 non-zoom:
!cc      PARAMETER (nfilun=12, nfilus=11, nfilvn=12, nfilvs=12)
!
!        PARAMETER ( nfilun=20, nfilus=20, nfilvn=20, nfilvs=20 )
!       PARAMETER ( nfilun=8, nfilus=7, nfilvn=7, nfilvs=7 )
!
!
!      Ici , on a exagere  les nombres de lignes de latitudes a filtrer .
!
!      La premiere fois que  le Gcm  rentrera  dans le Filtre ,
!
!      il indiquera  les bonnes valeurs  de  nfilun , nflius, nfilvn  et 
!
!      nfilvs  a  mettre .  Il suffira alors de changer ces valeurs dans
!
!      Parameter  ci-dessus  et de relancer  le  run .  

