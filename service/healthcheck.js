// Used by the Dockerfile HEALTHCHECK in place of curl or wget, which the image
// does not include. Exits 0 when the PDS answers /xrpc/_health with a 2xx
// status, and 1 otherwise.
const port = process.env.PDS_PORT || '3000'
const url = `http://localhost:${port}/xrpc/_health`

try {
  const res = await fetch(url, { signal: AbortSignal.timeout(5000) })
  if (!res.ok) {
    console.error(`healthcheck failed: ${url} returned ${res.status}`)
    process.exit(1)
  }
} catch (err) {
  const reason = err.cause?.code ?? err.cause?.message ?? err.message
  console.error(`healthcheck failed: ${url}: ${reason}`)
  process.exit(1)
}
