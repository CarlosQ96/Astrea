BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "reminders" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "title" text NOT NULL,
    "description" text,
    "dueAtUtc" timestamp without time zone NOT NULL,
    "originalTimezone" text NOT NULL,
    "repeatRule" text,
    "snoozedUntilUtc" timestamp without time zone,
    "isCompleted" boolean NOT NULL DEFAULT false,
    "priority" bigint NOT NULL DEFAULT 2,
    "revision" bigint NOT NULL DEFAULT 1,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "reminder_user_idx" ON "reminders" USING btree ("userId");
CREATE INDEX "reminder_user_active_idx" ON "reminders" USING btree ("userId", "isCompleted", "dueAtUtc");
CREATE INDEX "reminder_due_idx" ON "reminders" USING btree ("dueAtUtc");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_settings" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "defaultSnoozeMinutes" bigint NOT NULL DEFAULT 15,
    "quietHoursStart" text,
    "quietHoursEnd" text,
    "voiceEnabled" boolean NOT NULL DEFAULT true,
    "timezone" text NOT NULL DEFAULT 'UTC'::text
);

-- Indexes
CREATE UNIQUE INDEX "user_settings_user_idx" ON "user_settings" USING btree ("userId");


--
-- MIGRATION VERSION FOR astrea
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('astrea', '20260128232050919', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260128232050919', "timestamp" = now();

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
