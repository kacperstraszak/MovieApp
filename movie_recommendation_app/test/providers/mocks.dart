import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockPostgrestClient extends Mock implements PostgrestClient {}

class MockPostgrestQueryBuilder extends Mock
    implements PostgrestQueryBuilder {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}
