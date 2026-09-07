-- ==============================================================================
-- BidGuard AI - Supabase Database Schema & Authorization Architecture
-- ==============================================================================

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer', 'vendor')),
  vendor_id TEXT,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW())
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. SELECT Policy: Authenticated users can view their own profile
CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
USING (auth.uid() = id);

-- 4. INSERT Policy: Constrained self-signup for buyers only
-- Prevents privilege escalation (cannot self-assign vendor role or vendor_id)
CREATE POLICY "Users can insert own profile as buyer"
ON public.profiles
FOR INSERT
WITH CHECK (
  auth.uid() = id AND
  role = 'buyer' AND
  vendor_id IS NULL
);

-- 5. UPDATE Policy: No direct self-updates to role/vendor_id.
-- Normal users cannot promote themselves or alter vendor_id.
-- Profile field changes must be done through trusted server mechanisms.

-- ==============================================================================
-- TechCorp Vendor Provisioning Procedure
-- ==============================================================================
-- Step 1: Create the TechCorp vendor user in Supabase Auth (Dashboard -> Authentication -> Users -> Add User)
--         e.g., Email: vendor@techcorp.com, Password: <secure_password>
--
-- Step 2: In the Supabase SQL Editor (Admin context), attach the trusted vendor profile:
--
-- INSERT INTO public.profiles (id, email, role, vendor_id, display_name)
-- VALUES (
--   '<TECHCORP_USER_UUID_FROM_AUTH_USERS>',
--   'vendor@techcorp.com',
--   'vendor',
--   'techcorp',
--   'TechCorp Solutions'
-- )
-- ON CONFLICT (id) DO UPDATE SET
--   role = 'vendor',
--   vendor_id = 'techcorp',
--   display_name = 'TechCorp Solutions';
