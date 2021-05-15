import RayCaster as RC
import ColorTypes as CT

import ReinforcementLearningBase as RLBase

import StableRNGs
import Dates
import Random
import FileIO
import ImageMagick
import FixedPointNumbers

get_img(env::RC.SingleRoom) = reinterpret.(CT.RGB24, RC.get_combined_view(env))

function display(env::RC.SingleRoom)
    img = get_img(env)
    IV.imshow(img)
    return nothing
end

function simulate_random_policy()
    seed = 123
    max_steps = 240
    rng = StableRNGs.StableRNG(seed)

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

    FileIO.save("animation.gif", reinterpret.(CT.RGB24, gif), fps = 12)

    return env
end
