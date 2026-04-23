import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../eden_ui.dart';

/// Showcase screen for the EdenDiagram component.
class DiagramScreen extends StatefulWidget {
  const DiagramScreen({super.key});

  @override
  State<DiagramScreen> createState() => _DiagramScreenState();
}

class _DiagramScreenState extends State<DiagramScreen> {
  late EdenDiagramData _data;
  bool _showJson = false;

  @override
  void initState() {
    super.initState();
    _data = _sampleFlowchart();
  }

  /// Sample flowchart demonstrating AI-generatable JSON structure.
  EdenDiagramData _sampleFlowchart() {
    return EdenDiagramData(
      title: 'User Signup Flow',
      nodes: [
        EdenDiagramNode(
          id: 'start',
          shape: EdenNodeShape.pill,
          x: 60, y: 40,
          width: 140, height: 50,
          label: 'Start',
          color: '#22C55E',
          textColor: '#FFFFFF',
        ),
        EdenDiagramNode(
          id: 'form',
          shape: EdenNodeShape.roundedRect,
          x: 40, y: 140,
          width: 180, height: 60,
          label: 'Signup Form',
          sublabel: 'name, email, password',
        ),
        EdenDiagramNode(
          id: 'validate',
          shape: EdenNodeShape.diamond,
          x: 50, y: 260,
          width: 160, height: 100,
          label: 'Valid?',
          color: '#F59E0B',
          textColor: '#FFFFFF',
        ),
        EdenDiagramNode(
          id: 'error',
          shape: EdenNodeShape.roundedRect,
          x: 300, y: 275,
          width: 160, height: 60,
          label: 'Show Errors',
          color: '#EF4444',
          textColor: '#FFFFFF',
        ),
        EdenDiagramNode(
          id: 'create',
          shape: EdenNodeShape.roundedRect,
          x: 40, y: 420,
          width: 180, height: 60,
          label: 'Create Account',
          sublabel: 'write to database',
        ),
        EdenDiagramNode(
          id: 'email',
          shape: EdenNodeShape.parallelogram,
          x: 40, y: 530,
          width: 180, height: 60,
          label: 'Send Welcome Email',
        ),
        EdenDiagramNode(
          id: 'dashboard',
          shape: EdenNodeShape.pill,
          x: 60, y: 640,
          width: 140, height: 50,
          label: 'Dashboard',
          color: '#3B82F6',
          textColor: '#FFFFFF',
        ),
      ],
      edges: [
        EdenDiagramEdge(
          id: 'e1',
          sourceId: 'start', targetId: 'form',
          sourcePort: EdenPortSide.bottom, targetPort: EdenPortSide.top,
        ),
        EdenDiagramEdge(
          id: 'e2',
          sourceId: 'form', targetId: 'validate',
          sourcePort: EdenPortSide.bottom, targetPort: EdenPortSide.top,
          label: 'submit',
        ),
        EdenDiagramEdge(
          id: 'e3',
          sourceId: 'validate', targetId: 'error',
          sourcePort: EdenPortSide.right, targetPort: EdenPortSide.left,
          label: 'no',
          style: EdenEdgeStyle.dashed,
          color: '#EF4444',
        ),
        EdenDiagramEdge(
          id: 'e4',
          sourceId: 'error', targetId: 'form',
          sourcePort: EdenPortSide.top, targetPort: EdenPortSide.right,
          label: 'retry',
          style: EdenEdgeStyle.dashed,
          color: '#EF4444',
        ),
        EdenDiagramEdge(
          id: 'e5',
          sourceId: 'validate', targetId: 'create',
          sourcePort: EdenPortSide.bottom, targetPort: EdenPortSide.top,
          label: 'yes',
          color: '#22C55E',
        ),
        EdenDiagramEdge(
          id: 'e6',
          sourceId: 'create', targetId: 'email',
          sourcePort: EdenPortSide.bottom, targetPort: EdenPortSide.top,
        ),
        EdenDiagramEdge(
          id: 'e7',
          sourceId: 'email', targetId: 'dashboard',
          sourcePort: EdenPortSide.bottom, targetPort: EdenPortSide.top,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagram / Flow'),
        actions: [
          IconButton(
            icon: Icon(_showJson ? Icons.draw : Icons.code),
            tooltip: _showJson ? 'Show Diagram' : 'Show JSON',
            onPressed: () => setState(() => _showJson = !_showJson),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy JSON',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _data.toJsonString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard'), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to sample',
            onPressed: () => setState(() => _data = _sampleFlowchart()),
          ),
        ],
      ),
      body: _showJson
          ? _JsonView(data: _data)
          : Padding(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hints
                  Container(
                    padding: const EdgeInsets.all(EdenSpacing.space3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: EdenRadii.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Drag nodes to move. Click port dots to connect. Scroll to zoom. Delete key removes selected.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EdenSpacing.space3),
                  Expanded(
                    child: EdenDiagram(
                      data: _data,
                      onChanged: (d) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.data});
  final EdenDiagramData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: EdenCodeBlock(
        language: 'json',
        code: data.toJsonString(),
        lineNumbers: true,
      ),
    );
  }
}
