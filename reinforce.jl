using Reinforce
import Reinforce: step!, reset!, action, actions
# using Plots
using Flux, StatsBase
import Base: reset, done
using WebIO
using JSExpr
using Blink
import WebIO.render

include("env.jl")
include("draw.jl")

env = VRP()

EPISODES=4
sLen = sLength(env)
β = 0.01

mutable struct VRPPolicy <: Reinforce.AbstractPolicy end
reset!(policy::VRPPolicy) = return

# actor critic model
actor = Chain(
      Dense(sLen, 32, σ),
      Dense(32, 32, σ),
      Dense(32, L, σ),
      softmax)
critic =  Chain(
      Dense(sLen, 32, σ),
      Dense(32, 32, σ),
      Dense(32, L))


actor_loss(s, G) = -sum((log.(actor(s)))'.*G)
critic_loss(s, G) = Flux.mse(critic(s), G)

Q(s, a) = critic(s).data[a]
V(s::Array{Float64, 1}) = max(critic(s).data...)
π′(s, a) = actor(s).data[a]

function action(policy::VRPPolicy, s′::Array{Float64, 1})
   if rand() < β
      return rand(1:L)
   end

   prob = actor(s′).data
   sample(ProbabilityWeights(prob))
end
action(policy::VRPPolicy, r::Array{Int64,1}, s′::sType) = [ action(policy, playerState(s′, K)) for i=1:K ]

policy = VRPPolicy()

train_actor(data) = Flux.train!(actor_loss, data, ADAM(Flux.params(actor)))
train_critic(data) = Flux.train!(critic_loss, data, ADAM(Flux.params(critic)))

limit=300
actor_data = []
critic_data = []

# using td(λ)
for i=1:EPISODES
   # ep = Episode(env, policy)
   # @show env
   k = 1
   total_reward = zeros(K)
   @show env.maxsteps
   while !done(env) && k <= env.maxsteps
      s = state(env)
      a = action(policy, env.reward, state(env))
      r, s′ = step!(env, s, a)
      draw(env, s, a, r, s′)
      for j in 1:K
         s̃ = playerState(s, j)
         s″ = playerState(s′, j)
         a″ = action(policy, s″)

         tg = a[j]
         R = r[j] + γ*V(s″)
         val = critic(s̃).data
         val[tg, 1] = R

         push!(critic_data, (s̃, val))
         push!(actor_data, (s̃, val))
      end

      train_critic(critic_data)
      train_actor(actor_data)

      empty!(critic_data)
      empty!(actor_data)

      env.state = s′
      env.reward = r

      total_reward += r
      k += 1
   end
   @show i, k
   reset!(env)
end
