CREATE SCHEMA IF NOT EXISTS tflow;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    CREATE DOMAIN tflow.id_type UUID;
    CREATE DOMAIN tflow.bait_score DECIMAL;
    CREATE DOMAIN tflow.link_type VARCHAR(300);
    CREATE TYPE tflow.link_score AS (
        link tflow.link_type,
        score tflow.bait_score
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE OR REPLACE FUNCTION tflow.id()
RETURNS tflow.id_type
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN uuid_generate_v4();
END;
$$;

CREATE TABLE IF NOT EXISTS tflow.link (
    link_id tflow.id_type PRIMARY KEY,
    link tflow.link_type UNIQUE NOT NULL,
    count BIGINT CHECK (count >= 0) DEFAULT 0,
    last_clicked TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tflow.link_predictions (
    link_id tflow.id_type PRIMARY KEY,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    bScore tflow.bait_score DEFAULT 0.0 NOT NULL,
    bScoreUpdated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    bScore_last tflow.bait_score DEFAULT 0.0 NOT NULL,
    FOREIGN KEY (link_id) REFERENCES tflow.link (link_id) ON DELETE CASCADE
);

CREATE OR REPLACE PROCEDURE tflow.insert_link(
    link_p tflow.link_type,
    score_p tflow.bait_score 
)
LANGUAGE plpgsql
AS $$
    DECLARE ident tflow.id_type := tflow.id();
BEGIN
    WITH returnR AS (
        INSERT INTO tflow.link ( link_id, link, count ) VALUES (ident, link_p, 1 )
        ON CONFLICT (link) DO UPDATE SET
        count = tflow.link.count + 1
        RETURNING tflow.link.link_id
    )
    SELECT COALESCE((SELECT link_id FROM returnR), ident) INTO ident;

    INSERT INTO tflow.link_predictions (link_id, bScore) VALUES (ident, score_p) 
    ON CONFLICT (link_id) DO UPDATE SET bScore = score_p
    WHERE NOT link_predictions.verified;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE tflow.insert_links(
    links_p tflow.link_type[],
    bScores_p tflow.bait_score[]
)
LANGUAGE plpgsql
AS $$
DECLARE 
    linkF tflow.link_type;
    ident tflow.id_type := tflow.id();
    iterator INTEGER := 0;
BEGIN
    IF cardinality(bScores_p) = cardinality(links_p) THEN
        FOREACH linkF IN ARRAY links_p
        LOOP
            iterator := iterator + 1;
            ident := tflow.id();
            WITH returnL AS (
                INSERT INTO tflow.link ( link_id, link) 
                VALUES (ident, linkF)
                ON CONFLICT (link) DO UPDATE SET link=EXCLUDED.link
                RETURNING tflow.link.link_id
            )
            SELECT COALESCE((SELECT link_id FROM returnL), ident) INTO ident;

            INSERT INTO tflow.link_predictions ( link_id, bScore)
            VALUES (ident, bScores_p[iterator]) ON CONFLICT (link_id)
            DO UPDATE SET bScore = bScores_p[iterator]
            WHERE NOT link_predictions.verified;
        END LOOP;
    END IF;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE FUNCTION tflow.link_predictions_updated()
RETURNS TRIGGER 
AS $$
BEGIN
    UPDATE tflow.link_predictions
    SET bScoreUpdated = NOW(), bScore_last = OLD.bScore
    WHERE link_id = NEW.link_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_last_link_predictions_updated
AFTER UPDATE OF bScore ON tflow.link_predictions
FOR EACH ROW 
EXECUTE PROCEDURE tflow.link_predictions_updated();


CREATE OR REPLACE PROCEDURE tflow.update_link_predictions(
    link_p tflow.link_type,
    bScore_p tflow.bait_score,
    verified_p BOOLEAN DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE tflow.link_predictions AS p
    SET bScore = bScore_p, verified = COALESCE(verified_p, p.verified)
    FROM tflow.link AS l 
    WHERE l.link_id = p.link_id AND l.link = link_p AND NOT p.verified;
END;
$$;

CREATE OR REPLACE FUNCTION tflow.get_unscored_link(
    just_one BOOLEAN DEFAULT FALSE
)
RETURNS SETOF tflow.link_score
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT link, bscore AS score FROM tflow.link_predictions 
    JOIN tflow.link USING (link_id)
    WHERE verified = FALSE LIMIT CASE WHEN just_one THEN 1 END;
END;
$$;