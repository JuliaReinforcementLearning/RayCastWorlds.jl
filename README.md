# RayCastWorlds

**Important:** This package is not registered yet. It is a work in progress.

This package provides simple raycasted games.

Right now only one game is provided called `SingleRoom`.

## Notes

#### RayCaster

The core raycasting algorithm is implemented in the [`RayCaster`](https://github.com/Sid-Bhatia-0/RayCaster.jl) package.

#### Units

There are 4 types of units:
1. 'wu': Stands for world units. These are usually floating point numbers representing positions in the real world.
1. 'tu': Stands for tile units. These are integers representing positions on the tile map.
1. 'pu': Stands for pixel units. These are integers representing positions on the visualization image.
1. 'au': Stands for angle units. These are integers representing angles from 0 to `num_directions`.

The height of the tile map correponds to the x-axis of the coordinate system (indexed with `i` in the code base) and width correponds to the y-axis (indexed with `j` in the code base) . This is to keep the coordinate system right handed.

#### Play

Here is how you start the game:

julia'''
import RayCastWorlds as RCW

env = RCW.SingleRoomModule.SingleRoom()

RCW.play!(env)
'''

Here are the keybindings:
1. `q`: quit
1. `r`: reset
1. `w`: move forward
1. `s`: move backward
1. `a`: turn left
1. `d`: turn right
1. `v`: toggle top view and camera view
