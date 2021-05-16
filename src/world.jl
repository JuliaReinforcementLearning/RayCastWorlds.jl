function is_agent_colliding(tm, center_wu, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu)
    height_tm_tu = size(tm, 2)
    square = StdSquare(tile_half_side_wu)
    circle = StdCircle(radius_wu)
    return any(pos -> (tm[GW.WALL, pos] || tm[GW.GOAL, pos]) && is_colliding(square, circle, center_wu .- get_tile_center_wu(pos.I, wu_per_tu, height_tm_tu, tile_half_side_wu)), get_agent_region_tu(center_wu, radius_wu, wu_per_tu, height_world_wu))
end

function is_agent_colliding(tm, center_wu, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu, object)
    height_tm_tu = size(tm, 2)
    square = StdSquare(tile_half_side_wu)
    circle = StdCircle(radius_wu)
    return any(pos -> tm[object, pos] && is_colliding(square, circle, center_wu .- get_tile_center_wu(pos.I, wu_per_tu, height_tm_tu, tile_half_side_wu)), get_agent_region_tu(center_wu, radius_wu, wu_per_tu, height_world_wu))
end
