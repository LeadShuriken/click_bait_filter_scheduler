CREATE SCHEMA IF NOT EXISTS plugin;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    CREATE DOMAIN plugin.id_type UUID;
    CREATE DOMAIN plugin.bait_score DECIMAL;
    CREATE DOMAIN plugin.link_type VARCHAR(300);
    CREATE DOMAIN plugin.user_name_type VARCHAR(100);
    CREATE DOMAIN plugin.domain_name_type VARCHAR(100);
    CREATE DOMAIN plugin.user_password_type VARCHAR(200);
    CREATE TYPE plugin.user_role_type AS ENUM ('ADMIN', 'USER');
    CREATE TYPE plugin.privilege_type AS ENUM (
        'USERS_READ',
        'USERS_WRITE',
        'CLICKS_READ',
        'CLICKS_WRITE',
        'DOMAINS_READ',
        'DOMAINS_WRITE'
    );
    CREATE TYPE plugin.user_privileges AS ENUM (
        'CLICKS_WRITE',
        'DOMAINS_READ'
    );
    CREATE TYPE plugin.admin_privileges AS ENUM (
        'USERS_READ',
        'USERS_WRITE',
        'CLICKS_READ',
        'CLICKS_WRITE',
        'DOMAINS_READ',
        'DOMAINS_WRITE'
    );
    CREATE TYPE plugin.user_response AS (
        user_id plugin.id_type,
        name plugin.user_name_type,
        password plugin.user_password_type,
        role plugin.user_role_type,
        privileges TEXT[],
        enabled BOOLEAN,          
        account_expired BOOLEAN,  
        account_locked BOOLEAN,   
        cred_expired BOOLEAN
    );
    CREATE TYPE plugin.users_response AS (
        user_id plugin.id_type,
        name plugin.user_name_type,
        role plugin.user_role_type,
        privileges TEXT[]
    );
    CREATE TYPE plugin.tabs_response AS (
        name plugin.domain_name_type,
        index INTEGER
    );
    CREATE TYPE plugin.link_score AS (
        link plugin.link_type,
        score plugin.bait_score
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE OR REPLACE FUNCTION plugin.id()
RETURNS plugin.id_type
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN uuid_generate_v4();
END;
$$;