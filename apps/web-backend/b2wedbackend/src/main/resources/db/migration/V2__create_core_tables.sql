-- V2__create_core_tables.sql
-- B2 core tables (MVP)

-- =========================
-- 1) users
-- =========================
CREATE TABLE users (
                       id BIGSERIAL PRIMARY KEY,
                       oidc_subject VARCHAR(255) NOT NULL UNIQUE,
                       email VARCHAR(255) NOT NULL UNIQUE,
                       name VARCHAR(100) NOT NULL,
                       role VARCHAR(20) NOT NULL,
                       created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                       CONSTRAINT chk_users_role
                           CHECK (role IN ('STUDENT', 'TEACHER', 'ADMIN'))
);

-- =========================
-- 2) requests
-- =========================
CREATE TABLE requests (
                          id BIGSERIAL PRIMARY KEY,
                          user_id BIGINT NOT NULL,
                          project_name VARCHAR(255) NOT NULL,
                          purpose TEXT NOT NULL,
                          team_lead_name VARCHAR(100) NOT NULL,
                          team_members TEXT,
                          start_at TIMESTAMPTZ NOT NULL,
                          end_at TIMESTAMPTZ NOT NULL,
                          expected_gpu_hours NUMERIC(10,2) NOT NULL,
                          reason TEXT NOT NULL,
                          status VARCHAR(20) NOT NULL,
                          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                          CONSTRAINT fk_requests_user
                              FOREIGN KEY (user_id) REFERENCES users(id),

                          CONSTRAINT chk_requests_status
                              CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED')),

                          CONSTRAINT chk_requests_gpu_hours
                              CHECK (expected_gpu_hours >= 0),

                          CONSTRAINT chk_requests_period
                              CHECK (start_at < end_at)
);

CREATE INDEX idx_requests_user_id ON requests(user_id);
CREATE INDEX idx_requests_status ON requests(status);
CREATE INDEX idx_requests_start_end ON requests(start_at, end_at);

-- =========================
-- 3) approvals
-- =========================
CREATE TABLE approvals (
                           id BIGSERIAL PRIMARY KEY,
                           request_id BIGINT NOT NULL,
                           teacher_user_id BIGINT NOT NULL,
                           decision VARCHAR(20) NOT NULL,
                           reason TEXT,
                           decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                           CONSTRAINT fk_approvals_request
                               FOREIGN KEY (request_id) REFERENCES requests(id),

                           CONSTRAINT fk_approvals_teacher
                               FOREIGN KEY (teacher_user_id) REFERENCES users(id),

                           CONSTRAINT chk_approvals_decision
                               CHECK (decision IN ('APPROVE', 'REJECT'))
);

CREATE INDEX idx_approvals_request_id ON approvals(request_id);
CREATE INDEX idx_approvals_teacher_user_id ON approvals(teacher_user_id);

-- =========================
-- 4) dgx_accounts
-- =========================
CREATE TABLE dgx_accounts (
                              id BIGSERIAL PRIMARY KEY,
                              request_id BIGINT NOT NULL UNIQUE,
                              dgx_username VARCHAR(64) NOT NULL UNIQUE,
                              account_status VARCHAR(20) NOT NULL,
                              active_at TIMESTAMPTZ,
                              disabled_at TIMESTAMPTZ,
                              archive_path TEXT,
                              purge_scheduled_at TIMESTAMPTZ,
                              last_error TEXT,

                              CONSTRAINT fk_dgx_accounts_request
                                  FOREIGN KEY (request_id) REFERENCES requests(id),

                              CONSTRAINT chk_dgx_accounts_status
                                  CHECK (account_status IN ('PROVISIONING', 'ACTIVE', 'DISABLED', 'ARCHIVED', 'PURGED', 'FAILED'))
);

CREATE INDEX idx_dgx_accounts_status ON dgx_accounts(account_status);

-- =========================
-- 5) provision_jobs
-- =========================
CREATE TABLE provision_jobs (
                                id BIGSERIAL PRIMARY KEY,
                                request_id BIGINT NOT NULL,
                                job_type VARCHAR(20) NOT NULL,
                                job_status VARCHAR(20) NOT NULL,
                                retry_count INT NOT NULL DEFAULT 0,
                                request_idempotency_key VARCHAR(100) NOT NULL UNIQUE,
                                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                last_error TEXT,

                                CONSTRAINT fk_provision_jobs_request
                                    FOREIGN KEY (request_id) REFERENCES requests(id),

                                CONSTRAINT chk_provision_jobs_type
                                    CHECK (job_type IN ('CREATE', 'DISABLE', 'ARCHIVE', 'PURGE')),

                                CONSTRAINT chk_provision_jobs_status
                                    CHECK (job_status IN ('PENDING', 'RUNNING', 'SUCCESS', 'FAILED', 'RETRYING')),

                                CONSTRAINT chk_provision_jobs_retry_count
                                    CHECK (retry_count >= 0)
);

CREATE INDEX idx_provision_jobs_request_id ON provision_jobs(request_id);
CREATE INDEX idx_provision_jobs_status ON provision_jobs(job_status);
CREATE INDEX idx_provision_jobs_type ON provision_jobs(job_type);

-- =========================
-- 6) audit_logs
-- =========================
CREATE TABLE audit_logs (
                            id BIGSERIAL PRIMARY KEY,
                            actor_user_id BIGINT,
                            action VARCHAR(64) NOT NULL,
                            target_type VARCHAR(20) NOT NULL,
                            target_id BIGINT,
                            result VARCHAR(20) NOT NULL,
                            reason TEXT,
                            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                            meta JSONB,

                            CONSTRAINT fk_audit_logs_actor
                                FOREIGN KEY (actor_user_id) REFERENCES users(id),

                            CONSTRAINT chk_audit_logs_result
                                CHECK (result IN ('SUCCESS', 'FAILED'))
);

CREATE INDEX idx_audit_logs_actor_user_id ON audit_logs(actor_user_id);
CREATE INDEX idx_audit_logs_target ON audit_logs(target_type, target_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);