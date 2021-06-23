wu_to_tu(x_wu::AbstractFloat) = floor(Int, x_wu) + 1
wu_to_pu(x_wu::AbstractFloat, pu_per_wu) = floor(Int, x_wu * pu_per_wu) + 1
pu_to_tu(i_pu::Integer, pu_per_tu) = (i_pu - 1) ÷ pu_per_tu + 1
