// Conditional export for web/non-web platforms
export 'web_video_player_stub.dart'
    if (dart.library.html) 'web_video_player_web.dart';

