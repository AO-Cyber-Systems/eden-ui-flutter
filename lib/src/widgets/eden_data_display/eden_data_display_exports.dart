// The DATA-DISPLAY components: widgets that render an agent-intent payload.
//
// These are the components a headless agent names by `component_id`. Each one
// exposes that id as a static on the widget (`EdenAppointmentList.componentId`,
// `EdenRefusal.componentId`) so a dispatcher can build its map by reading the
// components rather than maintaining a second list beside them.
//
// Their DATA SHAPES are transcribed from recorded production payloads — see
// the provenance block at the top of `agent_intent_data.dart`.

export 'agent_intent_data.dart';
export 'eden_appointment_list.dart';
export 'eden_refusal.dart';
