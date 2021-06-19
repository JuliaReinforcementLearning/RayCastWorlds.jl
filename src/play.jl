module Play

import REPL

const ESC = Char(0x1B)
const HIDE_CURSOR = ESC * "[?25l"
const SHOW_CURSOR = ESC * "[?25h"
const CLEAR_SCREEN = ESC * "[2J"
const MOVE_CURSOR_TO_ORIGIN = ESC * "[H"
const CLEAR_SCREEN_BEFORE_CURSOR = ESC * "[1J"
const EMPTY_SCREEN = CLEAR_SCREEN_BEFORE_CURSOR * MOVE_CURSOR_TO_ORIGIN

open_maybe(file_name::AbstractString) = open(file_name, "w")
open_maybe(::Nothing) = nothing

close_maybe(io::IO) = close(io)
close_maybe(io::Nothing) = nothing

write_maybe(io::IO, content) = write(io, content)
write_maybe(io::Nothing, content) = 0
write_io1_maybe_io2(io1::IO, io2::Union{Nothing, IO}, content) = write(io1, content) + write_maybe(io2, content)

show_maybe(io::IO, mime::MIME, content) = show(io, mime, content)
show_maybe(io::Nothing, mime::MIME, content) = nothing
function show_io1_maybe_io2(io1::IO, io2::Union{Nothing, IO}, mime::MIME, content)
    show(io1, mime, content)
    show_maybe(io2, mime, content)
end

function show_image(io::IO, ::MIME"text/plain", image)
    height, width = size(image)

    for i in 1:height
        for j in 1:width
            print(io, image[i, j])
        end

        if i < height
            print(io, "\n")
        end
    end

    return nothing
end

show_image_maybe(io::IO, mime, image) = show_image(io, mime, image)
show_image_maybe(io::Nothing, mime, image) = nothing
function show_image_io1_maybe_io2(io1::IO, io2::Union{Nothing, IO}, mime::MIME, content)
    show_image(io1, mime, content)
    show_image_maybe(io2, mime, content)
    return nothing
end

function replay(terminal::REPL.Terminals.UnixTerminal, file_name::AbstractString, frame_rate)
    terminal_out = terminal.out_stream
    delimiter = EMPTY_SCREEN
    frames = split(read(file_name, String), delimiter)
    for frame in frames
        write(terminal_out, frame)
        sleep(1 / frame_rate)
        write(terminal_out, delimiter)
    end

    return nothing
end

replay(file_name; frame_rate = 2) = replay(REPL.TerminalMenus.terminal, file_name, frame_rate)

end # module
