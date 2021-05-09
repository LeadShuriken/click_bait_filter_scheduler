CREATE OR REPLACE FUNCTION plugin.link_predictions_updated()
RETURNS TRIGGER 
AS $$
BEGIN
    UPDATE plugin.link_predictions SET bScoreUpdated = NOW()
    WHERE link_id = NEW.link_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_last_link_predictions_updated
AFTER UPDATE OF bScore ON plugin.link_predictions
FOR EACH ROW 
EXECUTE PROCEDURE plugin.link_predictions_updated();

CREATE OR REPLACE FUNCTION plugin.link_last_clicked()
RETURNS TRIGGER 
AS $$
BEGIN
    UPDATE plugin.link SET last_clicked = NOW()
    WHERE link_id = NEW.link_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_last_clicked_trigger 
AFTER UPDATE OF count ON plugin.link
FOR EACH ROW 
EXECUTE PROCEDURE plugin.link_last_clicked();