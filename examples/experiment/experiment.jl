import RayCaster as RC
import GridWorlds as GW
import MiniFB as MFB
import RayCaster as RC
import StaticArrays as SA
import ImageView as IV
import ColorTypes as CT

import ReinforcementLearningBase as RLBase
import ReinforcementLearningCore as RLCore
import ReinforcementLearningEnvironments as RLEnvs
import ReinforcementLearningZoo as RLZoo

import TensorBoardLogger as TBL
import StableRNGs
import Logging
import Flux
import Dates
import Random

#####
# utils
#####

macro generate_getters(type)
    T = getfield(__module__, type)::Union{Type,DataType}
    defs = Expr(:block)
    for field in fieldnames(T)
        get = Symbol(:get_, field)
        qn = QuoteNode(field)
        push!(defs.args, :($(esc(get))(instance::$type) = getfield(instance, $qn)))
    end
    return defs
end

macro generate_setters(type)
    T = getfield(__module__, type)::Union{Type,DataType}
    defs = Expr(:block)
    for field in fieldnames(T)
        set = Symbol(:set_, field, :!)
        qn = QuoteNode(field)
        push!(defs.args, :($(esc(set))(instance::$type, x) = setfield!(instance, $qn, x)))
    end
    return defs
end

#####
# environment
#####

mutable struct RayCastWorld{T, R} <: RLBase.AbstractEnv
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

@generate_getters(RayCastWorld)
@generate_setters(RayCastWorld)

function RayCastWorld(;
        # tm_layout = [1 1 1 1 1 1 1 1
                     # 1 0 0 0 0 0 0 1
                     # 1 0 0 0 0 0 0 1
                     # 1 0 0 0 0 0 0 1
                     # 1 0 0 0 0 0 2 1
                     # 1 0 0 0 0 0 0 1
                     # 1 0 0 0 0 0 0 1
                     # 1 1 1 1 1 1 1 1
                    # ],
        tm_layout = [1 1 1 1
                     1 0 0 1
                     1 0 2 1
                     1 1 1 1
                    ],
        T = Float32,
        wu_per_tu = convert(T, 1),
        pu_per_tu = 32,
        agent_pos = SA.SVector(convert(T, 1.5), convert(T, 2.5)),
        agent_dir = SA.SVector(cos(convert(T, pi / 6)), sin(convert(T, pi / 6))),
        agent_radius_wu = convert(T, 0.25),
        num_rays = 128,
        semi_fov = convert(T, pi / 6),
        position_increment = convert(T, 0.1),
        theta_increment = convert(T, pi / 60),
        rng = Random.GLOBAL_RNG,
    )

    height_tm_tu = size(tm_layout, 1)
    width_tm_tu = size(tm_layout, 2)

    objects = (GW.WALL, GW.GOAL)
    tile_map = GW.GridWorldBase(objects, height_tm_tu, width_tm_tu)
    goal_pos = CartesianIndex(height_tm_tu - 1, width_tm_tu - 1)

    for pos in keys(tm_layout)
        if tm_layout[pos] == 1
            tile_map[GW.WALL, pos] = true
        elseif tm_layout[pos] == 2
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
    agent_radius_pu = RC.wu_to_pu(agent_radius_wu, pu_per_wu)
    direction_increment = SA.SVector(cos(theta_increment), sin(theta_increment))
    direction_decrement = SA.SVector(direction_increment[1], -direction_increment[2])

    reward = zero(T)
    terminal_reward = one(T)
    done = false

    RC.draw_tv!(top_view, tile_map, agent_pos, agent_dir, semi_fov, num_rays, wu_per_tu, pu_per_tu, pu_per_wu, height_world_wu, agent_radius_pu)
    RC.draw_av!(agent_view, tile_map, agent_pos, agent_dir, semi_fov, num_rays, wu_per_tu)

    env = RayCastWorld(tile_map, top_view, agent_view, agent_pos, agent_dir, agent_radius_wu, agent_radius_pu, wu_per_tu, pu_per_tu, pu_per_wu, num_rays, semi_fov, position_increment, direction_increment, direction_decrement, height_world_wu, width_world_wu, tile_half_side_wu, goal_pos, reward, terminal_reward, done, rng)

    RLBase.reset!(env)

    return env
end

RLBase.state_space(env::RayCastWorld, ::RLBase.Observation, ::RLBase.DefaultPlayer) = nothing
RLBase.state(env::RayCastWorld, ::RLBase.Observation, ::RLBase.DefaultPlayer) = copy(env.agent_view)
RLBase.action_space(env::RayCastWorld, ::RLBase.DefaultPlayer) = (GW.DIRECTED_NAVIGATION_ACTIONS..., MOVE_BACKWARD)
RLBase.reward(env::RayCastWorld, ::RLBase.DefaultPlayer) = get_reward(env)
RLBase.is_terminated(env::RayCastWorld) = get_done(env)

RLBase.reset!(env::RayCastWorld) = env

struct MoveBackward <: GW.AbstractMoveAction end
const MOVE_BACKWARD = MoveBackward()

get_position_change(env::RayCastWorld, ::GW.MoveForward) = env.position_increment
get_position_change(env::RayCastWorld, ::MoveBackward) = -env.position_increment

function (env::RayCastWorld{T})(action::GW.AbstractMoveAction) where {T}
    tile_map = get_tile_map(env)

    new_agent_pos = env.agent_pos + get_position_change(env, action) * env.agent_dir

    if RC.is_agent_colliding(tile_map, new_agent_pos, env.wu_per_tu, env.tile_half_side_wu, env.agent_radius_wu, env.height_world_wu, GW.GOAL)
        set_done!(env, true)
        set_reward!(env, get_terminal_reward(env))
    elseif RC.is_agent_colliding(tile_map, new_agent_pos, env.wu_per_tu, env.tile_half_side_wu, env.agent_radius_wu, env.height_world_wu, GW.WALL)
        set_done!(env, false)
        set_reward!(env, zero(T))
    else
        env.agent_pos = new_agent_pos
        set_done!(env, false)
        set_reward!(env, zero(T))
    end

    RC.draw_tv!(env.top_view, tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu, env.pu_per_tu, env.pu_per_wu, env.height_world_wu, env.agent_radius_pu)
    RC.draw_av!(env.agent_view, tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu)

    return nothing
end

get_direction_change(env::RayCastWorld, ::GW.TurnLeft) = env.direction_increment
get_direction_change(env::RayCastWorld, ::GW.TurnRight) = env.direction_decrement

function (env::RayCastWorld{T})(action::GW.AbstractTurnAction) where {T}
    new_agent_dir = RC.rotate(env.agent_dir, get_direction_change(env, action))
    env.agent_dir = new_agent_dir

    set_done!(env, false)
    set_reward!(env, zero(T))

    RC.draw_tv!(env.top_view, env.tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu, env.pu_per_tu, env.pu_per_wu, env.height_world_wu, env.agent_radius_pu)
    RC.draw_av!(env.agent_view, env.tile_map, env.agent_pos, env.agent_dir, env.semi_fov, env.num_rays, env.wu_per_tu)

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

function display(env::RayCastWorld)
    img = reinterpret.(CT.RGB24, get_combined_view(env))
    IV.imshow(img)
    return nothing
end

function RLCore.Experiment(
    ::Val{:JuliaRL},
    ::Val{:BasicDQN},
    ::Val{:RayCastWorld},
    ::Nothing;
    seed = 123,
    save_dir = nothing,
)
    if isnothing(save_dir)
        t = Dates.format(Dates.now(), "yyyy_mm_dd_HH_MM_SS")
        save_dir = joinpath(pwd(), "checkpoints", "JuliaRL_BasicDQN_RayCastWorld$(t)")
    end
    log_dir = joinpath(save_dir, "tb_log")
    lg = TBL.TBLogger(log_dir, min_level = Logging.Info)
    rng = StableRNGs.StableRNG(seed)

    inner_env = RayCastWorld(rng = rng)
    action_space_mapping = x -> Base.OneTo(length(RLBase.action_space(inner_env)))
    action_mapping = i -> RLBase.action_space(inner_env)[i]
    env = RLEnvs.ActionTransformedEnv(
        inner_env,
        action_space_mapping = action_space_mapping,
        action_mapping = action_mapping,
    )
    env = RLEnvs.StateOverriddenEnv(env, x -> vec(Float32.(x)))
    env = RLEnvs.RewardOverriddenEnv(env, x -> x - convert(typeof(x), 0.01))
    env = RLEnvs.MaxTimeoutEnv(env, 100)

    ns, na = length(RLBase.state(env)), length(RLBase.action_space(env))
    agent = RLCore.Agent(
        policy = RLCore.QBasedPolicy(
            learner = RLZoo.BasicDQNLearner(
                approximator = RLCore.NeuralNetworkApproximator(
                    model = Flux.Chain(
                        Flux.Dense(ns, 128, Flux.relu; initW = Flux.glorot_uniform(rng)),
                        # Flux.Dense(128, 128, relu; initW = Flux.glorot_uniform(rng)),
                        Flux.Dense(128, na; initW = Flux.glorot_uniform(rng)),
                    ) |> Flux.cpu,
                    optimizer = Flux.ADAM(),
                ),
                batch_size = 16,
                min_replay_history = 10,
                loss_func = Flux.Losses.huber_loss,
                rng = rng,
            ),
            explorer = RLCore.EpsilonGreedyExplorer(
                kind = :exp,
                ϵ_stable = 0.01,
                decay_steps = 500,
                rng = rng,
            ),
        ),
        trajectory = RLCore.CircularArraySARTTrajectory(
            capacity = 1000,
            state = Vector{Float32} => (ns,),
        ),
    )

    stop_condition = RLCore.StopAfterStep(1000)

    total_reward_per_episode = RLCore.TotalRewardPerEpisode()
    time_per_step = RLCore.TimePerStep()
    hook = RLCore.ComposedHook(
        total_reward_per_episode,
        time_per_step,
        RLCore.DoEveryNStep() do t, agent, env
            Logging.with_logger(lg) do
                @info "training" loss = agent.policy.learner.loss
                @info "training" reward = RLBase.reward(env)
            end
        end,
        RLCore.DoEveryNEpisode() do t, agent, env
            Logging.with_logger(lg) do
                @info "training" total_reward = total_reward_per_episode.rewards[end] log_step_increment = 0
            end
        end,
    )

    description = """
    This experiment uses three dense layers to approximate the Q value.
    The testing environment is EmptyRoom.
    You can view the runtime logs with `tensorboard --logdir $log_dir`.
    Some useful statistics are stored in the `hook` field of this experiment.
    """

    RLCore.Experiment(agent, env, stop_condition, hook, description)
end

experiment = RLCore.Experiment(Val{:JuliaRL}(), Val{:BasicDQN}(), Val{:RayCastWorld}(), nothing)
out = RLCore.run(experiment)
