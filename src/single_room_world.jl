module SingleRoomModule

import Random
import RayCaster as RC
import ..RayCastWorlds as RCW
import StaticArrays as SA

const NUM_OBJECTS = 2
const WALL = 1
const GOAL = 2
const NUM_ACTIONS = 4

mutable struct SingleRoom{T, RNG, R}
    tile_map::BitArray{3}
    num_directions::Int
    player_position_wu::SA.SVector{2, T}
    player_direction_au::Int
    player_radius_wu::T
    position_increment_wu::T
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

function SingleRoom(;
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 128, # angles go from 0 to num_directions - 1 (0 corresponding to positive x-axes)
        field_of_view_au = isodd(num_directions ÷ 6) ? num_directions ÷ 6 : (num_directions ÷ 6) + 1 ,
        player_position_wu = SA.SVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 8,
        player_radius_wu = convert(T, 1 / 8), # should be less than 0.5
        position_increment_wu = convert(T, 1 / 8),
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

    world = SingleRoom(tile_map,
                       num_directions,
                       player_position_wu,
                       player_direction_au,
                       player_radius_wu,
                       position_increment_wu,
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

function RCW.reset!(world::SingleRoom{T}) where {T}
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

function RCW.act!(world::SingleRoom, action)
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

        if !is_colliding_with_wall
            if is_colliding_with_goal
                world.reward = world.goal_reward
                world.done = true
            else
                world.reward = zero(world.reward)
                world.done = false
            end

            world.player_position_wu = new_player_position_wu
        end
    else
        num_directions = world.num_directions
        if action == 3
            world.player_direction_au = RCW.turn_left(player_direction_au, num_directions)
        else
            world.player_direction_au = RCW.turn_right(player_direction_au, num_directions)
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

function RCW.cast_rays!(world::SingleRoom)
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

end # module
