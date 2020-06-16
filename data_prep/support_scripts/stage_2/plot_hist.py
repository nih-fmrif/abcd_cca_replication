import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats
from matplotlib import colors
from matplotlib.ticker import PercentFormatter

def plot_hist(l1,l2,titlestr):
    bins=50
    fig, ax = plt.subplots()

    # Call the sns.set() function 
    sns.set()
    sns.distplot(l1,bins=bins,norm_hist=True,label='hcp',fit=stats.gamma,kde=False,color=sns.xkcd_rgb["pale red"])
    sns.distplot(l2,bins=bins,norm_hist=True,label='abcd',fit=stats.gamma,kde=False,color=sns.xkcd_rgb["denim blue"])

    # plt.axvline(np.median(hcp), linestyle='--',color=sns.xkcd_rgb["pale red"])
    # plt.axvline(np.median(abcd), linestyle='--',color=sns.xkcd_rgb["denim blue"])

    plt.legend(loc='upper right', bbox_to_anchor=(0.95, 0.99),fontsize=12)

    ax.set_xlabel('Frame displacement (mm)')
    ax.set_ylabel('Probability density')
    ax.set_title(titlestr)

    textstr1 = '\n'.join((
        r'$n=%d$' % (len(l1), ),
        r'$\mu=%.4f$' % (np.mean(l1), ),
        r'$\mathrm{median}=%.4f$' % (np.median(l1), ),
        r'$\sigma=%.4f$' % (np.std(l1), )))

    textstr2 = '\n'.join((
        r'$n=%d$' % (len(l2), ),
        r'$\mu=%.4f$' % (np.mean(l2), ),
        r'$\mathrm{median}=%.4f$' % (np.median(l2), ),
        r'$\sigma=%.4f$' % (np.std(l2), )))

    props1 = dict(boxstyle='round', facecolor=sns.xkcd_rgb["pale red"], alpha=0.5)
    props2 = dict(boxstyle='round', facecolor=sns.xkcd_rgb["denim blue"], alpha=0.5)

    # place a text box in upper left in axes coords
    ax.text(0.95, 0.7, textstr1, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', horizontalalignment='right', bbox=props1)
    # place a text box in upper left in axes coords
    ax.text(0.95, 0.4, textstr2, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', horizontalalignment='right', bbox=props2)

    # Tweak spacing to prevent clipping of ylabel
    fig.tight_layout()
    plt.show()
    fig.savefig(os.path.join(cwd,'data/hcp_abcd_FD_histogram.png'),dpi=600)
