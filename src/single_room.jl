mutable struct SingleRoom{T, R} <: RLBase.AbstractEnv
    tile_map::GW.GridWorldBase{Tuple{GW.Wall, GW.Goal}}
    top_view::Array{UInt32, 2}
    agent_view::Array{UInt32, 2}
    agent_pos::SA.SVector{2, T}
    agent_dir::SA.SVector{2, T}
    agent_radius_wu::T
    agent_radius_pu::Int
    wu_per_tu::T
    pu_per_tu::Int
    pu_per_wu::T
    num_rays::Int
    semi_fov::T
    position_increment::T
    direction_increment::SA.SVector{2, T}
    direction_decrement::SA.SVector{2, T}
    height_world_wu::T
    width_world_wu::T
    tile_half_side_wu::T
    goal_pos::CartesianIndex{2}
    reward::T
    terminal_reward::T
    done::Bool
    rng::R
end

@generate_getters(SingleRoom)
@generate_setters(SingleRoom)

function SingleRoom(;
        tile_map_layout = [1 1 1 1 1 1 1 1
                           1 0 0 0 0 0 0 1
                           1 0 0 0 0 0 0 1
                           1 0 0 0 0 0 0 1
                           1 0 0 0 0 0 2 1
                           1 0 0 0 0 0 0 1
                           1 0 0 0 0 0 0 1
                           1 1 1 1 1 1 1 1
                          ],
        T = Float32,
        wu_per_tu = convert(T, 1),
        pu_per_tu = 32,
        agent_pos = SA.SVector(convert(T, 1.5), convert(T, 2.5)),
        agent_dir = SA.SVector(cos(convert(T, pi / 6)), sin(convert(T, pi / 6))),
        agent_radius_wu = convert(T, 0.25),
        num_rays = 64,
        semi_fov = convert(T, pi / 6),
        position_increment = convert(T, 0.1),
        theta_increment = convert(T, pi / 60),
        rng = Random.GLOBAL_RNG,
    )

    height_tm_tu = size(tile_map_layout, 1)
    width_tm_tu = size(tile_map_layout, 2)

    objects = (GW.WALL, GW.GOAL)
    tile_map = GW.GridWorldBase(objects, height_tm_tu, width_tm_tu)
    goal_pos = CartesianIndex(height_tm_tu - 1, width_tm_tu - 1)

    for pos in keys(tile_map_layout)
        if tile_map_layout[pos] == 1
            tile_map[GW.WALL, pos] = true
        elseif tile_map_layout[pos] == 2
            goal_pos = pos
            tile_map[GW.GOAL, pos] = true
        end
    end

    tile_map[GW.GOAL, goal_pos] = true

    height_world_wu = convert(T, height_tm_tu * wu_per_tu)
    width_world_wu = convert(T, width_tm_tu * wu_per_tu)

    tile_half_side_wu = wu_per_tu / 2

    height_tv_pu = pu_per_tu * height_tm_tu
    width_tv_pu = pu_per_tu * width_tm_tu

    height_av_pu = num_rays
    width_av_pu = num_rays

    top_view = zeros(UInt32, height_tv_pu, width_tv_pu)
    agent_view = zeros(UInt32, height_av_pu, width_av_pu)

    pu_per_wu = pu_per_tu / wu_per_tu
    agent_radius_pu = wu_to_pu(agent_radius_wu, pu_per_wu)
    direction_increment = SA.SVector(cos(theta_increment), sin(theta_increment))
    direction_decrement = SA.SVector(direction_increment[1], -direction_increment[2])

    reward = zero(T)
    terminal_reward = one(T)
    done = false

    draw_tv!(top_view, tile_map, agent_pos, agent_dir, semi_fov, num_rays, wu_per_tu, pu_per_tu, pu_per_wu, height_world_wu, agent_radius_pu)
    draw_av!(agent_view, tile_map, agent_pos, agent_dir, semi_fov, num_rays, wu_per_tu)

    env = SingleRoom(tile_map, top_view, agent_view, agent_pos, agent_dir, agent_radius_wu, agent_radius_pu, wu_per_tu, pu_per_tu, pu_per_wu, num_rays, semi_fov, position_increment, direction_increment, direction_decrement, height_world_wu, width_world_wu, tile_half_side_wu, goal_pos, reward, terminal_reward, done, rng)

    RLBase.reset!(env)

    return env
end

RLBase.state_space(env::SingleRoom, ::RLBase.Observation, ::RLBase.DefaultPlayer) = nothing
RLBase.state(env::SingleRoom, ::RLBase.Observation, ::RLBase.DefaultPlayer) = copy(env.agent_view)
RLBase.action_space(env::SingleRoom, ::RLBase.DefaultPlayer) = (GW.DIRECTED_NAVIGATION_ACTIONS..., MOVE_BACKWARD)
RLBase.reward(env::SingleRoom, ::RLBase.DefaultPlayer) = get_reward(env)
RLBase.is_terminated(env::SingleRoom) = get_done(env)

RLBase.reset!(env::SingleRoom) = env

struct MoveBackward <: GW.AbstractMoveAction end
const MOVE_BACKWARD = MoveBackward()

get_position_change(env::SingleRoom, ::GW.MoveForward) = env.position_increment
get_position_change(env::SingleRoom, ::MoveBackward) = -env.position_increment

function (env::SingleRoom{T})(action::GW.AbstractMoveAction) where {T}
    tile_map = get_tile_map(env)

    new_agent_pos = env.agent_pos + get_position_change(env, action) * env.agent_dir

    if is_agent_colliding(tile_map, new_agent_pos, env.wu_per_tu, env.tile_half_side_wu, env.agent_radius_wu, env.height_world_wu, GW.GOAL)
        set_done!(env, true)
        set_reward!(env, get_terminal_reward(env))
        @info "reward = $(RLBase.reward(env))"
    elseif is_agent_colliding(tile_map, new_agent_pos, env.wu_per_tu, env.tile_half_side_wu, env.agent_radius_wu, env.height_world_wu, GW.WALL)
        set_done!(env, false)
        set_reward!(env, zero(T))
    else
        env.agent_pos = new_agent_pos
        set_done!(env, false)
        set_reward!(env, zero(T))
    end

    draw_tv!(env.top_view, tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu, env.pu_per_tu, env.pu_per_wu, env.height_world_wu, env.agent_radius_pu)
    draw_av!(env.agent_view, tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu)

    return nothing
end

get_direction_change(env::SingleRoom, ::GW.TurnLeft) = env.direction_increment
get_direction_change(env::SingleRoom, ::GW.TurnRight) = env.direction_decrement

function (env::SingleRoom{T})(action::GW.AbstractTurnAction) where {T}
    new_agent_dir = rotate(env.agent_dir, get_direction_change(env, action))
    env.agent_dir = new_agent_dir

    set_done!(env, false)
    set_reward!(env, zero(T))

    draw_tv!(env.top_view, env.tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu, env.pu_per_tu, env.pu_per_wu, env.height_world_wu, env.agent_radius_pu)
    draw_av!(env.agent_view, env.tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu)

    return nothing
end

function get_combined_view(env)
    height_tv_pu = size(env.top_view, 1)
    width_tv_pu = size(env.top_view, 2)

    height_av_pu = size(env.agent_view, 1)
    width_av_pu = size(env.agent_view, 2)

    height_cv_pu = max(height_tv_pu, height_av_pu)
    width_cv_pu = width_tv_pu + width_av_pu

    combined_view = zeros(UInt32, height_cv_pu, width_cv_pu)
    combined_view[1:height_tv_pu, 1:width_tv_pu] = env.top_view
    combined_view[1:height_av_pu, width_tv_pu + 1 : width_cv_pu] = env.agent_view

    return combined_view
end
