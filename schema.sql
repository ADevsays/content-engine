-- Enable pgvector extension (required for scripts.embedding)
CREATE EXTENSION IF NOT EXISTS vector;

-- Conversation state per Telegram chat
CREATE TABLE IF NOT EXISTS conversation_states (
  chat_id       text NOT NULL PRIMARY KEY,
  state         text,
  current_script text,
  user_prompt   text,
  last_updated  timestamp without time zone
);

-- Current file being processed per chat
CREATE TABLE IF NOT EXISTS current_file (
  chat_id      text NOT NULL PRIMARY KEY,
  file_name    text,
  file_id      text,
  file_url     text,
  last_updated timestamp without time zone
);

-- Script content with vector embedding for semantic search
CREATE TABLE IF NOT EXISTS scripts (
  id        bigint NOT NULL PRIMARY KEY,
  content   text,
  metadata  jsonb,
  embedding vector(1024),
  style     text
);

-- Post publishing status per chat
CREATE TABLE IF NOT EXISTS post_status (
  chat_id             text NOT NULL PRIMARY KEY,
  last_post_result_url text,
  current_post        text,
  updated_at          timestamp without time zone
);

-- n8n workflow execution error log
CREATE TABLE IF NOT EXISTS n8n_error_logs (
  id            integer NOT NULL PRIMARY KEY,
  workflow_name text,
  error_message text,
  execution_id  text,
  created_at    timestamp with time zone
);

-- n8n workflow backups
CREATE TABLE IF NOT EXISTS n8n_backups (
  id          integer NOT NULL PRIMARY KEY,
  workflow_id text NOT NULL,
  name        text,
  nodes_config jsonb,
  backup_date timestamp with time zone
);

-- n8n AI chat message histories
CREATE TABLE IF NOT EXISTS n8n_chat_histories (
  id         integer NOT NULL PRIMARY KEY,
  session_id character varying(255) NOT NULL,
  message    jsonb NOT NULL
);



-- Meme asset library
CREATE TABLE IF NOT EXISTS meme_data (
  id         bigint NOT NULL PRIMARY KEY,
  created_at timestamp with time zone NOT NULL,
  url        text,
  emotion    text,
  color      numeric
);

-- Meme generation session per chat
CREATE TABLE IF NOT EXISTS meme_session (
  chat_id                 text NOT NULL PRIMARY KEY,
  last_status             text,
  last_color              text,
  updated_at              timestamp without time zone,
  last_video_template_url text
);

