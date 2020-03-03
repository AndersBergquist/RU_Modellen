proc ds2;
	package &prglib..rumprg_scbdata / overwrite=yes;
	dcl private varchar(132) inTabell;
	dcl private integer ar minAr region alder alderModer minAlder maxMalder;
	dcl private char(50) kon;
	dcl varchar(8) userdata projdata;
	dcl private double befolkning_dec befolkning_jan medelbefolkning inrikesInflyttning inrikesUtflyttning Invandringar Utvandringar doda fodda aggFodda;
	dcl package hash h_befolkning();
	dcl package hash h_fodda();
	dcl package hash h_foddaAggregat();
	dcl package hash h_regioner();
	dcl package hiter hi_regioner(h_regioner);


		method rumprg_scbdata();
			dcl package sqlstmt stmtModersAlder();
			projdata=%tslit(&datalib);
			userdata=%tslit(&userdata);	
			stmtModersAlder.prepare('select min(alderModer) as minAlder, max(alderModer) as maxMalder, min(ar) as minAr from ' || projdata || '.SCB_FODDA');
			stmtModersAlder.execute();
			stmtModersAlder.bindresults([minAlder maxMalder minAr]);
			stmtModersAlder.fetch();
		end; *rumprg_scbdata; 

		method run(integer iBasAr,char(50) iRegionIndelning, char(50) iRegionNamn, char(50) uScbBefolkning, char(50) uScbFodda, char(50) uScbFlyttningar);
			dcl varchar(1000) sql;
			projdata=%tslit(&datalib);
			userdata=%tslit(&userdata);	

			h_befolkning.keys([ar region kon alder]);
			h_befolkning.data([ar region kon alder befolkning_dec befolkning_jan medelbefolkning inrikesInflyttning inrikesUtflyttning Invandringar Utvandringar doda fodda]);
			h_befolkning.dataset('{SELECT t1.AR, t2.region_cd as region, t1.KON, t1.ALDER, SUM(t1.BEFOLKNING_DEC) AS BEFOLKNING_DEC, sum(befolkning_jan) as befolkning_jan, sum(medelbefolkning) as medelbefolkning,
							t3.INRIKESINFLYTTNING,  t3.INRIKESUTFLYTTNING, SUM(t1.INVANDRINGAR) AS INVANDRINGAR, SUM(t1.UTVANDRINGAR) AS UTVANDRINGAR,
							sum(t1.doda) as doda, 0 as fodda
				      FROM ' || strip(projdata) || '.SCB_BEFOLKNING t1, ' || uScbFlyttningar || ' t3, ' || iRegionIndelning || ' t2
				      WHERE (t1.AR = t3.AR AND t1.KON = t3.KON AND t1.ALDER = t3.ALDER AND t1.REGION = t2.kommun_cd AND t2.region_cd = 
				           t3.REGION_CD AND t1.ar < ' || iBasAr || ')
				      GROUP BY t1.AR, t2.region_cd, t1.KON, t1.ALDER, t3.INRIKESINFLYTTNING, t3.INRIKESUTFLYTTNING}');
			h_befolkning.defineDone();
			h_fodda.keys([ar region alderModer kon]);
			h_fodda.data([ar region alderModer kon fodda]);
			h_fodda.dataset('{SELECT t2.ar, t1.region_cd AS region, t2.alderModer, t2.kon, (SUM(t2.fodda)) AS fodda
			      FROM ' || strip(iRegionIndelning) || ' t1 INNER JOIN ' || strip(projdata) || '.SCB_FODDA t2 ON (t1.kommun_cd = t2.REGION) AND regiontyp=''Kommun''
				  WHERE t2.ar < ' || iBasAr || '
			      GROUP BY t2.ar, t1.region_cd, t2.ALDERMODER, t2.kon
				  }');
			h_fodda.defineDone();

			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region, region_nm from ' || strip(iRegionNamn) || ' }');
			h_regioner.defineDone();

			do ar=minAr to iBasAr-1;
			hi_regioner.first([region]);
			do until(hi_regioner.next([region])<>0);
					do kon='män', 'kvinnor';
						do alder=0 to 100;
							if alder=0 then do;
								aggFodda=0;
								do alderModer=minAlder to maxMalder;
									h_fodda.find([ar region alderModer kon],[ar region alderModer kon fodda]);
									aggFodda=sum(aggFodda,fodda);
								end; *alderModer;
							end;
							else do;
								aggFodda=0;
							end;*alder=0 beräknar antalet födda nollåringar, annars sätts fodda=0 då bara nollåringar kan föddas;
							h_befolkning.find([ar region kon alder],[ar region kon alder befolkning_dec befolkning_jan medelbefolkning inrikesInflyttning inrikesUtflyttning Invandringar Utvandringar doda fodda]);
							*medelbefolkning=sum(2*befolkning_dec,-inrikesInflyttning,inrikesUtflyttning,-Invandringar,Utvandringar,doda,-fodda)/2;
							fodda=aggFodda;
							if inrikesInflyttning <> . then do;
								h_befolkning.replace([ar region kon alder],[ar region kon alder befolkning_dec befolkning_jan medelbefolkning inrikesInflyttning inrikesUtflyttning Invandringar Utvandringar doda fodda]);
							end;
						end; *alder;
					end;*kon;
				end; *regioner;
			end; *ar;
		h_befolkning.output(uScbBefolkning);
		h_fodda.output(uScbFodda);
		end; *run, flyttar och beräknar SCB:s historiska data;
	endPackage ;

run;quit;
