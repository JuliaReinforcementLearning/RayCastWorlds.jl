import RayCastWorlds as RCW
import Random
import ReinforcementLearningBase as RLBase
import Test

const MAX_STEPS = 5000
const NUM_RESETS = 5

get_terminal_returns(env::RCW.RLBaseEnv{E}) where {E <: RCW.SingleRoomModule.SingleRoom} = (env.env.world.goal_reward,)

ENVS = [
        RCW.SingleRoomModule.SingleRoom
       ]

Test.@testset "RayCastWorlds.jl" begin
    for Env in ENVS
        Test.@testset "$(Env)" begin
            R = Float32
            env = RCW.RLBaseEnv(Env(R = R))
            for _ in 1:NUM_RESETS
                RLBase.reset!(env)
                Test.@test RLBase.reward(env) == zero(R)
                Test.@test RLBase.is_terminated(env) == false

                total_reward = zero(R)
                for i in 1:MAX_STEPS
                    state = RLBase.state(env)
                    action = rand(RLBase.action_space(env))
                    env(action)
                    total_reward += RLBase.reward(env)

                    if RLBase.is_terminated(env)
                        Test.@test total_reward in get_terminal_returns(env)
                        break
                    end

                    if i == MAX_STEPS
                        @info "$Env not terminated after MAX_STEPS = $MAX_STEPS"
                    end
                end
            end
        end
    end
end
