// Do NOT regenerate via LLM — hand-built fixtures for EdenInspectionFormPage.
// Edit by hand only.

import 'dart:typed_data';

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenInspectionFormPageFixtures {
  EdenInspectionFormPageFixtures._();

  /// 1×1 PNG bytes (same as photo capture fixture).
  static Uint8List onePixelPng() => Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

  /// Simple 1-section/1-text-field form (draft, no required).
  static EdenInspectionForm singleText({String? value}) => EdenInspectionForm(
        id: 'f1',
        name: 'Quick Inspection',
        status: EdenInspectionFormStatus.draft,
        sections: [
          EdenInspectionSection(
            id: 's1',
            title: 'Section 1',
            fields: [
              EdenInspectionField(
                id: 'fld-text-1',
                label: 'Notes',
                type: EdenInspectionFieldType.text,
                value: value,
              ),
            ],
          ),
        ],
        createdAt: DateTime(2026, 5, 16),
      );

  /// Two-required-field form (text + boolean) for progress + submit gating.
  static EdenInspectionForm twoRequired() => EdenInspectionForm(
        id: 'f2',
        name: 'Two Required',
        status: EdenInspectionFormStatus.draft,
        sections: [
          EdenInspectionSection(
            id: 's1',
            title: 'Required Section',
            fields: [
              EdenInspectionField(
                id: 'r-text',
                label: 'Field A',
                type: EdenInspectionFieldType.text,
                isRequired: true,
              ),
              EdenInspectionField(
                id: 'r-bool',
                label: 'Field B',
                type: EdenInspectionFieldType.boolean,
                isRequired: true,
              ),
            ],
          ),
        ],
        createdAt: DateTime(2026, 5, 16),
      );

  /// All-types form for rendering smoke tests.
  static EdenInspectionForm allTypes() => EdenInspectionForm(
        id: 'f3',
        name: 'All Types',
        status: EdenInspectionFormStatus.draft,
        sections: [
          EdenInspectionSection(
            id: 's-text',
            title: 'Text fields',
            fields: const [
              EdenInspectionField(
                  id: 't', label: 'Text', type: EdenInspectionFieldType.text),
              EdenInspectionField(
                  id: 'lt',
                  label: 'Long Text',
                  type: EdenInspectionFieldType.longText),
              EdenInspectionField(
                  id: 'n',
                  label: 'Number',
                  type: EdenInspectionFieldType.number),
            ],
          ),
          EdenInspectionSection(
            id: 's-other',
            title: 'Other fields',
            fields: const [
              EdenInspectionField(
                  id: 'b',
                  label: 'Bool',
                  type: EdenInspectionFieldType.boolean),
              EdenInspectionField(
                id: 'ss',
                label: 'Single Select',
                type: EdenInspectionFieldType.singleSelect,
                options: ['A', 'B', 'C'],
              ),
              EdenInspectionField(
                id: 'ms',
                label: 'Multi Select',
                type: EdenInspectionFieldType.multiSelect,
                options: ['Red', 'Green', 'Blue'],
              ),
              EdenInspectionField(
                  id: 'photo',
                  label: 'Photo',
                  type: EdenInspectionFieldType.photo),
              EdenInspectionField(
                  id: 'sig',
                  label: 'Signature',
                  type: EdenInspectionFieldType.signature),
            ],
          ),
        ],
        createdAt: DateTime(2026, 5, 16),
      );

  /// Submitted form (read-only).
  static EdenInspectionForm submitted() => EdenInspectionForm(
        id: 'f-sub',
        name: 'Submitted Form',
        status: EdenInspectionFormStatus.submitted,
        sections: [
          EdenInspectionSection(
            id: 's',
            title: 'Section',
            fields: const [
              EdenInspectionField(
                  id: 'a',
                  label: 'Field',
                  type: EdenInspectionFieldType.text,
                  value: 'filled'),
            ],
          ),
        ],
        createdAt: DateTime(2026, 5, 16),
        submittedAt: DateTime(2026, 5, 16, 10),
      );

  /// Save recorder.
  static (
    List<EdenInspectionForm>,
    Future<EdenInspectionForm> Function(EdenInspectionForm)
  ) saveRecorder() {
    final captured = <EdenInspectionForm>[];
    Future<EdenInspectionForm> fn(EdenInspectionForm f) async {
      captured.add(f);
      return f;
    }
    return (captured, fn);
  }

  /// Failing save.
  static Future<EdenInspectionForm> Function(EdenInspectionForm)
      failingSave(String msg) => (_) async => throw Exception(msg);

  /// Photo callback returning a sample.
  static Future<EdenCapturedPhoto?> Function(EdenInspectionField)
      photoSample() => (_) async => EdenCapturedPhoto(
            filePath: '/tmp/insp.png',
            bytes: onePixelPng(),
            mimeType: 'image/png',
            capturedAt: DateTime(2026, 5, 16, 14, 30),
          );
}
