/*
  # Create leads table for contact form submissions

  1. New Tables
    - `leads`
      - `id` (uuid, primary key) - Unique identifier for each lead
      - `name` (text) - Contact's full name
      - `email` (text) - Contact's email address
      - `phone` (text) - Contact's phone number
      - `street_address` (text) - Property address for service
      - `service_type` (text) - Type of service requested (e.g., "Lawn Mowing", "Other")
      - `service_details` (text, nullable) - Additional details when service_type is "Other"
      - `created_at` (timestamptz) - Timestamp when lead was submitted
      - `status` (text) - Lead status tracking (default: "new")
      
  2. Security
    - Enable RLS on `leads` table
    - Add policy for anonymous users to insert their own submissions
    - Add policy for authenticated users (staff) to view all leads
    - Add policy for authenticated users (staff) to update lead status

  3. Notes
    - The table is designed to capture all information from the contact form
    - Anonymous users can only insert data (submit forms)
    - Only authenticated staff members can view and manage leads
    - Status field allows for lead tracking workflow
*/

-- Create leads table
CREATE TABLE IF NOT EXISTS leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  street_address text NOT NULL,
  service_type text NOT NULL DEFAULT 'Lawn Mowing',
  service_details text,
  status text NOT NULL DEFAULT 'new',
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to insert leads (submit contact forms)
CREATE POLICY "Anyone can submit a lead"
  ON leads
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Allow authenticated users (staff) to view all leads
CREATE POLICY "Authenticated users can view all leads"
  ON leads
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users (staff) to update leads
CREATE POLICY "Authenticated users can update leads"
  ON leads
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create index for faster queries on created_at
CREATE INDEX IF NOT EXISTS leads_created_at_idx ON leads(created_at DESC);

-- Create index for status filtering
CREATE INDEX IF NOT EXISTS leads_status_idx ON leads(status);