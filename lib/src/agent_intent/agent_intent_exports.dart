// The AGENT-INTENT COMPOSITION LAYER: the step from an agent's wire payload
// to a rendered component.
//
// Everything under `eden_data_display/` takes TYPED DART DATA. This library
// is what turns `{component_id, data, actions}` into that data and picks the
// widget. It is the transport owner, and it is the only place in this
// package that reads the wire format.
//
// THE CONTRACT IT ENFORCES, in one place so no consumer has to rediscover it:
//
//  1. The renderer never fetches. Everything drawn comes from the payload.
//  2. Affordances are granted by the payload. A control exists only when
//     `intent.actions` carries its id; empty actions mean read-only, which
//     is correct rather than degraded.
//  3. Actions bind to tool ids or proposal ids, NEVER to routes. A route
//     binding would be an authorization bypass.
//  4. Refusal is one-sided: zero actions, and it carries a reason.
//  5. What this layer cannot do honestly becomes a refusal — never a guess,
//     never a crash.
library;

export 'eden_agent_intent.dart';
export 'eden_intent_decoder.dart';
