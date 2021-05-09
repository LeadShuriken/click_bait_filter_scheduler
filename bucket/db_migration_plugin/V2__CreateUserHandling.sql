CREATE TABLE IF NOT EXISTS plugin.role (
    role_id plugin.id_type DEFAULT plugin.id() PRIMARY KEY,
    name plugin.user_role_type NOT NULL
);

CREATE TABLE IF NOT EXISTS plugin.privilege (
    privilege_id plugin.id_type DEFAULT plugin.id() PRIMARY KEY,
    name plugin.privilege_type NOT NULL,
    role_id plugin.id_type,
    UNIQUE (name, role_id),
    FOREIGN KEY (role_id) REFERENCES plugin.role (role_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS plugin.users (
    user_id plugin.id_type DEFAULT plugin.id() PRIMARY KEY,
    name plugin.user_name_type NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,           -- sohead
    account_expired BOOLEAN NOT NULL DEFAULT FALSE,  -- sohead
    account_locked BOOLEAN NOT NULL DEFAULT FALSE,   -- sohead
    cred_expired BOOLEAN NOT NULL DEFAULT FALSE,     -- sohead
    password plugin.user_password_type NOT NULL,
    tflow_token plugin.user_password_type,
    role_id plugin.id_type,
    UNIQUE (name),
    FOREIGN KEY (role_id) REFERENCES plugin.role (role_id) ON DELETE SET NULL
);

CREATE OR REPLACE PROCEDURE plugin.user_authentication(
    user_id_p plugin.id_type,
    enabled_p BOOLEAN,
    account_expired_p BOOLEAN,
    account_locked_p BOOLEAN,
    cred_expired_p BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE plugin.users SET 
        enabled = COALESCE(enabled_p, users.enabled), 
        account_expired = COALESCE(account_expired_p, users.account_expired),  
        account_locked = COALESCE(account_locked_p, users.account_locked),   
        cred_expired = COALESCE(cred_expired_p, users.cred_expired) 
    WHERE user_id = user_id_p;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE TABLE IF NOT EXISTS plugin.user_privilege (
    user_id plugin.id_type NOT NULL,
    privilege_id plugin.id_type NOT NULL,
    FOREIGN KEY (user_id) REFERENCES plugin.users (user_id) ON DELETE CASCADE,
    FOREIGN KEY (privilege_id) REFERENCES plugin.privilege (privilege_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, privilege_id)
);

CREATE OR REPLACE FUNCTION plugin.insert_user(
    name_p plugin.user_name_type,
    password_p plugin.user_password_type,
    role_p plugin.user_role_type
)
RETURNS plugin.id_type
LANGUAGE plpgsql
AS $$
DECLARE
    ident CONSTANT plugin.id_type := plugin.id();
    priv plugin.privilege_type;
    temp plugin.privilege_type[];
BEGIN
    INSERT INTO plugin.users (user_id, name, password, role_id ) 
    VALUES (ident, name_p, password_p, 
        (SELECT role_id FROM plugin.role WHERE name = role_p)
    );
    EXECUTE 'SELECT enum_range(NULL::plugin.' || LOWER(role_p::text) || '_privileges)' INTO temp;
    FOREACH priv IN ARRAY temp LOOP
        INSERT INTO plugin.user_privilege (user_id, privilege_id) VALUES (ident, 
        (SELECT privilege_id FROM plugin.privilege AS priv_p 
         INNER JOIN plugin.role AS role_f USING (role_id)
         WHERE priv_p.name = priv AND role_f.name = role_p));
    END LOOP;
    RETURN ident;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE FUNCTION plugin.get_all_users()
RETURNS SETOF plugin.users_response
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        users.user_id, users.name, role.name as role,
        ARRAY_AGG(privilege.name::text) AS privileges
    FROM plugin.users 
    INNER JOIN plugin.role USING (role_id)
    INNER JOIN plugin.user_privilege USING (user_id)
    INNER JOIN plugin.privilege USING (privilege_id)
    GROUP BY users.user_id, users.name, role.name;
END;
$$;

CREATE OR REPLACE FUNCTION plugin.is_password_taken(
    password_p plugin.user_password_type
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE there BOOLEAN;
BEGIN
    SELECT EXISTS ( SELECT 1 FROM plugin.users WHERE password = password_p ) INTO there;
    RETURN there;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.delete_user(
    user_id_p plugin.id_type
)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM plugin.users WHERE user_id = user_id_p;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.update_password(
    user_id_p plugin.id_type,
    password_p plugin.user_password_type
)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE plugin.users SET password = password_p WHERE user_id = user_id_p;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.update_name(
    user_id_p plugin.id_type,
    name_p plugin.user_name_type
)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE plugin.users SET name = name_p WHERE user_id = user_id_p;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE FUNCTION plugin.get_user(
    user_id_p plugin.id_type,
    name_p plugin.user_name_type,
    password_p plugin.user_password_type,
    password_pass BOOLEAN DEFAULT FALSE
)
RETURNS SETOF plugin.user_response
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        users.user_id, users.name,
        (CASE WHEN password_pass 
        THEN users.password END)::plugin.user_password_type 
        AS password, role.name as role,
        ARRAY_AGG(privilege.name::text) AS privileges,
        users.enabled,
        users.account_expired,
        users.account_locked,
        users.cred_expired
    FROM plugin.users 
    INNER JOIN plugin.role USING (role_id)
    INNER JOIN plugin.user_privilege USING (user_id)
    INNER JOIN plugin.privilege USING (privilege_id)
    WHERE users.user_id = user_id_p OR 
    (users.name = name_p AND users.password = password_p) 
    OR users.name = name_p
    GROUP BY users.user_id, users.name, role.name;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.add_privilege(
    user_id_p plugin.id_type,
    privilege_p plugin.privilege_type[]
)
LANGUAGE plpgsql
AS $$
DECLARE 
priv plugin.privilege_type;
temp plugin.id_type;
BEGIN
    FOREACH priv IN ARRAY privilege_p LOOP
        SELECT privilege_id INTO temp FROM plugin.privilege
            JOIN plugin.role USING (role_id)
            WHERE privilege.name = priv AND role.name = (
                SELECT role.name FROM plugin.users 
                INNER JOIN plugin.role USING (role_id)
                WHERE users.user_id = user_id_p);
        IF temp IS NOT NULL THEN
            INSERT INTO plugin.user_privilege (user_id, privilege_id) VALUES 
            (user_id_p, temp)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.remove_privilege(
    user_id_p plugin.id_type,
    privilege_p plugin.privilege_type[]
)
LANGUAGE plpgsql
AS $$
DECLARE priv plugin.privilege_type;
BEGIN
    FOREACH priv IN ARRAY privilege_p LOOP
        DELETE FROM plugin.user_privilege 
        WHERE user_privilege.user_id = user_id_p
        AND user_privilege.privilege_id = 
        (SELECT privilege_id FROM plugin.privilege
         WHERE privilege.name = priv
         AND privilege.role_id = (
                SELECT role.role_id FROM plugin.users 
                INNER JOIN plugin.role USING (role_id)
                WHERE users.user_id = user_id_p));
    END LOOP;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.update_user(
    user_id_p plugin.id_type,
    name_p plugin.user_name_type,
    password_p plugin.user_password_type,
    role_p plugin.user_role_type,
    privilege_p plugin.privilege_type[]
)
LANGUAGE plpgsql
AS $$
DECLARE 
    priv plugin.privilege_type;
    cur_role_id plugin.id_type;
    cur_role_type plugin.user_role_type;
    temp plugin.privilege_type[];
BEGIN
    UPDATE plugin.users SET 
        name = COALESCE(name_p, users.name), 
        password = COALESCE(password_p, users.password)
    WHERE user_id = user_id_p;
    IF role_p IS NOT NULL THEN
        SELECT role.role_id, role.name INTO cur_role_id, cur_role_type 
        FROM plugin.users JOIN plugin.role 
        USING (role_id) WHERE user_id = user_id_p;
        IF role_p != cur_role_type THEN
            DELETE FROM plugin.user_privilege WHERE user_privilege.user_id = user_id_p;
            UPDATE plugin.users SET role_id = (SELECT role_id FROM plugin.role WHERE role.name = role_p)
            WHERE user_id = user_id_p;
            EXECUTE 'SELECT enum_range(NULL::plugin.' || LOWER(role_p::text) || '_privileges)' INTO temp;
            FOREACH priv IN ARRAY temp LOOP
                INSERT INTO plugin.user_privilege (user_id, privilege_id) VALUES (user_id_p, 
                (SELECT privilege_id FROM plugin.privilege AS priv_p 
                INNER JOIN plugin.role AS role_f USING (role_id)
                WHERE priv_p.name = priv AND role_f.name = role_p));
            END LOOP;
        END IF;
    END IF;
    IF privilege_p IS NOT NULL THEN
        DELETE FROM plugin.user_privilege WHERE user_id = user_id_p;
        CALL plugin.add_privilege(user_id_p, privilege_p);
    END IF;
EXCEPTION 
  WHEN OTHERS THEN 
  ROLLBACK;
COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE plugin.user_tflow_token_set(
     user_id_p plugin.id_type,
     tflow_token_p plugin.user_password_type
 )
 LANGUAGE plpgsql
 AS $$
 BEGIN
     UPDATE plugin.users SET 
         tflow_token = tflow_token_p
     WHERE user_id = user_id_p;
     COMMIT;
 END;
 $$;