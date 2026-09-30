-- V1: core tables (skip or adjust if students already exists in your bootcamp DB)
CREATE TABLE IF NOT EXISTS students (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);
