turn_left(direction_au, num_directions, direction_increment_au) = mod(direction_au + direction_increment_au, num_directions)
turn_right(direction_au, num_directions, direction_increment_au) = mod(direction_au - direction_increment_au, num_directions)

move_forward(position_wu, direction_wu, position_increment_wu) = position_wu + position_increment_wu * direction_wu
move_backward(position_wu, direction_wu, position_increment_wu) = position_wu - position_increment_wu * direction_wu
