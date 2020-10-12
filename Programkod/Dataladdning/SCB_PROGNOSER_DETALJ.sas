proc  ds2;
	package &prglib..rumprg_SCB_prog_det / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nytta();
		declare package &prglib..pxwebtosas3a px();
		declare varchar(500) inUrl aktUrl arkivUrl;
		declare varchar(8) datalib;
		declare varchar(32) dataTabell;
		declare varchar(250) values valuetexts code;
		declare integer maxCeller maxBasAr startBasAr sistaArkivAr aktAr;

		forward uppdateraTabell arkivar;

		method rumprg_SCB_prog_det();
			arkivUrl='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0401/BE0401B';
			inUrl='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0401/BE0401B/BefProgOsiktDetalj';
			aktUrl='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0401/BE0401A/BefProgOsiktDetN';
			maxCeller=50000;
			datalib=%tslit(&datalib);
			dataTabell='SCB_PROGNOSER_DETALJ';
			startBasAr=2010;
		end;
		method run();
			declare integer finns finnsUpdate basar finnsTabell rc i;
			declare varchar(32) tabellNamnTmp;
			declare varchar(500) url;
			declare package sqlstmt s_maxBasar();
			sistaArkivAr=arkivar();
			aktAr=sistaArkivAr+1;

			if nytta.finnsTabell(datalib,dataTabell)=0 then do;
				sqlexec('create table ' || datalib || '.' || dataTabell || ' (
						basar integer,
						befolkning_dec integer having format nlnum11.,
						doda integer having format nlnum11.,
						inflyttade integer having format nlnum11.,
						utflyttade integer having format nlnum11.,
						medelbefolkning integer,
						kon varchar(7),
						fodelseland varchar(33),
						ar integer,
						alder integer,
						uppdaterat_dttm datetime having format datetime16.
						)');
				basar=startBasAr;
			end;
			else do;
				s_maxBasar.prepare('select max(basar) as maxBasAr from ' || datalib || '.' || dataTabell);
				rc=s_maxBasar.execute();
				if rc=0 then do;
					s_maxBasar.fetch([maxBasAr]);
					basar=maxBasAr+1;
					if basar=. then do;
					end;
				end;
				else do;
					basar=startBasAr;
				end;
				s_maxBasar.delete();
			end;
			if basar-1=sistaArkivAr then do;
				declare package &prglib..pxwebToSAS3A getData();
				getData.getData(aktUrl);
				tabellNamnTmp=scan(aktUrl,-1);
				uppdateraTabell(aktAr, tabellNamnTmp);
				getData.delete();
				sqlexec('drop table work.' || tabellNamnTmp);
				sqlexec('drop table work.meta_' || tabellNamnTmp);
			end;
			else if basar <=sistaArkivAr then do;
				do i=basar to sistaArkivAr;
					if i^=2014 then do;
						declare package &prglib..pxwebToSAS3A getData();
						url=inUrl || i-2000;
						getData.getData(Url);
						tabellNamnTmp=scan(Url,-1);
						uppdateraTabell(i, tabellNamnTmp);
						getData.delete();
						sqlexec('drop table work.' || tabellNamnTmp);
						sqlexec('drop table work.meta_' || tabellNamnTmp);
					end;
				end;
				do;
					declare package &prglib..pxwebToSAS3A getData();
					getData.getData(aktUrl);
					tabellNamnTmp=scan(aktUrl,-1);
					uppdateraTabell(aktAr, tabellNamnTmp);
					getData.delete();
					sqlexec('drop table work.' || tabellNamnTmp);
					sqlexec('drop table work.meta_' || tabellNamnTmp);
				end;
			end;

		end;

		method uppdateraTabell(integer iBasar, varchar(32) iTabellNamnTmp);
			declare package sqlstmt s_sqlVar();
			declare varchar(250) sqlValueString inValueString;
			declare varchar(100) rowValues;
			declare varchar(25) foddland;
			declare varchar(1000) sql;
			sqlValueString='';
			s_sqlVar.prepare('select "values", valuetexts from work.meta_' || iTabellNamnTmp || ' where code=''ContentsCode''');
			s_sqlVar.execute();
			do while(s_sqlVar.fetch([values, valuetexts])=0);
				if valuetexts='Folkmängd' then rowValues='befolkning_dec';
				else if valuetexts='Döda' then rowValues='doda';
				else if valuetexts='Medelfolkmängd' then rowValues='medelbefolkning';
				else rowValues=valuetexts;

				if iTabellNamnTmp='BefProgOsiktDetN' then foddland='Fodelselandgrupp_nm';
					else foddland='FODELSELAND_NM';
				if anydigit(values)=1 then values = 'x' || values;
					values=transtrn(values,'!','z1');
					values=transtrn(values,'€','z2');
					values=transtrn(values,'£','z3');
					values=transtrn(values,'$','z4');
					values=transtrn(values,'~','z5');
					values=transtrn(values,'§','z6');
				sqlValueString=sqlValueString || ', ' || strip(values) || ' as ' || strip(rowValues);
				inValueString=inValueString || ', ' || strip(rowValues);
			end;
			sqlexec('insert into ' || datalib || '.' || dataTabell || '
				(basar, kon,fodelseland, ar, alder ' || inValueString || ', UPPDATERAT_DTTM)
				select ' || iBasar || ' as basar, kon_nm as kon, ' || foddland || ' as fodelseland,
				cast(tid_cd as integer) as ar, alder_cd as alder'
				|| sqlValueString ||
				', UPPDATERAT_DTTM FROM work.' || iTabellNamnTmp || ' WHERE alder_cd <= 100 '
				);
		end;

		method arkivar() returns integer;
			declare package http pxwebContent();
			declare varchar(1000000) respons;
			declare integer sc rc sistaAr;
			pxwebContent.createGetMethod(arkivUrl);
			pxwebContent.executeMethod();

			sc=pxwebContent.getStatusCode();
	  	    if substr(sc,1,1) not in ('4', '5') then do;
	           	pxwebContent.getResponseBodyAsString(respons, rc);
				respons=scan(respons,2,':');
				respons=scan(respons,1,'"');
				respons=substr(respons,length(respons)-3);
				sistaAr=respons;
	 		end;
		   else do;
		   		respons='Error';
		   end;
		return  sistaAr;
		end;
	endpackage;
run;quit;

