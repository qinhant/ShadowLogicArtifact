import sys, os
import numpy as np


# STEP: data
resultDir = os.path.dirname(os.path.abspath(__file__))

# FILL ME: Update this array with data get from experiments.
time = [
  [
    [209, 461, 402, 429],
    [539, 461, 462, 220],
    [40, 461, 1020, 6354]
  ],
  [
    [1299, 1382, 1685, 1922],
    [344, 1382, 30124],
    [17, 1382]
  ]
]
for i in [0,1]:
  for j in [0,1,2]:
    time[i][j] = [x/60 for x in time[i][j]]

size = [
  [
    [2, 4, 8, 16],
    [2, 4, 8, 16],
    [2, 4, 8, 16]
  ],
  [
    [2, 4, 8, 16],
    [2, 4, 8],
    [2, 4]
  ]
]
color = ["black", "green", "lightpink"]
marker = ["o", "X", "^"]
label = ["Regfile Size", "Data Mem Size", "ROB Size"]




# STEP: figure
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
gs = gridspec.GridSpec(1, 2, height_ratios=[1], width_ratios=[1, 1])
fig = plt.figure(figsize=(16,5))
ax = [fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1])]



def plot_ax(ax, time, size):
  # STEP: lines
  ax.plot(size[0], time[0], color=color[0], linewidth=8, marker=marker[0], markersize=25, markeredgewidth=0, alpha=0.7, label=label[0])
  ax.plot(size[1], time[1], color=color[1], linewidth=8, marker=marker[1], markersize=25, markeredgewidth=0, alpha=0.7, label=label[1])
  ax.plot(size[2], time[2], color=color[2], linewidth=8, marker=marker[2], markersize=25, markeredgewidth=0, alpha=0.7, label=label[2])

  # STEP: axe labels
  ax.set_xscale("log")
  ax.set_xticks([2, 4, 8, 16], ["2", "4", "8", "16"])
  ax.set_yscale("log")
  ax.set_yticks([1, 10, 100, 1000], ["1", "10", "100", "1000"])
  ax.set_ylim([0.1, 2000])
  ax.minorticks_off()
  ax.tick_params(axis='x', labelsize=28)
  ax.tick_params(axis='y', labelsize=28)
  ax.set_xlabel("Number of Entries", fontsize=28)

plot_ax(ax[0], time[0], size[0])
plot_ax(ax[1], time[1], size[1])




# STEP: figure labels
ax[0].set_ylabel("Proving Time (min)", fontsize=28)
ax[0].legend(loc='upper left', bbox_to_anchor=(0.02, 1.26), ncol=3, fontsize=28)
ax[0].text(-0.02, -0.49, r"$\bf{(a)}$ Prove $\mathsf{NoFwd_{futuristic}}$ for" + "\n      Sandbox Contract", fontsize=30, transform=ax[0].transAxes)
ax[1].text(-0.02, -0.49, r"$\bf{(b)}$ Prove $\mathsf{Delay_{spectre}}$ for"    + "\n      Constant-time Contract", fontsize=30, transform=ax[1].transAxes)


plt.savefig(resultDir + "/performance.pdf", bbox_inches="tight")


