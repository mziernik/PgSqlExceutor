CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "hstore";

--drop schema IF  EXISTS scenario cascade;

CREATE SCHEMA IF NOT EXISTS scenario;



--------------------------------------------------------------------------------



CREATE TABLE scenario.function 
(
	id 		VARCHAR(100) PRIMARY KEY,
	name 		VARCHAR(300) NOT NULL UNIQUE,
	created 	TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	created_by 	INTEGER NOT NULL REFERENCES users.users(id),
	last_modified 	TIMESTAMP WITHOUT TIME ZONE ,
	last_modified_by INTEGER REFERENCES users.users(id),
	functions 	INTEGER[],  -- jeśli functions <> null znaczy to, ze funkcja jest blokiem. Wszystkie wejścia i wyjścia powinny mieć powiązanie z funkcjami z tablicy
	embedded 	BOOLEAN NOT NULL -- funkcja wbudowana/użytkownika

);

CREATE TABLE scenario.input
(
	id 		VARCHAR(100),
	function 	VARCHAR(100) NOT NULL REFERENCES scenario.function (id),
	name 		VARCHAR(300) NOT NULL UNIQUE,
	description 	TEXT,
	PRIMARY KEY (id, function)
);


CREATE TABLE scenario.output
(
	id 		VARCHAR(100) ,
	function 	VARCHAR(100) NOT NULL REFERENCES scenario.function (id),
	name 		VARCHAR(300) NOT NULL UNIQUE,
	description 	TEXT,
	positive 	BOOLEAN NOT NULL,
	PRIMARY KEY (id, function)
);

CREATE TABLE scenario.data_type
(
	id 		VARCHAR(100) NOT NULL PRIMARY KEY,
	class 		VARCHAR(300) NOT NULL,	-- klasa javy
	is_array 	BOOLEAN NOT NULL DEFAULT false,
	min 		INTEGER, 	-- wartność minimalna dla typu numerycznego, lub minimalna długość tekstu
	max 		INTEGER,	-- wartność maksymalna dla typu numerycznego, lub maksymalna długość tekstu
	default_value 	JSON	-- zapis w formacie JSON
);

CREATE TABLE scenario.property
(
	id 		VARCHAR(100),
	function 	VARCHAR(100) NOT NULL REFERENCES scenario.function (id),
	type 		VARCHAR(100) NOT NULL REFERENCES scenario.data_type (id),
	name 		VARCHAR(300) NOT NULL UNIQUE,
	description 	TEXT,	
	default_value 	JSON,
	value 		JSON,
	required 	BOOLEAN NOT NULL,
	PRIMARY KEY (id, function)
);

CREATE TABLE scenario.variable
(
	id 		VARCHAR(100),
	function 	VARCHAR(100) NOT NULL REFERENCES scenario.function (id),
	type 		VARCHAR(100) NOT NULL REFERENCES scenario.data_type (id),
	name 		VARCHAR(300) NOT NULL UNIQUE,
	description 	TEXT,
	PRIMARY KEY (id, function)
);

-------------------------------------------------------------------------------------------------

CREATE TABLE scenario.scenario 
(
	id 		VARCHAR(100) PRIMARY KEY,
	name 		VARCHAR(300) NOT NULL UNIQUE,
	enabled 	BOOLEAN NOT NULL DEFAULT true,
	created 	TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	created_by 	INTEGER NOT NULL REFERENCES users.users(id),
	last_modified 	TIMESTAMP WITHOUT TIME ZONE ,
	last_modified_by INTEGER REFERENCES users.users(id),	
	priority 	NUMERIC NOT NULL DEFAULT 0,
	number 		VARCHAR(50) NOT NULL , -- docelowy numer telefonu
	notes 		TEXT, -- notatki użytkownika
	ui_properties 	HSTORE NOT NULL DEFAULT ''
);

CREATE TABLE scenario.scenario_function
(
	id 		SERIAL PRIMARY KEY,
	scenario 	VARCHAR(100) NOT NULL REFERENCES scenario.scenario (id),
	function 	VARCHAR(100) NOT NULL REFERENCES scenario.function (id),
	created 	TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	ui_properties 	HSTORE NOT NULL DEFAULT ''

)

