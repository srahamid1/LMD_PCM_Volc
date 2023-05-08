










      subroutine blackl(blalong,blat,blae)

      implicit double precision (a-h,o-z)

      ! physical constants
      sigma=5.67032D-8
      pi=datan(1.d0)*4.d0
      c0=2.9979d+08
      h=6.6262d-34
      cbol=1.3806d-23
      rind=1.d0
      c=c0/rind
      c1=h*(c**2)
      c2=h*c/cbol


      blae=2.d0*pi*c1/blalong**5/(dexp(c2/blalong/blat)-1.d0)


      return
      end
