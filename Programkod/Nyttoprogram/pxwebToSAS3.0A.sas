proc ds2;
	package  &prglib..pxwebToSAS3A / overwrite=yes;
		declare package &prglib..pxwebToSAS2 px();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare package SQLSTMT s_getSistaTid();
		declare package hash h_variables();
		declare package hash h_ContentsCode();
		declare package hiter hi_variables(h_variables);
		declare package hiter hi_ContentsCode(h_ContentsCode);
		declare varchar(20) maxTid;	
		declare varchar(5) tid;
		declare varchar(250) titel code text values valueTexts;
		declare integer maxLengthValues maxLengthValueTexts;

		forward getData getData_helper fetchData createInfil cleanUp;	

		method pxwebToSAS31A();

		end;

/* getData, innitierar programmet */
		method getData(varchar(500) iUrl);
			declare varchar(8) iLib;
			declare varchar(32) iTabell;
			declare varchar(100) felText;
			declare integer iAntalCeller filfinns;
			iAntalCeller=50000;
			iLib='work';
			iTabell=scan(iUrl,-1);
 			filFinns=nytta.finnsTabell(iLib, iTabell);
			if filFinns=0 then do;
				getData_helper(iUrl, iAntalCeller, iLib, iTabell, iLib, iTabell, 'tid_cd');
			end;
			else do;
				feltext = 'Filen work.' || iTabell || ' finns redan i work.';
				put feltext;
			end;
		end;
		method getData(varchar(500) iUrl, integer iAntalCeller);
			declare varchar(8) iLib;
			declare varchar(32) iTabell;
			declare varchar(100) felText;
			declare integer filfinns;
			iLib='work';
			iTabell=scan(iUrl,-1);
 			filFinns=nytta.finnsTabell('work', iTabell);
			if filFinns=0 then do;
				getData_helper(iUrl, iAntalCeller, iLib, iTabell, iLib, iTabell, 'tid_cd');
			end;
			else do;
				feltext = 'Filen work.' || iTabell || ' finns redan i work.';
				put feltext;
			end;
		end;
		method getData(varchar(500) iUrl, integer iAntalCeller, varchar(8) sLib, varchar(32) sTabell);
			declare varchar(8) iLib;
			declare varchar(32) iTabell;
			declare varchar(100) felText;
			declare integer filfinns;
			iLib='work';
			iTabell=scan(iUrl,-1);
 			filFinns=nytta.finnsTabell(iLib, iTabell);
			if filFinns=0 then do;
				getData_helper(iUrl, iAntalCeller, iLib, iTabell, sLib, sTabell, 'tid_cd');
			end;
            else do;
				feltext = 'Filen work.' || iTabell || ' finns redan i work.';
				put feltext;
			end;
		end;
		method getData(varchar(500) iUrl, integer iAntalCeller, varchar(8) sLib, varchar(32) sTabell, varchar(32) iTidVar);
			declare varchar(8) iLib;
			declare varchar(32) iTabell;
			declare varchar(100) felText;
			declare integer filfinns;
			iLib='work';
			iTabell=scan(iUrl,-1);
 			filFinns=nytta.finnsTabell(iLib, iTabell);
			if filFinns=0 then do;
				getData_helper(iUrl, iAntalCeller, iLib, iTabell, sLib, sTabell, iTidVar);
			end;
            else do;
				feltext = 'Filen work.' || iTabell || ' finns redan i work.';
				put feltext;
			end;
		end;
/* End getData */

		method getData_helper(varchar(500) iUrl, integer iAntalCeller, varchar(8) iLib, varchar(32) iTabell, varchar(8) sLib, varchar(32) sTabell, varchar(32) iTidVar);
*			declare varchar(32) filnamn;
			declare integer finnsUpdate;

*			filnamn=scan(iUrl,-1);
			finnsUpdate=fetchData(iUrl, iAntalCeller, sLib, sTabell, iTabell, iTidVar);
			if finnsUpdate=1 then do;
				createInfil(iLib, iTabell);
				cleanUp(iLib, iTabell);
			end;
		end;*getData_helper;

		method fetchData(varchar(500) iUrl, integer iAntalCeller, varchar(8) sLib, varchar(32) sTabell, varchar(32) iTabell, varchar(32) iTidVar) returns integer;
			declare varchar(32) metaTabell;
			declare integer filFinns finnsUpdate;
			filFinns=nytta.finnsTabell(sLib, sTabell);
*			metaTabell='meta_' || filnamn;
			if filFinns=1 then do;
				s_getSistaTid.prepare('select max(' || iTidVar || ') as maxTid from ' || sLib ||'.' || sTabell);
				s_getSistaTid.execute();
				s_getSistaTid.bindresults([maxTid]);
				s_getSistaTid.fetch();
				finnsUpdate=px.getData(iUrl,iAntalCeller,maxTid);
				s_getSistaTid.delete();
				if finnsUpdate=1 then do;
					sqlexec('insert into ' || sLib || '.meta_' || sTabell || ' select * from work.meta_' || iTabell || ' where tid=''true''');
				end;
			end;
			else do;
				finnsUpdate=px.getData(iUrl,iAntalCeller);
				if sLib ^= 'work' and sTabell ^= iTabell then sqlexec('create table ' || sLib || '.meta_' || sTabell || ' AS select * from work.meta_' || iTabell);
			end;
			return finnsUpdate;
		end;*fetchData;

		method createInfil(varchar(8) iLib, varchar(32) iTabell);
			declare varchar(5000) sql_infil sql_metaDelFil sqlInfil sqlSelect sqlFrom sqlWhere test;
			declare varchar(32) metaFilnamn inFilnamn;
			declare integer firstRow t r;

			metaFilnamn='meta_' || iTabell ;
			inFilnamn=iTabell || '_in';

			h_variables.keys([code]);
			h_variables.data([titel code text tid maxLengthValues maxLengthValueTexts]);
			h_variables.dataset('{SELECT trim(titel) as titel, trim(code) as code, trim(text) as text, trim(tid) as tid, (MAX(CHARACTER_LENGTH(trim("values")))) AS maxLengthValues, (MAX(CHARACTER_LENGTH(trim(valueTexts)))+1) AS maxLengthValueTexts
		      FROM work.' || metaFilnamn || ' WHERE code ^= ''ContentsCode''
		      GROUP BY titel, code, text, tid}');
			h_variables.defineDone();

			h_ContentsCode.keys([values]);
			h_ContentsCode.data([values valueTexts]);
			h_ContentsCode.dataset('{SELECT trim("values") as "values", trim(valueTexts) as valueTexts FROM work.' || metaFilnamn || ' WHERE code = ''ContentsCode''}');
			h_ContentsCode.defineDone();

			firstRow=1;
			t=0;
			hi_variables.first([titel code text tid maxLengthValues maxLengthValueTexts]);
			sql_infil='CREATE TABLE ' || iLib || '.' || iTabell || ' {options label=''' || titel || '''} ';
			sqlFrom=' FROM work.' || iTabell || ' t0 ';
			do until(hi_variables.next([titel code text tid maxLengthValues maxLengthValueTexts]));
				t=t+1;
				if firstRow = 0 then do;
					sql_infil=sql_infil || ', ';
					sqlSelect=sqlSelect || ', ';
					sqlFrom=sqlFrom || ', ';
					sqlWhere=sqlWhere || ' AND ';
				end;
				else if firstRow = 1 then do;
					sql_infil=sql_infil || '(';
					sqlSelect=' SELECT ';
					sqlFrom=sqlFrom || ', ';
					sqlWhere=' WHERE (';
					firstRow=0;
				end;*firstRow;
				if lowCase(tid)='true' then do;
					if lowCase(text) in ('ar' 'år') then do;
						sql_infil=sql_infil || code || '_cd varchar(' || maxLengthValues || ') having label ''' || text || ', kod'', ';
						sql_infil=sql_infil || code || '_dt integer having label '' År, datumvärde'' format year4. ';
						sql_metaDelFil='create table work.m_' || code || ' as select "values",  cast("values" as varchar(' || maxLengthValues || ')) as ' ||code || '_cd,
							mdy(1,1,cast(substr("values",1,4) as integer)) as ' || code || '_dt from work.' || metaFilnamn || ' where code=''' || code || '''';
						sqlexec(sql_metaDelFil);
						sqlSelect = sqlSelect || 't' || t || '.' || code || '_cd, t' || t || '.' || code || '_dt';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t ;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
					else if lowCase(text) in ('manad' 'månad') then do;
						sql_infil=sql_infil || code || '_cd varchar(' || maxLengthValues || ') having label ''' || text || ', kod'', ';
						sql_infil=sql_infil || code || '_dt integer having label ''Månad, datumvärde'' format yymmd7. ';
						sql_metaDelFil='create table work.m_' || code || ' as select "values",  cast("values" as varchar(' || maxLengthValues || ')) as ' ||code || '_cd,
							mdy(1,cast(substr("values",6,2) as integer),cast(substr("values",1,4) as integer)) as ' || code || '_dt from work.' || metaFilnamn || ' where code=''' || code || '''';
						sqlexec(sql_metaDelFil);
						sqlSelect = sqlSelect || 't' || t || '.' || code || '_cd, t' || t || '.' || code || '_dt';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t ;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
					else if lowCase(text) in ('kvartal') then do;
						sql_infil=sql_infil || code || '_cd varchar(' || maxLengthValues || ') having label ''' || text || ', kod'', ';
						sql_infil=sql_infil || code || '_dt integer having label ''Kvartal, datumvärde'' format yyqd6. ';
						sql_metaDelFil='create table work.m_' || code || ' as select "values",  cast("values" as varchar(' || maxLengthValues || ')) as ' ||code || '_cd,
							mdy(cast(substr("values",6,1) as integer)*3-2,1,cast(substr("values",1,4) as integer)) as ' || code || '_dt from work.' || metaFilnamn || ' where code=''' || code || '''';
						sqlexec(sql_metaDelFil);
						sqlSelect = sqlSelect || 't' || t || '.' || code || '_cd, t' || t || '.' || code || '_dt';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t ;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
 					else do;
						sql_infil=sql_infil || code || '_cd varchar(' || maxLengthValues || ') having label ''' || text || ', kod'', ';
						sql_infil=sql_infil || code || '_nm varchar(' || maxLengthValueTexts || ') having label ''' || text || ', text''';				
						sqlSelect = sqlSelect || 't' || t  || '.' || code || '_cd, t' || t || '.' || code || '_nm';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
				end;
				else do;
					if lowCase(code) in ('kon' 'kön') then do;
						sql_infil=sql_infil || code || '_cd varchar(' || maxLengthValues || ') having label ''' || text || ', 1=män, 2=kvinnor'', ';
						sql_metaDelFil='create table work.m_' || code || ' as select "values",  cast("values" as varchar(' || maxLengthValues || ')) as ' ||code || '_cd, cast(valueTexts as varchar(' || maxLengthValueTexts || ')) as 
								' || code || '_nm from work.' || metaFilnamn || ' where code=''' || code || '''';
						sqlexec(sql_metaDelFil);
						sqlSelect = sqlSelect || 't' || t || '.' || code || '_cd, t' || t || '.' || code || '_nm';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t ;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
					else if lowCase(code) in ('alder' 'ålder') and maxLengthValues <5 then do;
						sql_infil=sql_infil || code || '_cd integer having label ''' || text || ', numeriskt'', ';
						sql_metaDelFil='create table work.m_' || code || ' as select "values", (case when strip("values") = ''tot'' then 999
								when substr("values",1,1)=''-'' then cast(substr("values",2,2) as integer) when substr("values",3,1)=''+'' then cast(substr("values",1,2) as integer) 
									else cast(substr("values",1,3) as integer) end) as ' ||code || '_cd, cast(valueTexts as varchar(' || maxLengthValueTexts || ')) as 
								' || code || '_nm from work.' || metaFilnamn || ' where code=''' || code || '''';
						sqlexec(sql_metaDelFil);
						sqlSelect = sqlSelect || 't' || t || '.' || code || '_cd, t' || t || '.' || code || '_nm';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t ;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
					else do;
						sql_infil=sql_infil || code || '_cd varchar(' || maxLengthValues || ') having label ''' || text || ', kod'', ';
						sql_metaDelFil='create table work.m_' || code || ' as select "values",  cast("values" as varchar(' || maxLengthValues || ')) as ' ||code || '_cd, cast(valueTexts as varchar(' || maxLengthValueTexts || ')) as 
								' || code || '_nm from work.' || metaFilnamn || ' where code=''' || code || '''';
						sqlexec(sql_metaDelFil);
						sqlSelect = sqlSelect || 't' || t || '.' || code || '_cd, t' || t || '.' || code || '_nm';
						sqlFrom = sqlFrom || ' work.m_' || code || ' t' || t ;
						sqlWhere = sqlWhere || 't0.' || code || ' = t' || t || '.values';
					end;
					sql_infil=sql_infil || code || '_nm varchar(' || maxLengthValueTexts || ') having label ''' || text || ', text''';
				end;
			end;*variabler;
			hi_ContentsCode.first([values valueTexts]);
			do until(hi_ContentsCode.next([values valueTexts]));
				if anydigit(values)=1 then values = 'x' || values;
					values=transtrn(values,'!','z1');
					values=transtrn(values,'£','z3');
					values=transtrn(values,'$','z4');
					values=transtrn(values,'~','z5');
					values=transtrn(values,'§','z6');
				sql_infil=sql_infil || ', ' || values || ' double having label ''' || valueTexts || '''';
				sqlSelect=sqlSelect || ', t0.' || values;
			end;*ContentsCode;
			sql_infil=sql_infil || ', uppdaterat_dttm datetime having label ''Tidpunkten när raden uppdaterades, mest för interna referenser'' format datetime16.)';

			sqlSelect=sqlSelect || ', datetime() AS uppdaterat_dttm';
			sqlWhere=sqlWhere || ')';
			sqlexec('CREATE TABLE WORK.' || inFilnamn  || ' AS ' || sqlSelect || sqlFrom || sqlWhere); 
			sqlexec('drop table work.' || iTabell);
			if nytta.finnsTabell(iLib, iTabell) = 0 then sqlexec(sql_infil);
			
			sqlexec('insert into work.' || iTabell || ' select * from WORK.' || inFilnamn);

		end;*createInfil;

		method cleanUp(varchar(8) iLib, varchar(32) iTabell);
			declare integer filFinns;
			declare varchar(100) raderaFil metaFilnamn metaTabell;
			metaFilnamn='meta_' || iTabell;
			metaTabell='meta_' || iTabell;
			if iLib ^= 'work' or iTabell ^= iTabell then do;
				if nytta.finnsTabell('work', iTabell)=1 then sqlexec('drop table work.' || iTabell);
			end;
			if iLib ^= 'work' or metaFilnamn ^= metaTabell then do;
				if nytta.finnsTabell('work', 'meta_' || iTabell)=1 then sqlexec('drop table work.meta_' || iTabell);
			end;
			if nytta.finnsTabell('work', iTabell || '_in')=1 then sqlexec('drop table work.' || iTabell || '_in');
			hi_variables.first([titel code text tid maxLengthValues maxLengthValueTexts]);
			do until(hi_variables.next([titel code text tid maxLengthValues maxLengthValueTexts]));
				raderaFil='m_' || code;
				if nytta.finnsTabell('work', raderaFil)=1 then sqlexec('drop table work.' || raderaFil);
			end;

		end;

	endpackage;
run;quit;			
