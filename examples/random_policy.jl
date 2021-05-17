import ColorTypes as CT
import Dates
import FileIO
import ImageMagick
import Random
import RayCastWorlds as RCW
import ReinforcementLearningBase as RLBase

get_image(env::RCW.SingleRoom) = reinterpret.(CT.RGB24, RCW.get_combined_view(env))

function display(env::RCW.SingleRoom)
    image = get_image(env)
    IV.imshow(image)
    return nothing
end

function simulate_random_policy()
    seed = 123
    max_steps = 240
    rng = Random.MersenneTwister(seed)

    env = RCW.SingleRoom(rng = rng)

    gif = zeros(UInt32, size(RCW.get_combined_view(env))..., max_steps)
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
        gif[:, :, i] .= RCW.get_combined_view(env)
    end

    file_name = joinpath("output/random_policy", Dates.format(Dates.now(), "yyyy_mm_dd_HH_MM_SS")) * ".gif"
    FileIO.save(file_name, reinterpret.(CT.RGB24, gif), fps = 24)

    return env
end

env = simulate_random_policy();
