CREATE TABLE STATION
(
idstation integer constraint pk_Station PRIMARY KEY,
secteur varchar2(20) constraint val_stationsecteurss CHECK (secteur IN ('Centre', 'NO', 'NE', 'SE' , 'SO')),
etat varchar2(10) constraint val_stationeta CHECK (etat IN ('Ouvert', 'Ferme')),
nbattache integer not null,
bonus integer constraint val_bonus CHECK (bonus IN (1, 0))
);

CREATE TABLE VELO
(
idvelo integer constraint pk_Velo PRIMARY KEY,
idstation integer constraint fk_Velo_Station REFERENCES STATION(idstation),
etat varchar2(20) constraint val_velo CHECK (etat IN ('aquai', 'reparation', 'utilisation'))
);

CREATE TABLE ATTACHE
(
idattache integer not null,
idvelo integer REFERENCES VELO(idvelo),
idstation integer constraint fk_Attache_Station REFERENCES STATION(idstation) on delete cascade,
voyant varchar(10) constraint val_voyant CHECK (voyant IN ('vert', 'rouge', 'eteint')),
constraint key_attache_station UNIQUE (idstation,idattache)
);

CREATE TABLE BORNE
(
idborne integer constraint pk_Velo_Borne PRIMARY KEY,
idstation integer constraint fk_borne_Station REFERENCES STATION(idstation) on delete cascade
);

CREATE TABLE UTILISATEUR
(
idUtilisateur integer constraint pk_Utilisateur PRIMARY KEY,
nom varchar2(25) not null,
prenom varchar2(15) not null,
solde number(6,2),
daten DATE not null
);

CREATE TABLE ABONNEMENT
(
idabonnement integer constraint pk_Abonnement PRIMARY KEY,
prix number(6,2) not null,
duree number(5,2) not null,
description varchar(200) not null
);

CREATE TABLE SOUSCRIPTION
(
idutilisateur integer constraint fk_Souscription_Utilisateur REFERENCES UTILISATEUR(idutilisateur),
idabonnement integer constraint fk_Souscription_Abonnement REFERENCES ABONNEMENT(idabonnement),
dateouv date,
datefin date
);


CREATE TABLE LOCATION	
(
idlocation integer constraint pk_Velo_location PRIMARY KEY,
idvelo integer constraint fk_idvelo_location REFERENCES VELO(idvelo),
idutilisateur integer constraint fk_iduser_location REFERENCES UTILISATEUR(idutilisateur),
dated DATE not null,
datef DATE,
idstationdepart integer not null constraint fk_idstationdepart_location REFERENCES STATION(idstation),
idstationarrive integer constraint fk_idstationarrive_location REFERENCES STATION(idstation),
prix number(5,2)
);

CREATE TABLE CAMIONNETTE
(
idcamionnette integer constraint pk_Camionnette PRIMARY KEY,
nbvelomax integer not null
);

CREATE TABLE VOYAGE
(
idvoyage integer constraint pk_Voyage PRIMARY KEY,
idcamionnette integer not null constraint fk_voyage_camionnette REFERENCES CAMIONNETTE(idcamionnette),
datevoyage DATE not null,
idstationdepart integer not null constraint fk_voyage_stationdep REFERENCES STATION(idstation),
idstationarrive integer not null constraint fk_voyage_stationarr REFERENCES STATION(idstation)
);

CREATE TABLE VELOVOYAGE
(
idvelo integer not null constraint fk_velovoyage_velo REFERENCES VELO(idvelo),
idvoyage integer not null constraint fk_velovoyage_voyage REFERENCES VOYAGE(idvoyage),
constraint key_velo_voyage UNIQUE (idvoyage,idvelo)
);

-------------------------------------	----------


CREATE OR REPLACE VIEW ABONNEMENTUTILISATEUR
AS SELECT DISTINCT UTILISATEUR.nom, UTILISATEUR.prenom, ABONNEMENT.prix, SOUSCRIPTION.dateouv, SOUSCRIPTION.datefin
FROM ABONNEMENT,UTILISATEUR, SOUSCRIPTION
WHERE ABONNEMENT.idabonnement = SOUSCRIPTION.idabonnement and SOUSCRIPTION.idutilisateur=UTILISATEUR.idutilisateur
WITH READ ONLY;

CREATE OR REPLACE VIEW LOCATIONUTILISATEUR
AS SELECT DISTINCT UTILISATEUR.idutilisateur, UTILISATEUR.nom, UTILISATEUR.prenom, LOCATION.idlocation, LOCATION.idvelo, LOCATION.dated, LOCATION.datef, LOCATION.prix
FROM UTILISATEUR, LOCATION
WHERE LOCATION.idutilisateur=UTILISATEUR.idutilisateur
WITH READ ONLY;
		
CREATE OR REPLACE VIEW LOCATIONSTATION
AS SELECT LOCATION.idstationdepart, COUNT(LOCATION.idlocation) AS nbLocation
FROM LOCATION
GROUP BY LOCATION.idstationdepart
order by LOCATION.idstationdepart
WITH READ ONLY;
		
create or replace view VELOAQUAI
AS SELECT VELO.idstation, COUNT(VELO.idstation) as nbvelo
FROM VELO,STATION
WHERE etat = 'aquai'
group by VELO.idstation
order by VELO.idstation
WITH READ ONLY;

create or replace view TRANSPORTEUR
AS SELECT VELO.idstation, COUNT(VELO.idstation) as nbvelo, (SELECT Count(ATTACHE.idstation) FROM ATTACHE WHERE ATTACHE.idstation = VELO.idstation AND ATTACHE.voyant = 'eteint' GROUP BY idstation) as pd
FROM VELO
WHERE etat = 'aquai'
group by VELO.idstation
order by VELO.idstation
WITH READ ONLY;

create or replace view TEMP_SOUSCRIPTION
AS SELECT *
FROM SOUSCRIPTION;


SELECT idstation, COUNT(*)
FROM VELO
WHERE etat = 'aquai'
group by idstation
order by idstation;

--		create or replace view nbLocationUtil
--AS SELECT numeroU, stationD, COUNT(numeroU) Nb FROM Location L GROUP BY numeroU, stationD;
-------------------------------------------------

CREATE OR REPLACE TRIGGER TUI_VELO
BEFORE INSERT OR UPDATE
ON VELO
FOR EACH ROW
WHEN (NEW.etat='reparation' OR NEW.etat='utilisation')
BEGIN
	IF :NEW.idstation IS NOT NULL THEN RAISE_APPLICATION_ERROR(-20001,'Etat incompatible avec la mise à quai');
	END IF;
END;
/

CREATE OR REPLACE TRIGGER TUI_STATION_FERME
BEFORE INSERT OR UPDATE
ON VELO
FOR EACH ROW
DECLARE
	etatStation STATION.etat%TYPE;
BEGIN
	IF (:NEW.idstation IS NOT NULL) THEN
		SELECT etat INTO etatStation FROM STATION WHERE STATION.idstation=:NEW.idstation;
		IF etatStation='Ferme' THEN RAISE_APPLICATION_ERROR(-20002,'Station fermé');
		END IF;
	END IF;
END;
/

CREATE OR REPLACE TRIGGER TUI_VELO_ATTACHE
BEFORE INSERT OR UPDATE
ON ATTACHE
FOR EACH ROW
DECLARE
	idS VELO.idvelo%TYPE;
BEGIN
	IF (:NEW.idvelo IS NOT NULL) THEN
		IF (:NEW.idStation IS NOT NULL) THEN
			SELECT idstation INTO idS FROM VELO WHERE VELO.idvelo=:NEW.idvelo;
			IF :NEW.idstation<>idS THEN RAISE_APPLICATION_ERROR(-20006,'L attache n appartient pas à la même station que le vélo');
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(-20005,'Attache utilisé sans station');
		END IF;
	END IF;
END;
/

CREATE OR REPLACE TRIGGER TUI_ATTACHE
BEFORE INSERT OR UPDATE
ON ATTACHE
FOR EACH ROW
WHEN (NEW.voyant='rouge')
BEGIN
	IF :NEW.idvelo IS NOT NULL THEN RAISE_APPLICATION_ERROR(-20003,'Impossible d attacher le vélo');
	END IF;
END;
/

CREATE OR REPLACE TRIGGER TI_ATTACHE
AFTER INSERT
ON ATTACHE
FOR EACH ROW
DECLARE
	nbA integer;
BEGIN
	SELECT COUNT(*) INTO nbA FROM ATTACHE WHERE ATTACHE.idstation=:NEW.idstation;
	UPDATE STATION SET nbattache=nbA WHERE STATION.idstation=:NEW.idstation;
END;
/

CREATE OR REPLACE TRIGGER TD_ATTACHE
AFTER DELETE
ON ATTACHE
FOR EACH ROW
DECLARE
	nbA integer;
BEGIN
    SELECT COUNT(*) INTO nbA FROM ATTACHE WHERE ATTACHE.idstation=:OLD.idstation;
	UPDATE STATION SET nbattache=nbA WHERE STATION.idstation=:OLD.idstation;
END;
/

CREATE OR REPLACE TRIGGER TI_LOCATION
BEFORE INSERT
ON LOCATION
FOR EACH ROW
DECLARE
	etatStation STATION.etat%TYPE;
BEGIN
	SELECT etat INTO etatStation FROM STATION WHERE STATION.idstation=:NEW.idstationdepart;
	IF etatStation='Ferme' THEN RAISE_APPLICATION_ERROR(-20002,'Station fermé');
	END IF;
END;
/

CREATE OR REPLACE TRIGGER TI_SOUSCRIPTION
INSTEAD OF INSERT
ON TEMP_SOUSCRIPTION
FOR EACH ROW
DECLARE
	dateF date;
BEGIN
	dateF := :NEW.dateouv + 365;
	INSERT INTO SOUSCRIPTION VALUES (:NEW.idutilisateur,:NEW.idabonnement,:NEW.dateouv,dateF);
END;
/

CREATE OR REPLACE PROCEDURE fermeStation(idS in integer)
IS
BEGIN
	UPDATE STATION SET etat='Ferme' WHERE STATION.idstation=idS;
	UPDATE ATTACHE SET voyant='rouge' WHERE ATTACHE.idstation=idS;
END;
/


CREATE OR REPLACE PROCEDURE callconseiller(idU in integer)
IS
BEGIN
	UPDATE STATION SET etat='Ferme' WHERE STATION.idstation=idS;
	UPDATE ATTACHE SET voyant='rouge' WHERE ATTACHE.idstation=idS;
END;
/

CREATE OR REPLACE PROCEDURE louerVelo(idV in integer, idU in integer)
IS
	idS VELO.idStation%TYPE;
	idL LOCATION.idLocation%TYPE;
	dateActuel VARCHAR2(20);
BEGIN
	SELECT idStation INTO idS FROM VELO WHERE idVelo=idV;
	UPDATE ATTACHE SET idVelo=NULL, voyant='eteint' WHERE idVelo=idV;
	SELECT MAX(idLocation)+1 INTO idL FROM LOCATION;
	SELECT TO_CHAR(SYSDATE,'DD-MM-YYYY HH24:MI') INTO dateActuel FROM DUAL;
	INSERT INTO LOCATION VALUES (idL,idV,idU,TO_DATE(dateActuel,'DD-MM-YYYY HH24:MI'),NULL,idS,NULL,NULL);
	UPDATE VELO SET idStation=null, etat='utilisation' WHERE idVelo=idV;
END;
/

CREATE OR REPLACE PROCEDURE deposeVelo(idL in integer, idS in integer)
IS
	nbAttachesDispo integer;
	tempLocation integer;
	prixLocation LOCATION.prix%TYPE;
	idV LOCATION.idVelo%TYPE;
	idU LOCATION.idutilisateur%TYPE;
BEGIN
	SELECT idVelo INTO idV FROM LOCATION WHERE idLocation=idL;
	SELECT idutilisateur INTO idU FROM LOCATION WHERE idLocation=idL;
	SELECT COUNT(*) INTO nbAttachesDispo FROM ATTACHE WHERE idStation=idS AND voyant='eteint';
	IF (nbAttachesDispo>0) THEN
		UPDATE ATTACHE SET idVelo=(SELECT idVelo FROM LOCATION WHERE idLocation=idL), voyant='vert' WHERE idAttache=(SELECT * FROM (SELECT idAttache FROM ATTACHE WHERE idStation=idS AND voyant='eteint') WHERE rownum <= 1);
		UPDATE VELO SET idStation=idS, etat='aquai' WHERE idVelo=idV;
		UPDATE LOCATION SET datef=SYSDATE, idStationArrive=idS WHERE idVelo=idV AND idutilisateur=idU;
		SELECT ((TO_DATE(TO_CHAR(datef,'DD-MM-YYYY HH24:MI'), 'DD-MM-YYYY HH24:MI') - TO_DATE(TO_CHAR(dated,'DD-MM-YYYY HH24:MI'), 'DD-MM-YYYY HH24:MI')) * 24 * 60) INTO tempLocation FROM LOCATION WHERE idLocation=idL;
		IF (tempLocation<=30) THEN
			prixLocation := 0;
		ELSIF (tempLocation<=60) THEN
			prixLocation := 1;
		ELSIF (tempLocation<=90) THEN
			prixLocation := 3;
		ELSIF (tempLocation<1440) THEN
			prixLocation := FLOOR(tempLocation/30)*4-9;
		ELSE
			prixLocation := FLOOR(tempLocation/30)*4+141;
		END IF;
		UPDATE LOCATION SET prix=prixLocation WHERE idLocation=idL;
	ELSE
		RAISE_APPLICATION_ERROR(-20010,'Pas de place dans la station');
	END IF;
END;
/

-------------------------------------------------
 
insert into STATION values (0001,'Centre','Ouvert',5,1);
insert into STATION values (0002,'NO','Ouvert',10,1);
insert into STATION values (0003,'NE','Ouvert',10,0);
insert into STATION values (0004,'SE','Ouvert',5,0);
insert into STATION values (0005,'SO','Ferme',10,0);

-------------------------------------------------

insert into BORNE values (0001,0001);
insert into BORNE values (0002,0002);
insert into BORNE values (0003,0003);
insert into BORNE values (0004,0004);
-------------------------------------------------

--4/5 velo station 1
insert into VELO values (0001,0001,'aquai'); 
insert into VELO values (0002,0001,'aquai');
insert into VELO values (0003,0001,'aquai');
insert into VELO values (0004,0001,'aquai');

--10/10 velo station 2
insert into VELO values (0005,0002,'aquai');
insert into VELO values (0006,0002,'aquai');
insert into VELO values (0007,0002,'aquai');
insert into VELO values (0008,0002,'aquai');
insert into VELO values (0009,0002,'aquai');
insert into VELO values (0010,0002,'aquai');
insert into VELO values (0011,0002,'aquai');
insert into VELO values (0012,0002,'aquai');
insert into VELO values (0013,0002,'aquai');
insert into VELO values (0014,0002,'aquai');

--5/10 velo station 3
insert into VELO values (0015,0003,'aquai');
insert into VELO values (0016,0003,'aquai');
insert into VELO values (0017,0003,'aquai');
insert into VELO values (0018,0003,'aquai');
insert into VELO values (0019,0003,'aquai');

--1/5 velo station 4
insert into VELO values (0020,0004,'aquai');

--3/10 velo station 5
insert into VELO values (0021,0005,'aquai');
insert into VELO values (0022,0005,'aquai');
insert into VELO values (0023,0005,'aquai');

--7 velo hors station
insert into VELO values (0024,null,'utilisation');
insert into VELO values (0025,null,'utilisation');
insert into VELO values (0026,null,'utilisation');
insert into VELO values (0027,null,'utilisation');
insert into VELO values (0028,null,'utilisation');
insert into VELO values (0029,null,'reparation');
insert into VELO values (0030,null,'reparation');

-----------------------------------------------------

insert into attache values (0001,0001,0001,'vert');
insert into attache values (0002,0002,0001,'vert');
insert into attache values (0003,0003,0001,'vert');
insert into attache values (0004,0004,0001,'vert');
insert into attache values (0005,null,0001,'rouge');

insert into attache values (0006,0005,0002,'vert');
insert into attache values (0007,0006,0002,'vert');
insert into attache values (0008,0007,0002,'vert');
insert into attache values (0009,0008,0002,'vert');
insert into attache values (0010,0009,0002,'vert');
insert into attache values (0011,0010,0002,'vert');
insert into attache values (0012,0011,0002,'vert');
insert into attache values (0013,0012,0002,'vert');
insert into attache values (0014,0013,0002,'vert');
insert into attache values (0015,0014,0002,'vert');

insert into attache values (0016,0015,0003,'vert');
insert into attache values (0017,0016,0003,'vert');
insert into attache values (0018,0017,0003,'vert');
insert into attache values (0019,0018,0003,'vert');
insert into attache values (0020,0019,0003,'vert');
insert into attache values (0021,null,0003,'rouge');
insert into attache values (0022,null,0003,'eteint');
insert into attache values (0023,null,0003,'eteint');
insert into attache values (0024,null,0003,'eteint');
insert into attache values (0025,null,0003,'eteint');

insert into attache values (0026,0020,0004,'vert');
insert into attache values (0027,null,0004,'eteint');
insert into attache values (0028,null,0004,'eteint');
insert into attache values (0029,null,0004,'eteint');
insert into attache values (0030,null,0004,'eteint');

insert into attache values (0031,null,0005,'rouge');
insert into attache values (0032,null,0005,'rouge');
insert into attache values (0033,null,0005,'rouge');
insert into attache values (0034,null,0005,'rouge');
insert into attache values (0035,null,0005,'rouge');

-----------------------------------------------------

insert into UTILISATEUR values (0001,'Lolo','Chatbrion',50.00,TO_DATE('2000-01-01','YYYY-MM-DD'));
insert into UTILISATEUR values (0002,'Jean','Peuplu',50.00,TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into UTILISATEUR values (0003,'Bernard','Tapis',500.00,TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into UTILISATEUR values (0004,'Michel','Sardou',3.00,TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into UTILISATEUR values (0005,'Bertrand','Renard',100.00,TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into UTILISATEUR values (0006,'joeny','alidl',100.00,TO_DATE('1990-01-01','YYYY-MM-DD'));

-----------------------------------------------------

insert into ABONNEMENT values (0001,30,365,'Annuel');
insert into ABONNEMENT values (0002,3,30,'Mensuel');
insert into ABONNEMENT values (0003,15,365,'16-25 annuel');

-----------------------------------------------------

insert into TEMP_SOUSCRIPTION values (0001,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into TEMP_SOUSCRIPTION values (0002,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into TEMP_SOUSCRIPTION values (0003,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into TEMP_SOUSCRIPTION values (0004,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1990-01-01','YYYY-MM-DD'));
insert into TEMP_SOUSCRIPTION values (0005,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1990-01-01','YYYY-MM-DD'));

-----------------------------------------------------

insert into CAMIONNETTE values (0001,30);
insert into CAMIONNETTE values (0002,40);
insert into CAMIONNETTE values (0003,50);

-----------------------------------------------------

insert into LOCATION values (0001,0005,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1998-01-01','YYYY-MM-DD'),0001,0003,1);
insert into LOCATION values (0002,0005,0002,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1998-01-01','YYYY-MM-DD'),0001,0002,7);
insert into LOCATION values (0003,0005,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1998-01-01','YYYY-MM-DD'),0003,0002,3);
insert into LOCATION values (0004,0005,0003,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1998-01-01','YYYY-MM-DD'),0004,0003,1);
insert into LOCATION values (0005,0005,0001,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1998-01-01','YYYY-MM-DD'),0002,0002,7);
insert into LOCATION values (0006,0005,0005,TO_DATE('1990-01-01','YYYY-MM-DD'),TO_DATE('1998-01-01','YYYY-MM-DD'),0003,0002,3);
insert into LOCATION values (0007,0005,0005,TO_DATE('15-12-2017 12:30','DD-MM-YYYY HH24:MI'),TO_DATE('15-12-2017 17:30','DD-MM-YYYY HH24:MI'),0003,0002,3);

-----------------------------------------------------
























