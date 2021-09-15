#%% bb2021.09.15 I don't recommend using this file. I was just seeing what test.45.20 looks like. 
import numpy as np 
import matplotlib.pyplot as plt 

outfile = "test.45.20" 

outdat = np.loadtxt(outfile) 

fig,ax = plt.subplots(1,1, figsize = (10,10)) 
plt.plot(outdat)
plt.title('This quick and dirty script stiched together the three segments of test.45.20. \n This isnt particularly useful.')