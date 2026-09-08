# clinreg-website

Publishes the ClinReg leaderboard to **https://clinreg.log10.io** via GitHub Pages.

Everything under [`site/`](site/) is the live site. Pushing to `main` deploys it.

## Publishing a leaderboard

```sh
make publish HTML=output.html                  # page only
make publish HTML=output.html CSV=data.csv     # page + downloadable data
```

That copies the files into `site/`, commits, and pushes. The push triggers
[deploy.yml](.github/workflows/deploy.yml), and the board is live about a minute
later. The CSV lands at `/data.csv`, same origin as the page, so the HTML can
`fetch("data.csv")` with no CORS setup.

Add `SNAPSHOT=1` to also archive the board under `site/runs/<date>/`, which keeps
it linkable after the next publish replaces the front page.

```sh
make serve     # preview site/ at http://localhost:8000
make check     # verify site/ still has the files Pages needs
```

## One-time setup

Pages on the Team plan serves public repositories only, so step 1 is required
before any of the rest works.

**1. Make the repository public**

```sh
gh repo edit log10-io/clinreg-website --visibility public \
  --accept-visibility-change-consequences
```

**2. Turn on Pages with GitHub Actions as the source**

```sh
gh api -X POST repos/log10-io/clinreg-website/pages -f build_type=workflow
```

Or: Settings → Pages → Source → *GitHub Actions*.

**3. Point the domain at it**

Add one record in Cloudflare, on the `log10.io` zone:

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `clinreg` | `log10-io.github.io` | **DNS only** (grey cloud) |

The target is the *organization* Pages host, with no repository path in it.

The grey cloud is load-bearing. Cloudflare proxying intercepts the ACME
challenge GitHub uses to issue the TLS certificate, and provisioning then hangs
indefinitely with no useful error. Leave the record unproxied — this matches
`app.everest.log10.io`, which is also a DNS-only CNAME to its origin.

**4. Set the custom domain and enforce HTTPS**

```sh
gh api -X PUT repos/log10-io/clinreg-website/pages -f cname=clinreg.log10.io
```

Certificate issuance takes a few minutes once DNS resolves. When Settings →
Pages stops showing the certificate as pending, tick **Enforce HTTPS** (or
`gh api -X PUT repos/log10-io/clinreg-website/pages -F https_enforced=true`).

## Repository layout

```
site/
  index.html      the leaderboard; make publish overwrites this
  data.csv        underlying data, when published alongside
  404.html
  CNAME           custom domain, kept in-repo so the intent is visible
  .nojekyll       stops Pages from hiding paths that start with _
  runs/<date>/    archived boards, when published with SNAPSHOT=1
scripts/publish.sh
.github/workflows/deploy.yml
```

## Notes

Pages gives no control over response headers, so there is no CSP, no custom
cache-control, and no access logs here. If the leaderboard ever needs any of
those — or the generator has to move into a private repository — the equivalent
setup is S3 + CloudFront + ACM, following the pattern in everest's
`packages/app/infra/modules/artifact-sandbox`.

Soft limits worth knowing: 1 GB published site, 100 GB/month bandwidth, 10
builds per hour.
