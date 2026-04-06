import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Showcase screen for the Trades-inspired enterprise UI components.
class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  // ---------------------------------------------------------------------------
  // Scheduler state
  // ---------------------------------------------------------------------------
  EdenSchedulerView _schedulerView = EdenSchedulerView.week;
  final Set<String> _selectedAssignees = {};

  final _schedulerEvents = [
    EdenSchedulerEvent(
      id: 'e1',
      title: 'HVAC Repair — Johnson',
      start: DateTime(2026, 3, 23, 9, 0),
      end: DateTime(2026, 3, 23, 11, 0),
      assignee: 'Mike T.',
      color: Colors.blue,
      description: 'Replace condenser unit at 742 Evergreen Terrace',
    ),
    EdenSchedulerEvent(
      id: 'e2',
      title: 'Plumbing Inspection',
      start: DateTime(2026, 3, 23, 13, 0),
      end: DateTime(2026, 3, 23, 14, 30),
      assignee: 'Sarah K.',
      color: Colors.teal,
    ),
    EdenSchedulerEvent(
      id: 'e3',
      title: 'Electrical Panel Upgrade',
      start: DateTime(2026, 3, 24, 8, 0),
      end: DateTime(2026, 3, 24, 12, 0),
      assignee: 'Mike T.',
      color: Colors.orange,
    ),
    EdenSchedulerEvent(
      id: 'e4',
      title: 'Water Heater Install',
      start: DateTime(2026, 3, 24, 14, 0),
      end: DateTime(2026, 3, 24, 16, 0),
      assignee: 'David R.',
      color: Colors.purple,
    ),
    EdenSchedulerEvent(
      id: 'e5',
      title: 'Thermostat Replacement',
      start: DateTime(2026, 3, 25, 10, 0),
      end: DateTime(2026, 3, 25, 11, 0),
      assignee: 'Sarah K.',
      color: Colors.green,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Approval queue state
  // ---------------------------------------------------------------------------
  final _approvalItems = [
    EdenApprovalItem(
      id: 'a1',
      title: 'Work Order #4821 — HVAC Compressor Replacement',
      subtitle: 'Estimated: \$2,450.00',
      submittedBy: 'Mike Torres',
      submittedAt: DateTime(2026, 3, 21, 14, 30),
      priority: EdenApprovalPriority.high,
      status: EdenApprovalStatus.pending,
      metadata: {'Customer': 'Johnson Residence', 'Parts': '3 items'},
    ),
    EdenApprovalItem(
      id: 'a2',
      title: 'Change Order — Additional Outlet Install',
      subtitle: 'Estimated: \$380.00',
      submittedBy: 'Sarah Kim',
      submittedAt: DateTime(2026, 3, 21, 10, 15),
      priority: EdenApprovalPriority.normal,
      status: EdenApprovalStatus.pending,
      metadata: {'Project': 'Martin Remodel'},
    ),
    EdenApprovalItem(
      id: 'a3',
      title: 'Overtime Request — Emergency Pipe Burst',
      submittedBy: 'David Ruiz',
      submittedAt: DateTime(2026, 3, 20, 22, 0),
      priority: EdenApprovalPriority.urgent,
      status: EdenApprovalStatus.approved,
    ),
    EdenApprovalItem(
      id: 'a4',
      title: 'Material Purchase — 200ft Copper Pipe',
      subtitle: '\$1,200.00 from Ferguson Supply',
      submittedBy: 'Mike Torres',
      submittedAt: DateTime(2026, 3, 19, 9, 0),
      priority: EdenApprovalPriority.normal,
      status: EdenApprovalStatus.rejected,
    ),
    EdenApprovalItem(
      id: 'a5',
      title: 'Subcontractor Invoice — ABC Concrete',
      subtitle: '\$3,750.00',
      submittedBy: 'Sarah Kim',
      submittedAt: DateTime(2026, 3, 18, 16, 45),
      priority: EdenApprovalPriority.low,
      status: EdenApprovalStatus.changesRequested,
      metadata: {'Invoice #': 'ABC-2026-0891'},
    ),
  ];

  // ---------------------------------------------------------------------------
  // Checklist state
  // ---------------------------------------------------------------------------
  final _checklistItems = [
    EdenChecklistItem(
      id: 'sec1',
      title: 'Pre-Arrival',
      sectionHeader: 'Pre-Arrival',
      children: [
        EdenChecklistItem(
          id: 'c1',
          title: 'Review work order details',
          isChecked: true,
        ),
        EdenChecklistItem(
          id: 'c2',
          title: 'Confirm customer contact info',
          isChecked: true,
          isRequired: true,
        ),
        EdenChecklistItem(
          id: 'c3',
          title: 'Load required parts on truck',
          type: EdenChecklistItemType.checkbox,
        ),
      ],
    ),
    EdenChecklistItem(
      id: 'sec2',
      title: 'On-Site Inspection',
      sectionHeader: 'On-Site Inspection',
      children: [
        EdenChecklistItem(
          id: 'c4',
          title: 'Photograph existing equipment',
          type: EdenChecklistItemType.photoRequired,
          isRequired: true,
        ),
        EdenChecklistItem(
          id: 'c5',
          title: 'Record model & serial numbers',
          type: EdenChecklistItemType.textInput,
          isRequired: true,
        ),
        EdenChecklistItem(
          id: 'c6',
          title: 'Check electrical connections',
        ),
        EdenChecklistItem(
          id: 'c7',
          title: 'Test airflow / water pressure',
        ),
      ],
    ),
    EdenChecklistItem(
      id: 'sec3',
      title: 'Completion',
      sectionHeader: 'Completion',
      children: [
        EdenChecklistItem(
          id: 'c8',
          title: 'Customer sign-off',
          type: EdenChecklistItemType.signatureRequired,
          isRequired: true,
        ),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Permission matrix state
  // ---------------------------------------------------------------------------
  List<EdenRole> _roles = [
    const EdenRole(
      id: 'admin',
      name: 'Admin',
      color: Colors.indigo,
      permissions: {
        'wo_create', 'wo_edit', 'wo_delete', 'wo_assign',
        'inv_view', 'inv_manage',
        'rep_view', 'rep_export',
      },
    ),
    const EdenRole(
      id: 'manager',
      name: 'Field Manager',
      color: Colors.teal,
      permissions: {
        'wo_create', 'wo_edit', 'wo_assign',
        'inv_view', 'inv_manage',
        'rep_view',
      },
    ),
    const EdenRole(
      id: 'tech',
      name: 'Technician',
      color: Colors.orange,
      permissions: {
        'wo_edit',
        'inv_view',
        'rep_view',
      },
    ),
  ];

  final _permissions = const [
    EdenPermission(id: 'wo_create', label: 'Create Work Orders', category: 'Work Orders'),
    EdenPermission(id: 'wo_edit', label: 'Edit Work Orders', category: 'Work Orders'),
    EdenPermission(id: 'wo_delete', label: 'Delete Work Orders', category: 'Work Orders'),
    EdenPermission(id: 'wo_assign', label: 'Assign Technicians', category: 'Work Orders'),
    EdenPermission(id: 'inv_view', label: 'View Inventory', category: 'Inventory & Reports'),
    EdenPermission(id: 'inv_manage', label: 'Manage Inventory', category: 'Inventory & Reports'),
    EdenPermission(id: 'rep_view', label: 'View Reports', category: 'Inventory & Reports'),
    EdenPermission(id: 'rep_export', label: 'Export Reports', category: 'Inventory & Reports'),
  ];

  // ---------------------------------------------------------------------------
  // Sync indicator state
  // ---------------------------------------------------------------------------
  EdenSyncStatus _syncStatus = EdenSyncStatus.syncing;

  // ---------------------------------------------------------------------------
  // Activity feed data
  // ---------------------------------------------------------------------------
  final _activities = [
    EdenActivity(
      id: 'act1',
      type: EdenActivityType.statusChange,
      actorName: 'Mike Torres',
      timestamp: DateTime(2026, 3, 22, 14, 35),
      title: 'Marked WO #4821 as In Progress',
      body: 'Arrived on site, beginning HVAC compressor replacement.',
    ),
    EdenActivity(
      id: 'act2',
      type: EdenActivityType.upload,
      actorName: 'Mike Torres',
      timestamp: DateTime(2026, 3, 22, 14, 20),
      title: 'Uploaded 3 photos to WO #4821',
    ),
    EdenActivity(
      id: 'act3',
      type: EdenActivityType.comment,
      actorName: 'Sarah Kim',
      timestamp: DateTime(2026, 3, 22, 13, 50),
      title: 'Commented on WO #4789',
      body: 'Parts are back-ordered until Thursday. @DavidR can you check the warehouse?',
    ),
    EdenActivity(
      id: 'act4',
      type: EdenActivityType.assignment,
      actorName: 'System',
      timestamp: DateTime(2026, 3, 22, 12, 0),
      title: 'Auto-assigned WO #4830 to David Ruiz',
      body: 'Based on proximity and availability.',
    ),
    EdenActivity(
      id: 'act5',
      type: EdenActivityType.approval,
      actorName: 'Janet Lee',
      timestamp: DateTime(2026, 3, 22, 11, 30),
      title: 'Approved overtime request',
      body: 'Emergency pipe burst — approved 4 hours OT for @DavidR.',
    ),
    EdenActivity(
      id: 'act6',
      type: EdenActivityType.statusChange,
      actorName: 'David Ruiz',
      timestamp: DateTime(2026, 3, 22, 10, 0),
      title: 'Completed WO #4815',
    ),
    EdenActivity(
      id: 'act7',
      type: EdenActivityType.system,
      actorName: 'System',
      timestamp: DateTime(2026, 3, 22, 9, 0),
      title: 'Daily route optimization completed',
      body: '12 work orders scheduled across 3 technicians.',
    ),
    EdenActivity(
      id: 'act8',
      type: EdenActivityType.comment,
      actorName: 'Janet Lee',
      timestamp: DateTime(2026, 3, 22, 8, 45),
      title: 'Left a note on WO #4810',
      body: 'Customer requested afternoon window only. Please reschedule.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Map view state
  // ---------------------------------------------------------------------------
  final _mapMarkers = [
    const EdenMapMarker(
      id: 'm1',
      latitude: 33.749,
      longitude: -84.388,
      label: 'Johnson Residence',
      category: 'Residential',
      icon: Icons.home,
      color: Colors.blue,
    ),
    const EdenMapMarker(
      id: 'm2',
      latitude: 33.755,
      longitude: -84.395,
      label: 'Martin Remodel',
      category: 'Commercial',
      icon: Icons.business,
      color: Colors.orange,
    ),
    const EdenMapMarker(
      id: 'm3',
      latitude: 33.742,
      longitude: -84.380,
      label: 'Warehouse #2',
      category: 'Internal',
      icon: Icons.warehouse,
      color: Colors.green,
    ),
  ];

  final _mapFilters = [
    const EdenMapFilter(id: 'res', label: 'Residential', color: Colors.blue, isSelected: true),
    const EdenMapFilter(id: 'com', label: 'Commercial', color: Colors.orange, isSelected: true),
    const EdenMapFilter(id: 'int', label: 'Internal', color: Colors.green),
  ];

  // ---------------------------------------------------------------------------
  // Barcode scanner state
  // ---------------------------------------------------------------------------
  final _scanHistory = [
    EdenScanRecord(
      value: 'WO-2026-04821',
      format: EdenBarcodeFormat.qrCode,
      timestamp: DateTime(2026, 3, 22, 14, 10),
    ),
    EdenScanRecord(
      value: 'PART-CMP-4490X',
      format: EdenBarcodeFormat.code128,
      timestamp: DateTime(2026, 3, 22, 13, 55),
    ),
    EdenScanRecord(
      value: '4901234567890',
      format: EdenBarcodeFormat.ean13,
      timestamp: DateTime(2026, 3, 22, 11, 30),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Data grid data
  // ---------------------------------------------------------------------------
  final _workOrders = <Map<String, String>>[
    {'id': 'WO-4821', 'customer': 'Johnson, R.', 'type': 'HVAC', 'status': 'In Progress', 'tech': 'Mike T.', 'est': '\$2,450'},
    {'id': 'WO-4822', 'customer': 'Martin, P.', 'type': 'Electrical', 'status': 'Scheduled', 'tech': 'Sarah K.', 'est': '\$380'},
    {'id': 'WO-4823', 'customer': 'Garcia, M.', 'type': 'Plumbing', 'status': 'Completed', 'tech': 'David R.', 'est': '\$1,200'},
    {'id': 'WO-4824', 'customer': 'Chen, W.', 'type': 'HVAC', 'status': 'Pending', 'tech': 'Unassigned', 'est': '\$890'},
    {'id': 'WO-4825', 'customer': 'Brown, T.', 'type': 'Plumbing', 'status': 'Scheduled', 'tech': 'David R.', 'est': '\$550'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trades Components')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // ---------------------------------------------------------------
          // 1. Scheduler
          // ---------------------------------------------------------------
          Section(
            title: 'SCHEDULER',
            child: SizedBox(
              height: 520,
              child: EdenScheduler(
                events: _schedulerEvents,
                view: _schedulerView,
                initialDate: DateTime(2026, 3, 23),
                assignees: const ['Mike T.', 'Sarah K.', 'David R.'],
                selectedAssignees: _selectedAssignees,
                onViewChanged: (v) => setState(() => _schedulerView = v),
                onAssigneeFilterChanged: (s) => setState(() {
                  _selectedAssignees
                    ..clear()
                    ..addAll(s);
                }),
                onEventTap: (e) {},
                onTimeSlotTap: (dt) {},
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // 2. Calendar (enhanced)
          // ---------------------------------------------------------------
          Section(
            title: 'CALENDAR',
            child: EdenCalendar(
              initialDate: DateTime(2026, 3, 22),
              onDateSelected: (d) {},
              events: [
                EdenCalendarEvent(date: DateTime(2026, 3, 23), color: Colors.blue),
                EdenCalendarEvent(date: DateTime(2026, 3, 23), color: Colors.teal),
                EdenCalendarEvent(date: DateTime(2026, 3, 24), color: Colors.orange),
                EdenCalendarEvent(date: DateTime(2026, 3, 24), color: Colors.purple),
                EdenCalendarEvent(date: DateTime(2026, 3, 25), color: Colors.green),
                EdenCalendarEvent(date: DateTime(2026, 3, 27)),
                EdenCalendarEvent(date: DateTime(2026, 3, 27)),
                EdenCalendarEvent(date: DateTime(2026, 3, 27)),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // 3. Document Viewer
          // ---------------------------------------------------------------
          Section(
            title: 'DOCUMENT VIEWER',
            child: SizedBox(
              height: 400,
              child: EdenDocumentViewer(
                showThumbnails: true,
                pages: [
                  _DocPage(color: EdenColors.blue[50]!, label: 'Work Order #4821', subtitle: 'Page 1 — Customer Agreement'),
                  _DocPage(color: EdenColors.emerald[50]!, label: 'Service Report', subtitle: 'Page 2 — Inspection Details'),
                  _DocPage(color: EdenColors.gold[50]!, label: 'Invoice', subtitle: 'Page 3 — Billing Summary'),
                ],
                annotations: const [
                  EdenDocumentAnnotation(
                    id: 'ann1',
                    page: 0,
                    rect: Rect.fromLTWH(0.1, 0.2, 0.35, 0.08),
                    text: 'Customer signature required here',
                    type: EdenAnnotationType.note,
                    color: Color(0xFFF59E0B),
                  ),
                  EdenDocumentAnnotation(
                    id: 'ann2',
                    page: 1,
                    rect: Rect.fromLTWH(0.05, 0.5, 0.9, 0.06),
                    type: EdenAnnotationType.highlight,
                  ),
                ],
                onAnnotationTap: (a) {},
                onPageChanged: (p) {},
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // 4. Signature Pad
          // ---------------------------------------------------------------
          Section(
            title: 'SIGNATURE PAD — Interactive',
            child: EdenSignaturePad(
              height: 180,
              placeholderText: 'Customer signature',
              onSignatureChanged: (strokes) {},
            ),
          ),
          Section(
            title: 'SIGNATURE PAD — Read-only (Captured)',
            child: EdenSignaturePad(
              height: 140,
              readOnly: true,
              placeholderText: 'No signature captured',
              initialStrokes: [
                EdenSignatureStroke(
                  points: [
                    const EdenSignaturePoint(20, 100),
                    const EdenSignaturePoint(40, 60),
                    const EdenSignaturePoint(60, 80),
                    const EdenSignaturePoint(80, 40),
                    const EdenSignaturePoint(110, 70),
                    const EdenSignaturePoint(140, 50),
                    const EdenSignaturePoint(170, 90),
                    const EdenSignaturePoint(200, 60),
                    const EdenSignaturePoint(230, 80),
                    const EdenSignaturePoint(260, 45),
                  ],
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // 5. Form Wizard
          // ---------------------------------------------------------------
          Section(
            title: 'FORM WIZARD',
            child: SizedBox(
              height: 420,
              child: EdenFormWizard(
                mode: EdenWizardMode.linear,
                onSubmit: () {},
                steps: [
                  EdenWizardStep(
                    title: 'Customer Info',
                    icon: Icons.person,
                    content: (ctx, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EdenInput(label: 'Customer Name', hint: 'e.g. Robert Johnson'),
                          const SizedBox(height: EdenSpacing.space3),
                          EdenInput(label: 'Phone', hint: '(555) 123-4567'),
                          const SizedBox(height: EdenSpacing.space3),
                          EdenInput(label: 'Address', hint: '742 Evergreen Terrace'),
                        ],
                      ),
                    ),
                  ),
                  EdenWizardStep(
                    title: 'Service Details',
                    icon: Icons.build,
                    content: (ctx, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EdenInput(label: 'Service Type', hint: 'HVAC, Plumbing, Electrical...'),
                          const SizedBox(height: EdenSpacing.space3),
                          EdenInput(label: 'Issue Description', hint: 'Describe the problem...', maxLines: 3),
                          const SizedBox(height: EdenSpacing.space3),
                          EdenInput(label: 'Priority', hint: 'Normal'),
                        ],
                      ),
                    ),
                  ),
                  EdenWizardStep(
                    title: 'Schedule',
                    icon: Icons.calendar_today,
                    content: (ctx, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EdenInput(label: 'Preferred Date', hint: '03/25/2026'),
                          const SizedBox(height: EdenSpacing.space3),
                          EdenInput(label: 'Time Window', hint: 'Morning (8 AM–12 PM)'),
                          const SizedBox(height: EdenSpacing.space3),
                          EdenInput(label: 'Assigned Technician', hint: 'Auto-assign'),
                        ],
                      ),
                    ),
                  ),
                  EdenWizardStep(
                    title: 'Review',
                    icon: Icons.check_circle,
                    content: (ctx, _) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review your work order details before submitting.',
                              style: TextStyle(fontSize: 14)),
                          SizedBox(height: EdenSpacing.space3),
                          _ReviewRow(label: 'Customer', value: 'Robert Johnson'),
                          _ReviewRow(label: 'Service', value: 'HVAC — Compressor Replacement'),
                          _ReviewRow(label: 'Date', value: 'March 25, 2026 — Morning'),
                          _ReviewRow(label: 'Technician', value: 'Auto-assign'),
                          _ReviewRow(label: 'Estimate', value: '\$2,450.00'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // 6. Approval Queue
          // ---------------------------------------------------------------
          Section(
            title: 'APPROVAL QUEUE',
            child: EdenApprovalQueue(
              items: _approvalItems,
              onApprove: (ids) {},
              onReject: (ids, comment) {},
              onRequestChanges: (ids, comment) {},
              onItemTap: (item) {},
            ),
          ),

          // ---------------------------------------------------------------
          // 7. Photo Gallery
          // ---------------------------------------------------------------
          Section(
            title: 'PHOTO GALLERY',
            child: EdenPhotoGallery(
              mode: EdenPhotoGalleryMode.grid,
              columnCount: 3,
              onAddPhoto: () {},
              onDeletePhotos: (ids) {},
              photos: [
                EdenPhoto(
                  id: 'p1',
                  imageProvider: _colorImageProvider(Colors.blue[300]!),
                  caption: 'Compressor — Before',
                ),
                EdenPhoto(
                  id: 'p2',
                  imageProvider: _colorImageProvider(Colors.green[300]!),
                  caption: 'Ductwork inspection',
                ),
                EdenPhoto(
                  id: 'p3',
                  imageProvider: _colorImageProvider(Colors.orange[300]!),
                  caption: 'Electrical panel',
                ),
                EdenPhoto(
                  id: 'p4',
                  imageProvider: _colorImageProvider(Colors.red[300]!),
                  caption: 'Water heater — old unit',
                ),
                EdenPhoto(
                  id: 'p5',
                  imageProvider: _colorImageProvider(Colors.purple[300]!),
                  caption: 'Thermostat wiring',
                ),
                EdenPhoto(
                  id: 'p6',
                  imageProvider: _colorImageProvider(Colors.teal[300]!),
                  caption: 'Completed install',
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // 8. Checklist Builder
          // ---------------------------------------------------------------
          Section(
            title: 'CHECKLIST BUILDER',
            child: EdenChecklistBuilder(
              items: _checklistItems,
              showProgress: true,
              showCompletionSummary: true,
              allowAdd: true,
              allowReorder: true,
              onItemChanged: (item) {},
              onItemAdded: (title) {},
            ),
          ),

          // ---------------------------------------------------------------
          // 9. Permission Matrix
          // ---------------------------------------------------------------
          Section(
            title: 'PERMISSION MATRIX',
            child: EdenPermissionMatrix(
              permissions: _permissions,
              roles: _roles,
              onPermissionToggled: (roleId, permId, granted) {
                setState(() {
                  _roles = _roles.map((r) {
                    if (r.id == roleId) {
                      return r.copyWithPermission(permId, granted);
                    }
                    return r;
                  }).toList();
                });
              },
            ),
          ),

          // ---------------------------------------------------------------
          // 10. Sync Indicator
          // ---------------------------------------------------------------
          Section(
            title: 'SYNC — STATUS BAR',
            child: Column(
              children: [
                EdenSyncStatusBar(
                  status: _syncStatus,
                  itemsSynced: 7,
                  totalItems: 12,
                  onRetry: () => setState(() => _syncStatus = EdenSyncStatus.syncing),
                ),
                const SizedBox(height: EdenSpacing.space3),
                Wrap(
                  spacing: EdenSpacing.space2,
                  runSpacing: EdenSpacing.space2,
                  children: [
                    _SyncChip(label: 'Online', onTap: () => setState(() => _syncStatus = EdenSyncStatus.online)),
                    _SyncChip(label: 'Offline', onTap: () => setState(() => _syncStatus = EdenSyncStatus.offline)),
                    _SyncChip(label: 'Syncing', onTap: () => setState(() => _syncStatus = EdenSyncStatus.syncing)),
                    _SyncChip(label: 'Error', onTap: () => setState(() => _syncStatus = EdenSyncStatus.error)),
                    _SyncChip(label: 'Conflict', onTap: () => setState(() => _syncStatus = EdenSyncStatus.conflict)),
                  ],
                ),
              ],
            ),
          ),
          Section(
            title: 'SYNC — CONFLICT CARD',
            child: EdenConflictCard(
              conflict: const EdenConflictData(
                id: 'conf1',
                title: 'Work Order #4821 — Schedule Conflict',
                description: 'The appointment time was changed on both the device and the server.',
                localTimestamp: 'Mar 22, 2:35 PM (device)',
                serverTimestamp: 'Mar 22, 2:40 PM (office)',
                fields: [
                  EdenConflictField(
                    fieldName: 'Scheduled Date',
                    localValue: 'March 25, 2026',
                    serverValue: 'March 26, 2026',
                  ),
                  EdenConflictField(
                    fieldName: 'Assigned Tech',
                    localValue: 'Mike Torres',
                    serverValue: 'David Ruiz',
                  ),
                ],
              ),
              onResolveConflict: (id, resolution) {},
            ),
          ),
          Section(
            title: 'SYNC — QUEUE',
            child: EdenSyncQueue(
              operations: const [
                EdenSyncOperation(id: 'op1', label: 'Upload photos (WO #4821)', status: EdenSyncOperationStatus.completed),
                EdenSyncOperation(id: 'op2', label: 'Update work order status', status: EdenSyncOperationStatus.syncing),
                EdenSyncOperation(id: 'op3', label: 'Submit timesheet entry', status: EdenSyncOperationStatus.pending),
                EdenSyncOperation(id: 'op4', label: 'Sync inventory count', status: EdenSyncOperationStatus.failed, errorMessage: 'Network timeout'),
              ],
              onRetry: (id) {},
            ),
          ),

          // ---------------------------------------------------------------
          // 11. Activity Feed
          // ---------------------------------------------------------------
          Section(
            title: 'ACTIVITY FEED',
            child: EdenActivityFeed(
              activities: _activities,
              onActivityTap: (a) {},
              onMentionTap: (mention) {},
              hasMore: true,
              onLoadMore: () {},
            ),
          ),

          // ---------------------------------------------------------------
          // 12. Map View
          // ---------------------------------------------------------------
          Section(
            title: 'MAP VIEW',
            child: SizedBox(
              height: 400,
              child: EdenMapView(
                mapBuilder: Container(
                  decoration: BoxDecoration(
                    color: EdenColors.neutral[200],
                    borderRadius: EdenRadii.borderRadiusLg,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 48, color: EdenColors.neutral[400]),
                        const SizedBox(height: EdenSpacing.space2),
                        Text(
                          'Map Provider Placeholder',
                          style: TextStyle(color: EdenColors.neutral[500], fontSize: 14),
                        ),
                        Text(
                          'Integrate Google Maps, Mapbox, etc.',
                          style: TextStyle(color: EdenColors.neutral[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                markers: _mapMarkers,
                filters: _mapFilters,
                legend: const [
                  EdenMapLegendItem(color: Colors.blue, label: 'Residential'),
                  EdenMapLegendItem(color: Colors.orange, label: 'Commercial'),
                  EdenMapLegendItem(color: Colors.green, label: 'Internal'),
                ],
                onMarkerTap: (id) {},
                onFilterChanged: (id) {},
                onSearchChanged: (q) {},
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // 13. Barcode Scanner
          // ---------------------------------------------------------------
          Section(
            title: 'BARCODE SCANNER',
            child: SizedBox(
              height: 420,
              child: EdenBarcodeScanner(
                cameraPreview: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 48, color: Colors.white30),
                        const SizedBox(height: EdenSpacing.space2),
                        Text(
                          'Camera Preview',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                status: EdenScannerStatus.scanning,
                scanMode: EdenScanMode.single,
                showHistory: true,
                history: _scanHistory,
                onBarcodeDetected: (value) {},
                onFlashToggle: () {},
                onCameraSwitch: () {},
                onHistoryItemTap: (value) {},
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // 14. Kanban (enhanced with drag-and-drop)
          // ---------------------------------------------------------------
          Section(
            title: 'KANBAN — WORK ORDERS',
            child: SizedBox(
              height: 440,
              child: EdenKanbanBoard(
                onCardMoved: (cardId, from, to, index) {},
                onCardReordered: (cardId, col, oldIdx, newIdx) {},
                children: [
                  EdenKanbanColumn(
                    id: 'pending',
                    title: 'Pending',
                    color: EdenKanbanColumnColor.neutral,
                    count: 2,
                    children: [
                      EdenKanbanCard(
                        id: 'k1',
                        title: 'Furnace Inspection — Chen',
                        description: 'Annual maintenance check',
                        tags: [const EdenKanbanTag(label: 'HVAC')],
                        priority: EdenKanbanPriority.low,
                        dueDate: 'Mar 25',
                      ),
                      EdenKanbanCard(
                        id: 'k2',
                        title: 'Faucet Replacement — Brown',
                        tags: [const EdenKanbanTag(label: 'Plumbing')],
                        priority: EdenKanbanPriority.medium,
                        dueDate: 'Mar 26',
                      ),
                    ],
                  ),
                  EdenKanbanColumn(
                    id: 'scheduled',
                    title: 'Scheduled',
                    color: EdenKanbanColumnColor.primary,
                    count: 2,
                    children: [
                      EdenKanbanCard(
                        id: 'k3',
                        title: 'Panel Upgrade — Martin',
                        description: '200A service upgrade',
                        tags: [const EdenKanbanTag(label: 'Electrical')],
                        priority: EdenKanbanPriority.high,
                        assigneeInitials: ['SK'],
                        dueDate: 'Mar 24',
                      ),
                      EdenKanbanCard(
                        id: 'k4',
                        title: 'Water Heater — Garcia',
                        tags: [const EdenKanbanTag(label: 'Plumbing')],
                        priority: EdenKanbanPriority.medium,
                        assigneeInitials: ['DR'],
                        dueDate: 'Mar 24',
                      ),
                    ],
                  ),
                  EdenKanbanColumn(
                    id: 'in_progress',
                    title: 'In Progress',
                    color: EdenKanbanColumnColor.warning,
                    count: 1,
                    children: [
                      EdenKanbanCard(
                        id: 'k5',
                        title: 'HVAC Compressor — Johnson',
                        description: 'Replacing condenser unit',
                        tags: [const EdenKanbanTag(label: 'HVAC'), const EdenKanbanTag(label: 'Urgent')],
                        priority: EdenKanbanPriority.high,
                        assigneeInitials: ['MT'],
                        dueDate: 'Today',
                      ),
                    ],
                  ),
                  EdenKanbanColumn(
                    id: 'completed',
                    title: 'Completed',
                    color: EdenKanbanColumnColor.success,
                    count: 1,
                    children: [
                      EdenKanbanCard(
                        id: 'k6',
                        title: 'Pipe Burst Repair — Adams',
                        tags: [const EdenKanbanTag(label: 'Emergency')],
                        priority: EdenKanbanPriority.high,
                        assigneeInitials: ['DR'],
                        dueDate: 'Mar 21',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // 15. Data Grid (enhanced)
          // ---------------------------------------------------------------
          Section(
            title: 'DATA GRID — WORK ORDERS',
            child: SizedBox(
              height: 360,
              child: EdenDataGrid<Map<String, String>>(
                reorderable: true,
                onColumnsReordered: (order) {},
                striped: true,
                bordered: true,
                selectable: true,
                multiSelect: true,
                onSelectionChanged: (selected) {},
                columns: [
                  EdenGridColumn<Map<String, String>>(
                    id: 'id',
                    label: 'WO #',
                    width: 100,
                    cellBuilder: (row, _) => Text(
                      row['id']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  EdenGridColumn<Map<String, String>>(
                    id: 'customer',
                    label: 'Customer',
                    width: 140,
                    cellBuilder: (row, _) => Text(row['customer']!),
                  ),
                  EdenGridColumn<Map<String, String>>(
                    id: 'type',
                    label: 'Type',
                    width: 110,
                    cellBuilder: (row, _) => Text(row['type']!),
                  ),
                  EdenGridColumn<Map<String, String>>(
                    id: 'status',
                    label: 'Status',
                    width: 120,
                    cellBuilder: (row, _) => _StatusChip(label: row['status']!),
                  ),
                  EdenGridColumn<Map<String, String>>(
                    id: 'tech',
                    label: 'Technician',
                    width: 120,
                    cellBuilder: (row, _) => Text(row['tech']!),
                  ),
                  EdenGridColumn<Map<String, String>>(
                    id: 'est',
                    label: 'Estimate',
                    width: 100,
                    textAlign: TextAlign.end,
                    cellBuilder: (row, _) => Text(
                      row['est']!,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
                rows: _workOrders,
                rowKey: (row) => row['id']!,
                onRowTap: (row) {},
              ),
            ),
          ),

          const SizedBox(height: EdenSpacing.space8),
        ],
      ),
    );
  }

  /// Creates a simple solid-color MemoryImage provider as a photo placeholder.
  ImageProvider _colorImageProvider(Color color) {
    // Use a 1x1 BMP encoded in memory as a minimal placeholder.
    // In a real app these would be network/file images.
    return _SolidColorImage(color);
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

/// A placeholder document page with colored background and text.
class _DocPage extends StatelessWidget {
  const _DocPage({required this.color, required this.label, required this.subtitle});

  final Color color;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 560,
      padding: const EdgeInsets.all(EdenSpacing.space6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(color: EdenColors.neutral[300]!),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: EdenSpacing.space2),
          Text(subtitle, style: TextStyle(fontSize: 13, color: EdenColors.neutral[600])),
          const SizedBox(height: EdenSpacing.space4),
          // Fake text lines
          for (int i = 0; i < 8; i++) ...[
            Container(
              height: 10,
              width: i % 3 == 0 ? 280 : (i % 2 == 0 ? 320 : 240),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: EdenColors.neutral[300]!.withValues(alpha: 0.5),
                borderRadius: EdenRadii.borderRadiusSm,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A simple review row for the wizard summary step.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EdenColors.neutral[500],
                )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// A small chip for toggling sync status in the demo.
class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// A work order status chip for the data grid.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  Color get _color {
    switch (label) {
      case 'Completed':
        return EdenColors.success;
      case 'In Progress':
        return EdenColors.info;
      case 'Scheduled':
        return Colors.purple;
      case 'Pending':
        return EdenColors.warning;
      default:
        return EdenColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}

/// A minimal [ImageProvider] that produces a solid-color 100x100 image.
///
/// This avoids needing network images or bundled assets in the demo app.
class _SolidColorImage extends ImageProvider<_SolidColorImage> {
  const _SolidColorImage(this.color);

  final Color color;

  @override
  Future<_SolidColorImage> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _SolidColorImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_createImage());
  }

  Future<ImageInfo> _createImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = color,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SolidColorImage && other.color == color;

  @override
  int get hashCode => color.hashCode;
}
