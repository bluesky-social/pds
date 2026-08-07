import type { AtIdentifierString } from '@atproto/lex'
import { PDS, httpLogger, readEnv } from '@atproto/pds'
import pkg from '@atproto/pds/package.json' with { type: 'json' }
import type { Request, Response } from 'express'

// matches docker tag used in compose file, may deviate from @atproto/pds version.
const DISTRO_VER = '0.4'

void PDS.run({
  env: getEnv(),
  onCreated: (pds) => {
    pds.app.get('/tls-check', async (req, res) => {
      try {
        const { domain } = req.query
        if (!domain || typeof domain !== 'string') {
          return res.status(400).json({
            error: 'InvalidRequest',
            message: 'bad or missing domain query param'
          })
        }
        if (domain === pds.ctx.cfg.service.hostname) {
          return res.json({ success: true })
        }
        const isHostedHandle = pds.ctx.cfg.identity.serviceHandleDomains.find(
          (avail) => domain.endsWith(avail)
        )
        if (!isHostedHandle) {
          return res.status(400).json({
            error: 'InvalidRequest',
            message: 'handles are not provided on this domain'
          })
        }
        const account = await pds.ctx.accountManager.getAccount(
          domain as AtIdentifierString
        )
        if (!account) {
          return res.status(404).json({
            error: 'NotFound',
            message: 'handle not found for this domain'
          })
        }
        return res.json({ success: true })
      } catch (err) {
        httpLogger.error({ err }, 'check handle failed')
        return res.status(500).json({
          error: 'InternalServerError',
          message: 'Internal Server Error'
        })
      }
    })
  }
}).catch((err) => {
  // @NOTE we don't want to let the error propagate to the UnhandledRejection
  // handler, because that would cause Node to exit, which won't allow telemetry
  // to flush. Instead, we log the error and set the exit code.
  console.error('PDS failed to start:', err)
  process.exitCode = 1

  // In case the some resource were not properly cleaned up, we force exit after
  // a short delay. This is a last resort, and should not be necessary if the
  // PDS is implemented correctly. The delay is to give the telemetry a chance
  // to flush.
  setTimeout(() => process.exit(process.exitCode || 1), 5000).unref()
})

function getEnv() {
  const env = readEnv()
  env.version ||= ver(DISTRO_VER, pkg.version)
  return env
}

// e.g. ver('0.4', '0.5.1') -> '0.4.5001'
function ver(base: `${string}.${string}`, pkgver: string) {
  const { 0: major, 1: minor, 2: patch, length } = pkgver.split('.')
  if (length !== 3) return pkgver
  if (major !== '0') return pkgver
  if (minor === '' || minor === '0') return pkgver
  if (patch === '') return pkgver
  return `${base}.${minor}${patch.padStart(3, '0')}`
}
