CREATE SCHEMA IF NOT EXISTS audita;

CREATE TABLE IF NOT EXISTS audita.user_audit (
    user_id plugin.id_type PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    delete_at TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION audita.set_create_timestamp()
RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO audita.user_audit (user_id) VALUES (NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audita.set_update_timestamp()
RETURNS TRIGGER
AS $$
BEGIN
    UPDATE audita.user_audit SET updated_at = NOW()
    WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audita.set_delete_timestamp()
RETURNS TRIGGER 
AS $$
BEGIN
    UPDATE audita.user_audit SET delete_at = NOW()
    WHERE user_id = OLD.user_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_create_trigger
AFTER INSERT ON plugin.users
FOR EACH ROW
EXECUTE PROCEDURE audita.set_create_timestamp();

CREATE TRIGGER set_update_trigger
AFTER UPDATE ON plugin.users
FOR EACH ROW
EXECUTE PROCEDURE audita.set_update_timestamp();

CREATE TRIGGER set_delete_trigger
AFTER DELETE ON plugin.users
FOR EACH ROW
EXECUTE PROCEDURE audita.set_delete_timestamp();