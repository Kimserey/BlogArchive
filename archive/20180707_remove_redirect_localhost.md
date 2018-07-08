# Remove redirection of localhost to HTTPS

## Symptoms

- Chrome redirects `http://localhost` to `https://localhost`
- On guest mode, `http://localhost` is accessible
- Curl can retrieve `http://localhost`

## Cause

One of my test project was configuring SSL on nginx.
__The configuration was redirecting `localhost` to `https` for testing purposes and Chrome had since then cached the redirection.__ 
Subsequent calls were no longer hitting nginx as they were only hitting Chrome cache.

## Fix

1. Open the `Web Developer Console` on Chrome, `CTRL+SHIFT+I`
2. Right click on the reload arrow 
3. Select `Empty Cache And Hard Reload`

This will remove all cached items including the redirection. `http://localhost` will no longer be redirected by Chrome.