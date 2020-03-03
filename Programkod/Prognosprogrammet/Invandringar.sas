proc ds2;
	package &prglib..rumprg_invandringar / overwrite=yes;
		dcl package hash h_invandringarPrognos();
		dcl private integer ar region alder;
		dcl private char(50) kon;
		dcl private char(8) userdata;
		dcl private double invandringar updateInvandringar;

		
		method rumprg_invandringar();
		end;*rumprg_invandringar;

		method setup(char(50) iInvTabell);
			h_invandringarPrognos.keys([ar region kon alder]);
			h_invandringarPrognos.data([invandringar]);
			h_invandringarPrognos.dataset('{SELECT ar, region, kon, alder, (sum(invandringar,addInvandringar)*multInvandringar) AS invandringar FROM ' || strip(iInvTabell) || '}');
			h_invandringarPrognos.defineDone();

		end;*setup;

		method getInvandringar(integer iAr, integer iRegion, char(8) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_invandringarPrognos.find([ar region kon alder],[invandringar]);
		return invandringar;
		end;*getInvandringar;

		method updateInvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iAntalInvandringar);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			updateInvandringar=iAntalInvandringar;
			h_invandringarPrognos.replace([ar, region, kon, alder],[updateInvandringar]);
		end;*updateUtflyttade;

	endpackage ;
run;quit;
