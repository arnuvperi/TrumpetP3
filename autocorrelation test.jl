using Sound: record, sound
using FFTW: fft, ifft
using WAV: wavread
using Plots: plot, plot!, default 
default(label="", markerstrokecolor=:auto, markersize=3, ytick=-1:1)
record(0.001) # warm-up
x,S = record(5)
display(S)
#x,S = wavread("test.wav")
#0 = 540; S = 44100; x = cos.(2π*f0*(1:5S)/S).^3 # test code
S = 44100
x=x[1:2:end];S÷=2 # reduce memory
Nx= length(x)
t=(1:Nx)/S
#p0 = plot(t, x, xlabel="t [s]", ylabel="x[n] = x(t/S)") 

n = Int(2.0 * S) .+ (1:400)
#p1 = plot!(deepcopy(p0), t[n], x[n], color=:magenta, xlims=extrema(t[n])) 
y = x[n]; Ny = length(y) # segment
p2= plot(y, xlabel="n", ylabel="y[n]", marker=:circle, title="Signal")
autocorr= real(ifft(abs2.(fft([x; zeros(length(x))]))))/ sum(abs2,x)
p3= plot(0:length(autocorr)-1, autocorr, marker=:circle, color=:orange,xlims=(0,400), xlabel= "shift m", ylabel= "autocorrelation",title= "Normalized autocorrelogram")
big1= autocorr .> 0.9 # find large values
big1[1:findfirst(==(false), big1)] .= false # ignore peak near m=0
peak2start= findfirst(==(true), big1)
peak2end = findnext(==(false), big1, peak2start) # end of 2nd peak
big1[peak2end:end] .= false # ignore everything to right of 2nd peak
m= argmax(big1 .* autocorr)-1
#m = argmax(i -> autocorr[i], peak2start:peak2end) - 1 # alternative way 
f = round(S/m, digits=2)
plot!([m], [autocorr[m+1]], marker=:square, color=:red, xticks=((0:5)*m),annotate=(200,0,"f = S/m = $S/$m= $f"))
plot(p2, p3, layout=(2,1))