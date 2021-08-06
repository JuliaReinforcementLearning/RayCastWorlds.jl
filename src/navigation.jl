turn_left(direction_au, num_directions) = mod(direction_au + 1, num_directions)
turn_right(direction_au, num_directions) = mod(direction_au - 1, num_directions)

move_forward(position_wu, direction_wu, position_increment_wu) = position_wu + position_increment_wu * direction_wu
move_backward(position_wu, direction_wu, position_increment_wu) = position_wu - position_increment_wu * direction_wu
