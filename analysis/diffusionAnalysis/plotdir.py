#!/usr/bin/python

opacity_of_negative_direction = 0.2
size_of_markers = 30
range_of_b = [0.0, 1.0e99]
colormap = 'Set1'

import matplotlib.pyplot as plt
import numpy as np
import sys

data = np.loadtxt (sys.argv[1])
bmax = np.max(data[:,3])
n = [ i for i in np.arange(len(data)) if data[i,3] >= range_of_b[0] and data[i,3] <= range_of_b[1] ]

b = data[n,3]
data = data[n,0:3] * np.reshape (b, (-1,1))

fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')

ax.scatter ( data[:,0],  data[:,1],  data[:,2],
    vmin=0, vmax=bmax, c=b, s=size_of_markers,
    alpha=1.0, cmap=plt.get_cmap(colormap))
ax.scatter (-data[:,0], -data[:,1], -data[:,2],
    vmin=0, vmax=bmax, c=b, s=size_of_markers,
    alpha=opacity_of_negative_direction, cmap=plt.get_cmap(colormap))

ax.set_box_aspect([1, 1, 1])
ax.set_position([0, 0, 1, 1])
ax.set_axis_off()
plt.show()