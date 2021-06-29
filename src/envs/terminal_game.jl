module SingleRoomGameModule

import ..Play
import ..RayCastWorlds as RCW
import REPL
import ..SingleRoomModule as SRM
import StaticArrays as SA

const OBJECT_CHARACTERS = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)
const TILE_MAP_CHARACTERS = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)
const ACTION_CHARACTERS = ('w', 's', 'a', 'd')

const NUM_VIEWS = 2
const CAMERA_VIEW = 1
const TOP_VIEW = 2

struct SingleRoomGame{T, C}
    world::SRM.SingleRoom{T}
    top_view::Array{C, 2}
    camera_view::Array{C, 2}
    tile_map_colors::NTuple{SRM.NUM_OBJECTS + 1, C}
    ray_color::C
    player_color::C
    floor_color::C
    ceiling_color::C
    wall_dim_1_color::C
    wall_dim_2_color::C
end

get_default_tile_map_colors(Char) = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)
get_default_ray_color(Char) = RCW.BLOCK_HALF_SHADED
get_default_player_color(Char) = RCW.BLOCK_THREE_QUARTER_SHADED
get_default_floor_color(Char) = RCW.BLOCK_QUARTER_SHADED
get_default_ceiling_color(Char) = RCW.BLOCK_FULL_SHADED
get_default_wall_dim_1_color(Char) = RCW.BLOCK_HALF_SHADED
get_default_wall_dim_2_color(Char) = RCW.BLOCK_THREE_QUARTER_SHADED

function SingleRoomGame(;
        C = Char,
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 128,
        field_of_view_au = isodd(num_directions ÷ 6) ? num_directions ÷ 6 : (num_directions ÷ 6) + 1 ,
        player_position_wu = SA.MVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 8,
        player_radius_wu = convert(T, 1 / 8),
        position_increment_wu = convert(T, 1 / 8),
        pu_per_tu = 4,
    )

    @assert isodd(field_of_view_au)

    world = SRM.SingleRoom(T = T,
                           height_tile_map_tu = height_tile_map_tu,
                           width_tile_map_tu = width_tile_map_tu,
                           num_directions = num_directions,
                           field_of_view_au = field_of_view_au,
                           player_position_wu = player_position_wu,
                           player_direction_au = player_direction_au,
                           player_radius_wu = player_radius_wu,
                           position_increment_wu = position_increment_wu,
                          )

    tile_map_colors = get_default_tile_map_colors(C)
    ray_color = get_default_ray_color(C)
    player_color = get_default_player_color(C)
    floor_color = get_default_floor_color(C)
    ceiling_color = get_default_ceiling_color(C)
    wall_dim_1_color = get_default_wall_dim_1_color(C)
    wall_dim_2_color = get_default_wall_dim_2_color(C)

    SRM.cast_rays!(world)

    camera_view = Array{C}(undef, field_of_view_au, field_of_view_au)
    RCW.update_camera_view!(camera_view, world, floor_color, ceiling_color, wall_dim_1_color, wall_dim_2_color)

    top_view = Array{C}(undef, height_tile_map_tu * pu_per_tu, width_tile_map_tu * pu_per_tu)
    RCW.update_top_view!(top_view, world, tile_map_colors, ray_color, player_color)

    game = SingleRoomGame(world,
                          top_view,
                          camera_view,
                          tile_map_colors,
                          ray_color,
                          player_color,
                          floor_color,
                          ceiling_color,
                          wall_dim_1_color,
                          wall_dim_2_color,
                         )

    return game
end

function play!(terminal::REPL.Terminals.UnixTerminal, game::SingleRoomGame; file_name::Union{Nothing, AbstractString} = nothing)
    world = game.world
    top_view = game.top_view
    camera_view = game.camera_view
    tile_map_colors = game.tile_map_colors
    ray_color = game.ray_color
    player_color = game.player_color
    floor_color = game.floor_color
    ceiling_color = game.ceiling_color
    wall_dim_1_color = game.wall_dim_1_color
    wall_dim_2_color = game.wall_dim_2_color

    REPL.Terminals.raw!(terminal, true)

    terminal_out = terminal.out_stream
    terminal_in = terminal.in_stream
    file = Play.open_maybe(file_name)

    Play.write_io1_maybe_io2(terminal_out, file, Play.CLEAR_SCREEN)
    Play.write_io1_maybe_io2(terminal_out, file, Play.MOVE_CURSOR_TO_ORIGIN)
    Play.write_io1_maybe_io2(terminal_out, file, Play.HIDE_CURSOR)

    current_view = CAMERA_VIEW

    try
        while true
            if current_view == TOP_VIEW
                Play.show_image_block_pixels_io1_maybe_io2(terminal_out, file, MIME("text/plain"), top_view)
            else
                Play.show_image_block_pixels_io1_maybe_io2(terminal_out, file, MIME("text/plain"), camera_view)
            end

            char = read(terminal_in, Char)

            if char == 'q'
                Play.write_io1_maybe_io2(terminal_out, file, Play.SHOW_CURSOR)
                Play.close_maybe(file)
                REPL.Terminals.raw!(terminal, false)
                return nothing
            elseif char == 'v'
                current_view = mod1(current_view + 1, NUM_VIEWS)
                Play.write_io1_maybe_io2(terminal_out, file, Play.CLEAR_SCREEN_BEFORE_CURSOR)
            elseif char in ACTION_CHARACTERS
                SRM.act!(world, findfirst(==(char), ACTION_CHARACTERS))
                SRM.cast_rays!(world)
                RCW.update_top_view!(top_view, world, tile_map_colors, ray_color, player_color)
                RCW.update_camera_view!(camera_view, world, floor_color, ceiling_color, wall_dim_1_color, wall_dim_2_color)
            end

            Play.write_io1_maybe_io2(terminal_out, file, Play.MOVE_CURSOR_TO_ORIGIN)
        end
    finally
        Play.write_io1_maybe_io2(terminal_out, file, Play.SHOW_CURSOR)
        Play.close_maybe(file)
        REPL.Terminals.raw!(terminal, false)
    end

    return nothing
end

play!(game::SingleRoomGame; file_name = nothing) = play!(REPL.TerminalMenus.terminal, game, file_name = file_name)

end # module
