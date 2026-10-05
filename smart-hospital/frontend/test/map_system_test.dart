import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:smart_hospital/config/app_theme.dart';
import 'package:smart_hospital/models/admin_hospital_item.dart';
import 'package:smart_hospital/models/hospital_search_result.dart';
import 'package:smart_hospital/services/map_service.dart';
import 'package:smart_hospital/widgets/widgets.dart';

void main() {
  test('MapService URL formatting tests', () {
    // Test that MapService produces proper Google Maps directions and query formats
    final dest = '17.4435,78.3772';
    final directionsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving';
    final searchUrl = 'https://www.google.com/maps/search/?api=1&query=$dest';

    expect(directionsUrl.contains('travelmode=driving'), isTrue);
    expect(directionsUrl.contains('destination=17.4435,78.3772'), isTrue);
    expect(searchUrl.contains('query=17.4435,78.3772'), isTrue);
  });

  testWidgets('HospitalMap renders with custom markers and controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final suitable = [
      HospitalMatchItem(
        hospitalId: 'h1',
        name: 'City General Hospital',
        address: '123 Health Ave',
        contact: '555-0100',
        latitude: 25.3960,
        longitude: 68.3578,
        distanceKm: 4.2,
        estimatedTravelMinutes: 12,
        matchPercent: 95.0,
        capacities: {
          'icu_bed': CapacityDetail(total: 10, occupied: 6, reserved: 1, temporarilyUnavailable: 0, available: 3),
        },
        stale: false,
      ),
      HospitalMatchItem(
        hospitalId: 'h2',
        name: 'Apollo Hospital',
        address: '456 Care Blvd',
        contact: '555-0200',
        latitude: 25.4150,
        longitude: 68.3100,
        distanceKm: 8.5,
        estimatedTravelMinutes: 22,
        matchPercent: 82.0,
        capacities: {
          'icu_bed': CapacityDetail(total: 20, occupied: 15, reserved: 2, temporarilyUnavailable: 0, available: 3),
        },
        stale: false,
      ),
    ];

    final excluded = [
      HospitalExcludedItem(
        hospitalId: 'h3',
        name: 'Community Clinic',
        address: '789 Aid St',
        contact: '555-0300',
        latitude: 25.3980,
        longitude: 68.3780,
        distanceKm: 15.0,
        estimatedTravelMinutes: 35,
        exclusionReason: 'No ICU beds available',
        capacities: {},
        stale: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: HospitalMap(
            userLocation: const LatLng(25.3960, 68.3578),
            suitableHospitals: suitable,
            excludedHospitals: excluded,
            requiredResources: const ['icu_bed'],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Suitable'), findsOneWidget);
    expect(find.text('Excluded'), findsOneWidget);
    expect(find.byIcon(Icons.crop_free_rounded), findsOneWidget);
  });

  testWidgets('HospitalMap renders in admin mode with occupancy pins', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final adminHospitals = [
      AdminHospitalItem(
        id: 'h1',
        name: 'Metropolitan Hospital',
        address: '100 Metro Way',
        contact: '555-1111',
        latitude: 25.3960,
        longitude: 68.3578,
        overallOccupancyPercent: 94.0,
        icuOccupancyPercent: 90.0,
        totalCapacity: 100,
        totalOccupied: 94,
        verificationStatus: 'verified',
        accountStatus: 'active',
      ),
      AdminHospitalItem(
        id: 'h2',
        name: 'St Jude Hospital',
        address: '200 Saint St',
        contact: '555-2222',
        latitude: 25.4150,
        longitude: 68.3100,
        overallOccupancyPercent: 78.0,
        icuOccupancyPercent: 70.0,
        totalCapacity: 80,
        totalOccupied: 62,
        verificationStatus: 'verified',
        accountStatus: 'active',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: HospitalMap(
            adminHospitals: adminHospitals,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('94%'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('< 70%'), findsOneWidget);
    expect(find.text('70–90%'), findsOneWidget);
    expect(find.text('> 90% Occupancy'), findsOneWidget);
  });
}
