#Team Trumpet Project 3
using Gtk
using Sound: sound
using WAV: wavwrite
using FFTW: fft
using DelimitedFiles
using Plots; default(markerstrokecolor=:auto, label="")
using Statistics: mean
using Measures

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
    GAccessor.text(label, "Current Song: " * currentSong)
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
    display(frequencies)
    generatePlot(durations, frequencies)
    img = GtkImage("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/plot.png")
    g[5,1] = img
end

function generatePlot(durations::Vector{Any}, frequencies::Vector{Any})
    plt = plot(frequencies, line=:stem, marker=:circle, markersize = 10, color=:black)
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
end


##Creating Elements


##label indiciating selected instrument
label = GtkLabel("Current Song: " * currentSong)
g[1:3, 1] = label

##create default image
img = GtkImage("/Users/arnuvperi/Library/CloudStorage/OneDrive-Personal/UMich/Winter 2022/ENGR 100/Project 3/Project 3 Code/TrumpetP3/plot.png")
g[4:10,1:3] = img








#Create window and push GTK to window
win = GtkWindow("TrumpetScriber", 1000 , 600) # 1000×600 pixel window for all the buttons
push!(win, g) # put button grid into the window

##Close Window
cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond) # exit program on window close