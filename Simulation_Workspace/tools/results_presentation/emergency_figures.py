"""Static report figures for the additional emergency supply study."""
from pathlib import Path
import csv
import math
import textwrap
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

TEAL = "#087f7c"
NAVY = "#16394e"
AMBER = "#be7e27"
RED = "#b75642"


def records(path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def number(row, key):
    try:
        x = float(row.get(key, ""))
        return x if math.isfinite(x) else float("nan")
    except (ValueError, TypeError):
        return float("nan")


def build_emergency_figures(root: Path, output: Path):
    destination = output / "emergency"
    destination.mkdir(parents=True, exist_ok=True)
    source = root / "results/emergency_supply"
    figures = []
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10,
                         "axes.spines.top": False, "axes.spines.right": False,
                         "axes.titleweight": "bold", "figure.facecolor": "white",
                         "savefig.facecolor": "white"})

    def save(fig, filename, title, caption):
        fig.savefig(destination / filename, dpi=170, bbox_inches="tight")
        plt.close(fig)
        figures.append({"title": title, "path": "emergency/" + filename, "caption": caption})

    rows = [r for r in records(source / "summary.csv")
            if math.isfinite(number(r, "Paux_Supplied_MW")) and
            math.isfinite(number(r, "Paux_Unserved_MW"))]
    if rows:
        fig, ax = plt.subplots(figsize=(12, max(4, len(rows)*.65+1.8)))
        y = np.arange(len(rows))
        supplied = np.array([number(r, "Paux_Supplied_MW") for r in rows])
        unserved = np.array([number(r, "Paux_Unserved_MW") for r in rows])
        ax.barh(y, supplied, label="AC auxiliary demand supplied", color=TEAL, height=.57)
        ax.barh(y, unserved, left=supplied, label="AC auxiliary demand unserved", color="#d2a06d", height=.57)
        ax.set_yticks(y, [textwrap.fill(r["Case_ID"].replace("_"," "), 27) for r in rows])
        ax.invert_yaxis()
        ax.set_xlabel("Active power (MW)")
        ax.set_title("AC auxiliary service with the main generator disconnected", loc="left", pad=20)
        ax.grid(axis="x", alpha=.2)
        ax.set_axisbelow(True)
        for i,(a,b) in enumerate(zip(supplied,unserved)):
            if a>0: ax.text(a/2,i,f"{a:.2f} MW",ha="center",va="center",color="white",weight="bold")
            if b>0: ax.text(a+b/2,i,f"{b:.2f} MW",ha="center",va="center",color=NAVY)
        ax.legend(loc="upper center",bbox_to_anchor=(.5,-.18),ncol=2,frameon=False)
        fig.tight_layout()
        save(fig,"auxiliary_service.png","Auxiliary AC supply: served versus unserved",
             "The stacked bars represent supplied plus unserved AC demand for each stated emergency condition. DC service is a separate load boundary; it is not counted as AC auxiliary power.")

    grid = [r for r in rows if math.isfinite(number(r, "V_6_6_kV")) and
            number(r,"Grid_P_MW")>0]
    if grid:
        fig, axes = plt.subplots(1,2,figsize=(12,4.5),gridspec_kw={"width_ratios":[1.25,1]})
        labels=[textwrap.fill(r["Case_ID"].replace("_"," "),22) for r in grid]
        voltages=[number(r,"V_6_6_kV") for r in grid]
        axes[0].bar(np.arange(len(grid)),voltages,color=TEAL,width=.5)
        axes[0].axhline(6.6,color=AMBER,linestyle="--",label="6.6 kV nominal")
        axes[0].set_xticks(range(len(grid)),labels)
        axes[0].set_ylim(0,max(7,max(voltages)*1.1))
        axes[0].set_ylabel("Auxiliary bus voltage (kV)")
        axes[0].set_title("Grid-fed emergency voltage",loc="left")
        for i,v in enumerate(voltages):axes[0].text(i,v+.12,f"{v:.3f}",ha="center")
        axes[0].legend(frameon=False,loc="lower right")
        x=np.arange(len(grid)); width=.24
        for j,(key,label,color) in enumerate([("GSUT_Loading_pct","GSUT",NAVY),("UAT_Loading_pct","UAT",TEAL),("GAT_Loading_pct","GAT",AMBER)]):
            vals=np.array([number(r,key) for r in grid])
            axes[1].bar(x+(j-1)*width,vals,width,label=label,color=color)
        axes[1].set_xticks(x,labels);axes[1].set_ylabel("Transformer loading (%)")
        axes[1].set_title("Loading on the selected supply path",loc="left")
        axes[1].axhline(100,color=RED,linestyle="--",linewidth=1,label="Rated MVA")
        axes[1].legend(frameon=False,ncol=2,fontsize=9)
        for ax in axes:ax.grid(axis="y",alpha=.2);ax.set_axisbelow(True)
        fig.tight_layout()
        save(fig,"grid_backfeed_voltage_loading.png","Grid supply: voltage and transformer loading",
             "Values come from the added disconnected-generator steady-state calculation. Zero loading represents an isolated path only where the case definition states that isolation. This does not prove automatic transfer or motor restart performance.")

    fig, ax=plt.subplots(figsize=(12,5.8))
    ax.set_xlim(0,12);ax.set_ylim(0,6);ax.axis("off")
    def box(x,y,w,text,color=TEAL):
        ax.text(x+w/2,y,text,ha="center",va="center",fontsize=10,color=NAVY,
                bbox={"boxstyle":"round,pad=.7","fc":"#edf4f2","ec":color,"lw":1.4})
    def arrow(a,b,y,dashed=False):
        ax.annotate("",xy=(b,y),xytext=(a,y),arrowprops={"arrowstyle":"->","color":TEAL,"lw":1.8,
                    "linestyle":"--" if dashed else "-"})
    ax.text(.1,5.7,"Auxiliary supply paths during a generator outage",fontsize=17,weight="bold",color=NAVY)
    ax.text(.1,5.23,"Main generator disconnected: no generation and no voltage regulation",fontsize=10,color="#596c78")
    box(.1,4.25,2.2,"Grid available\n230 kV network")
    box(4.25,4.25,2.5,"Selected transformer path\nGAT or retained GSUT/UAT")
    box(8.9,4.25,2.7,"6.6 kV auxiliaries\nAC load-flow assessment")
    arrow(2.6,4,4.25);arrow(7.15,8.65,4.25)
    box(.1,2.8,2.2,"AC source unavailable\nStation battery")
    box(4.25,2.8,2.5,"Station DC bus\nAcademic capacity model")
    box(8.9,2.8,2.7,"Controls and trip circuits\nRepresented DC loads")
    arrow(2.6,4,2.8);arrow(7.15,8.65,2.8)
    box(.1,1.3,2.2,"Emergency diesel\nRating unresolved",AMBER)
    box(4.25,1.3,2.5,"Transfer and load shedding\nPlant sequence unresolved",AMBER)
    box(8.9,1.3,2.7,"Essential AC auxiliaries\nLoad schedule required",AMBER)
    arrow(2.6,4,1.3,True);arrow(7.15,8.65,1.3,True)
    ax.text(.1,.35,"Dashed path: conceptual supply requirement. Diesel/UPS voltage, transient response and installed capacity are not established.",fontsize=9,color="#6b5b3a")
    save(fig,"emergency_supply_paths.png","Which source supplies which auxiliary system",
         "The paths distinguish the modeled grid supply and academic DC continuity from the diesel transfer path that still requires plant data. Station DC is not a source for the full AC auxiliary demand.")
    return figures
