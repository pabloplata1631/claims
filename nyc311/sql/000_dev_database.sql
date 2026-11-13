-- Creates only DEV; preserves any existing database.
USE master;
GO
IF DB_ID(N'NYC_Operations_Dev') IS NULL
    CREATE DATABASE [NYC_Operations_Dev];
GO
