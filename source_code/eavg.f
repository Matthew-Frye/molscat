      SUBROUTINE EAVG(NT,T,NGP,E,NNRG,IPRINT)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE physical_constants, ONLY: K_in_inv_cm
      USE sizes, ONLY: MXNRG => MXNRG_in_MOLSCAT
C  THIS ROUTINE SETS UP ENERGIES FOR NGP-POINT GAUSS-LAGUERRE INTEG.
C  AT SPECIFIED TEMPERATURES (DEG. KELVIN).
C
C  ON ENTRY: NT IS THE NUMBER OF TEMPERATURES FOR WHICH BOLTZMANN
C            AVERAGES ARE REQUIRED;
C            T ARE THEIR VALUES;
C            NGP IS THE NUMBER OF GAUSS-LAGUERRE POINTS (CONSTRAINED TO
C            BE BETWEEN 2 AND 6);
C            MXNRG IS A CONSTRAINT ON HOW MANY ENERGY VALUES MAY BE
C            PASSED BACK OUT.
C  ON EXIT:  E ARE THE VALUES OF THE ENERGY NEEDED TO FACILITATE
C            GAUSS-LAGUERRE QUADRATURE;
C            NNRG IS THE NUMBER OF ENERGY VALUES NEEDED.

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION E(1),T(1)
      DIMENSION A(20),W(20)
C     DATA XK /.6950305D0/
C  16-10-16: NOW OBTAIN FROM MODULE physical_constants
      PARAMETER (XK=K_in_inv_cm)
      DATA A /.585786437627D0, 3.414213562373D0,
     2       0.415774556783D0, 2.294280360279D0, 6.289945082937D0,
     3       0.322547689619D0, 1.745761101158D0, 4.536620296921D0,
     4       9.395070912301D0, 0.263560319718D0, 1.413403059107D0,
     5       3.596425771041D0, 7.085810005859D0, 12.640800844276D0,
     6       6*0.D0/
      DATA W / 0.853553390593D0, 0.146446609407D0, 0.711093009929D0,
     8         0.278517733569D0, 0.103892565016D-1, 0.603154104342D0,
     9         0.357418692438D0, 0.388879085150D-1, 0.539294705561D-3,
     A         0.521755610583D0, 0.398666811083D0, 0.759424496817D-1,
     B         0.361175867992D-2, 0.233699723858D-4, 6*0.D0/

      NGP=MAX(2,MIN(6,ABS(NGP)))
      IST=NGP*(NGP-1)/2-1
      IF (IPRINT.GE.1) WRITE(6,600) NGP
  600 FORMAT(/' ENERGY VALUES WILL BE GENERATED TO FACILITATE',I4,
     1       '-POINT GAUSS-LAGUERRE INTEGRATION OVER BOLTZMANN ',
     2       'DISTRIBUTION')
      NN=0
      DO 1000 I=1,NT
        IF (NN+NGP.LE.MXNRG) GOTO 1010

        WRITE(6,601) I,T(I)
  601   FORMAT(/' * * * WARNING.  NOT ENOUGH SPACE IN ENERGY() TO ',
     1         'PROCESS TEMP(',I3,' ) =',F8.2)
        GOTO 1000

 1010   XT=XK*T(I)
        IF (IPRINT.GE.1) WRITE(6,602) T(I),XT
  602   FORMAT(/'        FOR TEMP =',F8.2,' DEG. K  =',F8.2,
     1         ' (CM-1), THE AVERAGE IS APPROXIMATELY THE SUM OF')
        DO 1100 J=1,NGP
          EN=XT*A(IST+J)
          WT=A(IST+J)*W(IST+J)
          NN=NN+1
          E(NN)=EN
 1100     IF (IPRINT.GE.1) WRITE(6,603) WT,EN
  603   FORMAT(15X,F13.8, '  *  SIG( E =',F12.4,' ) ')
 1000 CONTINUE

      NNRG=MIN(MXNRG,MAX(NNRG,NN))
      RETURN
      END
