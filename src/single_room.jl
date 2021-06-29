module SingleRoomModule

import RayCaster as RC
import ..RayCastWorlds as RCW
import StaticArrays as SA

const NUM_OBJECTS = 1
const WALL = 1

const NUM_ACTIONS = 4
const MOVE_FORWARD = 1
const MOVE_BACKWARD = 2
const TURN_LEFT = 3
const TURN_RIGHT = 4

mutable struct SingleRoom{T}
    tile_map::BitArray{3}
    num_directions::Int
    player_position_wu::SA.MVector{2, T}
    player_direction_au::Int
    player_radius_wu::T
    position_increment_wu::T
    field_of_view_au::Int
    directions_wu::Array{T, 2}
    ray_stop_position_tu::Array{Int, 2}
    ray_hit_dimension::Array{Int, 1}
    ray_distance_wu::Array{T, 1}
end

function SingleRoom(;
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 128, # angles go from 0 to num_directions - 1 (0 corresponding to positive x-axes)
        field_of_view_au = isodd(num_directions ÷ 6) ? num_directions ÷ 6 : (num_directions ÷ 6) + 1 ,
        player_position_wu = SA.MVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 8,
        player_radius_wu = convert(T, 1 / 8), # should be less than 0.5
        position_increment_wu = convert(T, 1 / 8),
    )

    tile_map = falses(NUM_OBJECTS, height_tile_map_tu, width_tile_map_tu)

    tile_map[WALL, :, 1] .= true
    tile_map[WALL, :, width_tile_map_tu] .= true
    tile_map[WALL, 1, :] .= true
    tile_map[WALL, height_tile_map_tu, :] .= true

    directions_wu = Array{T}(undef, 2, num_directions)
    for i in 1:num_directions
        theta = (i - 1) * 2 * pi / num_directions
        directions_wu[1, i] = convert(T, cos(theta))
        directions_wu[2, i] = convert(T, sin(theta))
    end

    ray_stop_position_tu = Array{Int}(undef, 2, field_of_view_au)
    ray_hit_dimension = Array{Int}(undef, field_of_view_au)
    ray_distance_wu = Array{T}(undef, field_of_view_au)

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
                      )

    return world
end

function act!(world::SingleRoom, action::Integer)
    if action == MOVE_FORWARD
        player_direction_wu = @view world.directions_wu[:, world.player_direction_au + 1]
        new_player_position_wu = world.player_position_wu + world.position_increment_wu * player_direction_wu
        obstacle_map = @view world.tile_map[WALL, :, :]
        if !RCW.is_player_colliding(obstacle_map, new_player_position_wu, world.player_radius_wu)
            world.player_position_wu .= new_player_position_wu
        end
    elseif action == MOVE_BACKWARD
        player_direction_wu = @view world.directions_wu[:, world.player_direction_au + 1]
        new_player_position_wu = world.player_position_wu - world.position_increment_wu * player_direction_wu
        obstacle_map = @view world.tile_map[WALL, :, :]
        if !RCW.is_player_colliding(obstacle_map, new_player_position_wu, world.player_radius_wu)
            world.player_position_wu .= new_player_position_wu
        end
    elseif action == TURN_LEFT
        world.player_direction_au = mod(world.player_direction_au + 1, world.num_directions)
    elseif action == TURN_RIGHT
        world.player_direction_au = mod(world.player_direction_au - 1, world.num_directions)
    end

    return nothing
end

function cast_rays!(world::SingleRoom)
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
    obstacle_map = @view tile_map[WALL, :, :]
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
