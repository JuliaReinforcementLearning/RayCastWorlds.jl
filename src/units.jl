# conversion single coordinate

wu_to_pu(x_wu::AbstractFloat, pu_per_wu) = floor(Int, x_wu * pu_per_wu) + 1
wu_to_tu(x_wu::AbstractFloat, wu_per_tu) = floor(Int, x_wu / wu_per_tu) + 1
pu_to_tu(i_pu::Integer, pu_per_tu) = (i_pu - 1) ÷ pu_per_tu + 1

# others

wu_to_pu((x_wu, y_wu), pu_per_wu, height_world_wu) = (wu_to_pu(height_world_wu - y_wu, pu_per_wu), wu_to_pu(x_wu, pu_per_wu))
wu_to_tu((x_wu, y_wu), wu_per_tu, height_world_wu) = (wu_to_tu(height_world_wu - y_wu, wu_per_tu), wu_to_tu(x_wu, wu_per_tu))

get_tile_start_pu(i_tu, pu_per_tu) = (i_tu - 1) * pu_per_tu + 1
get_tile_stop_pu(i_tu, pu_per_tu) = i_tu * pu_per_tu

# tile region

get_tile_bottom_left_wu((i_tu, j_tu), wu_per_tu, height_tm_tu) = ((j_tu - 1) * wu_per_tu, (height_tm_tu - i_tu) * wu_per_tu)
get_tile_center_wu(tile_tu, wu_per_tu, height_tm_tu, tile_half_side_wu) = get_tile_bottom_left_wu(tile_tu, wu_per_tu, height_tm_tu) .+ tile_half_side_wu

# agent region

get_agent_center_pu(pos_wu, pu_per_wu, height_world_wu) = wu_to_pu(pos_wu, pu_per_wu, height_world_wu)

get_agent_bottom_left_tu(center_wu, radius_wu, wu_per_tu, height_world_wu) = wu_to_tu(center_wu .- radius_wu, wu_per_tu, height_world_wu)
get_agent_top_right_tu(center_wu, radius_wu, wu_per_tu, height_world_wu) = wu_to_tu(center_wu .+ radius_wu, wu_per_tu, height_world_wu)

function get_agent_region_tu(center_wu, radius_wu, wu_per_tu, height_world_wu)
    start_i, stop_j = get_agent_top_right_tu(center_wu, radius_wu, wu_per_tu, height_world_wu)
    stop_i, start_j = get_agent_bottom_left_tu(center_wu, radius_wu, wu_per_tu, height_world_wu)
    return CartesianIndices((start_i:stop_i, start_j:stop_j))
end
