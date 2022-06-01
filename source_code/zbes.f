      DOUBLE PRECISION FUNCTION ZBES(K)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  ROUTINE REQUIRED BY GASLEG (GAUSS LEGENDRE PT/WT GENERATOR)
C  TAKEN FROM AD VAN DER AVOIRD'S N2-N2 CODE (SG 11/7/91)
      DOUBLE PRECISION PI,B,BB,B3,B5,B7
      DATA PI/3.14159 26535 89793 D0/

      B=(DBLE(K)-0.25D0)*PI
      BB=1.D0/(8.D0*B)
      B3=BB*BB*BB
      B5=B3*BB*BB
      B7=B5*BB*BB
      ZBES=B+BB-(124.D0/3.D0)*B3+(120928.D0/15.D0)*B5
     1     -(401743168.D0/105.D0)*B7
      RETURN
      END
