# SYNTH FOR PROJECT 2 TEAM TRUMPET

using Gtk
using Sound: sound
using WAV: wavwrite
using FFTW: fft


# initialize two global variables used throughout
S = 8192 # sampling rate (samples/second)
N = div(8192,2) ; n = 0:N-1; t = n/S
#N is changing from the synth note length
tone = Float32[] # initialize "tone" as an empty vector
numbers = ""

frequencies = Float32[]
durations = Float32[]


sound([1], S) # speeds up first note playback

function generateTone(key, freq1::Float64, duration::Int64)
    global N = div(8192,duration) ; n = 0:N-1; t = n/S
    x = cos.(2 * pi * t * freq1) # generate sinusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global tone = [tone; x] # append note to the (global) tone vector
    push!(frequencies, freq1)
    push!(durations, duration)

    return nothing
end

#regular notes
wholenotes = ["C" 261.63 1; "D" 293.67 3; "E" 329.63 5; "F" 349.23 6; "G" 392.0 8; "A" 440.0 10; "B" 493.88 12; "C" 523.25 13]
halfnotes = ["1/2" 261.63 1; "1/2" 293.67 3; "1/2" 329.63 5; "1/2" 349.23 6; "1/2" 392.0 8; "1/2" 440.0 10; "1/2" 493.88 12; "1/2" 523.25 13]
quarternotes = ["1/4" 261.63 1; "1/4" 293.67 3; "1/4" 329.63 5; "1/4" 349.23 6; "1/4" 392.0 8; "1/4" 440.0 10; "1/4" 493.88 12; "1/4" 523.25 13]

#accidentals (sharps and flats)
sharpwhole = ["C#" 277.18 2; "D#" 311.13 4; "F#" 369.99 7; "G#" 415.3 9; "A#" 466.16 11]
sharphalf = ["1/2" 277.18 2; "1/2" 311.13 4; "1/2" 369.99 7; "G# 1/2" 415.3 9; "1/2" 466.16 11]
sharpquarter = ["1/4" 277.18 2; "1/4" 311.13 4; "1/4" 369.99 7; "1/4" 415.3 9; "1/4" 466.16 11]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)



#regular notes
for i in 1:size(wholenotes, 1) # add the row1 keys to the grid
    
    key, freq1, place = wholenotes[i,1:3]
    duration = 1
    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[place, 4] = b  # put the button in row 3 of the grid

    #color
    regularNote = GtkCssProvider(data="#reg {color:black; background:white;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(regularNote), 600)
    set_gtk_property!(b, :name, key) 
end

for i in 1:size(halfnotes, 1) # add the row1 keys to the grid
    key, freq1, place = halfnotes[i,1:3]
    duration = 2
    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[place, 3] = b  # put the button in row 2 of the grid

    #color
    regularNote = GtkCssProvider(data="#reg {color:black; background:white;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(regularNote), 600)
    set_gtk_property!(b, :name, key) 
end

for i in 1:size(quarternotes, 1) # add the row1 keys to the grid
    key, freq1, place = quarternotes[i,1:3]
    duration = 4
    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[place, 2] = b  # put the button in row 2 of the grid

    #color
    regularNote = GtkCssProvider(data="#reg {color:black; background:white;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(regularNote), 600)
    set_gtk_property!(b, :name, key) 
end

#sharps
for i in 1:size(sharpwhole, 1) # add the row1 keys to the grid
    key, freq1, place = sharpwhole[i,1:3]
    duration = 1
    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[place, 3] = b  # put the button in row 3 of the grid

    #color
    accidentalNote = GtkCssProvider(data="#acc {color:white; background:black;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(accidentalNote), 600)
    set_gtk_property!(b, :name, key) 
end

for i in 1:size(sharphalf, 1) # add the row1 keys to the grid
    key, freq1, place = sharphalf[i,1:3]
    duration = 1
    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[place, 2] = b  # put the button in row 3 of the grid

    #color
    accidentalNote = GtkCssProvider(data="#acc {color:white; background:black;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(accidentalNote), 600)
    set_gtk_property!(b, :name, key) 
end

for i in 1:size(sharpquarter, 1) # add the row1 keys to the grid
    key, freq1, place = sharpquarter[i,1:3]
    duration = 1
    b = GtkButton(key) # make a button for this key
    signal_connect((win) -> generateTone(key, freq1, duration), b, "clicked") # callback
    g[place, 1] = b  # put the button in row 3 of the grid

    #color
    accidentalNote = GtkCssProvider(data="#acc {color:white; background:black;}")
    push!(GAccessor.style_context(b), GtkStyleProvider(accidentalNote), 600)
    set_gtk_property!(b, :name, key) 
end



function end_button_clicked(w) # callback function for "end" button
    println("Playing Tone and Writing to File")
    sound(tone, S) # play the entire tone when user clicks "end"
    wavwrite(tone, "touch.wav"; Fs=S) # save tone to file
end

function undo_button_clicked(w) # callback function for undo button
    if length(tone) > 0
        global tone = tone[1:length(tone) - N]
    end
    global frequencies = frequenices[1:end-1]
    global durations = durations[1:end-1]

    println("Undid Last Tone")
end

function clear_button_clicked(w) # callback function for clear button
    global tone = Float32[]
    global numbers = ""
    global frequencies =  Float32[]
    global durations =  Float32[]
    println("Clearing Tone")
end


#define and place end, undo, and clear buttons

# define the "style" of the the end, undo, and claer buttons
endButton = GtkCssProvider(data="#end {color:white; background:green;}")
undo = GtkCssProvider(data="#undo {color:white; background:gray;}")
clear = GtkCssProvider(data="#clear {color:white; background:red;}")


ebutton = GtkButton("end") # make an "end" button
g[3, 6] = ebutton 
signal_connect(end_button_clicked, ebutton, "clicked") 
push!(GAccessor.style_context(ebutton), GtkStyleProvider(endButton), 600)
set_gtk_property!(ebutton, :name, "end") 

ubutton = GtkButton("undo") # undo button
g[2, 6] = ubutton
signal_connect(undo_button_clicked, ubutton, "clicked")
push!(GAccessor.style_context(ubutton), GtkStyleProvider(undo), 600)
set_gtk_property!(ubutton, :name, "undo")

cbutton = GtkButton("clear") # clear button
g[1, 6] = cbutton
signal_connect(clear_button_clicked, cbutton, "clicked")
push!(GAccessor.style_context(cbutton), GtkStyleProvider(clear), 600)
set_gtk_property!(cbutton, :name, "clear")


win = GtkWindow("TrumpetScriber Synthesizer", 400, 300) # 400×300 pixel window for all the buttons
push!(win, g) # put button grid into the window


signal_connect(win, "key-press-event") do widget, event # parse keyboard input
    if event.keyval == 112
        end_button_clicked(ebutton)
        Gtk.destroy(win)
    elseif event.keyval == 96
        clear_button_clicked(cbutton)
    elseif event.keyval == 119
        undo_button_clicked(ubutton)
    end
end


cond = Condition()
endit(win) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond)
 # exit program on window close
