proc ds2;
	package &prglib..rumprg_komInflyttning / overwrite=yes;
		dcl package hash h_inflyttAndel();
		dcl package hash h_alderAndel();
		dcl package hash h_komInflyttning();
		dcl varchar(8) userdata;
		dcl integer ar region alder xAr xRegion xAlder;
		dcl char(50) kon xKon;
		dcl double andelInflytt andelInvand inrikesInflytt invandringar andInrikesInflytt;

		method rumprg_komInflyttning();
			userdata=%tslit(&userdata);

			h_alderAndel.keys([ar region kon alder]);
			h_alderAndel.data([andelInflytt andelInvand]);
			h_alderAndel.dataset('{SELECT ar, region, kon, alder, ((tidAndelInflytt * multAndelInflytt) + addAndelInflytt) AS andelInflytt, 
	       		((tidAndelInvand * multAndelInvand) +addAndelInvand) AS andelInvand FROM ' || USERDATA || '.RUM_INFLYTTANDEL_KOM}');
			h_alderAndel.defineDone();

			h_inflyttAndel.keys([ar kon alder]);
			h_inflyttAndel.data([andInrikesInflytt]);
			h_inflyttAndel.dataset('{SELECT t1.ar, t1.kon, t1.alder, (t1.antalInflyttade / sum(t1.antalInflyttade,antalInvandrade)) AS andInrikesInflytt
				FROM ' ||USERDATA || '.RUM_FR_RESULTAT t1 INNER JOIN ' || USERDATA || '.RUM_KOMMUNER t2 ON (t1.region = t2.storRegion_cd)}');
			h_inflyttAndel.defineDone();

			h_komInflyttning.keys([ar region kon alder]);
			h_komInflyttning.data([inrikesInflytt invandringar]);
			h_komInflyttning.defineDone();
		end;*rumprg_komInflyttning;

		method calcInflyttning(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iIp);
			dcl integer rc;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;

			h_alderAndel.find([ar region kon alder],[andelInflytt andelInvand]);
			h_inflyttAndel.find([ar kon alder],[andInrikesInflytt]);

			inrikesInflytt=andelInflytt*andInrikesInflytt*iIp;
			invandringar=andelInvand*(1-andInrikesInflytt)*iIp;
			h_komInflyttning.ref([ar region kon alder],[inrikesInflytt invandringar]);
		end;*calcInflyttning;

		method getInrikesInflytt(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_komInflyttning.find([ar region kon alder],[inrikesInflytt invandringar]);
*inrikesInflytt=0;
		return inrikesInflytt;
		end;*getInrikesInflytt;

		method getInvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_komInflyttning.find([ar region kon alder],[inrikesInflytt invandringar]);
*invandringar=0;
		return invandringar;
		end;*getInvandringar;

		method updateInrikesInflytt(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iInrikesInflytt) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_komInflyttning.find([ar region kon alder],[inrikesInflytt invandringar]);
			inrikesInflytt=iInrikesInflytt;
			h_komInflyttning.replace([ar region kon alder],[inrikesInflytt invandringar]);
		return inrikesInflytt;
		end;*updateInrikesInflytt;

		method updateInvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iInvandringar) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_komInflyttning.find([ar region kon alder],[inrikesInflytt invandringar]);
			invandringar=iInvandringar;
			h_komInflyttning.replace([ar region kon alder],[inrikesInflytt invandringar]);
		return invandringar;
		end;*updateInvandringar;


	endpackage;
run;quit;
