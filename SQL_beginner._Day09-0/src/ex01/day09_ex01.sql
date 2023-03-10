CREATE OR REPLACE FUNCTION fnc_trg_person_update_audit() RETURNS trigger AS $trg_person_update_audit$
    BEGIN
        INSERT INTO person_audit (created, type_event, row_id, name, age, gender, address)
                SELECT now(), 'U', OLD.*;
        RETURN NULL;
    END;
$trg_person_update_audit$ LANGUAGE plpgsql;

CREATE TRIGGER trg_person_update_audit AFTER UPDATE ON person
    FOR EACH ROW EXECUTE FUNCTION fnc_trg_person_update_audit();

UPDATE person SET name = 'Bulat' WHERE id = 10;