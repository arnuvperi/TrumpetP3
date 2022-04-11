using Sound: record, sound
using FFTW: fft, ifft
using WAV: wavread
using Plots: plot, plot!, default 
default(label="", markerstrokecolor=:auto, markersize=3, ytick=-1:1)
record(0.001)

x,S = record(5)
display(length(x))
x=x[1:2:end];S÷=2 # reduce memory
Nx= length(x)

autocorr= real(ifft(abs2.(fft([x; zeros(length(x))]))))/ sum(abs2,x)
big1= autocorr .> 0.5 # find large values
big1[1:findfirst(==(false), big1)] .= false # ignore peak near m=0
peak2start= findfirst(==(true), big1)
peak2end = findnext(==(false), big1, peak2start) # end of 2nd peak
big1[peak2end:end] .= false # ignore everything to right of 2nd peak
m= argmax(big1 .* autocorr)-1
f = round(S/m, digits=2)

display(f)