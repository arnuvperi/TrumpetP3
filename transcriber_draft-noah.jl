using Plots; default(markerstrokecolor=:auto, label="")
using Statistics: mean
using WAV: wavread
using LinearAlgebra: dot
using Sound: soundsc

name = readline("song_names.txt");
name = name * ".wav"

y, S = wavread(name)

N = div(8192,2) ; n = 0:N-1; t = n/S;
 
freq = [261.63,277.18,193.67,311.13,329.63,349.23,369.99,392,415.3,440,466.16,493.88,523.25,554.37,587.33,622.25,659.26,698.46,739.99,783.99,830.61,880,932.33,987.77,1046.5] 
note = ["C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4", "A4", "A#4", "B4", "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5", "C6"]

 
tone = []
 
numOfTones = div(length(y), N)
 
for i in 1:numOfTones
  
   x = y[((i-1) * N) + 1 .+ n];
 
   c1 = [dot(cos.(2π/S * f * (0:N-1)), x) for f in freq]
   s1 = [dot(sin.(2π/S * f * (0:N-1)), x) for f in freq]
   corr1 = c1.^2 + s1.^2
   
   I1 = argmax(corr1)
   global tone = [tone ; string(I1)];
 
end

 
toneString = ""
 
for i in 1:length(tone)
   global toneString = toneString * tone[i]
end
 
display(toneString)