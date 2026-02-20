/*
  # Fix Contact Submissions Security

  1. Changes
    - Replace the overly permissive RLS policy with proper validation
    - Add validation constraints to prevent abuse and spam
    - Ensure email format is valid
    - Restrict service_type to allowed values
    - Add reasonable length limits to prevent database abuse
    
  2. Security Improvements
    - Remove the "always true" WITH CHECK clause
    - Add CHECK constraints for data validation
    - Validate email format using PostgreSQL regex
    - Limit text field lengths to prevent abuse
    - Restrict service_type to predefined values
    
  3. Important Notes
    - Public INSERT access is still allowed for legitimate form submissions
    - But now with proper validation to prevent malicious or spam submissions
    - Maintains usability while improving security posture
*/

-- Drop the existing overly permissive policy
DROP POLICY IF EXISTS "Anyone can submit contact form" ON contact_submissions;

-- Add validation constraints to the table
DO $$
BEGIN
  -- Add email format validation
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_email_format'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_email_format 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  END IF;

  -- Add service_type validation
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_service_type_valid'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_service_type_valid 
    CHECK (service_type IN ('Lawn Mowing', 'Other'));
  END IF;

  -- Add reasonable length limits
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_name_length'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_name_length 
    CHECK (char_length(name) > 0 AND char_length(name) <= 100);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_email_length'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_email_length 
    CHECK (char_length(email) > 0 AND char_length(email) <= 255);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_phone_length'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_phone_length 
    CHECK (char_length(phone) > 0 AND char_length(phone) <= 20);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_address_length'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_address_length 
    CHECK (char_length(street_address) > 0 AND char_length(street_address) <= 500);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contact_submissions_details_length'
  ) THEN
    ALTER TABLE contact_submissions 
    ADD CONSTRAINT contact_submissions_details_length 
    CHECK (service_details IS NULL OR char_length(service_details) <= 2000);
  END IF;
END $$;

-- Create a more secure policy with proper validation
CREATE POLICY "Allow valid contact form submissions"
  ON contact_submissions
  FOR INSERT
  TO anon
  WITH CHECK (
    -- Ensure all required fields are provided and not just whitespace
    char_length(trim(name)) > 0 AND
    char_length(trim(email)) > 0 AND
    char_length(trim(phone)) > 0 AND
    char_length(trim(street_address)) > 0 AND
    char_length(trim(service_type)) > 0 AND
    -- Additional validation is handled by table constraints
    -- This ensures the policy itself is not "always true"
    name IS NOT NULL AND
    email IS NOT NULL AND
    phone IS NOT NULL AND
    street_address IS NOT NULL AND
    service_type IS NOT NULL
  );