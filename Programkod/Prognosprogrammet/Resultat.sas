proc ds2;
	package &prglib..rumprg_resultat / overwrite=yes;
		*dcl package hash h_resultatTabell();
		declare package sqlstmt s_resultatTabell();
		dcl package &prglib..rumprg_nyttigheter nyttigheter();

		dcl private integer ar region alder;
		dcl private double totalBefolkning totalbefolkningjan antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade;
		dcl private char(50) kon;
		
		method rumprg_resultat(char(132) iTabellNamn);
		declare varchar(8) userdata;
		declare varchar(150) resultatfil;
		userdata=strip(substr(iTabellNamn,1,find(iTabellNamn,'.')));
		resultatfil=strip(substr(iTabellNamn,find(iTabellNamn,'.')+1));

		*	h_resultatTabell.keys([ar region kon alder]);
		*	h_resultatTabell.data([ar region kon alder totalBefolkning totalBefolkningJan antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		*	h_resultatTabell.ordered('A');
		*	h_resultatTabell.defineDone();
		if nyttigheter.finnsTabell(%tslit(&userdata),resultatfil)<>0 then sqlexec('drop table ' || iTabellNamn);

		sqlexec('create table ' || iTabellNamn || ' (
				ar integer, region integer, kon char(7), alder integer, totalbefolkning double, totalbefolkningjan double,
				antalDoda double, antalFodda double, antalInflyttade double, antalUtflyttade double, antalInvandrade double, antalUtvandrade double
				)');

		s_resultatTabell.prepare('insert into ' || iTabellNamn || ' (ar, region, kon, alder, totalBefolkning, totalBefolkningJan, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade)
			values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
		s_resultatTabell.bindparameters([ar region kon alder totalBefolkning totalBefolkningJan antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		end;

		method laggtillResultat(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iTotalBefolkning, double iTotalBefolkningJan, double iAntalDoda, double iAntalFodda, double iAntalInflyttade, double iAntalUtflyttade, double iAntalInvandrade, double iAntalUtvandrade);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			totalBefolkning=iTotalBefolkning;
			totalBefolkningJan=iTotalBefolkningJan;
			antalDoda=iAntalDoda;
			antalFodda=iAntalFodda;
			antalInflyttade=iAntalInflyttade;
			antalUtflyttade=iAntalUtflyttade;
			antalInvandrade=iAntalInvandrade;
			antalUtvandrade=iAntalUtvandrade;

			s_resultatTabell.execute();

		*	h_resultatTabell.replace([ar region kon alder],[ar region kon alder totalBefolkning totalBefolkningJan antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);	
		end; *skapaResultatTabell;

		method skrivTillTabell();
			s_resultatTabell.delete();

	*		h_resultatTabell.output(iTabellNamn);
		end; *skrivTillTabell;

	endpackage ;
run;quit;

