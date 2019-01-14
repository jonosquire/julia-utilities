using Plots; pyplot()
using LaTeXStrings
using Images, Colors
# ioff()

A = rand(100,100)
img = Gray.(A)               # creates a copy of the data
plot(0:0.2:20,0:0.2:20,img)
