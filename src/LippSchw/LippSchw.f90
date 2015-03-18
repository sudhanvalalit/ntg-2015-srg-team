!--------------------------------------------------------------------------
!	This program computes the solution of the Integro-differential
!	Equation for the deuteron problem. It also computes the eigenvalues
!	and eigen vectors for the same. Eventually provides the binding energy
!	of the system. The computation is for momentum space.
!	
!------------------------------------------------------------------------------		
!	Code needs lapack and lblas libraries to compute the eigenvalues and 
!	the wave function. In addition it also needs other subroutines.
!------------------------------------------------------------------------------
      program momentum

!      external v1
      implicit none

      integer :: i,j,ng,true, true1, k, kread, kwrite
      double precision :: mu,hc,pi,Ea,Enew, tolnr
      double precision :: v1,norm, dE, E, dk, v1sep

      parameter (ng=50)

      double precision :: x(ng),w(ng) ! points and weights from Gauss-Legendre
      double precision :: p(ng),w1(ng) ! mapping: points and weights to do the integral
      double precision :: h(ng,ng), identity(ng,ng) ! Hamiltonian  and identity matrix
      double precision :: diff(ng), delta
      double precision :: WR(ng),WI(ng),VL(ng,ng),VR(ng,ng),WORK(4*ng), dn(ng)
      integer :: INFO

      double precision xx(50)
      double precision fxx(50)
      integer ie, iemax

      data kread/5/, kwrite/6/
      data iemax/30/


!	 define constants

      hc=197.32705d0
      pi=4.d0*atan(1.d0)
      Ea = -5.d0
      tolnr=1.d-10
      mu=938.926d0	
!	 get Gauss points and weights
      call gauleg (-1.d0,1.d0,x,w,ng)

!	 Converting the indefinite integral to a finite integral by a transformation
      do i=1,ng
        p(i)=tan(pi/4.d0*(1+x(i))) 
        w1(i)=pi/4.d0*w(i)/cos(pi/4.d0*(1.d0+x(i)))**2
!	Identity matrix
        identity(i,i) = 1.d0
      end do
      open (7, file ="pot.dat", status ="unknown")
 !     write(7,*) "#         p(i)      qprime = 1.0   qprime = 1.0"
      do i = 1, ng  
      write(7,10002) p(i), (v1(p(i),1.d0)), (v1(p(i),1.5d0))
      end do
      close(7)

	k = 0
	dk = -0.2d0
!	do k = 1, 10
10	k = k+1
	dk = dk+ 0.2d0
!	if (k<3) then 
	E = Ea + dk
!	else 
!	E = Enew
!	end if
! 	build the Hamiltonian matrix
      do i=1,ng
        do j=1,ng
        if (i.eq.j) then
        h(i,j)=(w1(i)*v1(p(i),p(i)))/(E-hc**2*p(i)**2/mu)
        else
        h(i,j)=v1(p(i),p(j))*w1(j)/(E-hc**2*p(i)**2/mu)
        end if
!	print*, v1(i,j)
      end do
      end do

! use dgeev.f to calculate eigenvector and eigenvalues
      call DGEEV('N', 'V', ng, h, ng, WR, WI, VL, ng, VR, ng, WORK, 4*ng, INFO)

!	 find the position of binding energy
      do i=1,ng
        if (wr(i).lt.0.d0) then
        true=i 	!	Choose the eigen value and ignore others
        exit
        end if
      end do
!	Print binding energy to screen
      write(*,*) 'Binding energy is ',wr(true),'MeV'

! calculate the norm of the wave function
      norm=0.d0
      do i=1,ng
         norm=norm+w1(i)*vr(i,true)**2
      end do
      norm=sqrt(norm)

! open a file and save data 
      open(6,file='psi_10.dat',status='unknown')
      write(6,*) '#             q                 psi(q)'

      do i=1,ng
      write(6,10000) p(i),vr(i,true)/norm
      end do
	dn = 5.d0
	true1 = 1
!	FInding the closest eigenvalue 
      do i=1,ng
	dn(i) = abs(1.d0-wr(i))
        if (dn(i).le.dn(true1)) then
        true1=i 
!	print*, wr(true1)	!	Choose the eigen value and ignore others
!	exit
	end if
!	print*, dn(i), wr(i),wr(true1), dn(true1)
      end do
!	print*,"w(true1)=", wr(true1)


!	Newton Raphson method for finding zeros
	diff(k) = dn(true1)
	print*, diff(k)

	if(k<2) then 
!	k = k+1
	goto 10
	end if
	
	open(10, file = "test.dat", status ="unknown")
	write(10,*) E, h(20,20)


!        do newton search
!        starting from xinitial

      xx(1) = E
      fxx(1) = diff(1)
      xx(2) = xx(1) + dk
      fxx(2) = diff(2)

      ie=1

 20   ie=ie+1 
      if (ie.gt.iemax) stop!

      write (kwrite,*) ' f(',xx(ie),') = ',fxx(ie),ie
!     
      call newtonr (fxx(ie-1),fxx(ie),xx(ie-1),xx(ie),xx(ie+1),delta)
      fxx(ie+1) = delta

      if (abs(fxx(ie+1)).lt.tolnr) then!

      write(6,*) ' the root of f(x) is :',fxx(ie),'  at x = ',xx(ie)
      else 
      go to 20
      endif

      Enew = xx(ie+1)

!	write(*,*) k

	if (k>20) stop
	go to 10
!	do i = 1, ng  
!         print*, min(dn(i))
!      end do	
!	end do

10000 format(2x,2f20.10) 
10002 format(2x, 3f15.7)
      close(6)
      close(10)
      stop 'output written in psi_10.dat'
      end program

!========================================================================

