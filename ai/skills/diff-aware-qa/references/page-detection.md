# Mapping Changed Files to Affected Pages

## Next.js App Router (`app/` directory)

| Changed file pattern | Affected route |
|---|---|
| `app/page.tsx` | `/` |
| `app/dashboard/page.tsx` | `/dashboard` |
| `app/[slug]/page.tsx` | All dynamic routes under `/` |
| `app/layout.tsx` | All routes (global layout change) |
| `app/dashboard/layout.tsx` | All routes under `/dashboard` |

**Components:** trace upward — find all `import` references to the changed component, then map those files to their routes using the table above.

```bash
# Find all files importing a changed component
grep -r "from.*ComponentName" app/ --include="*.tsx" -l
```

## Next.js Pages Router (`pages/` directory)

File path maps directly to route:
- `pages/index.tsx` → `/`
- `pages/dashboard.tsx` → `/dashboard`
- `pages/api/events.ts` → API route, no browser test needed

## Non-web projects (skip browser testing)

- Go files, `.go` extension → skip, note "CLI project — no browser testing"
- Godot files, `.gd` or `.tscn` extension → skip, note "Godot project — no browser testing"
- API-only changes (files only in `api/` or `server/`) → skip browser, note "API-only change"

## Dev server URLs

Always test against the local dev server. Common ports:
- Next.js: `http://localhost:3000`
- Vite: `http://localhost:5173`
- Custom: check `package.json` scripts for `--port` flag
