import ColorTypes as CT
import Dates
import FileIO
import ImageMagick
import Random
import RayCaster as RC
import ReinforcementLearningBase as RLBase

get_image(env::RC.SingleRoom) = reinterpret.(CT.RGB24, RC.get_combined_view(env))

function display(env::RC.SingleRoom)
    image = get_image(env)
    IV.imshow(image)
    return nothing
end

function simulate_random_policy()
    seed = 123
    max_steps = 240
    rng = Random.MersenneTwister(seed)

    env = RC.SingleRoom(rng = rng)

    gif = zeros(UInt32, size(RC.get_combined_view(env))..., max_steps)
    RLBase.reset!(env)
    reward = RLBase.reward(env)

    T = typeof(reward)
    total_reward = zero(T)
    for i in 1:max_steps
        state = RLBase.state(env)
        action = rand(RLBase.action_space(env))
        env(action)
        reward = RLBase.reward(env)
        total_reward += RLBase.reward(env)
        gif[:, :, i] .= RC.get_combined_view(env)
    end

    file_name = joinpath("output/random_policy", Dates.format(Dates.now(), "yyyy_mm_dd_HH_MM_SS")) * ".gif"
    FileIO.save(file_name, reinterpret.(CT.RGB24, gif), fps = 24)

    return env
end

env = simulate_random_policy();
