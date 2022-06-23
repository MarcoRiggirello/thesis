##########################################################################
### This script associate the L1 reconstructed track with the MC ones. ###
### NO WARRANTY, USE AT YOUR OWN RISK                                  ###
###                                                                    ###
### Marco Riggirello, 2022                                             ###
##########################################################################

import argparse

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
            
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("filename", help="The filename of the root database.")
    args = parser.parse_args()
    
    df = ROOT.RDataFrame("L1TrackNtuple/eventTree", args.filename)
    df2 = delta_R_match(df)
    
    d0 = df2.Define("d0_res", "tp_d0 - mbmDR_trk_d0").Histo1D("d0_res")
    d0.Draw()
    eta = df2.Define("eta_res", "tp_eta - mbmDR_trk_eta").Histo1D("eta_res")
    eta.Draw()
    phi = df2.Define("phi_res", "tp_phi - mbmDR_trk_phi").Histo1D("phi_res")
    phi.Draw()
    pt = df2.Define("pt_res", "tp_pt - mbmDR_trk_pt").Histo1D("pt_res")
    pt.Draw()
    z0 = df2.Define("z0_res", "tp_z0 - mbmDR_trk_z0").Histo1D("z0_res")
    z0.Draw()
    input("Press a key to close...")
