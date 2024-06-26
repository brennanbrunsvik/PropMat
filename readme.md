This code calculates seismic traces for an incident ray. Karen Fischer, at Brown University, was the primary developer of this code (not me!). 

brb2021.09.15 Summary of instructions. First make the files. From the src folder, run 
> make -f Makefile_wpar

To test that things are working properly, run the test file and see if output and target output files are the same. Navigate to example and run 
> ./test.exe 

This only does diff on test.45.20 file.

An important problem is that if your traces are too long due to thick layers, then the predefined file sizes for traces may not be large enough. Once the end of a trace is reached, Fortran will simply overwrite the beginning of that trace with the remaining trace. 

Original Readme
********* February 2003, Karen Fischer ***************************

This tar file contains source code and input files for four
programs.  The first two generate propagator matrix synthetics
using the methods of Keith and Crampin (1977) should be run in the 
order:
synth
sourc1

To convert the propagator matrix code output to sac use:
saccpt

When you are making model layers, if you wish to average different 
sets of elastic coefficients try:
dilute
It will create new elastic moduli in aniso.data format by
adding weighted contributions from three input sets of elastic 
coefficients.

****synth******
Program synth calculates the transfer function for the plane layered model.
To compile you need:
synth.f
synth.sub.f
A sample makefile is included.

The program requires two input files (the name 'synth.in' is hardwired):
aniso.data
synth.in

aniso.data contains the elastic coefficients for each layer.
synth.in contains input parameters for the code.  Note that 
if you specify "bottom motion" in synth.in (2) instead of 
"top motion" (1), the program will output the transfer function
for the top of the bottom layer.  Be careful to make sure that
the number of points per second is small enough to be compatible
with the total number of points in your seismogram.

In the examples included here, aniso.data contains a two-layer model.
The top layer contains the coefficients for the Model 2 in Table 1
of Keith and Crampin (1977, Geophys. J. R. astr. Soc., 49, 225-243).
To verify the format of the coefficients, please refer to Table 2,
part b, of this paper.  In the second line of the input file,
2 specifies that the layer is anisotropic,  3.31 is the density,
and 200 km is the layer thickness.

The second layer is isotropic with vp=8.55 km/s, vs=4.7 km/s, and
a density of 3.5.  In the second line, 1 denotes that this layer
is isotropic.

You can increase the number of layers simply by adding more
sets of elastic coefficients into the file.  Just remember to
change the third line of synth.in.

aniso.data also contains a few more examples of elastic coefficients.
The code only reads down through the number of layers specified in
synth.in.

Descriptions of the other parameters are given in the body of the
code.  Please feel free to ask, however, if you have any questions.

****sourc1******
Program sourc1 convolves the transfer function with an incident
waveform.  I now have it hardwired to use a default waveform
for which you specify the period, but if you change the
parameter incidw from 2 to 1, you can input any incident 
wave function.  The program will ask you for the file name.

To compile you need:
sourc1.f
fork.fold.f


Good luck!

