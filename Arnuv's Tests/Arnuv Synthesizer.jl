#Team Trumpet Project 3 Synthesizer
using Gtk
using Sound: sound
using WAV: wavwrite
using FFTW: fft
using DelimitedFiles



# Initialize S and N variables for Sound Usage
S = 44100 # sampling rate (samples/second)
N = div(S,2) ; n = 0:N-1; t = n/S


#Initialize empty arrays to store data
freqs = Float32[] #stores frequencies of notes
durations = Float32[] #stores durations of notes
tone = Float32[] # initialize "tone" as an empty vector

songName = "Enter_Song_Name_Here"
instrumentOptions = ["Piano"; "Guitar"; "Trumpet"]
currentInstrument = instrumentOptions[1]


#Play Sound for Quicker Response later
sound([1], S)

##Generate Tone Function##
function generateTone(freq::Float64, duration::Int64)
    global N = div(S,duration) ; n = 0:N-1; t = n/S
    x = cos.(2 * pi * t * freq) # generate sinusoidal tone
    y = cos.(2 * pi * t * freq) #copy to upload to tone
    if currentInstrument == instrumentOptions[1]
        x = (sin.(pi*t*freq).^3)
    end
    sound(x, S) # play note so that user can hear it immediately
    global tone = [tone; y] # append note to the (global) tone vector
    global tone = [tone; zeros(100)] #append 100 zeros to the end for note spacing
    push!(freqs, freq) #push frequency into array of frequencies
    push!(durations, duration) #push duration into array of durations
    return nothing
end

#Define GTK grid and properties
g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)


sharp = GtkCssProvider(data="#wb {color:white; background:black;}")
endButton = GtkCssProvider(data="#end {color:white; background:green;}")
undo = GtkCssProvider(data="#undo {color:white; background:gray;}")
clear = GtkCssProvider(data="#clear {color:white; background:red;}")
instrument = GtkCssProvider(data="#ins {color:white; background:blue;}")
instrumentSelect = GtkCssProvider(data="#insClick {color:orange; background:blue;}")


##Define [Note Name Frequency PlaceOnGTKGrid]##

#regular notes
whitekeys = ["C" 261.63 1; "D" 293.67 3; "E" 329.63 5; "F" 349.23 6; "G" 392.0 8; "A" 440.0 10; "B" 493.88 12; "C" 523.25 13; "Rest" 0.0 14]

#accidentals (sharps and flats)

accidentals = ["C" 277.18 2; "D" 311.13 4; "F" 369.99 8; "G" 415.3 10; "A" 466.16 12]
sharphalf = ["1/2" 277.18 2; "1/2" 311.13 4; "1/2" 369.99 8; "1/2" 415.3 10; "1/2" 466.16 12]
sharpquarter = ["1/4" 277.18 2; "1/4" 311.13 4; "1/4" 369.99 8; "1/4" 415.3 10; "1/4" 466.16 12]


#Create whole note black keys
for i in 1:size(accidentals,1) # add the black keys to the grid
    key, freq, position = accidentals[i,1:3]
    duration = 1
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((win) -> generateTone(freq, duration), b, "clicked") # callback
    g[position .+ (0:1), 3] = b # put the button in row 3 of the grid

end

#Create 1/2 note black keys
for i in 1:size(accidentals,1) # add the black keys to the grid
    key, freq, position = accidentals[i,1:3]
    duration = 2

    b = GtkButton("1/2") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((win) -> generateTone(freq, duration), b, "clicked") # callback
    g[position .+ (0:1), 2] = b # put the button in row 2 of the grid
end

#Create 1/4 note black keys
for i in 1:size(accidentals,1) # add the black keys to the grid
    key, freq, position = accidentals[i,1:3]
    duration = 4

    b = GtkButton("1/4") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> generateTone(freq, duration), b, "clicked") # callback
    g[position .+ (0:1), 1] = b # put the button in row 1 of the grid
end

#Create whole note white keys
for i in 1:size(whitekeys,1) # add the white keys to the grid
    key, freq, place = whitekeys[i,1:3]
    duration = 1

    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(freq, duration), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 6] = b # put the button in row 6 of the grid
end

#Create 1/2 note white keys
for i in 1:size(whitekeys,1) # add the white keys to the grid
    key, freq, place = whitekeys[i,1:3]
    duration = 2

    b = GtkButton("1/2") # make a button for this key
    signal_connect((win) -> generateTone(freq, duration), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 5] = b # put the button in row 5 of the grid
end

#Create 1/4 note white keys
for i in 1:size(whitekeys,1) # add the white keys to the grid
    key, freq, place = whitekeys[i,1:3]
    duration = 4

    b = GtkButton("1/4") # make a button for this key
    signal_connect((win) -> generateTone(freq, duration), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 4] = b # put the button in row 4 of the grid
end

##Generate row of buttons for instruments

for i in 1:size(instrumentOptions,1) # add the instrument buttons to the grid
    insName = instrumentOptions[i]
    b = GtkButton(insName) # make a button for this key

    push!(GAccessor.style_context(b), GtkStyleProvider(instrument), 600)
    set_gtk_property!(b, :name, "ins") # set style of the "instrument" button
    signal_connect((win) -> instrument_selected(i), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 8] = b # put the button in row 5 of the grid
end


##CALLBACK FUNCTIONS##
function save_button_clicked(w) # callback function for "end" button
    println("Playing Tone and Writing to File")
    sound(tone, S) # play the entire tone when user clicks "end"
    wavwrite(tone, songName * ".wav"; Fs=S) # save tone to file
    writedlm(songName * ".txt", [freqs durations], ", ")
end

function undo_button_clicked(w) # callback function for undo button
    if length(tone) > 0
        global tone = tone[1:length(tone) - N]
    end
    global freqs = freqs[1:end-1]
    global durations = durations[1:end-1]
    println("Undid Last Tone")
end

function clear_button_clicked(w) # callback function for clear button
    global tone = Float32[]
    global freqs =  Float32[]
    global durations = Float32[]
    println("Clearing Tone")
end

function text_entered(w)
    global songName = get_gtk_property(ent,:text,String)
    println("Song Name Retrieved")
end

function instrument_selected(index::Int64)
    currentInstrument = instrumentOptions[index]
    GAccessor.text(label, "Current Instrument: " * currentInstrument)
    println(currentInstrument * " selected")
end



##INITIALIZE BUTTONS##

##end button
sbutton = GtkButton("save") # make an "end" button
g[4:7, 7] = sbutton # place in row
signal_connect(save_button_clicked, sbutton, "clicked") # callback
push!(GAccessor.style_context(sbutton), GtkStyleProvider(endButton), 600)
set_gtk_property!(sbutton, :name, "end") # set style of the "end" button


##undo button
ubutton = GtkButton("undo") # undo button
g[1:3, 7] = ubutton
signal_connect(undo_button_clicked, ubutton, "clicked")
push!(GAccessor.style_context(ubutton), GtkStyleProvider(undo), 600)
set_gtk_property!(ubutton, :name, "undo") #set style to undo

##clear button
cbutton = GtkButton("clear") # clear button
g[8:11, 7] = cbutton
signal_connect(clear_button_clicked, cbutton, "clicked")
push!(GAccessor.style_context(cbutton), GtkStyleProvider(clear), 600)
set_gtk_property!(cbutton, :name, "clear") #set style to clear


##entry field for name of song
ent = GtkEntry()
g[12:17, 7] = ent
set_gtk_property!(ent,:text, songName)
id = signal_connect(text_entered, ent, "changed")


##label indiciating selected instrument
label = GtkLabel("Current Instrument: " * currentInstrument)
g[12:17, 8] = label


#Create window and push GTK to window
win = GtkWindow("TrumpetScriber", 1000 , 600) # 1000×600 pixel window for all the buttons
push!(win, g) # put button grid into the window

##Signal Connect for Callback##
signal_connect(win, "key-press-event") do widget, event # parse keyboard input        
    if event.keyval == 112
        save_button_clicked(sbutton)
    elseif event.keyval == 96
        clear_button_clicked(cbutton)
    elseif event.keyval == 119
        undo_button_clicked(ubutton)
    end
end

##Close Window
cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond) # exit program on window close