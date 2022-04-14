#Team Trumpet Project 3
using Gtk
using WAV: wavwrite
using WAV: wavwrite, wavread
using DelimitedFiles
using Plots; default(markerstrokecolor=:auto, label="")
using Statistics: mean
using Measures
using Gtk: GtkGrid, GtkButton, GtkWindow, GAccessor, GtkWidget
using Gtk: GtkCssProvider, GtkStyleProvider
using Gtk: set_gtk_property!, signal_connect, showall
using Gtk: GtkGrid, GtkButton, GtkWindow, GAccessor, GtkCssProvider, GtkStyleProvider, set_gtk_property!, signal_connect, showall
using PortAudio: PortAudioStream
using Sound: record, sound
using FFTW: fft, ifft
using WAV: wavread


##Initiliaze variables

#Define GTK grid and properties
g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

synthButtonModel = GtkCssProvider(data="#synth {color:white; background:green;}")
transButtonModel = GtkCssProvider(data="#trans {color:white; background:blue;}")
songSelection = GtkCssProvider(data="#songs {color:white; background:black;}")

const S = 44100 # sampling rate (samples/second)
const N = 1024 # buffer length
const maxtime = 15 # maximum recording time 10 seconds (for demo)
recording = nothing # flag
nsample = 0 # count number of samples recorded
song = nothing # initialize "song"

sound([1], S)

inputSongFrequencies = []
inputSongDurations = []
inputSongMidi = []

dataSongFrequencies = []
dataSongDurations = []
dataSongMidi = []


filelist = readdir(string(@__DIR__) * "/Saved Songs")
databaseSongs = []
songNames = []

for i in 1:size(filelist,1)
    if filelist[i][end-2:end] == "txt"
        push!(databaseSongs, filelist[i])##get text files of all songs
        push!(songNames, filelist[i][1:end-4])##get names of all songs
    end
end

currentSong = songNames[1]

for i in 1:size(songNames,1) # add the instrument buttons to the grid
    name = songNames[i]
    b = GtkButton(name) # make a button for this key

    push!(GAccessor.style_context(b), GtkStyleProvider(songSelection), 600)
    set_gtk_property!(b, :name, "songs") # set style of the "instrument" button
    signal_connect((win) -> song_selected(i), b, "clicked") # callback
    g[1:3, 1 + i] = b # put the button in column 1 of the grid
end


##callback functions
##generates record buttons
function make_button(string, callback, column, stylename, styledata)
    b = GtkButton(string)
    signal_connect((w) -> callback(w), b, "clicked")
    g[column,4] = b
    s = GtkCssProvider(data = "#$stylename {$styledata}")
    push!(GAccessor.style_context(b), GtkStyleProvider(s), 600)
    set_gtk_property!(b, :name, stylename)
    return b
end

##changes song selected
function song_selected(index::Int64)
    global currentSong = songNames[index]
    GAccessor.text(songNameLabel, "Current Song: " * currentSong)
    println(currentSong * " selected")
    #getSongData()
    plotSong()
    x, S = wavread(string(@__DIR__) * "/Saved Songs/"* currentSong * ".wav")
    sound(x, S)
    file = string(@__DIR__) * "/plot.png"
     if isfile(file)
        display("file exists")
     end
    img = Gtk.GtkImage(file)
    g[4:10,1:3] = img
    showall(win)
end

##get selected song data
function getSongData()
    data = readdlm(string(@__DIR__) * "/Saved Songs/"* currentSong * ".txt")
    global dataSongFrequencies = data[:,1] #extract frequencies
    global dataSongDurations = data[:,2] #extract durations
    global dataSongMidi = []

    for i in 1:size(dataSongFrequencies,1)
        dataSongFrequencies[i] = parse(Float64, dataSongFrequencies[i][1:end-1])
        midi = Int(round(12*log2(dataSongFrequencies[i]/440))+69)
        push!(dataSongMidi, midi)
    end
    push!(dataSongFrequencies, 0)
    push!(dataSongMidi, 0)
    push!(dataSongDurations, 1)
end


##plots song for student to see
function plotSong()

    ##get selected song data
    getSongData()

    ##generate plot to place in upper right for student to see
    generateBasicSheetNotePlot(dataSongDurations, dataSongMidi)

end

##generates stem plot
function generateBasicSheetNotePlot(durations::Vector{Any}, midi::Vector{Any})
    midiWithDuration = []
    for i in 1:length(midi)-1

        push!(midiWithDuration, midi[i])
        num = floor(Int, durations[i] - 1.0)

        for i in 1:num
            push!(midiWithDuration, 0)
        end
    end
    
    plot(midiWithDuration, line=:stem, marker=:circle, markersize = 7, color=:black)
    plot!(size = (800,200)) # size of plot
    plot!(widen=true) # try not to cut off the markers
    plot!(xlims = (0, length(midiWithDuration) + 3))
    plot!(xticks = [], ylims = (58,85)) # for staff
    yticks!([64,67,71,74,77,81,84], ["E", "G", "B", "D", "F", "A", "C"]) # helpful labels for staff lines
    plot!(yforeground_color_grid = :blue) # blue staff, just for fun
    plot!(foreground_color_border = :red) # make border "invisible"
    plot!(gridlinewidth = 1.5) # increase width of grid lines
    plot!(gridalpha = 0.9) # make grid lines more visible
    plot!(margin = 5mm)
    savefig("plot.png")
end


##autocorrelationCalculator for finding frequency of input PortAudio
function autocorrelationCalculator()

    ##fast autocorrelation method for small segment of time (1/16th note)
    N = length(song)
    t = 8192

    for i in 1:t:(N-(t+1))
        z = song[i:i+(t-1)]
        n = length(z);

        autocorr = real(ifft(abs2.(fft([z; zeros((n))])))) / sum(abs2, z) # normalize
        big1 = autocorr .> 0.7 #Finds large values
        big1[1:findfirst(==(false), big1)] .= false # ignore peak near m=0
        peak2start = findfirst(==(true), big1)
        peak2end = findnext(==(false), big1, peak2start) # end of 2nd peak
        if isnothing(peak2end) #Skip peaks with nothing
            continue
        end
        big1[peak2end:end] .= false # ignore everything to right of 2nd peak
        m = argmax(big1 .* autocorr)-1
        f = round(S/m, digits=2)

        if f < 200
            continue
        end

        push!(inputSongMidi, Int(round(12*log2(f/440))+69))
    end

    tempMidi = []
    tempDuration = []
    localDuration = 1.0


    ##checks and adds for duration
    for i in 1:length(inputSongMidi)-1
        if inputSongMidi[i] == inputSongMidi[i+1]
            localDuration = localDuration + 1.0;
        elseif i == length(inputSongMidi)-1
            push!(tempMidi, inputSongMidi[i])
            push!(tempDuration, localDuration)
        elseif inputSongMidi[i] != inputSongMidi[i+1]
            push!(tempMidi, inputSongMidi[i])
            push!(tempDuration, localDuration)
            localDuration = 1.0
        end
    end

    push!(tempMidi, inputSongMidi[end])
    push!(tempDuration, localDuration)
    global inputSongMidi = tempMidi
    global inputSongDurations = tempDuration

    push!(inputSongMidi, 0)
    push!(inputSongDurations, 1)
    

end

##plays 2 seconds of metronome before recording starts
function playMetronome()
    bpm = 60
    bps = bpm / 30 # beats per second
    spb = 15 / bpm # seconds per beat
    t0 = 0.01 # each "tick" is this long
    tt = 0:1/S:2 # 2 seconds of ticking
    x = randn(length(tt)) .* (mod.(tt, spb) .< t0) / 4.5 # click via "envelope"
    sound(x, S)
end


##finds areas where student was off for each 16th note
function generateScore()

    ##error based on midi of note played
    counter = 0
    errorLocations = []
    for i in 1:size(dataSongMidi,1)
        counter = counter + 1
        dataMidi = 0
        inputMidi = 0

        if i > length(inputSongMidi)
            inputMidi = 0
        else
            inputMidi= inputSongMidi[i]
            dataMidi = dataSongMidi[i]
        end

        ##1 note off retruns an error
        errorThreshold = 1

        percentError = (abs(inputMidi - dataMidi) / dataMidi) * 100

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


    ##error based on duration differences
    counter = 0
    errorLocDuration = []
    for i in 1:size(dataSongDurations,1)
        counter = counter + 1
        dataDur = 0
        inputDur = 0

        if i > length(inputSongDurations)
            inputDur = 0
        else
            inputDur= inputSongMidi[i]
            dataDur = dataSongMidi[i]
        end

        ##1 note off retruns an error
        errorThreshold = 1

        percentError = (abs(inputDur - dataDur) / dataDur) * 100

        ##severity of error during each 16th note of playing
        if percentError >= 3 * errorThreshold
            push!(errorLocDuration, 3)
        elseif percentError >= 2 * errorThreshold
            push!(errorLocDuration, 2)
        elseif percentError >= errorThreshold
            push!(errorLocDuration, 1)
        else
            push!(errorLocDuration, 0)
        end
    end

    totalError = errorLocDuration .+ errorLocations

    generateMarkedPlot(dataSongDurations, dataSongMidi, totalError)


    ##calculate actual score

    totalNumErrors = sum(totalError)

    lengthOfErrors = length(totalError)

    finalScore = 100  - totalNumErrors;

    GAccessor.text(recordLabel, "Final Score: " * string(finalScore))
    println(string(finalScore) * " is your score")


end


#simple rectangle function for drawing on graph
function rectangle(w, h, x, y)
    return Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
end


#create marked plot with error locations
function generateMarkedPlot(durations::Vector{Any}, midi::Vector{Any}, totalError::Vector{Int64})
    midiWithDuration = []
    errorWithDuration = []
    ##converts midi and durations to a mix of the two, with 0 representing no note
    for i in 1:length(midi)-1

        push!(midiWithDuration, midi[i])
        push!(errorWithDuration, totalError[i])
        num = floor(Int, durations[i] - 1.0)

        for i in 1:num
            push!(midiWithDuration, 0)
            push!(errorWithDuration, 0)

        end
    end


    #does the same but for the error locations
    midiErrorDur = []
    for i in 1:length(midi)-1

        push!(midiErrorDur, inputSongMidi[i])
        num = floor(Int, inputSongDurations[i] - 1.0)

        for i in 1:num
            push!(midiErrorDur, 0)

        end
    end

    
    #plots both on same graph
    plot(midiWithDuration, line=:stem, marker=:circle, markersize = 7, color=:black)
    plot!(midiErrorDur, line=:stem, marker=:circle, markersize = 4, color=:red)
    

    ##plots rectangles that highlight errors, with different severity for each section
    for i in 1:length(errorWithDuration)

        errorNum = errorWithDuration[i]

        errorLoc = i

        if errorNum >= 6
            plot!(rectangle(errorLoc + 1, 100, errorLoc ,0), opacity=.3, color=:red)
        elseif errorNum >= 3
            plot!(rectangle(errorLoc + 1, 100, errorLoc ,0), opacity=.3, color=:orange)
        elseif errorNum > 1
            plot!(rectangle(errorLoc + 1, 100, errorLoc,0), opacity=.3, color=:yellow)
        end
    end

    plot!(size = (800,200)) # size of plot
    plot!(widen=true) # try not to cut off the markers
    plot!(xticks = [], ylims = (58,85)) # for staff
    plot!(xlims = (0, length(midiWithDuration) + 3))
    yticks!([64,67,71,74,77,81,84], ["E", "G", "B", "D", "F", "A", "C"]) # helpful labels for staff lines
    plot!(yforeground_color_grid = :blue) # blue staff, just for fun
    plot!(foreground_color_border = :red) # make border "invisible"
    plot!(gridlinewidth = 1.5) # increase width of grid lines
    plot!(gridalpha = 0.9) # make grid lines more visible
    plot!(margin = 5mm)
    savefig("errors.png")

    ##generate error.png
    errorImg = GtkImage(string(@__DIR__) * "/errors.png")
    g[4:10,5:8] = errorImg

end

##record loop for taking in audio until end
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
    playMetronome()
    
    
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

end

# callback function for "play" button
function call_transcribe(w)
    println("Transcribe")
    autocorrelationCalculator()


    ##display midis to console
    display(dataSongMidi)
    display(inputSongMidi)

    ##generate score
    generateScore()
end


##Creating Elements


##songNameLabel indiciating selected instrument
songNameLabel = GtkLabel("Current Song: " * currentSong)
g[1:3, 1] = songNameLabel

##recording indicator
recordLabel = GtkLabel("Press Record To Start")
g[6:8, 5] = recordLabel



# create buttons with appropriate callbacks, positions, and styles
br = make_button("Record", call_record, 5, "wr", "color:white; background:red;")
bs = make_button("Stop", call_stop, 6, "yb", "color:yellow; background:blue;")
bp = make_button("Play Song", call_play, 7, "wg", "color:white; background:green;")
bt = make_button("Generate Score", call_transcribe, 8, "wg", "color:white; background:purple;")


img = Gtk.GtkImage("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/start.png")
g[4:10,1:3] = img

getSongData()

#Create window and push GTK to window
win = GtkWindow("TrumpetScriber", 1000 , 600) # 1000×600 pixel window for all the buttons
push!(win, g) # put button grid into the window

##Close Window
cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond) # exit program on window close