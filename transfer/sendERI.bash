#/bin/bash 
# Run this from the transfer folder. 
# TODO should make send destination a variable that we choose when we run the script. 

rsync -ahv \
--exclude-from='exclude_PropMat.txt' \
../ \
brunsvik@tong.eri.ucsb.edu:~/repositories/Peoples_codes/PropMat