      SUBROUTINE BSYNBplatt(NALLIN)
*
*-----------------------------------------------------------------------
*
* BSYNB is merely a continuation of BSYN, data transfered
* via scratch-file 14
*
* B takes line-absorption coefficients generated by A and
* calculates the spectra.
*
* Export version  1988-03-24  ********* Olof Morell *** Uppsala
*
*-----------------------------------------------------------------------
*
      include 'spectrum.inc'
*
      character*50 mcode
      real ETAD(ndp),XC(ndp),maxetad
      real fluxme(lpoint),icenter(lpoint),prof(lpoint)
      real mum,prf,iprf(lpoint)
      doubleprecision XL1,XL2,eqwidth
      doubleprecision XLBEG,XLEND,DEL
      COMMON/ATMOS/ T(NDP),PE(NDP),PG(NDP),XI(NDP),MUM(NDP),RO(NDP),
     &  nnNTAU
*
      COMMON /CTRAN/X(NDP),S(NDP),BPLAN(NDP),XJ(NDP),HFLUX(NDP),XK(NDP)
     & ,FJ(NDP),SOURCE(NDP),TAUS(NDP),DTAUS(NDP),JTAU0,JTAU1,ISCAT
      COMMON/CSURF/ HSURF,Y1(NRAYS)
      COMMON/CANGLE/ NMY,XMY(nrays),XMY2(nrays),WMY(nrays)
      COMMON/TAUC/ TAU(ndp),DTAULN(ndp),NTAU
      COMMON/PIECES/ XL1,XL2,DEL,EPS,NMX,NLBLDU,IINT,XMYC,IWEAK
      COMMON/ROSSC/ ROSS(NDP),cross(ndp)
*
* extension for large number of wavelengths and lines (monster II)
      doubleprecision xlambda
      common/large/ xlambda(lpoint),maxlam,ABSO(NDP,lpoint),
     & absos(ndp,lpoint),absocont(ndp,lpoint),absoscont(ndp,lpoint)
*
      real fcfc(lpoint),y1cy1c(lpoint),y1y1(nrays,lpoint),
     & xlm(lpoint)

      logical findtau1,hydrovelo
      real velocity
      common/velo/velocity(ndp),hydrovelo
      logical debug
      data debug /.false./ 
*
* NLBLDU is a dummy
*
      DATA eqwidth/0./,profold/0./

      PI=3.141593
*
* Initiate angle quadrature points 
*
      NMY=NMX
      CALL GAUSI(NMY,0.,1.,WMY,XMY)
      DO 1 I=1,NMY
        XMY2(I)=XMY(I)*XMY(I)
    1 CONTINUE
*
* Initiate mode of calculation
* IINT =1  : intensity at MY=XMYC
* IINT =0  : flux
* XL1      : wavelength where synthetic spectrum starts
* XL2      : wavelength where synthetic spectrum stops
* DEL      : wavelength step
* IWEAK =1 : weak line approximation for L/KAPPA le. EPS
* note  XL2.gt.XL1
*
      iweak=0
      if (iint.gt.0) then
        nmy=nmy+1
        xmy(nmy)=xmyc
        wmy(nmy)=0.
        WRITE(6,200) XMYC,XL1,XL2,DEL
      end iF
      if(iint.eq.0) write(6,201) xl1,xl2,del
      if(iweak.gt.0) write(6,202) eps
*
* Continuum calculations:
*
*
* 13/03-2019 BPz. We now compute continuum at all wavelengths
* a little more costly in time, but avoid interpolation in wavelength
* continuum flux.
*

      do j=1,maxlam
        xlsingle=xlambda(j)
        do k=1,ntau
          x(k)=absocont(k,j)
          s(k)=absoscont(k,j)
          bplan(k)=bpl(T(k),xlsingle)
        enddo
cc      do 1963 jc=1,nlcont
cc        READ(14,rec=jc) MCODE,idum,xlm(jc),BPLAN,XC,S,XI
cc        if (debug) then
cc          print*,'bsynbplatt read 14 ',mcode,jc,idum,xlm(jc)
cc          print*,' XC     S     BPlan'
cc          do k=1,ntau
cc            print*,xc(k),s(k),bplan(k)
cc          enddo
cc        endif
cc      DO 9 K=1,NTAU
cc        X(K)=XC(K)
!        if (abs(xlsingle-5001.0).lt.1.e-4.and.k.eq.61) then
!           print*,'k',k,'kappa cont',x(k)*ross(k),s(k)*ross(k)
!        endif
cc    9 CONTINUE
       
        call traneqplatt(0)
        Y1CY1C(j)=Y1(NMY)
        FCFC(j)=4.*HSURF*pi
!        IF(IINT.LE.0) WRITE(7,204) fcFC(j),xlsingle
!        IF(IINT.GT.0) WRITE(7,205) Y1Cy1c(j),xlsingle
cc        if (debug) then
cc          print*,' continuum;  lambda = ',jc,xlm(jc),fcfc(jc)
cc        endif
cc1963  continue
      enddo
*
* cont + line flux
*
      numb=0
      do j=1,maxlam
        xlsingle=xlambda(j)
!        if (abs(xlsingle-5001.0).lt.1.e-4) then
!          print*,'k','61','kappa line',abso(61,j)*ross(61),
!     &       absos(61,j)*ross(61)
!        endif

        if(iweak.le.0.or.iint.le.0) then
          do k=1,ntau
* the continuum opacity is already included in abso
ccc              x(k)=xc(k)+abso(k,j+jjj)
            x(k)=abso(k,j)
            s(k)=absos(k,j)
            bplan(k)=bpl(T(k),xlsingle)
          enddo
c            if (debug) then
c              print*,' line;  lambda = ',xlambda(j)
c            endif
cc            if (abs(xlambda(j)-5240.41d0).lt.1.d-4.or.
cc     &          abs(xlambda(j)-5242.49d0).lt.1.d-4.or.
cc     &          abs(xlambda(j)-5241.62d0).lt.1.d-4)  then
cc              print*,'lambda = ',xlambda(j),' calling traneqplatt',idebug
cc              idebug=1
cc            else
          idebug=0
cc            endif
          call traneqplatt(idebug)

* starting with version 12.1, flux is not divided by pi anymore.
* F_lambda integrated over lambda is sigma.Teff^4
          prf=4.*pi*hsurf/fcfc(j)
          fluxme(j)=hsurf*4.*pi
          if (iint.gt.0) then
            iprf(j)=y1(nmy)/y1cy1c(j)
            icenter(j)=y1(nmy)
          endif
          prof(j)=1.-prf
        else
          do k=1,ntau
            etad(k)=abso(k,j)
            maxetad=max(maxetad,etad(k))
          enddo
          if (maxetad.le.eps) then
            call tranw(ntau,tau,xmyc,bplan,xc,etad,deli)
            prof(j)=deli/y1cy1c(j)
          else
            do k=1,ntau
              x(k)=abso(k,j)
              s(k)=absos(k,j)
              xlsingle=xlambda(j)
              bplan(K)=bpl(t(k),xlsingle)
            enddo
c            if (debug) then
c              print*,' line;  lambda = ',xlsingle
c            endif
            call traneqplatt(0)
* starting with version 12.1, flux is not divided by pi anymore.
* F_lambda integrated over lambda is sigma.Teff^4
            prf=4.*pi*hsurf/fcfc(j)
            fluxme(j)=hsurf*4.*pi
            if (iint.gt.0) then
              iprf(j)=y1(nmy)/y1cy1c(j)
              icenter(j)=y1(nmy)
            endif
            prof(j)=1.-prf
          endif
ccc          eqwidth=eqwidth+(prof(j)+profold)*del/2.
ccc          profold=prof(j)
        endif
*
* find depth where tau_lambda=1
        if (hydrovelo) then
          findtau1=.true.
        else
          findtau1=.false.
        endif
        if (findtau1) then
          taulambda=tau(1)*(x(1)+s(1))
          do k=2,ntau
            taulambda=taulambda+(tau(k)-tau(k-1))*(x(k)+s(k)+
     &               x(k-1)+s(k-1))*0.5
            if (taulambda.ge.1.) then
              print333,xlambda(j),k,tau(k),taulambda,t(k),ro(k)
333           format(f10.3,x,i3,x,1pe11.4,x,1pe11.4,x,0pf7.1,x,
     &            1pe11.4,0p)

              goto 1966
            endif
          enddo
1966      continue
        endif
*
* save intensities
        do nlx=1,nmy
          y1y1(nlx,j)=y1(nlx)
        enddo
*
* End loop over wavelengths
*
      enddo
*
* Write spectrum on file for convolution with instrument profile
*
      do j=1,maxlam
        plezflux=1.-prof(j)
        if (iint.eq.0) then
* fluxme is sigma teff^4
          write(46,1964) xlambda(j),plezflux,fluxme(j)
1964      format(f11.3,1x,f10.5,1x,1pe12.5)

C output in case of intensity calculation : store limb function
        else
* We add intensity at center of disk in spectrum output.
          write(46,1965) xlambda(j),plezflux,fluxme(j),
     &                   icenter(j),iprf(j)
1965      format(f11.3,1x,f10.5,2(1x,1pe12.5),1x,0pf8.5)
        endif
      enddo

      call clock
      return
*
  100 FORMAT(4X,I1,6X,I3)
  207 FORMAT(' SPECTRUM CALCULATED FOR THE FOLLOWING ',I3,' LINES'
     &      /' ELEMENT LAMBDA XI(EV) LOG(GF) LOG(ABUND) LINE NO')
  208 FORMAT('   ',A2,I2,F9.2,F5.2,1X,F6.2,3X,F7.2,4X,I5)
  200 FORMAT(' INTENSITY SPECTRUM AT MU=',F6.2,' BETWEEN',F10.3,
     &      ' AND',F10.3,' A WITH STEP',F6.3,' A')
  201 FORMAT(' FLUX SPECTRUM BETWEEN',F10.3,' A AND ',F10.3,' A WITH',
     &       ' STEP',F6.3,' A')
  202 FORMAT(' ***WEAK LINE APPROX FOR L/KAPPA L.T.',F7.4)
  203 FORMAT(' MODEL ATMOSPHERE:',A)
  204 FORMAT(' CONTINUUM FLUX=',E12.4, ' AT ',f10.2,'AA')
  205 FORMAT(' CONTINUUM INTENSITY=',E12.4,' at ',f10.2,'AA')
  206 FORMAT(1X,10F8.4)
 2341 FORMAT(1X,'Block number: ',I8)
*
      END