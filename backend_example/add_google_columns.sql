-- Add Google OAuth columns to users table if they don't exist

-- Add google_id column
ALTER TABLE users
ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) NULL UNIQUE,
ADD COLUMN IF NOT EXISTS photo_url TEXT NULL,
ADD COLUMN IF NOT EXISTS login_method VARCHAR(50) DEFAULT 'email',
ADD COLUMN IF NOT EXISTS last_login TIMESTAMP NULL;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_email ON users(email);

-- Update existing users to set default login method
UPDATE users
SET login_method = 'email'
WHERE login_method IS NULL OR login_method = '';
