#!/bin/csh
#ANGL is the incidence angle from vertical
set ANGL=30
#AZM is the clockwise horizontal azimuth from the 1-axis of the elastic
# coefficients
foreach AZM ( 45 )
#
./synth <<!
aniso.data
$ANGL
1
0.
$AZM
!
#
echo "Done propagation, now convolving source"
#
./sourc1 <<!
test.$AZM.$ANGL
1 0 0
5.
0.
2
!
#
./saccpt <<!
test.$AZM.$ANGL
0
!

end
echo OK
