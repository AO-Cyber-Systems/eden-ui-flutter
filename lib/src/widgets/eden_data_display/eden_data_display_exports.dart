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
export 'eden_customer_list.dart';
export 'eden_proposal_card.dart';
export 'eden_refusal.dart';
export 'eden_service_list.dart';

// IMPORTED as well as exported, deliberately: a barrel that only re-exports
// cannot SEE the symbols it names, and [kDataDisplayComponents] below has to
// reference them.
import 'eden_appointment_list.dart';
import 'eden_customer_list.dart';
import 'eden_proposal_card.dart';
import 'eden_refusal.dart';
import 'eden_service_list.dart';

/// Every `component_id` this package can actually render, paired with the
/// widget that renders it.
///
/// THE FIRST AUTHORITATIVE LIST, and until now there was none on either side
/// of the seam. A headless agent names a surface by `component_id` and this
/// package draws it; eden-biz carries 15 recorded fixtures using 10 distinct
/// ids, and its own integrity test (`go/internal/agentintent/
/// fixtures_integrity_test.go`) asserts only that the field is NON-EMPTY. So
/// an agent could emit `summary/pipeline`, the Go fixture test would pass,
/// and nothing anywhere knew the renderer cannot draw it. An unknown
/// `component_id` was an UNDETECTABLE condition; this list is what makes it
/// a detectable one.
///
/// FIVE ENTRIES, AND THE COUNT IS THE POINT. Five of eden-biz's ten ids
/// still have no renderer here — `detail/appointment`,
/// `detail/customer-history`, `list/availability-slots`,
/// `summary/pipeline`, `summary/scheduling`. An honest list of five plus a
/// working refusal path beats a hand-maintained list of ten, five of which
/// would be lies. [EdenRefusal] is the declared destination for an id that
/// is not here.
///
/// DIRECTION OF THE DEPENDENCY: this declares what eden-ui CAN RENDER, and
/// eden-biz checks its fixtures against it. The reverse — hard-coding
/// eden-biz's fixture ids here — would invert the dependency and make the
/// component library track the agent's test data.
///
/// THE ID COMES FROM THE WIDGET'S OWN STATIC, never a re-typed literal. A
/// re-typed string is a second list, and a second list is the drift this
/// exists to close. `test/tool/emit_component_manifest_test.dart` holds the
/// closed partition: every `componentId` declared under this directory must
/// appear here, and every entry here must still exist in source.
const List<(String, Type)> kDataDisplayComponents = <(String, Type)>[
  (EdenAppointmentList.componentId, EdenAppointmentList),
  (EdenRefusal.componentId, EdenRefusal),
  (EdenCustomerList.componentId, EdenCustomerList),
  (EdenServiceList.componentId, EdenServiceList),
  (EdenProposalCard.componentId, EdenProposalCard),
];
