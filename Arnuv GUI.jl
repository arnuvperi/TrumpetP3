#Team Trumpet Project 3
using Gtk
using WAV: wavwrite
using FFTW: fft
using DelimitedFiles
using Plots; default(markerstrokecolor=:auto, label="")
using Statistics: mean
using Measures
using Gtk: GtkGrid, GtkButton, GtkWindow, GAccessor
using Gtk: GtkCssProvider, GtkStyleProvider
using Gtk: set_gtk_property!, signal_connect, showall
using PortAudio: PortAudioStream
using Sound: record, sound
using FFTW: fft, ifft
using WAV: wavread

#Define GTK grid and properties
g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

synthButtonModel = GtkCssProvider(data="#synth {color:white; background:green;}")
transButtonModel = GtkCssProvider(data="#trans {color:white; background:blue;}")
songSelection = GtkCssProvider(data="#songs {color:white; background:black;}")



##READ DATABASE OF SONGS
filelist = readdir("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/Saved Songs")
databaseSongs = []
songNames = []
for i in 1:size(filelist,1)
    if filelist[i][end-2:end] == "txt"
        push!(databaseSongs, filelist[i])##get text files of all songs
        push!(songNames, filelist[i][1:end-4])##get names of all songs
    end
end

##Initiliaze variables

currentSong = songNames[1]

inputSongFrequencies = []
inputSongDurations = []

const S = 44100 # sampling rate (samples/second)
const N = 1024 # buffer length
const maxtime = 15 # maximum recording time 10 seconds (for demo)
recording = nothing # flag
nsample = 0 # count number of samples recorded
song = nothing # initialize "song"

for i in 1:size(songNames,1) # add the instrument buttons to the grid
    name = songNames[i]
    b = GtkButton(name) # make a button for this key

    push!(GAccessor.style_context(b), GtkStyleProvider(songSelection), 600)
    set_gtk_property!(b, :name, "songs") # set style of the "instrument" button
    signal_connect((win) -> song_selected(i), b, "clicked") # callback
    g[1:3, (1 + i) * 2] = b # put the button in column 1 of the grid
end


##callback functions
function song_selected(index::Int64)
    global currentSong = songNames[index]
    GAccessor.text(songNameLabel, "Current Song: " * currentSong)
    println(currentSong * " selected")
    plotSong()
end

function plotSong()
    data = readdlm("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/Saved Songs/"* currentSong * ".txt")
    frequencies = data[:,1] #extract frequencies
    durations = data[:,2] #extract durations

    for i in 1:size(frequencies,1)
        frequencies[i] = parse(Float64, frequencies[i][1:end-1])
    end
    generatePlot(durations, frequencies)
    img = GtkImage("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/plot.png")
    g[5,1] = img
end

function generatePlot(durations::Vector{Any}, frequencies::Vector{Any})
    midi_raw = [isnan(f) ? 63 : 69 + round(Int, 12 * log2(f/440)) for f in frequencies]
    V = [-2 0 .5 .75 1 1.25 1.5 1.75 2 2.5 2.75 3 3.25 3.5 4 4.25 4.5]
    v = V[midi_raw .- 62]
    plt = plot(v, line=:stem, marker=:circle, markersize = 10, color=:black)
    plot!(size = (800,200)) # size of plot
    plot!(widen=true) # try not to cut off the markers
    plot!(xticks = [], ylims = (-0.7,4.7)) # for staff
    yticks!(0:4, ["E", "G", "B", "D", "F"]) # helpful labels for staff lines
    plot!(yforeground_color_grid = :blue) # blue staff, just for fun
    plot!(foreground_color_border = :white) # make border "invisible"
    plot!(gridlinewidth = 1.5) # increase width of grid lines
    plot!(gridalpha = 0.9) # make grid lines more visible
    plot!(margin = 5mm)
    savefig("plot.png")
    display(plt)
end

function autocorrelationCalculator(x::Vector{Float32})
    S = 44100
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
    return f
end


##finds areas where student was off for each 16th note
function generateScore(inputSongFrequencies::Vector{Float64}, dataSongFrequencies::Vector{Float64})
    errorLocations = []
    for i in 1:size(dataSongFrequencies,1)
        dataFreq = dataSongFrequencies[i]
        inputFreq = inputSongFrequencies[i]

        errorThreshold = 5

        percentError = (abs(inputFreq - dataFreq) / dataFreq) * 100

        ##severity of error during each 16th note of playing
        if percentError >= 3 * errorThreshold
            push!(errorLocations, 3)
        elseif percentError >= 2 * errorThreshold
            push!(errorLocations, 2)
        elseif percentError >= errorThreshold
            push!(errorLocations, 1)
        else
            push!(errorLocations, 0)
        end
    end

    display(errorLocations)

end



# callbacks

"""
    record_loop!(in_stream, buf)
Record from input stream until maximum duration is reached,
or until the global "recording" flag becomes false.
"""
function record_loop!(in_stream, buf)
    global maxtime
    global S
    global N
    global recording
    global song
    global nsample
    Niter = floor(Int, maxtime * S / N)
    println("\nRecording up to Niter=$Niter ($maxtime sec).")
    for iter in 1:Niter
        if !recording
            break
        end
        read!(in_stream, buf)
        song[(iter-1)*N .+ (1:N)] = buf # save buffer to song
        nsample += N
        print("\riter=$iter/$Niter nsample=$nsample")
    end
    nothing
end


# callback function for "record" button
# The @async below is important so that the Stop button can work!
function call_record(w)
    global N
        
    in_stream = PortAudioStream(1, 0) # default input device
    buf = read(in_stream, N) # warm-up
    global recording = true
    global song = zeros(Float32, maxtime * S)

    @async record_loop!(in_stream, buf)
    nothing
end


# callback function for "stop" button
function call_stop(w)
    global recording = false
    global nsample
    duration = round(nsample / S, digits=2)
    num = round(nsample / 2048, digits = 2)
    GAccessor.text(recordLabel, "Recording Collected! Click Play to generate Score!")
    sleep(0.1) # ensure the async record loop finished
    flush(stdout)
    println("\nStop at nsample=$nsample, for $duration out of $maxtime sec.")
    global song = song[1:2048 * (floor(Int, num) + 1)] # truncate song to the recorded duration
    display(song)
end


# callback function for "play" button
function call_play(w)
    println("Play")
    @async sound(song, S) # play the entire recording

    """
    for i in 1:size(div(length(song), 8192),1) # add the instrument buttons to the grid
        curSection = song[1+((i-1)*8192):8192*i]
        f = autocorrelationCalculator(curSection)
        push!(inputSongFrequencies, f)
        push!(inputSongDurations, 1.0)
    end
    display(inputSongFrequencies)
    """
    testData = [261.63;261.63;261.63;261.63;293.67;293.67;261.63;261.63;261.63;261.63;349.23;329.63;]

    testInput = [261.63;261.63;293.67;293.67;293.67;293.67;261.63;261.63;261.63;261.63;349.23;329.63;]
    generateScore(testInput, testData)

end


##Creating Elements


##songNameLabel indiciating selected instrument
songNameLabel = GtkLabel("Current Song: " * currentSong)
g[1:3, 1] = songNameLabel

##recording indicator
recordLabel = GtkLabel("Press Record To Start")
g[6:8, 5] = recordLabel

##create default image
img = GtkImage("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/plot.png")
g[4:10,1:3] = img

function make_button(string, callback, column, stylename, styledata)
    b = GtkButton(string)
    signal_connect((w) -> callback(w), b, "clicked")
    g[column,4] = b
    s = GtkCssProvider(data = "#$stylename {$styledata}")
    push!(GAccessor.style_context(b), GtkStyleProvider(s), 600)
    set_gtk_property!(b, :name, stylename)
    return b
end

# create buttons with appropriate callbacks, positions, and styles
br = make_button("Record", call_record, 6, "wr", "color:white; background:red;")
bs = make_button("Stop", call_stop, 7, "yb", "color:yellow; background:blue;")
bp = make_button("Play", call_play, 8, "wg", "color:white; background:green;")




#Create window and push GTK to window
win = GtkWindow("TrumpetScriber", 1000 , 600) # 1000×600 pixel window for all the buttons
push!(win, g) # put button grid into the window

##Close Window
cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond) # exit program on window close