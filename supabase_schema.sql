-- =========================================================================
-- CareSphere - Supabase SQL Database Schema
-- Smartwatch 10-Minute Telemetry Storage & Daily Partitions
-- =========================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Main 10-Minute Telemetry Table
-- Stores every 10-minute snapshot collected from the patient's smartwatch
CREATE TABLE IF NOT EXISTS smartwatch_telemetry_10min (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id TEXT NOT NULL DEFAULT 'patient_eleanor_vance',
    reading_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reading_time TIME NOT NULL DEFAULT CURRENT_TIME,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 6 Key Vitals collected every 10 minutes
    heart_rate INT NOT NULL,                -- Heart Rate (BPM)
    spo2 INT NOT NULL,                      -- Blood Oxygen Saturation (%)
    sleep_duration NUMERIC(4, 2) NOT NULL,  -- Sleep Duration (Hours)
    daily_steps INT NOT NULL,               -- Daily Steps
    stress_index INT NOT NULL,              -- Stress Index (0-100)
    active_calories INT NOT NULL,           -- Active Calories Burned (kcal)
    activity_state TEXT DEFAULT 'Resting in Armchair',
    
    -- Synchronization Metadata
    synced_from TEXT DEFAULT 'CareSphere App',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Enforce single snapshot per patient per exact timestamp
    CONSTRAINT unique_patient_10min_sample UNIQUE (patient_id, recorded_at)
);

-- 2. High-Performance Indexes for Daily and Date-Range Queries
CREATE INDEX IF NOT EXISTS idx_telemetry_date 
    ON smartwatch_telemetry_10min (reading_date DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_patient_date 
    ON smartwatch_telemetry_10min (patient_id, reading_date DESC, reading_time DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_recorded_at 
    ON smartwatch_telemetry_10min (recorded_at DESC);

-- 3. Daily Rollup View (Full Day Aggregate Statistics)
-- Aggregates the 144 ten-minute intervals for each full calendar day
CREATE OR REPLACE VIEW daily_patient_telemetry_summary AS
SELECT 
    patient_id,
    reading_date,
    COUNT(*) AS total_10min_intervals,
    ROUND(AVG(heart_rate), 1) AS avg_heart_rate,
    MIN(heart_rate) AS min_heart_rate,
    MAX(heart_rate) AS max_heart_rate,
    ROUND(AVG(spo2), 1) AS avg_spo2,
    MIN(spo2) AS min_spo2,
    MAX(daily_steps) AS total_daily_steps,
    MAX(active_calories) AS total_calories_burned,
    ROUND(AVG(stress_index), 1) AS avg_stress_index,
    MAX(sleep_duration) AS recorded_sleep_hours,
    MIN(recorded_at) AS day_first_sample,
    MAX(recorded_at) AS day_latest_sample
FROM smartwatch_telemetry_10min
GROUP BY patient_id, reading_date
ORDER BY reading_date DESC;

-- 4. Enable Row Level Security (RLS)
ALTER TABLE smartwatch_telemetry_10min ENABLE ROW LEVEL SECURITY;

-- Allow read & insert access for authenticated or anon API clients
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon read access' AND tablename = 'smartwatch_telemetry_10min'
    ) THEN
        CREATE POLICY "Allow anon read access" ON smartwatch_telemetry_10min FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon insert access' AND tablename = 'smartwatch_telemetry_10min'
    ) THEN
        CREATE POLICY "Allow anon insert access" ON smartwatch_telemetry_10min FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- 5. ESP32 #1 Table: Wearable Vitals & Motion (Heart Rate, SpO2, Accel X/Y/Z, Gyro X/Y/Z)
CREATE TABLE IF NOT EXISTS esp32_vitals_telemetry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id TEXT NOT NULL DEFAULT 'esp32_vitals_01',
    patient_id TEXT NOT NULL DEFAULT 'patient_eleanor_vance',
    heart_rate INT NOT NULL,                  -- Heart Rate (BPM)
    spo2 INT NOT NULL,                        -- SpO2 (%)
    accel_x NUMERIC(6, 3) DEFAULT 0.0,        -- Accelerometer X (m/s²)
    accel_y NUMERIC(6, 3) DEFAULT 0.0,        -- Accelerometer Y (m/s²)
    accel_z NUMERIC(6, 3) DEFAULT 9.8,        -- Accelerometer Z (m/s²)
    gyro_x NUMERIC(6, 3) DEFAULT 0.0,         -- Gyroscope X (deg/s)
    gyro_y NUMERIC(6, 3) DEFAULT 0.0,         -- Gyroscope Y (deg/s)
    gyro_z NUMERIC(6, 3) DEFAULT 0.0,         -- Gyroscope Z (deg/s)
    fall_detected BOOLEAN DEFAULT FALSE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. ESP32 #2 Table: Room Environment (Light, Human Presence, Temp, Humidity, SOS)
CREATE TABLE IF NOT EXISTS esp32_room_telemetry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id TEXT NOT NULL DEFAULT 'esp32_room_02',
    patient_id TEXT NOT NULL DEFAULT 'patient_eleanor_vance',
    temperature NUMERIC(5, 2) NOT NULL,       -- Room Temperature (°C)
    humidity NUMERIC(5, 2) NOT NULL,          -- Room Humidity (%)
    ambient_light NUMERIC(7, 2) NOT NULL,     -- Light Presence (Lux)
    presence_detected BOOLEAN DEFAULT TRUE,   -- Human Presence (Radar/PIR)
    emergency_button BOOLEAN DEFAULT FALSE,   -- Physical SOS Button
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE esp32_vitals_telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE esp32_room_telemetry ENABLE ROW LEVEL SECURITY;

-- 7. Master Machine Learning Training Dataset Table
-- Stores all combined sensor inputs, engineered vector features, and ground-truth target labels for ML Model Training
CREATE TABLE IF NOT EXISTS caresphere_ml_training_dataset (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id TEXT NOT NULL DEFAULT 'patient_eleanor_vance',
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ESP32 #1 Vitals Features (MAX30102)
    heart_rate INT NOT NULL,                  -- BPM (e.g. 74)
    spo2 INT NOT NULL,                        -- % (e.g. 98)
    hr_slope_5m NUMERIC(6, 2) DEFAULT 0.0,    -- 5-min Heart Rate slope delta
    is_monotonic_hr_decay BOOLEAN DEFAULT FALSE,

    -- ESP32 #1 6-Axis Motion Features (MPU6050)
    accel_x NUMERIC(6, 3) NOT NULL,           -- m/s²
    accel_y NUMERIC(6, 3) NOT NULL,           -- m/s²
    accel_z NUMERIC(6, 3) NOT NULL,           -- m/s²
    gyro_x NUMERIC(6, 3) NOT NULL,            -- deg/s
    gyro_y NUMERIC(6, 3) NOT NULL,            -- deg/s
    gyro_z NUMERIC(6, 3) NOT NULL,            -- deg/s
    accel_magnitude NUMERIC(6, 3) GENERATED ALWAYS AS (
        SQRT(accel_x * accel_x + accel_y * accel_y + accel_z * accel_z)
    ) STORED,
    gyro_magnitude NUMERIC(6, 3) GENERATED ALWAYS AS (
        SQRT(gyro_x * gyro_x + gyro_y * gyro_y + gyro_z * gyro_z)
    ) STORED,
    fall_detected_flag BOOLEAN DEFAULT FALSE, -- IMU Impact Fall Flag

    -- ESP32 #2 Room & Climate Features (BH1750, HLK-LD2410, DHT22)
    room_temperature NUMERIC(5, 2) NOT NULL,  -- °C
    room_humidity NUMERIC(5, 2) NOT NULL,     -- %
    ambient_light_lux NUMERIC(7, 2) NOT NULL, -- Lux
    human_presence BOOLEAN DEFAULT TRUE,      -- Radar/PIR Presence
    emergency_button_pressed BOOLEAN DEFAULT FALSE,
    temp_rate_5m NUMERIC(5, 2) DEFAULT 0.0,   -- Thermal change rate over 5 min

    -- Smartwatch Contextual Features
    sleep_duration_hours NUMERIC(4, 2) DEFAULT 7.5,
    daily_steps INT DEFAULT 4200,
    stress_index INT DEFAULT 25,

    -- ML Model Training Ground-Truth Target Labels
    health_risk_score NUMERIC(5, 2) NOT NULL DEFAULT 10.0, -- 0-100 Continuous Target
    risk_level TEXT NOT NULL DEFAULT 'LOW',                 -- 'LOW', 'MODERATE', 'HIGH', 'CRITICAL'
    emergency_trigger BOOLEAN DEFAULT FALSE,                -- Supervised Emergency Label (0/1)
    anomaly_category TEXT DEFAULT 'NORMAL'                  -- 'NORMAL', 'TACHYCARDIA', 'HYPOXIA', 'FALL_IMPACT', 'HEAT_SURGE'
);

-- Index for fast time-series extraction during Python model training (Pandas/Scikit-Learn/PyTorch)
CREATE INDEX IF NOT EXISTS idx_ml_dataset_time 
    ON caresphere_ml_training_dataset (recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_ml_dataset_risk 
    ON caresphere_ml_training_dataset (risk_level);

ALTER TABLE caresphere_ml_training_dataset ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon read access' AND tablename = 'caresphere_ml_training_dataset'
    ) THEN
        CREATE POLICY "Allow anon read access" ON caresphere_ml_training_dataset FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon insert access' AND tablename = 'caresphere_ml_training_dataset'
    ) THEN
        CREATE POLICY "Allow anon insert access" ON caresphere_ml_training_dataset FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- =========================================================================
-- 8. Users Table
-- Stores user authentication details, profiles, and role-based links
-- =========================================================================
CREATE TABLE IF NOT EXISTS caresphere_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'patient', -- 'patient', 'caregiver', 'doctor'
    age INT,
    phone TEXT,
    elder_code TEXT UNIQUE,
    linked_elder_code TEXT,
    avatar_url TEXT DEFAULT 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    blood_group TEXT DEFAULT 'O+',
    weight NUMERIC(5, 2) DEFAULT 64.5,
    height NUMERIC(5, 2) DEFAULT 162.0,
    medical_conditions TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup of elder_code for linking accounts
CREATE INDEX IF NOT EXISTS idx_users_elder_code ON caresphere_users (elder_code);

ALTER TABLE caresphere_users ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon read access' AND tablename = 'caresphere_users'
    ) THEN
        CREATE POLICY "Allow anon read access" ON caresphere_users FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon insert access' AND tablename = 'caresphere_users'
    ) THEN
        CREATE POLICY "Allow anon insert access" ON caresphere_users FOR INSERT WITH CHECK (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Allow anon update access' AND tablename = 'caresphere_users'
    ) THEN
        CREATE POLICY "Allow anon update access" ON caresphere_users FOR UPDATE USING (true);
    END IF;
END $$;
