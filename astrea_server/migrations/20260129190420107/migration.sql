BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "device_tokens" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "token" text NOT NULL,
    "platform" text NOT NULL,
    "deviceId" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "device_token_user_idx" ON "device_tokens" USING btree ("userId");
CREATE UNIQUE INDEX "device_token_unique_idx" ON "device_tokens" USING btree ("userId", "token");


--
-- MIGRATION VERSION FOR astrea
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('astrea', '20260129190420107', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129190420107', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
