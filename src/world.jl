function is_agent_colliding(tile_map, position_wu, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu)
    height_tile_map_tu = GW.get_height(tile_map)
    square = StdSquare(tile_half_side_wu)
    circle = StdCircle(radius_wu)
    return any(pos -> (tile_map[GW.WALL, pos] || tile_map[GW.GOAL, pos]) && is_colliding(square, circle, position_wu .- get_tile_center_wu(pos.I, wu_per_tu, height_tile_map_tu, tile_half_side_wu)), get_agent_region_tu(position_wu, radius_wu, wu_per_tu, height_world_wu))
end

function is_agent_colliding(tile_map, position_wu, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu, object)
    height_tile_map_tu = GW.get_height(tile_map)
    square = StdSquare(tile_half_side_wu)
    circle = StdCircle(radius_wu)
    return any(pos -> tile_map[object, pos] && is_colliding(square, circle, position_wu .- get_tile_center_wu(pos.I, wu_per_tu, height_tile_map_tu, tile_half_side_wu)), get_agent_region_tu(position_wu, radius_wu, wu_per_tu, height_world_wu))
end
