      SUBROUTINE HERM(H,N,X)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  SUBROUTINE TO GENERATE HERMITE POLYNOMIALS USING RECURSION FORMULA
C  HK(X)=2X*HK-1(X)-(2K-4)HK-2(X) AND HK(X) CONTAINS THE HERMITE
C  POLYNOMIAL H_{K-1}(X)
C
C  ON ENTRY: N IS NUMBER OF HERMITE POLYNOMIALS;
C            X IS POSITION AT WHICH HERMITE POLYNOMIALS ARE EVALUATED.
C            UNCHANGED ON EXIT.
C  ON EXIT:  H CONTAINS THE VALUES OF THE HERMITE POLYNOMIALS AT X.
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION H(N)

      P0=1.D0
      H(1)=P0
      IF (N.LE.1) RETURN
      X2=X+X
      P1=X2
      H(2)=P1
      IF (N.LE.2) RETURN

      DO 100 K=3,N
        TEMP=X2*P1 - DBLE(K+K-4)*P0
        P0=P1
        P1=TEMP
        H(K)=P1
  100 CONTINUE

      RETURN
      END
