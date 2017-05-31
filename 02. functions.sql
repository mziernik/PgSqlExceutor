

CREATE OR REPLACE FUNCTION notNullArgs(arg anyarray) 
RETURNS INTEGER AS $$
-- Zwraca ilość wartości nie NULL-owych z tablicy
DECLARE
	cnt INTEGER = 0;
	str TEXT;
BEGIN
	FOREACH str IN ARRAY arg LOOP
		IF NOT str IS NULL THEN
			cnt := cnt + 1;
		END IF;
	END LOOP;

	RETURN cnt; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION only_one(arg TEXT[]) 
RETURNS BOOLEAN AS $$
/**
	 Funkcja zwaraca wartość pozytywną jeśli dokładnie jeden z elementów tablicy jest różny od null-a.
	 Przykładowe zastosowanie: CREATE TABLE -> dyrektywa CHECK
*/
DECLARE
	cnt INTEGER = 0;
	str TEXT;
BEGIN
	FOREACH str IN ARRAY arg LOOP
		IF NOT str IS NULL THEN
			cnt := cnt + 1;
		END IF;
	END LOOP;

	RETURN cnt = 1; 
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION xor(arg TEXT[]) 
RETURNS BOOLEAN AS $$
/**
	 Funkcja zwaraca wartość pozytywną jeśli wszystkie elementy tablicy są rózne od nulla albo każdy z nich jest nullem.
	 Przykładowe zastosowanie: CREATE TABLE -> dyrektywa CHECK
*/
DECLARE
	cnt INTEGER = 0;
	str TEXT;
BEGIN
	FOREACH str IN ARRAY arg LOOP
		IF NOT str IS NULL THEN
			cnt := cnt + 1;
		END IF;
	END LOOP;

	RETURN cnt = 1; 
END;
$$ LANGUAGE plpgsql;
