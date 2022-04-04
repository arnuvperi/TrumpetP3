#Team Trumpet Project 3 Synthesizer
using Gtk
using Sound: sound
using WAV: wavwrite
using FFTW: fft
using DelimitedFiles



# Initialize S and N variables for Sound Usage
S = 8192 # sampling rate (samples/second)
N = div(8192,2) ; n = 0:N-1; t = n/S


#Initialize empty arrays to store data
freqs = Float32[] #stores frequencies of notes
durations = Float32[] #stores durations of notes
tone = Float32[] # initialize "tone" as an empty vector


#Play Sound for Quicker Resposse later
sound([1], S)

#Define GTK grid and properties
g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)


##Generate Tone Function##
function generateTone(key, freq1::Float64, duration::Int64)
    global N = div(8192,duration) ; n = 0:N-1; t = n/S
    x = cos.(2 * pi * t * freq1) # generate sinusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global tone = [tone; x] # append note to the (global) tone vector
    push!(freqs, freq1)
    push!(durations, duration)

    return nothing
end



##Define [Note Name Frequency PlaceOnGTKGrid]##

#regular notes
wholenotes = ["C" 261.63 1; "D" 293.67 3; "E" 329.63 5; "F" 349.23 6; "G" 392.0 8; "A" 440.0 10; "B" 493.88 12; "C" 523.25 13; "REST" 0.0 14]
halfnotes = ["1/2" 261.63 1; "1/2" 293.67 3; "1/2" 329.63 5; "1/2" 349.23 6; "1/2" 392.0 8; "1/2" 440.0 10; "1/2" 493.88 12; "1/2" 523.25 13; "REST" 0.0 14]
quarternotes = ["1/4" 261.63 1; "1/4" 293.67 3; "1/4" 329.63 5; "1/4" 349.23 6; "1/4" 392.0 8; "1/4" 440.0 10; "1/4" 493.88 12; "1/4" 523.25 13; "REST" 0.0 14]

#accidentals (sharps and flats)
sharpwhole = ["C" 277.18 2; "D" 311.13 4; "F" 369.99 8; "G" 415.3 10; "A" 466.16 12]
sharphalf = ["1/2" 277.18 2; "1/2" 311.13 4; "1/2" 369.99 8; "G# 1/2" 415.3 10; "1/2" 466.16 12]
sharpquarter = ["1/4" 277.18 2; "1/4" 311.13 4; "1/4" 369.99 8; "1/4" 415.3 10; "1/4" 466.16 12]


#Create whole note black keys
for i in 1:size(sharpwhole,1) # add the black keys to the grid
    key, freq1, start = sharpwhole[i,1:3]
    duration = 1
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>

    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[start .+ (0:1), 3] = b # put the button in row 3 of the grid

    sharp = GtkCssProvider(data="#acc {color:white; background:black;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, key) # set "style" of black key
end

#Create 1/2 note black keys
for i in 1:size(sharphalf,1) # add the black keys to the grid
    key, freq1, start = sharphalf[i,1:3]
    duration = 2

    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>

    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[start .+ (0:1), 2] = b # put the button in row 2 of the grid

    sharp = GtkCssProvider(data="#acc {color:white; background:black;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, key) # set "style" of black key
end

#Create 1/4 note black keys
for i in 1:size(sharpquarter,1) # add the black keys to the grid
    key, freq1, start = sharpquarter[i,1:3]
    duration = 4
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>

    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[start .+ (0:1), 1] = b # put the button in row 1 of the grid

    sharp = GtkCssProvider(data="#acc {color:white; background:black;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, key) # set "style" of black key
end

#Create whole note white keys
for i in 1:size(wholenotes,1) # add the white keys to the grid
    key, freq1, place = wholenotes[i,1:3]
    duration = 1

    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 6] = b # put the button in row 6 of the grid
end

#Create 1/2 note white keys
for i in 1:size(halfnotes,1) # add the white keys to the grid
    key, freq1, place = halfnotes[i,1:3]
    duration = 2

    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 5] = b # put the button in row 5 of the grid
end

#Create 1/4 note white keys
for i in 1:size(quarternotes,1) # add the white keys to the grid
    key, freq1, place = quarternotes[i,1:3]
    duration = 4

    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 4] = b # put the button in row 4 of the grid
end

##Start of End Button##
endButton = GtkCssProvider(data="#end {color:white; background:green;}")

function end_button_clicked(w) # callback function for "end" button
    println("Playing Tone and Writing to File")
    sound(tone, S) # play the entire tone when user clicks "end"
    wavwrite(tone, "touch.wav"; Fs=S) # save tone to file
    writedlm("synthData.txt", [freqs durations], ", ")
end

ebutton = GtkButton("end") # make an "end" button
g[7:10, 7] = ebutton # place in row
signal_connect(end_button_clicked, ebutton, "clicked") # callback
push!(GAccessor.style_context(ebutton), GtkStyleProvider(endButton), 600)
set_gtk_property!(ebutton, :name, "end") # set style of the "end" button

##End of End Button##

##Start of Undo Button##
undo = GtkCssProvider(data="#undo {color:white; background:gray;}")

function undo_button_clicked(w) # callback function for undo button
    if length(tone) > 0
        global tone = tone[1:length(tone) - N]
    end
    global freqs = freqs[1:end-1]
    global durations = durations[1:end-1]
    println("Undid Last Tone")
end

ubutton = GtkButton("undo") # undo button
g[4:6, 7] = ubutton
signal_connect(undo_button_clicked, ubutton, "clicked")
push!(GAccessor.style_context(ubutton), GtkStyleProvider(undo), 600)
set_gtk_property!(ubutton, :name, "undo") #set style to undo


##End of Undo Button##

##Start of Clear Button##
clear = GtkCssProvider(data="#clear {color:white; background:red;}")

function clear_button_clicked(w) # callback function for clear button
    global tone = Float32[]
    global freqs =  Float32[]
    global durations = Float32[]
    println("Clearing Tone")
end

cbutton = GtkButton("clear") # clear button
g[11:13, 7] = cbutton
signal_connect(clear_button_clicked, cbutton, "clicked")
push!(GAccessor.style_context(cbutton), GtkStyleProvider(clear), 600)
set_gtk_property!(cbutton, :name, "clear") #set style to clear


##End of Clear Button##




#Create window and push GTK to window
win = GtkWindow("TrumpetScriber", 1000 , 600) # 1000×600 pixel window for all the buttons
push!(win, g) # put button grid into the window

##Signal Connect for Callback##
signal_connect(win, "key-press-event") do widget, event # parse keyboard input        
    if event.keyval == 112
        end_button_clicked(ebutton)
    elseif event.keyval == 96
        clear_button_clicked(cbutton)
    elseif event.keyval == 119
        undo_button_clicked(ubutton)
    end
end

##Close Window
cond = Condition()
endit(win) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond) # exit program on window close