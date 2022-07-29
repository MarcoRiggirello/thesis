##########################################################################
### This script associate the L1 reconstructed track with the MC ones. ###
### NO WARRANTY, USE AT YOUR OWN RISK                                  ###
###                                                                    ###
### Marco Riggirello, 2022                                             ###
##########################################################################

import argparse

import numpy as np
from matplotlib import pyplot as plt

import ROOT

ROOT.EnableImplicitMT()

cpp_code = """
/**
* This function compute the minimum DeltaR between the elements of two
* track vectors and returns the vector of indexes to match the first
* track with the second one. You can use this index vector to reorder
* the second track set, for example using the function 
* ROOT::VecOps::Take()
*
* @param eta1 The eta parameter RVec for the first set of tracks.
* @param eta2 The eta parameter RVec for the second set of tracks.
* @param phi1 The phi parameter RVec for the first set of tracks.
* @param phi2 The phi parameter RVec for the second set of tracks.
**/
ROOT::VecOps::RVec<size_t> match_by_min_DeltaR (const ROOT::RVecF & eta1, const ROOT::RVecF & eta2, const ROOT::RVecF & phi1, const ROOT::RVecF & phi2) {
	size_t k=0;
	float deltaR, minDR;
	ROOT::VecOps::RVec<size_t> mbmDR(eta1.size());
	for (size_t i=0; i < eta1.size(); i++) {
		deltaR = 0.;
		minDR = 999.;
		for (size_t j=0; j < eta2.size(); j++) {
			deltaR = ROOT::VecOps::DeltaR(eta1[i], eta2[j], phi1[i], phi2[j]);
			if (deltaR < minDR) {
				minDR = deltaR;
				k = j;
			}
		}
		mbmDR[i] = k;
	}
	return mbmDR;
}
"""

ROOT.gInterpreter.ProcessLine(cpp_code)

def delta_R_match(root_df):
    """
    Defines "mbmDR_trk_*" comlumn reordering "trk_*" columns strarting
    from mbmDR_index. (Only a few of them for now - the one that will be used).
    """
    out_df = root_df.Define("mbmDR_index", "match_by_min_DeltaR(tp_eta, trk_eta, tp_phi, trk_phi)")\
            .Define("mbmDR_trk_d0", "ROOT::VecOps::Take(trk_d0, mbmDR_index)")\
            .Define("mbmDR_trk_eta", "ROOT::VecOps::Take(trk_eta, mbmDR_index)")\
            .Define("mbmDR_trk_phi", "ROOT::VecOps::Take(trk_phi, mbmDR_index)")\
            .Define("mbmDR_trk_pt", "ROOT::VecOps::Take(trk_pt, mbmDR_index)")\
            .Define("mbmDR_trk_z0", "ROOT::VecOps::Take(trk_z0, mbmDR_index)")
    return out_df

def delta_R_quantiles(root_df, p, pt_min, pt_max):
    """
    This function computes quantiles of the DeltaR distribution
    for a given interval of pt.
    
    Parameters
    ----------
    root_df: ROOT Data Frame
    probs: np.array of place where compute quantiles
    pt_min: float
    pt_max: float

    Returns
    -------
    The quantiles of the distribution.
    """
    q = np.zeros_like(p)
    df1 = root_df.Define("DeltaR_filtered", f"DeltaR[{pt_min} <= tp_pt && tp_pt < {pt_max}]")
    DeltaR_min = 0#df1.Min("DeltaR_filtered").GetValue()
    DeltaR_max = 0.02#df1.Max("DeltaR_filtered").GetValue()
    Delta_q = 0# 0.144 * (DeltaR_max - DeltaR_min) / 128
    h = df1.Histo1D(("DeltaR", "DeltaR", 32, DeltaR_min, DeltaR_max), "DeltaR_filtered")
    _ = h.GetQuantiles(p.size, q, p)
    return q, h

#####################
### THE EXECUTION ###
#####################
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("filename", help="The filename of the root database.")
    args = parser.parse_args()
    
    df1 = ROOT.RDataFrame("L1TrackNtuple/eventTree", args.filename)
    df2 = delta_R_match(df1)
    df = df2.Define("DeltaR", "ROOT::VecOps::DeltaR(tp_eta, mbmDR_trk_eta, tp_phi, mbmDR_trk_phi)")

    p = np.array([.90, .99])

    q_90 = []
    q_99 = []
    
    delta_q = []

    pt_bin = np.array([2.,5.,10.,15.,20.,30.,40.,60.,100.])
    q_temp = 0
    delta_q_temp = 0

    for pt in zip(pt_bin[:-1],pt_bin[1:]):
        q_temp, delta_q_temp = delta_R_quantiles(df, p, pt[0], pt[1])

        q_90.append(q_temp[0])
        q_99.append(q_temp[1])
        
        delta_q.append(delta_q_temp)

    canvas_list = []
    for h in delta_q:
        c = ROOT.TCanvas("","",1200,900)
        canvas_list.append(c)
        h.Draw()
        c.Draw()


    input("a")
    pt_bin_center = .5 * (pt_bin[:-1] + pt_bin[1:])
    pt_bin_width = .5 * (pt_bin[1:] - pt_bin[:-1])

    plt.title("DeltaR vs pt")
    plt.errorbar(pt_bin_center, q_90, yerr=delta_q, xerr=pt_bin_width, linestyle=" ", label="90th percentile")
    #plt.errorbar(pt_bin_center, q_99, yerr=delta_q, xerr=pt_bin_width, linestyle=" ", label="99th percentile")
    plt.xlabel("tp_pt [GeV]")
    plt.ylabel("DeltaR")
    #plt.xscale("log")
    plt.legend()

    plt.show()

    
