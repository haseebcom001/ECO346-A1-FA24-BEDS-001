"""05_python_check.py  (Question 5: band table and Q3 figure in Python)
Run from the project root:  python scripts/05_python_check.py
Needs pandas, numpy, matplotlib. Reads only the local data files.
"""
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator

# 1. Read data and attach weight, province, area by hhid
person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv")[["hhid", "hhweight", "prov_code", "urban_rural"]]
d = person.merge(hh, on="hhid", how="left")

# 2. Variant 1: Punjab (2), urban (2); ages 15-64; earnings > 0
d = d[(d.prov_code == 2) & (d.urban_rural == 2)
      & (d.age >= 15) & (d.age <= 64) & (d.earn_annual > 0)].copy()
d["band_start"] = 15 + 5 * ((d.age - 15) // 5)
d["midpoint"] = d.band_start + 2

# 3. Band table: weighted mean = sum(w*x) / sum(w)
d["wx"] = d.hhweight * d.earn_annual
g = d.groupby("band_start")
bands = pd.DataFrame({
    "n_earners": g.size(),
    "weighted_mean": g.wx.sum() / g.hhweight.sum(),
}).reset_index()
bands["band"] = bands.band_start.astype(str) + "-" + (bands.band_start + 4).astype(str)
bands["midpoint"] = bands.band_start + 2
bands["thin"] = bands.n_earners < 30
bands["weighted_mean"] = bands.weighted_mean.round().astype(int)
bands = bands[["band_start", "band", "midpoint", "n_earners", "weighted_mean", "thin"]]
bands.to_csv("outputs/q3_band_table_python.csv", index=False)
print(bands.to_string(index=False))

# 4. Check against the R table (must agree to the rupee)
r = pd.read_csv("outputs/q3_band_table.csv")
same = (r.weighted_mean.values == bands.weighted_mean.values).all()
print("R and Python band means agree to the rupee:", same)

# 5. Redraw the Q3 figure
rupees = lambda v, _pos=None: f"Rs {v:,.0f}"
pts = d[(d.earn_annual >= 1e4) & (d.earn_annual <= 1e7)]
rng = np.random.default_rng(346)
jit = pts.age + rng.uniform(-0.4, 0.4, len(pts))
top = bands.loc[bands.weighted_mean.idxmax()]
red = "#C0392B"

fig, ax = plt.subplots(figsize=(9, 6))
ax.scatter(jit, pts.earn_annual, s=5, alpha=0.2, color="#4d4d4d", linewidths=0)
ax.plot(bands.midpoint, bands.weighted_mean, color=red, linewidth=2)
face = [("white" if t else red) for t in bands.thin]
ax.scatter(bands.midpoint, bands.weighted_mean, s=60, facecolors=face,
           edgecolors=red, linewidths=1.5, zorder=3)
ax.annotate(f"Highest mean: ages {top.band}\n{rupees(top.weighted_mean)}",
            xy=(top.midpoint, top.weighted_mean * 1.12),
            xytext=(top.midpoint, top.weighted_mean * 1.9),
            ha="center", color=red, fontweight="bold", fontsize=9,
            arrowprops=dict(arrowstyle="-", color=red))
ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.yaxis.set_major_locator(FixedLocator([1e4, 1e5, 1e6, 1e7]))
ax.yaxis.set_major_formatter(FuncFormatter(rupees))   # default would print 10^4 etc.
ax.yaxis.set_minor_locator(NullLocator())
ax.set_xlim(14.5, 64.5)
ax.set_xticks(range(15, 66, 5))
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (log scale)")
ax.set_title("Average earnings more than triple between the late teens and the late fifties",
             loc="left", fontweight="bold")
ax.grid(True, color="#e5e5e5")
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
fig.text(0.01, 0.01,
         f"Source: PSLM 2019-20 person file. Sample: {len(d):,} earners (ages 15-64, earnings > 0) "
         "in urban Punjab. Means weighted by hhweight.\nPoints jittered by up to 0.4 years. "
         "Hollow markers would mark thin bands (< 30 earners). Python reproduction.",
         fontsize=8, color="#595959")
fig.tight_layout(rect=(0, 0.05, 1, 1))
fig.savefig("figures/q3_earnings_by_age_python.svg")
