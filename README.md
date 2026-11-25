# CORNER STONER LEADERS

A responsive praise-team leadership portal built with HTML, CSS, JavaScript and Supabase Auth/Postgres.

## Included
- Sign-in, leader registration and password reset
- Pending approval screen for new accounts
- Administrator approval/rejection workflow
- Overview dashboard
- Song library
- Attendance records
- Daily activities
- Supabase Row Level Security policies

## Important: apply the database migration first
1. Open the Supabase project `gyezqkekuvkhdqndrzcu`.
2. Open SQL Editor and create a new query.
3. Paste the full contents of `supabase-approval-setup.sql`.
4. Run it and verify the final query shows the administrator profile with role `admin` and approval status `approved`.

This migration assumes the four tables and helper function `public.is_admin()` from the earlier setup already exist.

## Supabase Auth settings
- In Authentication > URL Configuration, set the Site URL to the deployed website URL.
- Add the deployed website URL to Redirect URLs.
- Email provider should be enabled.
- If email confirmation is enabled, leaders must confirm their email before signing in.
- Keep public signups enabled only if you want leaders to request accounts. The approval workflow prevents pending accounts from reading team data.

## Run locally
Because this is a static site, serve the folder with any local static server. Do not open `index.html` as a `file://` URL if the browser blocks module imports.

## Publish
Upload the contents of this folder to a static host such as Netlify, Cloudflare Pages or GitHub Pages. Publish the folder containing `index.html`, `app.js`, `styles.css`, and `config.js`.
After deployment, set the website URL in Supabase Authentication > URL Configuration.

## Security notes
- `config.js` contains only the Supabase project URL and publishable key. Publishable keys are intended for browser use.
- Never add an `sb_secret_` key or `service_role` key to frontend files.
- The SQL migration adds `approval_status`, protects that field from self-editing, and restricts data access to approved users or admins.
- Review RLS policies before inviting real members. Do not share administrator credentials.


## Finance daily records update

1. In Supabase, open SQL Editor and run the complete contents of `finance-setup.sql`. This adds the finance ledger and its Row Level Security policies.
2. In the website, sign in as the administrator and open **Leader approvals**. Under **Finance permission**, tap **Make treasurer** beside the approved leader who will manage the accounts.
3. Upload the updated website ZIP to Netlify using the site's deploy page. Do not upload the ZIP into Supabase.

All approved leaders can view finance records. Only the administrator and the appointed treasurer can add, edit, or delete transactions. Amounts are recorded in Zambian Kwacha (ZMW). Never place a Supabase secret/service-role key in the website files.
