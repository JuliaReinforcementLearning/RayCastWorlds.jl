struct RLBaseEnv{E} <: RLBase.AbstractEnv
    env::E
end

Base.show(io::IO, mime::MIME"text/plain", env::RLBaseEnv{E}) where {E <: AbstractGame} = show(io, mime, env.env)

play!(env::RLBaseEnv{E}) where {E <: AbstractGame} = play!(env.env)
