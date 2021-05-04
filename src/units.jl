# conversion single coordinate

wu_to_pu(x_wu::AbstractFloat, pu_per_wu) = floor(Int, x_wu * pu_per_wu) + 1
wu_to_tu(x_wu::AbstractFloat, wu_per_tu) = floor(Int, x_wu / wu_per_tu) + 1
pu_to_tu(i_pu::Integer, pu_per_tu) = (i_pu - 1) ÷ pu_per_tu + 1

# others

wu_to_pu((x_wu, y_wu), pu_per_wu, height_world_wu) = (wu_to_pu(height_world_wu - y_wu, pu_per_wu), wu_to_pu(x_wu, pu_per_wu))
wu_to_tu((x_wu, y_wu), wu_per_tu, height_world_wu) = (wu_to_tu(height_world_wu - y_wu, wu_per_tu), wu_to_tu(x_wu, wu_per_tu))

get_tile_start_pu(i_tu, pu_per_tu) = (i_tu - 1) * pu_per_tu + 1
get_tile_stop_pu(i_tu, pu_per_tu) = i_tu * pu_per_tu
