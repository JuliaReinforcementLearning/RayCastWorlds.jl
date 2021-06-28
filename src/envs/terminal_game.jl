module SingleRoomGameModule

import ..Play
import RayCaster as RC
import ..RayCastWorlds as RCW
import REPL
import SimpleDraw as SD
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
    tile_map_colors::NTuple{C}
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

# function update_drawings!(game::SingleRoomGame)
    # tile_map = game.tile_map
    # top_view = game.top_view
    # camera_view = game.camera_view

    # height_tile_map_tu, width_tile_map_tu = size(tile_map, 2), size(tile_map, 3)
    # height_top_view_pu, width_top_view_pu = size(top_view)
    # height_camera_view_pu, width_camera_view_pu = size(camera_view)

    # pu_per_tu = height_top_view_pu ÷ height_tile_map_tu

    # RCW.draw_tile_map!(top_view, tile_map, OBJECT_CHARACTERS)

    # i_player_position_pu, j_player_position_pu = RCW.wu_to_pu.(game.player_position_wu, pu_per_tu)
    # player_radius_pu = RCW.wu_to_pu(game.player_radius_wu, pu_per_tu)

    # SD.draw!(top_view, SD.Circle(i_player_position_pu, j_player_position_pu, player_radius_pu), RCW.BLOCK_THREE_QUARTER_SHADED)

    # ray_draw_string = RCW.BLOCK_HALF_SHADED
    # obstacle_map = @view tile_map[WALL, :, :]

    # player_direction_au = game.player_direction_au[]
    # player_direction_wu = @view game.directions_wu[:, player_direction_au + 1]
    # field_of_view_start_au = player_direction_au - (game.field_of_view_au - 1) ÷ 2
    # field_of_view_end_au = player_direction_au + (game.field_of_view_au - 1) ÷ 2

    # color_floor = RCW.BLOCK_FULL_SHADED
    # color_wall_dim_1 = RCW.BLOCK_THREE_QUARTER_SHADED
    # color_wall_dim_2 = RCW.BLOCK_HALF_SHADED
    # color_ceiling = RCW.BLOCK_QUARTER_SHADED

    # for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        # idx = mod(theta_au, game.num_directions) + 1
        # ray_direction_wu = @view game.directions_wu[:, idx]
        # # side_dist_wu, hit_dimension, i_hit_tu, j_hit_tu = RC.cast_ray(obstacle_map, game.player_position_wu..., ray_direction_wu...)
        # side_dist_wu, hit_dimension, i_hit_tu, j_hit_tu = RCW.cast_ray(obstacle_map, game.player_position_wu, ray_direction_wu)

        # # top_view
        # i_ray_stop_pu, j_ray_stop_pu = RCW.wu_to_pu.(game.player_position_wu + side_dist_wu * ray_direction_wu, pu_per_tu)

        # SD.draw!(top_view, SD.Line(i_player_position_pu, j_player_position_pu, i_ray_stop_pu, j_ray_stop_pu), ray_draw_string)

        # # camera_view
        # perp_dist = side_dist_wu * sum(player_direction_wu .* ray_direction_wu)
        # height_line_pu = floor(Int, height_camera_view_pu / perp_dist)

        # if hit_dimension == 1
            # color = color_wall_dim_1
        # elseif hit_dimension == 2
            # color = color_wall_dim_2
        # end

        # k = width_camera_view_pu - i + 1

        # if height_line_pu >= height_camera_view_pu - 1
            # camera_view[:, k] .= color
        # else
            # padding_pu = (height_camera_view_pu - height_line_pu) ÷ 2
            # camera_view[1:padding_pu, k] .= color_ceiling
            # camera_view[padding_pu + 1 : end - padding_pu, k] .= color
            # camera_view[end - padding_pu + 1 : end, k] .= color_floor
        # end
    # end

    # return nothing
# end

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
