const BLOCK_EMPTY_SHADED = ' '
const BLOCK_QUARTER_SHADED = '░'
const BLOCK_HALF_SHADED = '▒'
const BLOCK_THREE_QUARTER_SHADED = '▓'
const BLOCK_FULL_SHADED = '█'

function draw_tile_map!(top_view, tile_map, colors)

    _, height_tile_map_tu, width_tile_map_tu = size(tile_map)
    height_top_view_pu = size(top_view, 1)

    pu_per_tu = height_image ÷ height_tile_map

    for j in 1:width_tile_map
        for i in 1:height_tile_map
            i_top_left = (i - 1) * pu_per_tu + 1
            j_top_left = (j - 1) * pu_per_tu + 1

            shape = SD.FilledRectangle(i_top_left, j_top_left, pu_per_tu, pu_per_tu)

            object = findfirst(@view tile_map[:, i, j])
            if isnothing(object)
                color = colors[end]
            else
                color = colors[object]
            end

            SD.draw!(top_view, shape, color)
        end
    end

    return nothing
end

function update_camera_view!(camera_view, world)
    tile_map = world.tile_map
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    field_of_view_au = world.field_of_view_au
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    ray_stop_position_tu = world.ray_stop_position_tu
    ray_hit_dimension = world.ray_hit_dimension
    ray_distance_wu = world.ray_distance_wu
    directions_wu = world.directions_wu

    color_floor = RCW.BLOCK_FULL_SHADED
    color_wall_dim_1 = RCW.BLOCK_THREE_QUARTER_SHADED
    color_wall_dim_2 = RCW.BLOCK_HALF_SHADED
    color_ceiling = RCW.BLOCK_QUARTER_SHADED

    height_tile_map_tu, width_tile_map_tu = size(tile_map, 2), size(tile_map, 3)
    height_camera_view_pu, width_camera_view_pu = size(camera_view)

    player_direction_wu = @view game.directions_wu[:, player_direction_au + 1]
    field_of_view_start_au = player_direction_au - (field_of_view_au - 1) ÷ 2
    field_of_view_end_au = player_direction_au + (field_of_view_au - 1) ÷ 2

    for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        direction_idx = mod(theta_au, num_directions) + 1
        ray_direction_wu = @view directions_wu[:, direction_idx]

        projected_distance_wu = ray_distance_wu[i] * sum(player_direction_wu .* ray_direction_wu)
        height_line_pu = floor(Int, height_camera_view_pu / projected_distance_wu)

        hit_dimension = ray_hit_dimension[i]

        if hit_dimension == 1
            color = color_wall_dim_1
        elseif hit_dimension == 2
            color = color_wall_dim_2
        end

        k = width_camera_view_pu - i + 1

        if height_line_pu >= height_camera_view_pu - 1
            camera_view[:, k] .= color
        else
            padding_pu = (height_camera_view_pu - height_line_pu) ÷ 2
            camera_view[1:padding_pu, k] .= color_ceiling
            camera_view[padding_pu + 1 : end - padding_pu, k] .= color
            camera_view[end - padding_pu + 1 : end, k] .= color_floor
        end
    end

    return nothing
end

function update_top_view!(top_view, world, tile_map_colors, ray_color, player_color)
    tile_map = world.tile_map
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    field_of_view_au = world.field_of_view_au
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    player_radius_wu = world.player_radius_wu
    ray_stop_position_tu = world.ray_stop_position_tu
    ray_hit_dimension = world.ray_hit_dimension
    ray_distance_wu = world.ray_distance_wu
    directions_wu = world.directions_wu

    height_tile_map_tu, width_tile_map_tu = size(tile_map, 2), size(tile_map, 3)
    height_top_view_pu, width_top_view_pu = size(top_view)

    pu_per_tu = height_top_view_pu ÷ height_tile_map_tu

    i_player_position_pu, j_player_position_pu = wu_to_pu.(player_position_wu, pu_per_tu)
    player_radius_pu = wu_to_pu(player_radius_wu, pu_per_tu)

    draw_tile_map!(top_view, tile_map, tile_map_colors)

    for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        idx = mod(theta_au, num_directions) + 1
        ray_direction_wu = @view game.directions_wu[:, idx]

        i_ray_stop_pu, j_ray_stop_pu = wu_to_pu.(player_position_wu + ray_distance_wu[i] * ray_direction_wu, pu_per_tu)

        SD.draw!(top_view, SD.Line(i_player_position_pu, j_player_position_pu, i_ray_stop_pu, j_ray_stop_pu), ray_color)
    end

    SD.draw!(top_view, SD.Circle(i_player_position_pu, j_player_position_pu, player_radius_pu), player_color)

    return nothing
end
