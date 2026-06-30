# MyGrowLight – Supabase Database

Project: `vjlgfdrtecbokpylojpg`
URL: https://vjlgfdrtecbokpylojpg.supabase.co

## What's here

`migrations/0001_init.sql` creates the full schema:

| Table            | Purpose                                  |
|------------------|------------------------------------------|
| `profiles`       | 1:1 with `auth.users` (name, NIC, phone) |
| `members`        | Team members who save together           |
| `transactions`   | Income / expense records                 |
| `savings_boxes`  | Digital piggy banks (with running balance)|
| `savings_log`    | Deposit / withdraw history               |

Includes:
- **Row Level Security** – every user only sees their own rows.
- A trigger that auto-creates a `profiles` row when a user signs up.
- A trigger that keeps `savings_boxes.balance` in sync with `savings_log`.

## Apply the schema

### Option A – SQL editor (fastest, no CLI)
1. Open https://supabase.com/dashboard/project/vjlgfdrtecbokpylojpg/sql/new
2. Paste the contents of `migrations/0001_init.sql` and run it.

### Option B – Supabase CLI
Install the CLI first (it is **not** installable via `npm i -g`):

```bash
# Windows (scoop)
scoop install supabase
# or download from https://github.com/supabase/cli/releases
```

Then, from the project root:

```bash
supabase login                                  # opens browser for an access token
supabase link --project-ref vjlgfdrtecbokpylojpg
supabase db push                                # applies migrations/0001_init.sql
```

`supabase login` and `supabase db push` need the database password (the
`[YOUR-PASSWORD]` in your connection string), so they must be run by you
interactively — they can't be automated here.

## Frontend keys (for wiring the app to Supabase later)

```
SUPABASE_URL=https://vjlgfdrtecbokpylojpg.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_yHY5_IbzXmFhsSKL8J6srQ_us0fXeE5
```

> The app currently stores data in `localStorage`. Connecting it to this
> database is a separate step (load `@supabase/supabase-js`, replace the
> `save()/load()` layer with Supabase Auth + queries).
