/// Evio Core - Shared code for Evio Club
library;

// Services
export 'services/supabase_service.dart';
export 'services/spotify_service.dart';
export 'services/youtube_service.dart';

// Supabase client
export 'package:supabase_flutter/supabase_flutter.dart' hide User;

// Config
export 'config/supabase_config.dart';

// Constants
export 'constants/enums.dart';
export 'constants/app_constants.dart';
export 'constants/error_messages.dart';

// Models
export 'models/user.dart';
export 'models/event.dart';
export 'models/ticket_type.dart';
export 'models/ticket_category.dart';
export 'models/ticket_tier.dart';
export 'models/ticket.dart';
export 'models/order.dart';
export 'models/order_item.dart';
export 'models/lineup_artist.dart';
export 'models/event_status.dart';
export 'models/event_stats.dart';
export 'models/producer.dart';
export 'models/user_invitation.dart';

// Repositories
export 'repositories/auth_repository.dart';
export 'repositories/event_repository.dart';
export 'repositories/producer_repository.dart';
export 'repositories/user_repository.dart';
export 'repositories/order_repository.dart';
export 'repositories/ticket_repository.dart';

// Exceptions
export 'exceptions/order_exception.dart';

// Theme
export 'theme/theme.dart';
export 'theme/tokens/gradients.dart';
export 'utils/progress_color.dart';
