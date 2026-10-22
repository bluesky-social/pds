// Mirrors atproto's services/pds/run-script.ts so the commands in
// @atproto/pds's scripts README work in this image:
//   docker exec -it pds node run-script.js SCRIPT_NAME [ARGS...]
import { AppContext, scripts } from '@atproto/pds'

const main = async () => {
  const ctx = await AppContext.fromEnv()
  const scriptName = process.argv[2]
  const script = Object.hasOwn(scripts, scriptName)
    ? scripts[scriptName]
    : undefined
  if (!script) {
    throw new Error(`could not find script: ${scriptName}`)
  }
  await script(ctx, process.argv.slice(3))
  console.log('DONE')
}

main()
