CREATE TABLE IF NOT EXISTS plugin.link (
    link_id plugin.id_type PRIMARY KEY,
    domain_id plugin.id_type NOT NULL,
    link plugin.link_type UNIQUE NOT NULL,
    count BIGINT CHECK (count >= 0) DEFAULT 0,
    last_clicked TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (domain_id) REFERENCES plugin.domain (domain_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plugin.link_predictions (
    link_id plugin.id_type PRIMARY KEY,
    bScore plugin.bait_score DEFAULT 0.0 NOT NULL,
    bScoreUpdated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (link_id) REFERENCES plugin.link (link_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plugin.click (
    click_id plugin.id_type DEFAULT plugin.id() PRIMARY KEY,
    link_id plugin.id_type NOT NULL,
    user_id plugin.id_type NOT NULL,
    at_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES plugin.users (user_id) ON DELETE CASCADE,
    FOREIGN KEY (link_id) REFERENCES plugin.link (link_id) ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION plugin.insert_click(
    user_id_p plugin.id_type,
    domain_p plugin.domain_name_type,
    link_p plugin.link_type,
    score_p plugin.bait_score 
)
RETURNS plugin.id_type 
LANGUAGE plpgsql
AS $$
    DECLARE ident plugin.id_type := plugin.id();
BEGIN
    WITH returnR AS (
        INSERT INTO plugin.link ( link_id, link, domain_id, count ) VALUES (ident, link_p, 
            (SELECT domain_id FROM plugin.domain WHERE name = domain_p), 1 )
        ON CONFLICT (link) DO UPDATE SET
        count = plugin.link.count + 1
        RETURNING plugin.link.link_id
    )
    SELECT COALESCE((SELECT link_id FROM returnR), ident) INTO ident;

    INSERT INTO plugin.link_predictions (link_id, bScore) VALUES (ident, score_p) 
    ON CONFLICT (link_id) DO UPDATE SET bScore = score_p;
    INSERT INTO plugin.click (link_id, user_id) VALUES (ident, user_id_p);
    RETURN ident;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE FUNCTION plugin.get_clicks(
    user_id_p plugin.id_type DEFAULT NULL,
    domain_p plugin.domain_name_type DEFAULT NULL
)
RETURNS TABLE (
    user_id plugin.id_type,
    domain plugin.domain_name_type,
    link plugin.link_type,
    at_time TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u_click.user_id,
        u_domain.name as domain,
        u_link.link,
        u_click.at_time
    FROM plugin.click AS u_click 
        INNER JOIN plugin.link AS u_link USING (link_id) 
        INNER JOIN plugin.domain AS u_domain 
        ON u_domain.domain_id = u_link.domain_id
    WHERE (user_id_p IS NULL OR u_click.user_id = user_id_p)
    AND (domain_p IS NULL OR u_domain.name = domain_p);
END;
$$;

CREATE OR REPLACE FUNCTION plugin.get_link(
    just_one BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    link_id plugin.id_type,
    name plugin.link_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT link.link_id, link.link AS name FROM plugin.link
    LIMIT CASE WHEN just_one THEN 1 END;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.remove_link(
    link_id_p plugin.id_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM plugin.link WHERE link_id = link_id_p;
END;
$$;