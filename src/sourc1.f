c====================================================================   

c             "sourc1.ftn"    synthetic seismogram (2)     12/14/88
c                                      Mildly modified      10/01/93

c    source function *convolve* transfer function = time seris
c     (read from 2)            (output of "synth", in 30,31)

c             bound with "fork_fold.ftn"


c   motion=1 or 2; calculate (1)surface (2)bottom motions.
c   motion=3; both motions have been saved, but calculate one each run

c           nq1   : folding point (frequency) for "fork"
c           nperi : no. of points representing the input pulse.
c           tsec  : total sec of time series.
c           npps  : no. of points per second.

c  convention for the excitation factor on the bottom layer :
c              p : positive in the reversed propagation direction.
c                  ( + in the z direction)
c             SV : positive to the top of the propagation direction.
c                  ( + in -x and -z direction)
c             SH : positive to the right of the propagation direction.
c                  ( + in y direction)

c  ***** 
c   if we treat the observation point as a seismic station, and rotate
c   the system x ( or N ) to match the radial direction of the coming
c   wave, then the x will be Radial direction, -y will be the 
c   Transverse direction, and -z will be the Up direction.
c   then you have a new system R,T,U as a conventional way to describe
c   the 3 components at a station.                  
c  *****
c   you have options to select (x,y,z) or (R,T,U).
c
c ADDED BY ZE:
c  to lengthen the time series (may take longer, but not substantially) 
c  you need to increase the size of the arrays ui,u,v,w,etc.
c  If nsamps = 2^N (N is integer), make sure to change:
c
c   line 286:  complex ui(2^N)
c   line 330:  complex u(2^N),v(2^N),w(2^N)
c   line 352:  if(lx.ge.2^N)lxm=lx-4
c   line 407:  complex u(2^N)
c   line 513:  complex u(2^N),v(2^N),w(2^N)
c
c   line 60:   complex ui(2^N + 1),u(2^N + 1),v(2^N + 1),w(2^N + 1),vr(3),fru(3)
c   line 461:  complex ui(2^N + 1)
c
c   line 424:  complex ui(2^(N+1) + 1)

c====================================================================
      character*50 input_file,output_file,synthout1,synthout2,imag_outf                                    
      real*8 e1(6,6)
      real*4 e(6,6)
c  added at Ved's recommendation
      real*8 q1, theta
      complex ui(4097),u(4097),v(4097),w(4097),vr(3),fru(3)        
      complex arb(3,3),frd(3),ef(6),phase,ari(3,3,2000),fr(3)                            
      pi=3.1415926536                                                   
      pi2=2.*pi                                                         
      rad=pi/180.

         
      incidw=2      
c-------------------------------------------------------
c          incidw=1  read in incident waveform in sub "incid"
c          incidw=2  generate synthetic waveform in sub "incid1"
c               Note that default waveform is hard-wired in.
c-------------------------------------------------------
      if (incidw.eq.1)then
      print *,'the source waveform file ='
      read(*,'(a)')input_file
      open(2,file=input_file)
      end if

      print *,'output 3-cpt displacement file ='
      read(*,'(a)')output_file
      open(10,file=output_file)

	  print *,'synthout1 filename:'
      read(*,*)synthout1 	  
      print *,'synthout2 filename:'
      read(*,*)synthout2 
      print *,'imag_out filename:'
      read(*,*)imag_outf 

      open(30,form='unformatted',file=synthout1)
      open(31,form='unformatted',file=synthout2)
      open(20,file=imag_outf)
                 
c      open(20,file='imag_part.out')

      read(30)lx,npps,nc,motion
      read(30)q1,theta
      do 3 j=1,6
    3 read(30)(e1(i,j),i=1,6)
                             
c----------- too bad, apollo does't like real*8 and complex together.
      do 4 j=1,6
      do 4 i=1,6
    4 e(i,j)=e1(i,j)

      tsec=real(lx-1)/real(npps)

      print *,'========================>'
      write(*,'(1x,''lx='',i4,'';  '',i2,'' pts = 1 sec'')')lx,npps
      write(*,'(1x,''time series ='',f8.2,
     &'' sec;   cutting freq ='',i4,''/lx'')')tsec,nc
      print *
      print *,' ? excitation factor for upgoing <p,sv,sh> = ?'
      read(*,*) ef2,ef4,ef6

      print *,' ? basic period for the incident wave (sec) ?'
      read(*,*)peri
      peri=int(peri+0.001)

      if(motion.eq.1)then
      write(*,'(1x,'' calculate "surface motion"'')')
      ifsur=1
      else if(motion.eq.2)then
      write(*,'(1x,'' calculate "motion at depth"'')')
      ifsur=2
      else
      write(*,'(1x,'' ? (1)surface motion? (2) motion at depth?'')')
      read(*,*)ifsur
      end if

      print *,'  observational distance (km) = ?'
      read(*,*)xobs

      print *,'  output (1) x,y,z  or (2) R,T,U ?'
      read(*,*)ixyz

               
      t=sqrt(ef2*ef2+ef4*ef4+ef6*ef6)
      ef2=ef2/t
      ef4=ef4/t
      ef6=ef6/t


c--------------------------------------------------------------------
c  incidw=1 read; 2 calculate, input incident wave using <ui>
c  ***source waveform is 10 sec delayed.
c-------------------------------------------------------------------
      if (incidw.eq.1)then
      call incid (lx,peri,npps,ui,idelay)
      else                          
      l_delay_source=10
      call incid1 (lx,peri,npps,l_delay_source,ui)
      end if


      nq1=lx/2+1
      nperi=peri*npps+0.0001
      do 5 i=1,lx
      u(i)=0.    
      w(i)=0.    
    5 v(i)=0.    
      fr(1)=ef2  
      fr(2)=ef4  
      fr(3)=ef6  

c--------------------------------------------------------------------   
c      transform incident waveform to frequency domain in order to
c      multiply transfer function at each discrete frequency.
c--------------------------------------------------------------------
      call fork (lx,1,ui)

      t=q1*xobs*real(npps)
      arg1=2.*pi/real(lx)*t


c====================================================================
c             loop through each frequency component and
c        multiply the source with the transfer function [ari].
c   note : source function has small value beyond "freq" = nc/lx
c====================================================================
      read(30)ari
      
      
      do 800 k=1,nc
c---------------------------------------------------------------------
c       arg=arg1*(k-1)=w*t;   w=2*pi*(k-1)/lx   t=q1*x*npps
c---------------------------------------------------------------------
      if(t.eq.0.)then
        dr=1.
        di=0.
      else   
        arg=arg1*real(k-1)
        dr=cos(arg)
        di=sin(arg)
      end if       
      phase=cmplx(dr,di)


      do 105 i=1,3
  105 fru(i)=fr(i)*ui(k)*phase

c---------------------------------------------------------------------
c     source <fru> * transfer [ari] = displacement <vr> (in frequency)
c              <vr> is <u,w,v> at surface at frequency k.
c---------------------------------------------------------------------
      do 110 i=1,3
      vr(i)=0.
      do 100 j=1,3
  100 vr(i)=vr(i)+ari(i,j,k)*fru(j)
  110 continue

c---------------------------------------------------------------------
c       create spectrums of displacements in order to trasform
c       back to time domain by calling "ift" later.
c---------------------------------------------------------------------
      u(k)=vr(1)
      w(k)=vr(2)
      v(k)=vr(3)

      if(ifsur.eq.1)go to 800

c---------------------------------------------------------------------  
c                bottom motion = [e]<ef>
c        calculate bottom "excitation factor" for downgoing phases
c---------------------------------------------------------------------
      read(31)arb

      do 777 i=1,3
      frd(i)=0.
      do 776 j=1,3
  776 frd(i)=frd(i)+arb(i,j)*vr(j)
  777 continue
      ef(1)=frd(1)
      ef(2)=fru(1)
      ef(3)=frd(2)
      ef(4)=fru(2)
      ef(5)=frd(3)
      ef(6)=fru(3)


      u(k)=0.
      do 781 j=1,6
  781 u(k)=u(k)+e(1,j)*ef(j)
      w(k)=0.         
      do 782 j=1,6           
  782 w(k)=w(k)+e(2,j)*ef(j) 
      v(k)=0.                
      do 783 j=1,6           
  783 v(k)=v(k)+e(5,j)*ef(j) 
                             
  800 continue               
                             
                             
      call taper (u,1,1,1,nc-nc/10,nc,nq1)
      call taper (v,1,1,1,nc-nc/10,nc,nq1)
      call taper (w,1,1,1,nc-nc/10,nc,nq1)

      call fold  (lx,nq1,u)
      call fold  (lx,nq1,v)
      call fold  (lx,nq1,w)


c---------------------------------------------------------------------
c                transform back to time domain
c---------------------------------------------------------------------
      call fork (lx,-1,u)
      call fork (lx,-1,v)
      call fork (lx,-1,w)
      write(20,'(1x,''imaginary part of "u" "v" "w"'')')
      do 495 k=1,lx,8
  495 write(20,'(1x,i4,3e18.6)')k-1,aimag(u(k)),aimag(v(k)),aimag(w(k))
      close(20)

c---------------------------------------------------------------------
c    output 3-cpts of synthetic seismograms for plotting.
c---------------------------------------------------------------------

c----- "seism3" is for topdraw file.
c      call topdraw_seism3 (1,u,v,w,lx,npps,tsec,10)

      scale=10000.
      call outseism (u,v,w,scale,lx,npps,10,1,1,1,ixyz)


      stop
      end



      subroutine taper (ui,m0,m1,m2,n1,n2,n3)
c---------------------------------------------------------------------
c       window :  m0 --"0"--m1--"cos"--m2;   n1--"cos"--n2--"0"--n3
c---------------------------------------------------------------------
      complex ui(4096)
      pi=3.1415926536

      if(m1.eq.m2)go to 360

      x=m2-m1
      do 200 i=0,m2-m1
      theta=pi+pi*i/x
      t=(cos(theta)+1.)/2.
  200 ui(m1+i)=ui(m1+i)*t
      do 300 i=m0,m1
  300 ui(i)=0.

  360 if(n1.eq.n2)return

      x=n2-n1
      do 400 i=0,n2-n1
      theta=pi*i/x
      t=(cos(theta)+1.)/2.
  400 ui(n1+i)=ui(n1+i)*t
      do 500 i=n2,n3
  500 ui(i)=0.
      return
      end






                                                                        
      subroutine topdraw_seism3 (mode,u,v,w,lx,npps,tsec,nf)
c---------------------------------------------------------------------
c  ******* output subroutine for "topdraw" in the mainfram.

c          plot time series on file "nf";   find max for scale
c        mode=1 : 1 scale for all 3 cpts, i.e., max of them.
c        mode=2 : x & y has one scale, z has its own.
c        mode=3 : each cpt has its own scale.
c
c  note : displacements will be multiplied by 10000 to convert real no.
c         to integer; this is good for storage (ibm or tektronix).
c---------------------------------------------------------------------

      complex u(4096),v(4096),w(4096)
      dimension time(0:3),move(0:3)
      call fmax (lx,u,max,xmax,2)
      call fmax (lx,v,max,ymax,2)
      call fmax (lx,w,max,zmax,2)

      if(mode.eq.3)go to 250

      tmax=xmax
      if(ymax.gt.tmax)tmax=ymax

        if(mode.eq.2)then
        xmax=tmax
        ymax=tmax
        else
        if(zmax.gt.tmax)tmax=zmax
        xmax=tmax
        ymax=tmax
        zmax=tmax
        end if
  250 continue
      lxm=lx
      if(lx.ge.4096)lxm=lx-4

      msec=tsec+0.99
      write(nf,'(1x,''set window x 1.0 12.0 y 6.0 9.0'')')
      write(nf,'(1x,''set limits x 0 '',i4,''  y '',e11.4,1x,e11.4)')
     &msec,-xmax*10000.,xmax*10000.
      write(nf,'(1x,''set axes off'')')
c-------------- in topdraw file, 4 data in one line.

c---------x cpt
      write(nf,'(''x-cpt'')')
      write(nf,'(i5,2x,''0.'')')lx
      do 500 i=1,lxm,4
      do 470 j=0,3
      time(j)=real(i+j-1)/real(npps)
  470 move(j)=-real(u(i+j))*10000.
  500 write(nf,1007)(time(j),move(j),j=0,3)
c-----for topdraw file, semicolumn ; is needed.
 1007 format(3(1x,f7.3,i10,';'))
      write(nf,'(1x,''join 1'')')

      write(nf,'(1x,''set window x 1.0 12.0 y 3.3 6.3'')')
      write(nf,'(1x,''set limits x 0 '',i4,''  y '',e11.4,1x,e11.4)')
     &msec,-ymax*10000.,ymax*10000.

c---------y cpt
      write(nf,'(''y-cpt'')')
      write(nf,'(i5,2x,''0.'')')lx
      do 501 i=1,lxm,4
      do 471 j=0,3
      time(j)=real(i+j-1)/real(npps)
  471 move(j)=-real(v(i+j))*10000.
  501 write(nf,1007)(time(j),move(j),j=0,3)
      write(nf,'(1x,''join 1'')')

      write(nf,'(1x,''set window x 1.0 12.0 y 0.6 3.6'')')
      write(nf,'(1x,''set limits x 0 '',i4,''  y '',e11.4,1x,e11.4)')
     &msec,-zmax*10000.,zmax*10000.
      write(nf,'(1x,''set axes off bottom on'')')

c---------z cpt
      write(nf,'(''z-cpt'')')
      write(nf,'(i5,2x,''0.'')')lx
      do 502 i=1,lxm,4
      do 472 j=0,3
      time(j)=real(i+j-1)/real(npps)
  472 move(j)=real(w(i+j))*10000.
  502 write(nf,1007)(time(j),move(j),j=0,3)
      write(nf,'(1x,''join 1'')')
      return
      end



      subroutine fmax (lx,u,max,tmax,ifone)
      complex u(4096)
      tmax=0.
      do 200 i=1,lx,ifone
      dr=real(u(i))
      if(abs(dr).gt.tmax)then
      tmax=abs(dr)
      max=i
      end if
  200 continue
      return
      end


      subroutine incid (lx,peri,npps,ui,idelay)
c-------------------------------------------------------------------
c            read a "synthetic waveform" from file 2
c-------------------------------------------------------------------
      complex ui(4097)
      dimension u(100)

      read(2,*)scale
      print *,' scale=',scale

      idelay=50
      print *,'delay=50'

      do 100 i=1,75,5
  100 read(2,*)u(i),u(i+1),u(i+2),u(i+3),u(i+4)
      npoin=peri*npps+0.0001
      dx=75./npoin
      do 200 i=1,npoin
      x=dx*(i-1)
      m=x+1.0001
      s=(u(m+1)-u(m))
      t=u(m)+(x-m)*s
  200 ui(i+idelay)=-t*scale
      do 300 i=idelay+1+npoin,lx
  300 ui(i)=cmplx(0.,0.)
      do 301 i=1,idelay
  301 ui(i)=cmplx(0.,0.)
      return
      end




      subroutine incid1 (lx,peri,npps,lsec,ui)
c=============== a test input waveform (Keith+Crampin, 1977 III)
c    lsec : the starting time (sec) of this pulse
c    dinv : inverse damping factor, the smaller, the more damping.
c           K&C 1977 used dinv=3
c   


      complex ui(4097)
      pi=3.1415926536 
      npcyc=peri*npps
c npcyc=no. of points in one cycle (containing 2 swings).
      w0=2.*pi/real(npcyc)
      lstart=lsec*npps+1
c K&C 1977 used dinv=3
      dinv=2.7
      

      do 90 i=1,lstart-1
   90 ui(i)=(0.,0.)

      do 100 i=lstart,lx
      t=i-lstart
      ar1=w0*t/dinv
      arg=ar1*ar1
      if(arg.gt.150.)go to 150
      e=exp(-arg)
      ui(i)=t*t*e*sin(w0*t)/100.
  100 continue


  150 do 160 j=i,lx
  160 ui(j)=0.



c-------------------------------------------------------------
c  for better 2-swing pulse, window out x points from the 
c  end (m0) of one sine cycle.
c-------------------------------------------------------------
      x=10.
      m0=lstart+npcyc
      do 300 i=m0,m0+int(x)
      theta=pi*(i-m0)/x
      t=(cos(theta)+1.)/2.
  300 ui(i)=ui(i)*t

      do 400 i=m0+10,lx
  400 ui(i)=0.     

      return
      end


      subroutine outseism (u,v,w,scale,lx,npps,nf,ifx,ify,ifz,ixyz)
c---------------------------------------------------------------------

c     write 8 data per line and totally n data

c---------------------------------------------------------------------
      complex u(4096),v(4096),w(4096)
      real*8 tsec
      dimension move(0:7)
 1007 format(8(1x,i7))


      beg_orig=0.
      epi_dist=0.             
      baz=0.

                                    
      tsec=1.d0/dble(npps)


      if(ifx.eq.0)go to 201                                     
                                                
c******in the prior program "synth.ftn", always rotate x to 
c      match the radial direction R of the coming ray in the 
c      prior program "synth.ftn", rather than rotate R to match
c      x direction; same rotation angle with opposite sign will
c      make sign of predicted R and T opposite.

      write(nf,'(''x(=R) -cpt'')')

      write(nf,'(i5,1x,f10.5,3f10.3)')lx,tsec,beg_orig,epi_dist,baz
      do 150 i=1,lx,8
      do 130 j=0,7
  130 move(j)=real(u(i+j))*scale
  150 write(nf,1007)(move(j),j=0,7)



  201 if(ify.eq.0)go to 301

      if(ixyz.eq.1)then
      scale1=scale
      write(nf,'(''y-cpt'')')
      else
      scale1=-scale
      write(nf,'(''T-cpt'')')
      end if
                                       
      write(nf,'(i5,1x,f10.5,3f10.3)')lx,tsec,beg_orig,epi_dis,baz
      do 250 i=1,lx,8
      do 230 j=0,7
  230 move(j)=real(v(i+j))*scale1
  250 write(nf,1007)(move(j),j=0,7)
                           


  301 if(ifz.eq.0)return

      if(ixyz.eq.1)then
      scale1=scale
      write(nf,'(''z-cpt'')')
      else
      scale1=-scale
      write(nf,'(''U-cpt'')')
      end if

                 


      write(nf,'(i5,1x,f10.5,3f10.3)')lx,tsec,beg_orig,epi_dist,baz
      do 350 i=1,lx,8
      do 330 j=0,7
  330 move(j)=real(w(i+j))*scale1
  350 write(nf,1007)(move(j),j=0,7)

      return
      end
