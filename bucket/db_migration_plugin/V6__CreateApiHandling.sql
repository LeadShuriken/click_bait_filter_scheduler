CREATE OR REPLACE PROCEDURE plugin.create_page_model(
    domain_p plugin.domain_name_type,
    links_p plugin.link_type[],
    bScores_p plugin.bait_score[]
)
LANGUAGE plpgsql
AS $$
DECLARE 
    linkF plugin.link_type;
    domain_f plugin.id_type;
    ident plugin.id_type := plugin.id();
    iterator INTEGER := 0;
BEGIN
    IF cardinality(bScores_p) = cardinality(links_p) THEN
        WITH returnD AS (
            INSERT INTO plugin.domain (domain_id, name) VALUES (ident, domain_p)
            ON CONFLICT (name) DO UPDATE SET name=EXCLUDED.name
            RETURNING plugin.domain.domain_id
        )
        SELECT domain_id INTO domain_f FROM returnD;

        FOREACH linkF IN ARRAY links_p
        LOOP
            iterator := iterator + 1;
            ident := plugin.id();
            WITH returnL AS (
                INSERT INTO plugin.link ( link_id, link, domain_id ) 
                VALUES (ident, linkF, domain_f)
                ON CONFLICT (link) DO UPDATE SET link=EXCLUDED.link
                RETURNING plugin.link.link_id
            )
            SELECT COALESCE((SELECT link_id FROM returnL), ident) INTO ident;

            INSERT INTO plugin.link_predictions ( link_id, bScore)
            VALUES (ident, bScores_p[iterator]) ON CONFLICT (link_id)
            DO UPDATE SET bScore = bScores_p[iterator];
        END LOOP;
    END IF;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;