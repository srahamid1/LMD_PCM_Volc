










!
! $Id: dump2d.F 1279 2009-12-10 09:02:56Z fairhead $
!
      SUBROUTINE dump2d(im,jm,z,nom_z)
      IMPLICIT NONE
      INTEGER im,jm
      REAL z(im,jm)
      CHARACTER (len=*) :: nom_z

      INTEGER i,j,imin,illm,jmin,jllm
      REAL zmin,zllm

      WRITE(*,*) "dump2d: ",trim(nom_z)

      zmin=z(1,1)
      zllm=z(1,1)
      imin=1
      illm=1
      jmin=1
      jllm=1

      DO j=1,jm
         DO i=1,im
            IF(z(i,j).GT.zllm) THEN
               illm=i
               jllm=j
               zllm=z(i,j)
            ENDIF
            IF(z(i,j).LT.zmin) THEN
               imin=i
               jmin=j
               zmin=z(i,j)
            ENDIF
         ENDDO
      ENDDO

      PRINT*,'MIN: ',zmin
      PRINT*,'MAX: ',zllm

      IF(zllm.GT.zmin) THEN
       DO j=1,jm
        WRITE(*,'(600i1)') (NINT(10.*(z(i,j)-zmin)/(zllm-zmin)),i=1,im)
       ENDDO
      ENDIF
      RETURN
      END
