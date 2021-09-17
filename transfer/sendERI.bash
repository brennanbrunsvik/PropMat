#/bin/bash 
# Run this from the main CADMINEOS folder. 

rsync -ahv \
--exclude-from='transfer/exclude_PropMat.txt' \
/Users/brennanbrunsvik/Documents/repositories/Peoples_codes/PropMat/ \
brunsvik@tong.eri.ucsb.edu:~/repositories/Peoples_codes/PropMat