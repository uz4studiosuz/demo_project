import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:latlong2/latlong.dart';

import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';
import 'package:geolocator/geolocator.dart';

class DriverMapPage extends StatefulWidget {
  final LatLng destination;
  final String addressTitle;
  final HouseholdModel? household;
  final ResidentModel? targetResident;

  const DriverMapPage({
    super.key,
    required this.destination,
    required this.addressTitle,
    this.household,
    this.targetResident,
  });

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // ─── Mapbox Navigation ─────────────────────────────────────────
  MapBoxNavigationViewController? _controller;
  bool _isNavigating = false;
  bool _arrived = false;
  bool _isLoading = true;

  late MapBoxOptions _navigationOptions;

  @override
  void initState() {
    super.initState();
    _navigationOptions = MapBoxOptions(
      zoom: 15.0,
      tilt: 45.0,
      bearing: 0.0,
      enableRefresh: true,
      alternatives: true,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      allowsUTurnAtWayPoints: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: false,
      language: 'uz',
      longPressDestinationEnabled: false,
    );
  }

  // ─── Route Events ───────────────────────────────────────────────
  Future<void> _onRouteEvent(RouteEvent e) async {
    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        final progressEvent = e.data as RouteProgressEvent;
        if (mounted) {
          setState(() {
            _arrived = progressEvent.arrived ?? false;
          });
        }
        break;

      case MapBoxEvent.route_building:
        if (mounted) setState(() => _isLoading = true);
        break;

      case MapBoxEvent.route_built:
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Marshrut tayyor bo'lishi bilan navigatsiyani avtomatik boshlaymiz
          _startNavigation();
        }
        break;

      case MapBoxEvent.route_build_failed:
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marshrut qurishda xato yuz berdi'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        break;

      case MapBoxEvent.navigation_running:
        if (mounted) setState(() => _isNavigating = true);
        break;

      case MapBoxEvent.on_arrival:
        if (mounted) setState(() => _arrived = true);
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.of(context).pop();
        break;

      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
        break;

      default:
        break;
    }
  }

  // ─── Start Navigation ───────────────────────────────────────────
  Future<void> _startNavigation() async {
    if (_controller == null) return;
    await _controller!.startNavigation();
    if (mounted) setState(() => _isNavigating = true);
  }

  // Stop Navigation olib tashlandi, native UI ishlatiladi


  // Format helpers o'chirildi, native UI ishlatiladi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildRightDrawer(),
      body: Stack(
        children: [
          // ─── Mapbox Navigation View (to'liq ekran) ──────────────
          MapBoxNavigationView(
            options: _navigationOptions,
            onRouteEvent: _onRouteEvent,
            onCreated: (MapBoxNavigationViewController controller) async {
              _controller = controller;

              // Joriy joylashuvni aniqlaymiz
              final Position position = await Geolocator.getCurrentPosition();

              final origin = WayPoint(
                name: 'Mening joylashuvim',
                latitude: position.latitude,
                longitude: position.longitude,
              );

              final destination = WayPoint(
                name: widget.addressTitle,
                latitude: widget.destination.latitude,
                longitude: widget.destination.longitude,
              );

              await controller.buildRoute(
                wayPoints: [origin, destination],
                options: _navigationOptions,
              );

              if (mounted) setState(() => _isLoading = false);
            },
          ),

          // ─── Loading indicator ───────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Marshrut hisoblanmoqda...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Orqaga tugma (navigatsiya boshlanganda yashiriladi) ─
          if (!_isNavigating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Colors.white,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // ─── Manzil sarlavhasi (navigatsiya boshlanganda yashiriladi) ─
          if (!_isNavigating && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 64,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.addressTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // ─── Yetib kelindi banner ────────────────────────────────
          if (_arrived)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8D5B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Manzilga yetib keldingiz!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Bemor ma'lumoti (navigatsiya paytida) ───────────────
          if (_isNavigating &&
              (widget.targetResident != null || widget.household != null))
            _PatientInfoChip(
              targetResident: widget.targetResident,
              household: widget.household,
              onOpenInfo: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
        ],
      ),
    );
  }

  Widget _buildRightDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bemor ma\'lumotlari',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              if (widget.targetResident != null) ...[
                _buildDrawerSection('Asosiy bemor', [
                  _buildDrawerInfoRow(Icons.person, widget.targetResident!.displayFullName),
                  _buildDrawerInfoRow(Icons.phone, widget.targetResident!.phonePrimary ?? 'Kiritilmagan'),
                  _buildDrawerInfoRow(Icons.cake, widget.targetResident!.birthDate?.toString().split(' ')[0] ?? 'Noma\'lum'),
                ]),
              ],
              const SizedBox(height: 24),
              if (widget.household != null) ...[
                _buildDrawerSection('Oila a\'zolari', [
                  ...widget.household!.residents.map((res) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        res.gender == 'FEMALE' ? Icons.person_outline : Icons.person,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(res.displayFullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(res.role ?? '', style: const TextStyle(fontSize: 12)),
                  )),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDrawerInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bemor ma'lumoti chip ────────────────────────────────────────────────────

class _PatientInfoChip extends StatefulWidget {
  final ResidentModel? targetResident;
  final HouseholdModel? household;
  final VoidCallback onOpenInfo;

  const _PatientInfoChip({
    this.targetResident,
    this.household,
    required this.onOpenInfo,
  });

  @override
  State<_PatientInfoChip> createState() => _PatientInfoChipState();
}

class _PatientInfoChipState extends State<_PatientInfoChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 80,
      left: 12,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _expanded ? 220 : 60,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.targetResident?.gender == 'FEMALE'
                              ? Icons.person_outline
                              : Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.targetResident?.displayFullName ?? 'Bemor',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = false),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (widget.targetResident != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.targetResident!.birthDate != null ? "${DateTime.now().year - widget.targetResident!.birthDate!.year} yosh" : ""} • ${widget.targetResident!.role ?? ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: OutlinedButton(
                        onPressed: widget.onOpenInfo,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        child: const Text(
                          "Batafsil ma'lumot",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.targetResident?.gender == 'FEMALE'
                          ? Icons.person_outline
                          : Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Bemor',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Navigatsiya pastki paneli ───────────────────────────────────────────────

// _NavigationBottomBar o'chirildi, native UI ishlatiladi

