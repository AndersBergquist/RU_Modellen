proc ds2;
	package &prglib..rumprg_SCB_LADDA / overwrite=yes;
		declare package &prglib..rumprg_SCB_FODDA fodda();
		declare package &prglib..rumprg_SCB_flyttning68 bef68();
		declare package &prglib..rumprg_SCB_flyttning97 bef97();
		declare package &prglib..rumprg_SCB_Doda doda();
		declare package &prglib..rumprg_SCB_befolkningNy befNy;

		dcl package &prglib..rumprg_SCB_befolkning bef();
		dcl package &prglib..rumprg_SCB_NYBYGGNATION nybygg();
		dcl package &prglib..rumprg_SCB_prog_det det();
		dcl package &prglib..rumprg_SCB_PROG_DTAL dtal();
		dcl package &prglib..rumprg_SCB_prog_fodda progfodda();
		dcl package &prglib..rumprg_SCB_prog_ftal ftal();
		dcl package &prglib..rumprg_SCB_prog_sam sam();
		dcl package &prglib..rumprg_SCB_RflyttLan_hist RflyttLan_hist();

		method rumprg_SCB_LADDA();
		end;*rumprg_SCB_LADDA;

		method run();
			fodda.run();
			bef68.run();
			bef97.run();
			doda.run();
			befNy.run();
			bef.run();
			nybygg.run();
			det.run();
			dtal.run();
			progfodda.run();
			ftal.run();
			sam.run();
			RflyttLan_hist.run();
		end;*run;
	endpackage;
run;quit;
