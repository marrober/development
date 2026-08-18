const MAX_EVENTS = 500;

const events = [];

function addEvent(event) {
  events.unshift(event);
  if (events.length > MAX_EVENTS) {
    events.length = MAX_EVENTS;
  }
  return event;
}

function listEvents() {
  return events.map((event) => ({
    eventId: event.eventId,
    receivedAt: event.receivedAt,
    path: event.path,
    decoded: event.decoded,
    decodeError: event.decodeError,
    brief: event.brief,
    summary: event.summary,
  }));
}

function getEvent(eventId) {
  return events.find((event) => event.eventId === eventId);
}

function clearEvents() {
  events.length = 0;
}

function getStats() {
  return {
    storedEventCount: events.length,
    decodedEventCount: events.filter((event) => event.decoded).length,
  };
}

module.exports = {
  addEvent,
  listEvents,
  getEvent,
  clearEvents,
  getStats,
};
