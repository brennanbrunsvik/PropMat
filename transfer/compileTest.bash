# This script is an example of how to compile and test this set of codes. 
# If no changes are required for your computer, this should handle all compilation and testing. 

cd ../src
make -f Makefile_wpar

cd ../example 
./test.exe 

# echo 'Starting making CADMINEOS.'
# ./MAKEALL.bash 
# echo 'Finished running make for CADMINEOS.' 

# echo 'Starting test for CADMINEOS.'
# cd test 
# ./tst.exe 
# echo 'Finished running test for CADMINEOS'
