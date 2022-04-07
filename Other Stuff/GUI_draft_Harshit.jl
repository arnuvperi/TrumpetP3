using Gtk
using Sound: sound
using WAV: wavwrite
using FFTW: fft

white = ["G" 67; "A" 69; "B" 71; "C" 72; "D" 74; "E" 76; "F" 77; "G" 79; "REST" 0;]
white_half = ["(1/2) G" 67; "(1/2) A" 69; "(1/2) B" 71; "(1/2) C" 72; "(1/2) D" 74; "(1/2) E" 76; "(1/2) F" 77; "(1/2) G" 79; "(1/2) REST" 0;]
white_quarter = ["(1/4) G" 67 ; "(1/4) A" 69; "(1/4) B" 71 ; "(1/4) C" 72; "(1/4) D" 74; "(1/4) E" 76; "(1/4) F" 77; "(1/4) G" 79; "(1/4) REST" 0]
black = ["G" 68 2; "A" 70 4; "C" 73 8; "D" 75 10; "F" 78 14]
black_half = ["(1/2) G" 68 2; "(1/2) A" 70 4; "(1/2) C" 73 8; "(1/2) D" 75 10; "(1/2) F" 78 14]
black_quarter = ["(1/4) G" 68 2; "(1/4) A" 70 4; "(1/4) C" 73 8; "(1/4) D" 75 10; "(1/4) F" 78 14]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

# define the "style" of the the end button
endButton = GtkCssProvider(data="#end {color:white; background:green;}")
undo = GtkCssProvider(data="#undo {color:white; background:gray;}")
clear = GtkCssProvider(data="#clear {color:white; background:red;}")
save = GtkCssProvider(data="#clear {color:white; background:blue;}")
load =  GtkCssProvider(data="#clear {color:white; background:purple;}")
record =  GtkCssProvider(data="#clear {color:white; background:pink;}")

#black sharp whole note
for i in 1:size(black,1) # add the black keys to the grid
    key, midi, start = black[i,1:3]
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[start .+ (0:1), 3] = b # put the button in row 3 of the grid
end

#quarter note for black keys
for i in 1:size(black_quarter,1) # add the black keys to the grid
    key, midi, start = black_quarter[i,1:3]
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[start .+ (0:1), 1] = b # put the button in row 1 of the grid
end

#half notes for black keys
for i in 1:size(black_half,1) # add the black keys to the grid
    key, midi, start = black_half[i,1:3]
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[start .+ (0:1), 2] = b # put the button in row 2 of the grid
end

# quarter note white
for i in 1:size(white_quarter,1) # add the white keys to the grid
    key, midi = white_quarter[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 4] = b # put the button in row 4 of the grid
end

# half note
for i in 1:size(white_half,1) # add the white keys to the grid
    key, midi = white_half[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 5] = b # put the button in row 5 of the grid
end

# whole note
for i in 1:size(white,1) # add the white keys to the grid
    key, midi = white[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 6] = b # put the button in row 6 of the grid
end

function end_button_clicked(w) # callback function for "end" button
    println("Playing Song")
    sound(song, S) # play the entire song when user clicks "end"
    matwrite("proj1.mat", Dict("song" => song); compress=true) # save song to file
end

function undo_button_clicked(w)
    global song = song[1:length(song) - nsample]
    println("Undid Last Note")
end

function clear_button_clicked(w)
    global song = Float32[]
    println("Clearing Song")
end

function transcribe_button_clicked(w)
    println("Transcribing Song")
    include("transcriber.jl")
end

cb = GtkComboBoxText()
choices = ["Electric Guitar", "Bass section", "Flute", "Trumpet"]
for choice in choices
  push!(cb,choice)
end
# Lets set the active element to be "two"
set_gtk_property!(cb,:active,1)

signal_connect(cb, "changed") do widget, others...
  # get the active index
  idx = get_gtk_property(cb, "active", Int)
  # get the active string 
  # We need to wrap the GAccessor call into a Gtk bytestring
  str = Gtk.bytestring( GAccessor.active_text(cb) ) 
  println("Active element is \"$str\" at index $idx")
end
g[7:13,8] = cb

ebutton = GtkButton("end") # make an "end" button
g[7:10, 7] = ebutton # fill up entire row 3 of grid - why not?
signal_connect(end_button_clicked, ebutton, "clicked") # callback
push!(GAccessor.style_context(ebutton), GtkStyleProvider(finish), 600)
set_gtk_property!(ebutton, :name, "end") # set style of the "end" button

ubutton = GtkButton("undo") # undo button
g[4:6, 7] = ubutton
signal_connect(undo_button_clicked, ubutton, "clicked")
push!(GAccessor.style_context(ubutton), GtkStyleProvider(undo), 600)
set_gtk_property!(ubutton, :name, "undo")

cbutton = GtkButton("clear") # clear button
g[11:13, 7] = cbutton
signal_connect(clear_button_clicked, cbutton, "clicked")
push!(GAccessor.style_context(cbutton), GtkStyleProvider(clear), 600)
set_gtk_property!(cbutton, :name, "clear")

tbutton = GtkButton("transcribe") # transcribe button
g[14:16, 7] = tbutton
signal_connect(transcribe_button_clicked, tbutton, "clicked")
push!(GAccessor.style_context(tbutton), GtkStyleProvider(transcribe), 600)
set_gtk_property!(tbutton, :name, "transcribe")


win = GtkWindow("GUI keyboard",1000 , 600) # 600×600 pixel window for all the buttons
push!(win, g) # put button grid into the window

keyboard_to_midi = Dict(
    115 => 67,
    100 => 69,
    102 => 71,
    103 => 72,
    104 => 74,
    106 => 76,
    107 => 77,
    108 => 79,
    101 => 68,
    114 => 70,
    121 => 73,
    117 => 75,
    111 => 78
)

signal_connect(win, "key-press-event") do widget, event # parse keyboard input
    if haskey(keyboard_to_midi, event.keyval)
        miditone(keyboard_to_midi[event.keyval])
    elseif event.keyval == 113
        rest_button_clicked(rbutton)
    elseif event.keyval == 112
        end_button_clicked(ebutton)
    elseif event.keyval == 96
        clear_button_clicked(cbutton)
    elseif event.keyval == 119
        undo_button_clicked(ubutton)
    elseif event.keyval == 92
        transcribe_button_clicked(tbutton)
    end
end

cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond) # exit program on window close