#/bin/bash 
# Run this from the transfer folder. 

computer=${1:-brunsvik@tong.eri.ucsb.edu} # First argument is the computer you will send to. 

rsync -ahv \
--exclude-from='exclude_PropMat.txt' \
../ \
$computer:~/Documents/repositories/Peoples_codes/PropMat