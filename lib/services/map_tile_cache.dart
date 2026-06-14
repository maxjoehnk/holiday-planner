import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const mapTileStore = FMTCStore('mapTiles');

Future<void> initMapTileCache() async {
  final documents = await getApplicationDocumentsDirectory();
  await FMTCObjectBoxBackend().initialise(
    rootDirectory: p.join(documents.path, 'fmtc'),
    macosApplicationGroup: 'holidayPlanner',
  );
  await mapTileStore.manage.create();
}
