module SingleRoomGameModule

import ColorTypes as CT
import MiniFB as MFB
import ..Play
import ..PlayMiniFB
import ..RayCastWorlds as RCW
import REPL
import ..SingleRoomModule as SRM
import StaticArrays as SA

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

get_action_keys(::Type{Char}) = ('w', 's', 'a', 'd')
get_action_keys(::Type{CT.RGB24}) = (MFB.KB_KEY_W, MFB.KB_KEY_S, MFB.KB_KEY_A, MFB.KB_KEY_D)

get_default_tile_map_colors(::Type{Char}) = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)
get_default_tile_map_colors(::Type{CT.RGB24}) = (reinterpret(CT.RGB24, 0x00FFFFFF), reinterpret(CT.RGB24, 0x00404040))

get_default_ray_color(::Type{Char}) = RCW.BLOCK_HALF_SHADED
get_default_ray_color(::Type{CT.RGB24}) = reinterpret(CT.RGB24, 0x00808080)

get_default_player_color(::Type{Char}) = RCW.BLOCK_THREE_QUARTER_SHADED
get_default_player_color(::Type{CT.RGB24}) = reinterpret(CT.RGB24, 0x00c0c0c0)

get_default_floor_color(::Type{Char}) = RCW.BLOCK_QUARTER_SHADED
get_default_floor_color(::Type{CT.RGB24}) = reinterpret(CT.RGB24, 0x00404040)

get_default_ceiling_color(::Type{Char}) = RCW.BLOCK_FULL_SHADED
get_default_ceiling_color(::Type{CT.RGB24}) = reinterpret(CT.RGB24, 0x00FFFFFF)

get_default_wall_dim_1_color(::Type{Char}) = RCW.BLOCK_HALF_SHADED
get_default_wall_dim_1_color(::Type{CT.RGB24}) = reinterpret(CT.RGB24, 0x00808080)

get_default_wall_dim_2_color(::Type{Char}) = RCW.BLOCK_THREE_QUARTER_SHADED
get_default_wall_dim_2_color(::Type{CT.RGB24}) = reinterpret(CT.RGB24, 0x00c0c0c0)

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
    action_keys = get_action_keys(Char)

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
            elseif char in action_keys
                SRM.act!(world, findfirst(==(char), action_keys))
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

function play_minifb!(game::SingleRoomGame)
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

    height_top_view_pu, width_top_view_pu = size(top_view)
    height_camera_view_pu, width_camera_view_pu = size(camera_view)

    height_image = max(height_top_view_pu, height_camera_view_pu)
    width_image = max(width_top_view_pu, width_camera_view_pu)

    frame_buffer = zeros(UInt32, width_image, height_image)

    window = MFB.mfb_open("Game", width_image, height_image)

    action_keys = get_action_keys(CT.RGB24)

    current_view = CAMERA_VIEW
    if current_view == CAMERA_VIEW
        PlayMiniFB.copy_image_to_frame_buffer!(frame_buffer, camera_view)
    elseif current_view == TOP_VIEW
        PlayMiniFB.copy_image_to_frame_buffer!(frame_buffer, top_view)
    end

    function keyboard_callback(window, key, mod, is_pressed)::Cvoid
        if is_pressed
            println(key)

            if key == MFB.KB_KEY_Q
                MFB.mfb_close(window)
                return nothing
            elseif key == MFB.KB_KEY_V
                current_view = mod1(current_view + 1, NUM_VIEWS)
                fill!(frame_buffer, 0x00000000)
            elseif key in action_keys
                SRM.act!(world, findfirst(==(key), action_keys))
                SRM.cast_rays!(world)
                RCW.update_top_view!(top_view, world, tile_map_colors, ray_color, player_color)
                RCW.update_camera_view!(camera_view, world, floor_color, ceiling_color, wall_dim_1_color, wall_dim_2_color)
            end

            if current_view == CAMERA_VIEW
                PlayMiniFB.copy_image_to_frame_buffer!(frame_buffer, camera_view)
            elseif current_view == TOP_VIEW
                PlayMiniFB.copy_image_to_frame_buffer!(frame_buffer, top_view)
            end
        end

        return nothing
    end

    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    while MFB.mfb_wait_sync(window)
        state = MFB.mfb_update(window, frame_buffer)

        if state != MFB.STATE_OK
            break;
        end
    end

    return nothing
end

end # module
