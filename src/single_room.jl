module SingleRoomModule

import Random
import RayCaster as RC
import ..RayCastWorlds as RCW
import StaticArrays as SA

import MiniFB as MFB
import SimpleDraw as SD

const NUM_OBJECTS = 2
const WALL = 1
const GOAL = 2
const NUM_ACTIONS = 4

const NUM_VIEWS = 2
const CAMERA_VIEW = 1
const TOP_VIEW = 2

mutable struct SingleRoomWorld{T, RNG, R}
    tile_map::BitArray{3}
    num_directions::Int
    player_position_wu::SA.SVector{2, T}
    player_direction_au::Int
    player_radius_wu::T
    position_increment_wu::T
    direction_increment_au::Int
    field_of_view_au::Int
    directions_wu::Array{T, 2}
    ray_stop_position_tu::Array{Int, 2}
    ray_hit_dimension::Array{Int, 1}
    ray_distance_wu::Array{T, 1}
    goal_position::CartesianIndex{2}
    rng::RNG
    reward::R
    goal_reward::R
    done::Bool
end

function SingleRoomWorld(;
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 128, # angles go from 0 to num_directions - 1 (0 corresponding to positive x-axes)
        field_of_view_au = isodd(num_directions ÷ 6) ? num_directions ÷ 6 : (num_directions ÷ 6) + 1 ,
        player_position_wu = SA.SVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 8,
        player_radius_wu = convert(T, 1 / 8), # should be less than 0.5
        position_increment_wu = convert(T, 1 / 8),
        direction_increment_au = 2,
        rng = Random.GLOBAL_RNG,
        R = Float32,
    )

    tile_map = falses(NUM_OBJECTS, height_tile_map_tu, width_tile_map_tu)

    tile_map[WALL, :, 1] .= true
    tile_map[WALL, :, width_tile_map_tu] .= true
    tile_map[WALL, 1, :] .= true
    tile_map[WALL, height_tile_map_tu, :] .= true

    goal_position = CartesianIndex(rand(rng, 2 : height_tile_map_tu - 1), rand(rng, 2 : width_tile_map_tu - 1))
    tile_map[GOAL, goal_position] = true

    directions_wu = Array{T}(undef, 2, num_directions)
    for i in 1:num_directions
        theta = (i - 1) * 2 * pi / num_directions
        directions_wu[1, i] = convert(T, cos(theta))
        directions_wu[2, i] = convert(T, sin(theta))
    end

    ray_stop_position_tu = Array{Int}(undef, 2, field_of_view_au)
    ray_hit_dimension = Array{Int}(undef, field_of_view_au)
    ray_distance_wu = Array{T}(undef, field_of_view_au)

    reward = zero(R)
    goal_reward = one(R)
    done = false

    world = SingleRoomWorld(tile_map,
                       num_directions,
                       player_position_wu,
                       player_direction_au,
                       player_radius_wu,
                       position_increment_wu,
                       direction_increment_au,
                       field_of_view_au,
                       directions_wu,
                       ray_stop_position_tu,
                       ray_hit_dimension,
                       ray_distance_wu,
                       goal_position,
                       rng,
                       reward,
                       goal_reward,
                       done,
                      )

    RCW.reset!(world)

    return world
end

function RCW.reset!(world::SingleRoomWorld{T}) where {T}
    tile_map = world.tile_map
    rng = world.rng
    player_radius_wu = world.player_radius_wu
    goal_position = world.goal_position
    num_directions = world.num_directions
    _, height_tile_map_tu, width_tile_map_tu = size(tile_map)

    tile_map[GOAL, goal_position] = false

    new_goal_position = CartesianIndex(rand(rng, 2 : height_tile_map_tu - 1), rand(rng, 2 : width_tile_map_tu - 1))
    world.goal_position = new_goal_position
    tile_map[GOAL, goal_position] = true

    new_player_position_wu = SA.SVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2))
    player_direction_au = num_directions ÷ 8

    world.reward = zero(world.reward)
    done = false

    return nothing
end

function RCW.act!(world::SingleRoomWorld, action)
    @assert action in Base.OneTo(4) "Invalid action: $(action)"

    tile_map = world.tile_map
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    player_radius_wu = world.player_radius_wu
    goal_map = @view tile_map[GOAL, :, :]

    if action in Base.OneTo(2)
        directions_wu = world.directions_wu
        position_increment_wu = world.position_increment_wu
        player_direction_wu = @view directions_wu[:, player_direction_au + 1]
        wall_map = @view tile_map[WALL, :, :]

        if action == 1
            new_player_position_wu = RCW.move_forward(player_position_wu, player_direction_wu, position_increment_wu)
        else
            new_player_position_wu = RCW.move_backward(player_position_wu, player_direction_wu, position_increment_wu)
        end

        is_colliding_with_goal = RCW.is_player_colliding(goal_map, new_player_position_wu, player_radius_wu)
        is_colliding_with_wall = RCW.is_player_colliding(wall_map, new_player_position_wu, player_radius_wu)

        if is_colliding_with_goal || is_colliding_with_wall
            if is_colliding_with_goal
                world.reward = world.goal_reward
                world.done = true
            else
                world.reward = zero(world.reward)
                world.done = false
            end
        else
            world.player_position_wu = new_player_position_wu
            world.reward = zero(world.reward)
            world.done = false
        end
    else
        num_directions = world.num_directions
        direction_increment_au = world.direction_increment_au
        if action == 3
            world.player_direction_au = RCW.turn_left(player_direction_au, num_directions, direction_increment_au)
        else
            world.player_direction_au = RCW.turn_right(player_direction_au, num_directions, direction_increment_au)
        end

        is_colliding_with_goal = RCW.is_player_colliding(goal_map, player_position_wu, player_radius_wu)
        if is_colliding_with_goal
            world.reward = world.goal_reward
            world.done = true
        else
            world.reward = zero(world.reward)
            world.done = false
        end
    end

    return nothing
end

function RCW.cast_rays!(world::SingleRoomWorld)
    tile_map = world.tile_map
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    field_of_view_au = world.field_of_view_au
    directions_wu = world.directions_wu
    num_directions = world.num_directions
    ray_stop_position_tu = world.ray_stop_position_tu
    ray_hit_dimension = world.ray_hit_dimension
    ray_distance_wu = world.ray_distance_wu

    height_tile_map_tu, width_tile_map_tu = size(tile_map, 2), size(tile_map, 3)
    obstacle_map = @view any(tile_map, dims = 1)[1, :, :]
    player_direction_wu = @view directions_wu[:, player_direction_au + 1]
    field_of_view_start_au = player_direction_au - (field_of_view_au - 1) ÷ 2
    field_of_view_end_au = player_direction_au + (field_of_view_au - 1) ÷ 2

    for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        direction_idx = mod(theta_au, num_directions) + 1
        ray_direction_wu = @view directions_wu[:, direction_idx]
        i_hit_tu, j_hit_tu, hit_dimension, side_dist_wu = RC.cast_ray(obstacle_map, player_position_wu..., ray_direction_wu...)
        ray_stop_position_tu[1, i] = i_hit_tu
        ray_stop_position_tu[2, i] = j_hit_tu
        ray_hit_dimension[i] = hit_dimension
        ray_distance_wu[i] = side_dist_wu
    end

    return nothing
end

#####
##### Drawing & Playing
#####

struct SingleRoom{T, C}
    world::SingleRoomWorld{T}
    top_view::Array{C, 2}
    camera_view::Array{C, 2}
    tile_map_colors::NTuple{NUM_OBJECTS + 1, C}
    ray_color::C
    player_color::C
    floor_color::C
    ceiling_color::C
    wall_dim_1_color::C
    wall_dim_2_color::C
end

function SingleRoom(;
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 512,
        field_of_view_au = isodd(num_directions ÷ 6) ? num_directions ÷ 6 : (num_directions ÷ 6) + 1 ,
        player_position_wu = SA.SVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 8,
        player_radius_wu = convert(T, 1 / 8),
        position_increment_wu = convert(T, 1 / 8),
        direction_increment_au = 2,
        rng = Random.GLOBAL_RNG,
        R = Float32,
        pu_per_tu = 32,
    )

    @assert isodd(field_of_view_au)

    C = UInt32

    world = SingleRoomWorld(T = T,
                           height_tile_map_tu = height_tile_map_tu,
                           width_tile_map_tu = width_tile_map_tu,
                           num_directions = num_directions,
                           field_of_view_au = field_of_view_au,
                           player_position_wu = player_position_wu,
                           player_direction_au = player_direction_au,
                           player_radius_wu = player_radius_wu,
                           position_increment_wu = position_increment_wu,
                           direction_increment_au = direction_increment_au,
                           rng = rng,
                           R = R,
                          )

    tile_map_colors = (0x00FFFFFF, 0x00404040, 0x00000000)
    ray_color = 0x00808080
    player_color = 0x00c0c0c0
    floor_color = 0x00404040
    ceiling_color = 0x00FFFFFF
    wall_dim_1_color = 0x00808080
    wall_dim_2_color = 0x00c0c0c0

    RCW.cast_rays!(world)

    camera_view = Array{C}(undef, field_of_view_au, field_of_view_au)

    top_view = Array{C}(undef, height_tile_map_tu * pu_per_tu, width_tile_map_tu * pu_per_tu)

    env = SingleRoom(world,
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

    RCW.update_camera_view!(env)
    RCW.update_top_view!(env)
    return env
end

function draw_tile_map!(top_view, tile_map, colors)
    _, height_tile_map_tu, width_tile_map_tu = size(tile_map)
    height_top_view_pu = size(top_view, 1)

    pu_per_tu = height_top_view_pu ÷ height_tile_map_tu

    for j in 1:width_tile_map_tu
        for i in 1:height_tile_map_tu
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

function RCW.update_camera_view!(env::SingleRoom)
    world = env.world
    camera_view = env.camera_view
    floor_color = env.floor_color
    ceiling_color = env.ceiling_color
    wall_dim_1_color = env.wall_dim_1_color
    wall_dim_2_color = env.wall_dim_2_color

    tile_map = world.tile_map
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    field_of_view_au = world.field_of_view_au
    num_directions = world.num_directions
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    ray_stop_position_tu = world.ray_stop_position_tu
    ray_hit_dimension = world.ray_hit_dimension
    ray_distance_wu = world.ray_distance_wu
    directions_wu = world.directions_wu

    height_tile_map_tu, width_tile_map_tu = size(tile_map, 2), size(tile_map, 3)
    height_camera_view_pu, width_camera_view_pu = size(camera_view)

    player_direction_wu = @view directions_wu[:, player_direction_au + 1]
    field_of_view_start_au = player_direction_au - (field_of_view_au - 1) ÷ 2
    field_of_view_end_au = player_direction_au + (field_of_view_au - 1) ÷ 2

    for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        direction_idx = mod(theta_au, num_directions) + 1
        ray_direction_wu = @view directions_wu[:, direction_idx]

        projected_distance_wu = ray_distance_wu[i] * sum(player_direction_wu .* ray_direction_wu)
        height_line = height_camera_view_pu / projected_distance_wu
        if isfinite(height_line)
            height_line_pu = floor(Int, height_line)
        else
            height_line_pu = height_camera_view_pu
        end

        hit_dimension = ray_hit_dimension[i]

        if hit_dimension == 1
            color = wall_dim_1_color
        elseif hit_dimension == 2
            color = wall_dim_2_color
        end

        k = width_camera_view_pu - i + 1

        if height_line_pu >= height_camera_view_pu - 1
            camera_view[:, k] .= color
        else
            padding_pu = (height_camera_view_pu - height_line_pu) ÷ 2
            camera_view[1:padding_pu, k] .= ceiling_color
            camera_view[padding_pu + 1 : end - padding_pu, k] .= color
            camera_view[end - padding_pu + 1 : end, k] .= floor_color
        end
    end

    return nothing
end

function RCW.update_top_view!(env::SingleRoom)
    world = env.world
    top_view = env.top_view
    tile_map_colors = env.tile_map_colors
    ray_color = env.ray_color
    player_color = env.player_color
    tile_map = world.tile_map
    player_direction_au = world.player_direction_au
    player_position_wu = world.player_position_wu
    field_of_view_au = world.field_of_view_au
    num_directions = world.num_directions
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

    i_player_position_pu, j_player_position_pu = RCW.wu_to_pu.(player_position_wu, pu_per_tu)
    player_radius_pu = RCW.wu_to_pu(player_radius_wu, pu_per_tu)
    field_of_view_start_au = player_direction_au - (field_of_view_au - 1) ÷ 2
    field_of_view_end_au = player_direction_au + (field_of_view_au - 1) ÷ 2

    draw_tile_map!(top_view, tile_map, tile_map_colors)

    for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        idx = mod(theta_au, num_directions) + 1
        ray_direction_wu = @view directions_wu[:, idx]

        i_ray_stop_pu, j_ray_stop_pu = RCW.wu_to_pu.(player_position_wu + ray_distance_wu[i] * ray_direction_wu, pu_per_tu)

        SD.draw!(top_view, SD.Line(i_player_position_pu, j_player_position_pu, i_ray_stop_pu, j_ray_stop_pu), ray_color)
    end

    SD.draw!(top_view, SD.Circle(i_player_position_pu, j_player_position_pu, player_radius_pu), player_color)

    return nothing
end

RCW.get_action_keys(env::SingleRoom) = (MFB.KB_KEY_W, MFB.KB_KEY_S, MFB.KB_KEY_A, MFB.KB_KEY_D)
RCW.get_action_names(env::SingleRoom) = (:MOVE_FORWARD, :MOVE_BACKWARD, :TURN_LEFT, :TURN_RIGHT)

function RCW.play!(game::SingleRoom)
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

    action_keys = RCW.get_action_keys(game)

    current_view = CAMERA_VIEW
    if current_view == CAMERA_VIEW
        RCW.copy_image_to_frame_buffer!(frame_buffer, camera_view)
    elseif current_view == TOP_VIEW
        RCW.copy_image_to_frame_buffer!(frame_buffer, top_view)
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
                RCW.act!(world, findfirst(==(key), action_keys))
                RCW.cast_rays!(world)
                RCW.update_top_view!(game)
                RCW.update_camera_view!(game)
            end

            if current_view == CAMERA_VIEW
                RCW.copy_image_to_frame_buffer!(frame_buffer, camera_view)
            elseif current_view == TOP_VIEW
                RCW.copy_image_to_frame_buffer!(frame_buffer, top_view)
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
