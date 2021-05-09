CREATE TABLE IF NOT EXISTS plugin.domain (
    domain_id plugin.id_type DEFAULT plugin.id() PRIMARY KEY,
    name plugin.domain_name_type UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS plugin.tab (
    user_id plugin.id_type NOT NULL,
    domain_id plugin.id_type NOT NULL,
    index INTEGER CHECK (index >= 1),
    PRIMARY KEY (user_id, domain_id, index),
    FOREIGN KEY (user_id) REFERENCES plugin.users (user_id) ON DELETE CASCADE,
    FOREIGN KEY (domain_id) REFERENCES plugin.domain (domain_id) ON DELETE CASCADE
);

CREATE OR REPLACE PROCEDURE plugin.insert_tab(
    tad_id INOUT plugin.id_type, 
    name_p IN plugin.domain_name_type,
    index_p IN INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE ident CONSTANT plugin.id_type := plugin.id();
BEGIN
    DELETE FROM plugin.tab WHERE user_id = tad_id AND index = index_p;
    WITH returnR AS (
        INSERT INTO plugin.domain (domain_id, name) VALUES (ident, name_p)
        ON CONFLICT (name) DO UPDATE SET name=EXCLUDED.name
        RETURNING plugin.domain.domain_id
    )
    INSERT INTO plugin.tab (user_id, domain_id, index) 
    VALUES (tad_id, (SELECT domain_id FROM returnR), index_p);
    tad_id := ident;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE FUNCTION plugin.get_tab_data(
    user_id_p plugin.id_type,
    index_p INTEGER
)
RETURNS TABLE (
    index INTEGER,
    name plugin.domain_name_type,
    links plugin.link_score[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        tab.index, domain.name,
        ARRAY_AGG((link.link, link_predictions.bScore)::plugin.link_score 
        ORDER BY link_predictions.bScore) 
        FILTER (WHERE link.link IS NOT NULL) AS links
    FROM plugin.tab AS tab 
    INNER JOIN plugin.domain USING (domain_id)
    LEFT JOIN plugin.link USING (domain_id)
    LEFT JOIN plugin.link_predictions USING (link_id)
    WHERE tab.user_id = user_id_p AND tab.index = index_p
    GROUP BY tab.index, domain.name;
END;
$$;

CREATE OR REPLACE FUNCTION plugin.get_tabs(
    user_id_p plugin.id_type
)
RETURNS SETOF plugin.tabs_response
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT domain.name AS name, index  
    FROM plugin.tab JOIN plugin.domain AS domain USING (domain_id)
    WHERE (user_id_p IS NULL OR user_id = user_id_p);
END;
$$;