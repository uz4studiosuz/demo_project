import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../additional/map_border.dart';
import '../../../models/household_model.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import 'households_map_view_model.dart';
import 'dart:io' if (dart.library.html) '../../../utils/io_stub.dart' show Directory;

// Widgets
import 'widgets/map_layer_builder.dart';
import 'widgets/map_top_info_pill.dart';
import 'widgets/map_floating_actions.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  HouseholdsMapPage — Entry point
// ═══════════════════════════════════════════════════════════════════════════

class HouseholdsMapPage extends StatelessWidget {
  final HouseholdModel? focusHousehold;
  final void Function(HouseholdModel)? onGetDirections;

  const HouseholdsMapPage({
    super.key,
    this.focusHousehold,
    this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HouseholdsMapViewModel()..init(focusHousehold),
      child: _HouseholdsMapView(
        focusHousehold: focusHousehold,
        onGetDirections: onGetDirections,
      ),
    );
  }
}

class _HouseholdsMapView extends StatefulWidget {
  final HouseholdModel? focusHousehold;
  final void Function(HouseholdModel)? onGetDirections;

  const _HouseholdsMapView({this.focusHousehold, this.onGetDirections});

  @override
  State<_HouseholdsMapView> createState() => _HouseholdsMapViewState();
}

class _HouseholdsMapViewState extends State<_HouseholdsMapView> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Ma'lumotlarni yuklash — faqat focus household bo'lsa qayta yuklash kerak,
    // aks holda ota widget (LiteDashboard/SurveyorDashboard) allaqachon chaqirgan.
    if (widget.focusHousehold != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).fetchHouseholds();
        }
      });
    }
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: widget.focusHousehold != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.govNavy,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.govNavy,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: AppColors.govNavy,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Xarita tayyorlanmoqda...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.govNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapOverlay() {
    return Container(
      color: const Color(0xFFF5F6F8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.govNavy,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: AppColors.govNavy,
              strokeWidth: 3,
            ),
            const SizedBox(height: 14),
            const Text(
              'Xarita yuklanmoqda...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.govNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Iltimos kuting',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HouseholdsMapViewModel>();

    if (viewModel.isTransitioning) {
      return _buildLoadingState();
    }

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final households = provider.households;
        final currentZoom = viewModel.currentZoom;
        
        debugPrint('🔵 [HouseholdsMapPage] Xonadonlar soni: ${households.length}');

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.focusHousehold != null
                      ? LatLng(
                          widget.focusHousehold!.latitude,
                          widget.focusHousehold!.longitude,
                        )
                      : const LatLng(40.3864, 71.7825),
                  initialZoom: viewModel.currentZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: () =>
                      context.read<HouseholdsMapViewModel>().setMapReady(),
                  onPositionChanged: (pos, _) {
                    context.read<HouseholdsMapViewModel>().updateZoom(pos.zoom);
                    constrainMap(pos, _mapController);
                  },
                ),
                children: [
                   TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=${viewModel.mapType}&hl=uz&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.example.demoproject',
                    maxZoom: 20,
                    // FAQAT FARG'ONA HUDUDINI YUKLASH
                    tileBounds: getFerganaBounds(),
                    tileProvider: kIsWeb
                        ? null
                        : CachedTileProvider(
                            store: FileCacheStore(
                              "${Directory.systemTemp.path}/map_tiles_cache",
                            ),
                          ),
                  ),
                  
                  // FARG'ONA TASHQARISINI YOPISH (MASKA)
                  PolygonLayer(
                    polygons: [getInvertedFerganaMask()],
                  ),

                  if (kShowMapBorder)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: kFerganaBorder,
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          strokeWidth: 3,
                        ),
                      ],
                    ),

                  MarkerLayer(
                    markers: buildMapMarkers(
                      context: context,
                      viewModel: viewModel,
                      households: households,
                      currentZoom: currentZoom,
                      mapController: _mapController,
                      focusHousehold: widget.focusHousehold,
                      onGetDirections: widget.onGetDirections,
                    ),
                  ),
                ],
              ),

              // Loading overlay
              if (!viewModel.mapReady) _buildMapOverlay(),

              // Top info pill
              MapTopInfoPill(
                focusHousehold: widget.focusHousehold,
                householdsCount: households.length,
                currentZoom: currentZoom,
                onBack: () => Navigator.pop(context),
              ),
            ],
          ),
          floatingActionButton: MapFloatingActions(
            viewModel: viewModel,
            onLocationPress: viewModel.isLocationLoading
                ? null
                : () async {
                    final latLng = await viewModel.getMyLocation(context);
                    if (latLng != null) {
                      _mapController.move(latLng, 18.0);
                    }
                  },
          ),
        );
      },
    );
  }
}
