/*
  # Improve Leads Table Security

  1. Changes
    - Add basic validation constraints to prevent spam
    - Add indexes for better query performance
    - Keep anonymous INSERT access but add data validation
    
  2. Security Improvements
    - Email format validation
    - Phone number length validation  
    - Name and address minimum length requirements
    - These constraints help prevent automated spam submissions
    
  3. Performance
    - Add index on created_at for efficient sorting
    - Add index on status for filtering
*/

-- Add check constraints for data validation
DO $$ 
BEGIN
  -- Email must contain @ symbol (basic validation)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE table_name = 'leads' AND constraint_name = 'leads_email_format_check'
  ) THEN
    ALTER TABLE leads ADD CONSTRAINT leads_email_format_check 
      CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  END IF;

  -- Name must be at least 2 characters
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE table_name = 'leads' AND constraint_name = 'leads_name_length_check'
  ) THEN
    ALTER TABLE leads ADD CONSTRAINT leads_name_length_check 
      CHECK (char_length(trim(name)) >= 2);
  END IF;

  -- Phone must be at least 10 characters
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE table_name = 'leads' AND constraint_name = 'leads_phone_length_check'
  ) THEN
    ALTER TABLE leads ADD CONSTRAINT leads_phone_length_check 
      CHECK (char_length(regexp_replace(phone, '[^0-9]', '', 'g')) >= 10);
  END IF;

  -- Street address must be at least 5 characters
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE table_name = 'leads' AND constraint_name = 'leads_address_length_check'
  ) THEN
    ALTER TABLE leads ADD CONSTRAINT leads_address_length_check 
      CHECK (char_length(trim(street_address)) >= 5);
  END IF;
END $$;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);

-- Update the INSERT policy to be more restrictive
DROP POLICY IF EXISTS "Anyone can submit a lead" ON leads;

CREATE POLICY "Allow anonymous lead submissions with validation"
  ON leads
  FOR INSERT
  TO anon
  WITH CHECK (
    -- Ensure required fields are present and valid
    char_length(trim(name)) >= 2 AND
    char_length(trim(email)) >= 5 AND
    email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' AND
    char_length(regexp_replace(phone, '[^0-9]', '', 'g')) >= 10 AND
    char_length(trim(street_address)) >= 5 AND
    service_type IN ('Lawn Mowing', 'Other') AND
    status = 'new'
  );
