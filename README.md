# MyGrowLight – Personal Finance

A single-file personal finance web app (login/register, income & expense
transactions, savings, members, and a dashboard). The entry point is
[`index.html`](index.html) and it currently stores data in the browser's
`localStorage`.

## Run locally

Just open `index.html` in a browser, or serve the folder:

```bash
npx serve .
```

## Deploy to Netlify

This is a static site — no build step. `netlify.toml` sets the publish
directory to the repo root and serves `index.html`.

1. Push this repo to GitHub (see below).
2. Go to https://app.netlify.com/start/repos
3. Pick the `lairubusiness/My_Grow_Light` repository.
4. Leave **Build command** empty and **Publish directory** as `.` (or `/`).
5. Click **Deploy**.

## Push to GitHub

```bash
git remote add origin https://github.com/lairubusiness/My_Grow_Light.git
git branch -M main
git push -u origin main
```

When prompted, sign in with the GitHub account that owns the repo
(`udlsbusiness666@gmail.com`). Use a **Personal Access Token** as the
password (Settings → Developer settings → Personal access tokens).

## Supabase (planned backend)

- Project: `vjlgfdrtecbokpylojpg`
- URL: `https://vjlgfdrtecbokpylojpg.supabase.co`
- Publishable (anon) key: `sb_publishable_yHY5_IbzXmFhsSKL8J6srQ_us0fXeE5`

The publishable/anon key above is safe to ship in client-side code.
**Never** commit the Postgres connection string or the service-role key.

To link the project with the CLI later:

```bash
npm install -g supabase
supabase login
supabase init
supabase link --project-ref vjlgfdrtecbokpylojpg
```

> The app does not use Supabase yet — it runs on `localStorage`. Migrating
> auth and data to Supabase is the next step.
