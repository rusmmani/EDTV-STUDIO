# EDTV Studio — Static HTML + Supabase + Vercel

Versi ini sengaja dibuat tanpa Next.js, Node.js, npm, atau backend tambahan. Vercel hanya menyajikan file static, sedangkan Supabase menangani Auth, PostgreSQL, dan Storage.

## Struktur
- `index.html` — seluruh UI + JavaScript aplikasi.
- `config.js` — isi URL dan client/publishable/anon key Supabase.
- `supabase/schema.sql` — database, RLS, dan Storage policies.

## Instalasi
1. Buat project Supabase.
2. Supabase → SQL Editor → jalankan seluruh `supabase/schema.sql`.
3. Supabase → Authentication → Providers → Email → aktifkan Email.
4. Edit `config.js`:

```js
window.EDTV_CONFIG = {
  SUPABASE_URL: 'https://PROJECT.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR_CLIENT_OR_PUBLISHABLE_KEY'
};
```

5. Upload seluruh folder ini ke repository GitHub.
6. Di Vercel → Add New Project → Import repository tersebut.
7. Framework preset: Other (atau Static Site jika tersedia). Tidak perlu Build Command. Output directory: `.`.
8. Deploy.
9. Supabase → Authentication → URL Configuration → isi Site URL dengan domain Vercel.

## Penting
`SUPABASE_ANON_KEY` / publishable client key boleh berada di frontend. Jangan masukkan `service_role` key. Keamanan data berasal dari Row Level Security (RLS) di `schema.sql`.

## Fitur
- Login / register Supabase Auth.
- Dashboard project.
- Create/delete project.
- Script Action, Dialog, Expression, Shot.
- Save script ke PostgreSQL.
- Moodboard 4 kategori dengan upload/replace.
- Walkthrough video upload/replace.
- Private Supabase Storage + signed URLs.
- Responsive desktop/mobile.
- Hash routing sehingga tidak memerlukan rewrite Vercel.
