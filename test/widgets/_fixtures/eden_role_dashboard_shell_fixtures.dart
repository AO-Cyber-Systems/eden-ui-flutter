// Do NOT regenerate via LLM — hand-built fixtures for EdenRoleDashboardShell.
//
// Four representative section sets, one per vertical/role pair, with
// freeform Container bodies so fixtures stay stable across rebuilds.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenRoleDashboardShellFixtures {
  EdenRoleDashboardShellFixtures._();

  static final List<EdenDashboardSection> tradesDispatcherSections =
      <EdenDashboardSection>[
    EdenDashboardSection(
      id: 'blocked_work',
      title: 'Blocked Work',
      priority: EdenDashboardSectionPriority.high,
      icon: Icons.report_problem,
      body: Container(height: 60, alignment: Alignment.centerLeft,
          child: const Text('3 blocked work orders')),
    ),
    EdenDashboardSection(
      id: 'incoming_work',
      title: 'Incoming Work',
      icon: Icons.inbox,
      body: Container(height: 60, alignment: Alignment.centerLeft,
          child: const Text('12 new')),
      badge: '12',
    ),
    EdenDashboardSection(
      id: 'needs_action',
      title: 'Needs Your Action',
      icon: Icons.assignment_late,
      body: Container(height: 60, alignment: Alignment.centerLeft,
          child: const Text('5 approvals pending')),
    ),
    EdenDashboardSection(
      id: 'ai_insights',
      title: 'AI Insights',
      icon: Icons.auto_awesome,
      body: Container(height: 60, alignment: Alignment.centerLeft,
          child: const Text('2 anomalies detected')),
    ),
  ];

  static final List<EdenDashboardSection> salonOwnerSections =
      <EdenDashboardSection>[
    EdenDashboardSection(
      id: 'todays_schedule',
      title: "Today's Schedule",
      body: SizedBox(height: 60, child: const Text('8 appointments')),
    ),
    EdenDashboardSection(
      id: 'stylist_availability',
      title: 'Stylist Availability',
      body: SizedBox(height: 60, child: const Text('3 stylists working')),
    ),
    EdenDashboardSection(
      id: 'revenue',
      title: 'Revenue Pulse',
      body: SizedBox(height: 60, child: const Text(r'$4,250 today')),
    ),
    EdenDashboardSection(
      id: 'bookings',
      title: 'New Bookings',
      body: SizedBox(height: 60, child: const Text('2 in last hour')),
    ),
  ];

  static final List<EdenDashboardSection> medicalDoctorSections =
      <EdenDashboardSection>[
    EdenDashboardSection(
      id: 'patient_queue',
      title: 'Patient Queue',
      body: SizedBox(height: 60, child: const Text('5 patients waiting')),
    ),
    EdenDashboardSection(
      id: 'todays_appointments',
      title: "Today's Appointments",
      body: SizedBox(height: 60, child: const Text('14 scheduled')),
    ),
    EdenDashboardSection(
      id: 'lab_results',
      title: 'Lab Results In',
      body: SizedBox(height: 60, child: const Text('3 new')),
    ),
    EdenDashboardSection(
      id: 'messages',
      title: 'Messages',
      body: SizedBox(height: 60, child: const Text('7 unread')),
    ),
  ];

  static final List<EdenDashboardSection> govCaseworkerSections =
      <EdenDashboardSection>[
    EdenDashboardSection(
      id: 'open_cases',
      title: 'Open Cases',
      body: SizedBox(height: 60, child: const Text('42 active')),
    ),
    EdenDashboardSection(
      id: 'pending_review',
      title: 'Pending Review',
      body: SizedBox(height: 60, child: const Text('11 awaiting decision')),
    ),
    EdenDashboardSection(
      id: 'foia',
      title: 'FOIA Requests',
      body: SizedBox(height: 60, child: const Text('3 due this week')),
    ),
  ];
}
