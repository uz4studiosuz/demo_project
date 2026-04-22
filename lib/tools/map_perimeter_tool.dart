import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../additional/map_border.dart';

class MapPerimeterTool extends StatefulWidget {
  const MapPerimeterTool({super.key});

  @override
  State<MapPerimeterTool> createState() => _MapPerimeterToolState();
}

class _MapPerimeterToolState extends State<MapPerimeterTool> {
  final List<LatLng> _points = [];
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  // Undo/Redo tarixi
  final List<List<LatLng>> _undoStack = [];
  final List<List<LatLng>> _redoStack = [];

  // Drag qilish uchun - harakatlanayotgan nuqta indexi
  int? _draggingIndex;

  final TextEditingController _codeController = TextEditingController();
  String? _parseError;
  bool _isManualEdit = false;

  @override
  void initState() {
    super.initState();
    _points.addAll(kFerganaBorder);
    _updateCodeText();
  }

  void _updateCodeText() {
    if (_isManualEdit) return;
    _codeController.text = _generateCode();
    _parseError = null;
  }

  void _onCodeChanged(String value) {
    _isManualEdit = true;
    _parseFromText(value);
  }

  void _parseFromText(String text) {
    try {
      // Regex orqali LatLng(40.123, 71.123) formatini qidiramiz
      final exp = RegExp(r'LatLng\(\s*([\d\.-]+)\s*,\s*([\d\.-]+)\s*\)');
      final matches = exp.allMatches(text);

      if (matches.isEmpty) {
        setState(() {
          _parseError = 'Kodda LatLng nuqtalari topilmadi!';
        });
        return;
      }

      final List<LatLng> newPoints = [];
      for (final m in matches) {
        final lat = double.parse(m.group(1)!);
        final lng = double.parse(m.group(2)!);
        newPoints.add(LatLng(lat, lng));
      }

      // Agar oxirgi nuqta birinchisi bilan bir xil bo'lsa (yopiq border), uni olib tashlaymiz
      // chunki biz buildMapMarkers ichida o'zimiz yopamiz
      if (newPoints.length > 1 &&
          newPoints.first.latitude == newPoints.last.latitude &&
          newPoints.first.longitude == newPoints.last.longitude) {
        newPoints.removeLast();
      }

      setState(() {
        _points.clear();
        _points.addAll(newPoints);
        _parseError = null;
      });
    } catch (e) {
      setState(() {
        _parseError = 'Kodda xatolik bor, uni to\'g\'rilang!';
      });
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        _isManualEdit = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Har qanday o'zgarishdan oldin holatni saqla
  void _saveState() {
    _undoStack.add(List<LatLng>.from(_points));
    _redoStack.clear(); // Yangi harakat bo'lsa redo o'chadi
    // Stack hajmini cheklaymiz (xotira uchun)
    if (_undoStack.length > 100) {
      _undoStack.removeAt(0);
    }
  }

  // setState chaqirilganda textfield ham yangilanishi uchun
  void _triggerUpdate() {
    _updateCodeText();
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List<LatLng>.from(_points));
    final previous = _undoStack.removeLast();
    setState(() {
      _points.clear();
      _points.addAll(previous);
      _updateCodeText();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List<LatLng>.from(_points));
    final next = _redoStack.removeLast();
    setState(() {
      _points.clear();
      _points.addAll(next);
      _updateCodeText();
    });
  }

  void _addPoint(LatLng point) {
    // Agar drag qilinyotgan bo'lsa, tap ishlmasin
    if (_draggingIndex != null) return;

    _saveState();

    if (_points.length < 2) {
      setState(() {
        _points.add(point);
      });
      _triggerUpdate();
      return;
    }

    int bestIndex = _points.length;
    double minDistance = double.infinity;

    for (int i = 0; i < _points.length; i++) {
      final p1 = _points[i];
      final p2 = _points[(i + 1) % _points.length];
      final dist = _distanceToSegment(point, p1, p2);
      if (dist < minDistance) {
        minDistance = dist;
        bestIndex = i + 1;
      }
    }

    setState(() {
      if (minDistance < 0.005) {
        _points.insert(bestIndex, point);
      } else {
        _points.add(point);
      }
    });
    _triggerUpdate();
  }

  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    double l2 =
        (a.latitude - b.latitude) * (a.latitude - b.latitude) +
        (a.longitude - b.longitude) * (a.longitude - b.longitude);
    if (l2 == 0) {
      return (p.latitude - a.latitude) * (p.latitude - a.latitude) +
          (p.longitude - a.longitude) * (p.longitude - a.longitude);
    }

    double t =
        ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
            (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
        l2;
    t = t.clamp(0.0, 1.0);

    double dx = p.latitude - (a.latitude + t * (b.latitude - a.latitude));
    double dy = p.longitude - (a.longitude + t * (b.longitude - a.longitude));
    return dx * dx + dy * dy;
  }

  void _removeLast() {
    if (_points.isNotEmpty) {
      _saveState();
      setState(() {
        _points.removeLast();
        _updateCodeText();
      });
    }
  }

  void _clear() {
    if (_points.isNotEmpty) {
      _saveState();
      setState(() {
        _points.clear();
        _updateCodeText();
      });
    }
  }

  void _reset() {
    _saveState();
    setState(() {
      _points.clear();
      _points.addAll(kFerganaBorder);
      _updateCodeText();
    });
  }

  void _updatePoint(int index, LatLng newPoint) {
    setState(() {
      _points[index] = newPoint;
      _updateCodeText();
    });
  }

  /// Global pozitsiyadan LatLng olish (drag uchun ishonchli yo'l)
  LatLng? _globalToLatLng(Offset globalPosition) {
    final RenderBox? mapBox =
        _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (mapBox == null) return null;

    final localOffset = mapBox.globalToLocal(globalPosition);
    final camera = _mapController.camera;

    // YECHIM: flutter_map v7+ uchun to'g'ri API. Point kerak emas.
    return camera.offsetToCrs(localOffset);
  }

  String _generateCode() {
    final buffer = StringBuffer();
    buffer.writeln('const List<LatLng> kNewBorder = [');
    for (final p in _points) {
      buffer.writeln('  LatLng(${p.latitude}, ${p.longitude}),');
    }
    buffer.writeln('];');
    return buffer.toString();
  }

  void _copyToClipboard() {
    final code = _generateCode();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kod buferga nusxalandi!')));
  }

  @override
  Widget build(BuildContext context) {
    final bool canUndo = _undoStack.isNotEmpty;
    final bool canRedo = _redoStack.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chegara chizish asbobi (Tool)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Undo
          IconButton(
            onPressed: canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Orqaga (Ctrl+Z)',
            color: canUndo ? Colors.white : Colors.white38,
          ),
          // Redo
          IconButton(
            onPressed: canRedo ? _redo : null,
            icon: const Icon(Icons.redo),
            tooltip: 'Oldinga (Ctrl+Shift+Z)',
            color: canRedo ? Colors.white : Colors.white38,
          ),
          // Reset
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            tooltip: 'Dastlabki holatga qaytarish',
          ),
          // Oxirgisini o'chirish
          IconButton(
            onPressed: _points.isNotEmpty ? _removeLast : null,
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Oxirgisini o\'chirish',
            color: _points.isNotEmpty ? Colors.white : Colors.white38,
          ),
          // Tozalash
          IconButton(
            onPressed: _points.isNotEmpty ? _clear : null,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Tozalash',
            color: _points.isNotEmpty ? Colors.white : Colors.white38,
          ),
          // Nusxalash
          ElevatedButton.icon(
            onPressed: _points.isNotEmpty ? _copyToClipboard : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.copy),
            label: const Text('Kodni nusxalash'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final isCtrl =
                HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;
            final isShift = HardwareKeyboard.instance.isShiftPressed;

            if (isCtrl &&
                isShift &&
                event.logicalKey == LogicalKeyboardKey.keyZ) {
              _redo();
            } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
              _undo();
            }
          }
        },
        child: Stack(
          children: [
            // Xarita
            Container(
              key: _mapKey,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(40.3864, 71.7825),
                  initialZoom: 13.0,
                  onTap: (tapPos, point) => _addPoint(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=y&hl=uz&x={x}&y={y}&z={z}',
                  ),
                  // NUSXA (Referens chiziq) - Ko'k rangda, o'zgarmas bo'lib turadi
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: kFerganaBorder,
                        color: Colors.blue.withValues(alpha: 0.3),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                  // Polyline faqat nuqtalar bo'lganda (Siz chizayotgan qizil chiziq)
                  if (_points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _points,
                          color: Colors.red,
                          strokeWidth: 4,
                        ),
                        // Yopish chizig'i (preview)
                        if (_points.length > 2)
                          Polyline(
                            points: [_points.last, _points.first],
                            color: Colors.red.withValues(alpha: 0.5),
                            strokeWidth: 2,
                            pattern: StrokePattern.dashed(
                              segments: const [8, 4],
                            ),
                          ),
                      ],
                    ),
                  // Markerlar
                  MarkerLayer(
                    markers: List.generate(_points.length, (index) {
                      final p = _points[index];
                      return Marker(
                        point: p,
                        width: 32,
                        height: 32,
                        child: GestureDetector(
                          // Double tap = o'chirish
                          onDoubleTap: () {
                            _saveState();
                            setState(() {
                              _points.removeAt(index);
                              _updateCodeText();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${index + 1}-nuqta o\'chirildi'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          // Drag boshlanishi
                          onPanStart: (_) {
                            _saveState();
                            _draggingIndex = index;
                          },
                          // Drag davomida
                          onPanUpdate: (details) {
                            final newPoint = _globalToLatLng(
                              details.globalPosition,
                            );
                            if (newPoint != null) {
                              _updatePoint(index, newPoint);
                            }
                          },
                          // Drag tugashi
                          onPanEnd: (_) {
                            _draggingIndex = null;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _draggingIndex == index
                                  ? Colors.orange
                                  : Colors.yellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Nuqtalar soni (pastda chap)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _points.isEmpty
                      ? 'Xaritaga bosing — nuqta qo\'shiladi'
                      : 'Nuqtalar soni: ${_points.length}\nFormat: LatLng(lat, lng)',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Kod preview (o'ngda yuqorida) — faqat nuqtalar bo'lganda
            if (_points.isNotEmpty || _codeController.text.isNotEmpty)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 350,
                  height: 300,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                    border: Border.all(
                      color: _parseError != null ? Colors.red : Colors.indigo,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _parseError ?? 'Dart kodi (Edit qilish mumkin)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _parseError != null
                                  ? Colors.red
                                  : Colors.indigo,
                            ),
                          ),
                          if (_parseError != null)
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          maxLines: null,
                          onChanged: _onCodeChanged,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'LatLng kodingizni bu yerga tashlang...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
