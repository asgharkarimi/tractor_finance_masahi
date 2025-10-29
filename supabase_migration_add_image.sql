-- Migration: Add image_path column to lands table if it doesn't exist
-- Run this if you created the tables before adding image support

-- Add image_path column to lands table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'lands' 
        AND column_name = 'image_path'
    ) THEN
        ALTER TABLE lands ADD COLUMN image_path TEXT;
    END IF;
END $$;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'lands';
