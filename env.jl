const K = 5    # no of vehicles
const Q′ = 1    # max requests
const T = 20   # maximum time

const timeWindows = [(i, i + 10) for i=1:5:(T - 10)]
const graph = Dict([(1, [2]), (2,[1, 3, 5]), (3, [2, 6]), (4, [7]), (5, [2, 8]), (6, [3, 9]), (7, [4, 8]), (8, [7, 5]),(9, [6])])

const N = length(timeWindows)    # no of time windows
const l = length(graph)    # no of locations
const L = l*N   # no of customer types

V(k::Int64) = graph[k]

function path(a, b)
    s, p = searchGraph(a,b,[false for i=1:l])
    s == false && return []
    return p
end

sType = Tuple{Array{Int64,1},Array{Float64,1},Array{Int64,1},Array{Int64,1},Array{Int64,1}}

function searchGraph(a::Int64, b::Int64, visited::Array{Bool,1})
    p = []
    visited[a] = true
    if a == b
        return true, [a]
    end


    s = false
    for i in V(a)
        if (visited[i])
            continue
        end
        s′, p′ = searchGraph(i, b, visited)
        if s′
            s = s′
            p = [a]
            append!(p, p′)
            break
        end
    end
    visited[a] = false
    return s,p
end



mutable struct VRP <: Reinforce.AbstractEnvironment
    state::Tuple{Array{Int64,1},Array{Float64,1},Array{Int64,1},Array{Int64,1},Array{Int64,1}}
    reward::Vector{Int64}
    maxsteps::Int64
    t::Int64
    game_over::Bool
    pending::Array{Tuple{Int64,Int64,Int64}}
end

VRP(;maxsteps=300) = VRP(VRPState0(),zeros(K),maxsteps,0, false, [])

function VRPState0()
    ϵ = zeros(Int, K) + 5            # the current destination if committed, else the current position for each k ∈ K
    s = zeros(K) - 1            # the time to complete service if committed, else -1 for each k ∈ K
    b = zeros(Int, K) + 1            # committed => 0 else => 1 for each k ∈ K
    q = zeros(Int, L)                # number of unassigned requests for each q ∈ Q
    c = copy(ϵ)                 # current position

    (ϵ, s, b, q, c)
end

genertateRequests(t) = rand(0:Q′, L)


function step!(env::VRP, s′, a)
    s′ = state(env)
    (ϵ, s, b, q, c) = s′
    pending = env.pending

    reward = zeros(Int64, K)
    for i=1:K

        if b[i]== 1 #free vehicles
            vec = []
            j = a[i]
            lft = req_lft(j)
            if valid(env, s′, i, j)
                b[i] = 0    # committed
                ϵ[i] = lft[1]
                s[i] = lft[3]
                q[j] -= 1
                index = 0
                for k in 1:length(pending)
                    if req_i(pending[k]) == j
                        index = k
                        break
                    end
                end
                if index != 0
                    deleteat!(pending, index)
                else
                    throw(KeyError(index))
                end
            end
        end

        if b[i] == 0
            p = path(c[i], ϵ[i])
            if (ϵ[i] != 5)
                reward[i] = -1
            else
                reward[i] = 0
            end
            if (length(p) > 1) c[i] = p[2]
            elseif ϵ[i] != 5
                ϵ[i] = 5
                s[i] = length(path(c[i], ϵ[i]))
                reward[i] = 0
            else    # set free
                s[i] = -1
                b[i] = 1
                reward[i] = 1
            end
        end
    end

    del_ind = []
    for i in 1:length(pending)
        (loc, from, to) = pending[i]
        from -= 1
        to -= 1
        pending[i] = (loc, from, to)
        to < 0 && push!(del_ind, i)
    end

    for i in 1:length(del_ind)
        deleteat!(pending, del_ind[i] - i + 1)
    end

    o = genertateRequests(env.t)
    for i=1:length(o)
        lft = req_lft(i)
        for j=1:o[i]
            push!(pending,lft)
        end
    end

    q = zeros(Int64, L)
    for lft in pending
        q[req_i(lft)] += 1
    end

    env.t += 1

    env.reward = reward
    env.pending = pending
    return reward, (ϵ, s, b, q, c)
end

done(env::VRP) = false

function valid(env::VRP, s, k, reqI)
    (ϵ, s, b, q, c) = s
    t = env.t

    b[k] == 0 && return false
    lft = req_lft(reqI)
    q[reqI] == 0 && return false

    p = path(c[k], lft[1])
    length(p) == 0 && return false
    t + length(p) < lft[2] && return false

    return true
end

function playerState(state::sType, i::Int64)
    (ϵ, s, b, q, c) = state
    ϵ′ = copy(ϵ)
    s′ = copy(s)
    b′ = copy(b)
    c′ = copy(c)

    function top(a, b, j)
        b[1] = a[j]
        b[j] = a[1]
    end

    top(ϵ, ϵ′, i)
    top(s, s′, i)
    top(b, b′, i)
    top(c, c′, i)

    [ϵ′..., s′..., b′..., q..., c′...]
end

reset!(env::VRP) = (env.state=VRPState0(); env.reward=zeros(K); env.t = 0;env.game_over=false;return)

sLength(env::VRP) = 4K + L


function req_lft(i)
    loc = Int(floor((i-1)/N)) + 1
    t_wind = Int((i - 1)%N) + 1
    (loc, timeWindows[t_wind]...)
end

function req_i(lft)
    (loc, from, to) = lft
    t_wind = 1
    if from > 0
        t_wind = round(from/5) + 1
    end
    Int((loc -1)*N + t_wind)
end
