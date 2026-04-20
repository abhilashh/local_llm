class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String profilesTable = 'profiles';

  static const int maxMessageLength = 2000;
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
}
