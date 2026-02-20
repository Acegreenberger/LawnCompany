/*
  # Create Contact Submissions Table

  1. New Tables
    - `contact_submissions`
      - `id` (uuid, primary key) - Unique identifier for each submission
      - `name` (text, not null) - Customer's full name
      - `email` (text, not null) - Customer's email address
      - `phone` (text, not null) - Customer's phone number
      - `street_address` (text, not null) - Property address for service
      - `service_type` (text, not null) - Either 'Lawn Mowing' or 'Other'
      - `service_details` (text, nullable) - Additional details when service_type is 'Other'
      - `created_at` (timestamptz) - Timestamp of form submission
      
  2. Security
    - Enable RLS on `contact_submissions` table
    - Add policy for inserting new submissions (public access for form submissions)
    - Add policy for service owner to read all submissions

  Important Notes:
    - Public INSERT access is allowed to enable form submissions from anonymous users
    - Only authenticated service owners can read the submissions
    - All contact information is required except service_details which is conditional
*/

-- Create contact_submissions table
CREATE TABLE IF NOT EXISTS contact_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  street_address text NOT NULL,
  service_type text NOT NULL,
  service_details text,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert contact submissions (for public form)
CREATE POLICY "Anyone can submit contact form"
  ON contact_submissions
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Allow authenticated users to read all submissions (for service owner/admin)
CREATE POLICY "Authenticated users can view all submissions"
  ON contact_submissions
  FOR SELECT
  TO authenticated
  USING (true);