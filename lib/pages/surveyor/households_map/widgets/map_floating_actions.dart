import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../households_map_view_model.dart';

class MapFloatingActions extends StatelessWidget {
  final HouseholdsMapViewModel viewModel;
  final VoidCallback? onLocationPress;

  const MapFloatingActions({super.key, required this.viewModel, this.onLocationPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'map_type',
            onPressed: viewModel.toggleMapType,
            backgroundColor: Colors.white,
            child: Icon(
              viewModel.mapType == 'm'
                  ? Icons.layers_outlined
                  : Icons.layers,
              color: AppColors.govNavy,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'my_loc',
            onPressed: onLocationPress ?? () {},
            backgroundColor: Colors.white,
            elevation: 4,
            icon: viewModel.isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.govNavy,
                    ),
                  )
                : const Icon(Icons.my_location, color: AppColors.govNavy),
            label: Text(
              viewModel.isLocationLoading
                  ? 'Aniqlanmoqda...'
                  : 'Yaqin hudud',
              style: const TextStyle(
                color: AppColors.govNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
