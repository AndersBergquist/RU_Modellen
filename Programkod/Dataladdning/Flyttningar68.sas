proc  ds2;
	package &prglib..rumprg_SCB_flyttning68 / overwrite=yes;
		declare package &prglib..pxwebtosas3a px68();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url68 ;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_flyttning68();
			url68='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/Flyttningar';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;

		method run();
			declare integer finns;
			px68.getData(url68,maxCeller,datalib, 'SCB_BEFOLKNING', 'AR');
			if nytta.finnsTabell('work','Flyttningar')=1 then do;
				sqlexec('create table work.Flyttningar68X as select cast(tid_cd as integer) as ar, case when region_cd=''00'' then ''Riket'' when length(region_cd)=2 then ''Län'' 
					else ''Kommun'' end as regiontyp, kon_nm as kon,
						(case
							when region_cd=''11'' then ''12''
							when region_cd=''15'' then ''14''
							when region_cd=''16'' then ''14''
							when region_cd=''1504'' then ''1438''
							when region_cd=''1507'' then ''1439''
							when region_cd=''1521'' then ''1440''
							when region_cd=''1524'' then ''1441''
							when region_cd=''1527'' then ''1442''
							when region_cd=''1535'' then ''1443''
							when region_cd=''1602'' then ''1444''
							when region_cd=''1603'' then ''1445''
							when region_cd=''1637'' then ''1446''
							when region_cd=''1643'' then ''1447''
							when region_cd=''1552'' then ''1452''
							when region_cd=''1660'' then ''1460''
							when region_cd=''1561'' then ''1461''
							when region_cd=''1562'' then ''1462''
							when region_cd=''1563'' then ''1463''
							when region_cd=''1565'' then ''1465''
							when region_cd=''1566'' then ''1466''
							when region_cd=''1660'' then ''1470''
							when region_cd=''1661'' then ''1471''
							when region_cd=''1662'' then ''1472''
							when region_cd=''1663'' then ''1473''
							when region_cd=''1580'' then ''1487''
							when region_cd=''1581'' then ''1488''
							when region_cd=''1582'' then ''1489''
							when region_cd=''1583'' then ''1490''
							when region_cd=''1584'' then ''1491''
							when region_cd=''1585'' then ''1492''
							when region_cd=''1680'' then ''1493''
							when region_cd=''1681'' then ''1494''
							when region_cd=''1682'' then ''1495''
							when region_cd=''1683'' then ''1496''
							when region_cd=''1684'' then ''1497''
							when region_cd=''1685'' then ''1498''
							when region_cd=''1686'' then ''1499''
							when region_cd=''1622'' then ''0642''
							when region_cd=''1623'' then ''0643''
							when region_cd=''1121'' then ''1256''
							when region_cd=''1137'' then ''1257''
							when region_cd=''1160'' then ''1270''
							when region_cd=''1162'' then ''1272''
							when region_cd=''1163'' then ''1273''
							when region_cd=''1165'' then ''1275''
							when region_cd=''1166'' then ''1276''
							when region_cd=''1167'' then ''1277''
							when region_cd=''1168'' then ''1278''
							when region_cd=''1180'' then ''1290''
							when region_cd=''1181'' then ''1291''
							when region_cd=''1182'' then ''1292''
							when region_cd=''1183'' then ''1293''
							when region_cd=''1917'' then ''0321''
							else region_cd	end) as region,
							alder_cd as alder, 
							(case when region_cd in (''12'', ''11'') then 0.74*BE0101C7 when region_cd in (''14'', ''15'', ''16'') then 0.63*BE0101C7 else BE0101C7 end) as inrikesInflyttning,
							(case when region_cd in (''12'', ''11'') then 0.70*BE0101C8 when region_cd in (''14'', ''15'', ''16'') then 0.69*BE0101C8 else BE0101C8 end) as inrikesUtflyttning,
							BE0101C3 as invandringar, BE0101C4 as utvandringar
							from work.Flyttningar');
				sqlexec('create table flyttningar68B as select ar, regiontyp, kon, region, alder,
							sum(inrikesInflyttning) as inrikesInflyttning, sum(inrikesUtflyttning) as inrikesUtflyttning,
							sum(invandringar) as invandringar, sum(utvandringar) as utvandringar
							from work.Flyttningar68X
							where alder^=999
							group by ar, regiontyp, kon, region, alder');
				sqlexec('drop table work.Flyttningar68X');
				sqlexec('drop table work.Flyttningar');
				sqlexec('drop table work.meta_Flyttningar');
				sqlexec('drop table ' || datalib || '.meta_SCB_BEFOLKNING');
			end;
		end;

	endpackage;
run;quit;
