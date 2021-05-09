DO $$
DECLARE
    ident plugin.id_type;
    priv plugin.privilege_type;
    role_name plugin.user_role_type;
    temp plugin.privilege_type[];
BEGIN
    FOREACH role_name IN ARRAY enum_range(NULL::plugin.user_role_type) LOOP
        ident := plugin.id();
        INSERT INTO plugin.role (role_id, name) VALUES (ident, role_name);
        EXECUTE 'SELECT enum_range(NULL::plugin.' || LOWER(role_name::text) || '_privileges)' INTO temp;
        FOREACH priv IN ARRAY temp LOOP
            INSERT INTO plugin.privilege (name, role_id) VALUES (priv, ident);
        END LOOP;
    END LOOP;
END $$;