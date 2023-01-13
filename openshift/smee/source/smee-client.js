const SmeeClient = require('smee-client')

const smee = new SmeeClient({
  source: 'https://smee.io/3aC3MfW0AoBzRW6',
  target: 'http://localhost:3000/events',
  logger: console
})

const events = smee.start()

// Stop forwarding events
events.close()