import ColorTypes as CT
import Dates
import FileIO
import GridWorlds as GW
import ImageMagick
import MiniFB as MFB
import Random
import RayCaster as RC
import ReinforcementLearningBase as RLBase
import StaticArrays as SA

const T = Float32
const seed = 123
const rng = Random.MersenneTwister(seed)

const env = RC.SingleRoom(T = T, rng = rng)

step_number = 0

total_reward = zero(T)

const image_sequence = Vector{Matrix{UInt32}}()

function keyboard_callback(window, key, mod, isPressed)::Cvoid
    if isPressed
        println(key)

        if key == MFB.KB_KEY_UP
            action = GW.MOVE_FORWARD
        elseif key == MFB.KB_KEY_DOWN
            action = RC.MOVE_BACKWARD
        elseif key == MFB.KB_KEY_LEFT
            action = GW.TURN_LEFT
        elseif key == MFB.KB_KEY_RIGHT
            action = GW.TURN_RIGHT
        elseif key == MFB.KB_KEY_ESCAPE
            MFB.mfb_close(window)
            return nothing
        end

        global step_number += 1
        env(action)
        reward = RLBase.reward(env)
        global total_reward += reward
        is_terminated = RLBase.is_terminated(env)
        push!(image_sequence, RC.get_combined_view(env))

        println("step_number = $step_number")
        println("action = $action")
        println("reward = $reward")
        println("total_reward = $total_reward")
        println("is_terminated = $is_terminated")
        println("***********************************")
    end

    return nothing
end

function play(env::RC.SingleRoom)
    cv = RC.get_combined_view(env)
    push!(image_sequence, RC.get_combined_view(env))

    height_cv_pu, width_cv_pu = size(cv)
    fb_cv = zeros(UInt32, width_cv_pu, height_cv_pu)

    window = MFB.mfb_open("Combined View", width_cv_pu, height_cv_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    permutedims!(fb_cv, RC.get_combined_view(env), (2, 1))

    while MFB.mfb_wait_sync(window)
        permutedims!(fb_cv, RC.get_combined_view(env), (2, 1))

        state = MFB.mfb_update(window, fb_cv)

        if state != MFB.STATE_OK
            break;
        end
    end

    return nothing
end

play(env)

const gif = zeros(UInt32, size(RC.get_combined_view(env))..., length(image_sequence))

for (i, image) in enumerate(image_sequence)
    gif[:, :, i] .= image
end

file_name = joinpath("output/play", Dates.format(Dates.now(), "yyyy_mm_dd_HH_MM_SS")) * ".gif"
FileIO.save(file_name, reinterpret.(CT.RGB24, gif), fps = 24)
