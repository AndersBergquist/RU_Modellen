proc ds2;
	package &prglib..rumprg_invandringsAndel / overwrite=yes;
		dcl package hash h_invandringarDetalj();
		dcl package hash h_invandringarTotal();
		dcl package hash h_invandringarSCBPrognos();
		dcl package hash h_invandringarPrognos();
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl private integer ar region alder progMaxAr progMinAr;
		dcl private char(50) kon;
		dcl private char(8) userdata projdata;
		dcl private double medelInvandringar totalInvandringar prognosInvandringar invandringar addInvandringar multInvandringar;

		method rumprg_invandringsAndel();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end;*rumprg_invandringsAndel;

		method run(integer iBasAr, integer iAntalAr, char(50) iScbBef, char(50) iRegionNamn, char(50) uInvandringar);
			dcl private integer senasteAr startAr;
			dcl package sqlstmt stmtMaxAr();
			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;

			stmtMaxAr.prepare('select max(ar) as progMaxAr from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([progMaxAr]);
			stmtMaxAr.fetch();


			h_invandringarDetalj.keys([region kon alder]);
			h_invandringarDetalj.data([medelInvandringar]);
			h_invandringarDetalj.dataset('{select region, kon, alder, mean(invandringar) as medelInvandringar from ' || strip(iScbBef) || 
					' where ar between ' || startAr || ' and ' || senasteAr || ' group by region, kon, alder}');
			h_invandringarDetalj.defineDone();

			h_invandringarTotal.keys([kon alder]);
			h_invandringarTotal.data([totalInvandringar]);
			h_invandringarTotal.dataset('{select kon, alder, sum(invandringar) as totalInvandringar from ' || strip(projdata) || '.SCB_BEFOLKNING
					 where ar between ' || startAr || ' and ' || senasteAr || ' and regiontyp=''Riket'' group by kon, alder}');
			h_invandringarTotal.defineDone();

			h_invandringarSCBPrognos.keys([ar kon alder]);
			h_invandringarSCBPrognos.data([prognosInvandringar]);
			h_invandringarSCBPrognos.dataset('{SELECT ar, KON, alder, (SUM(inflyttade)) AS prognosInvandringar
			      FROM ' || strip(userdata) || '.SCB_PROGNOSER_DETALJ GROUP BY ar, KON, alder;}');
			h_invandringarSCBPrognos.defineDone();

			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region from ' || strip(iRegionNamn) || ' }');
			h_regioner.defineDone();

			h_invandringarPrognos.keys([ar region kon alder]);
			h_invandringarPrognos.data([ar region kon alder invandringar addInvandringar multInvandringar]);
			h_invandringarPrognos.ordered('A');
			h_invandringarPrognos.defineDone();


			addInvandringar=0;
			multInvandringar=1; *Detta är en additativ komponent som skall ändras av prognosmakaren i speciellt excelark;
			do ar=iBasAr to progMaxAr;
				hi_regioner.first([region]);
				do until(hi_regioner.next([region])<>0);
					do kon='män', 'kvinnor';
						do alder=0 to 100;
							h_invandringarDetalj.find([region kon alder],[medelInvandringar]);
							h_invandringarTotal.find([kon alder],[totalInvandringar]);
							h_invandringarSCBPrognos.find([ar kon alder],[prognosInvandringar]);
							if totalInvandringar = 0 then do;
								invandringar=0;
							end; else do;
								invandringar=((medelInvandringar*5)/totalInvandringar)*prognosInvandringar;
							end;

							h_invandringarPrognos.ref([ar region kon alder],[ar region kon alder invandringar addInvandringar multInvandringar]);
						end;*alder;
					end;*kon;
				end; *regioner;
			end;*ar;

			h_invandringarPrognos.output(strip(uInvandringar));
		end; *run;
	endpackage;
run;quit;