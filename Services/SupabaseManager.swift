import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    // MARK: - ⚠️ Replace these with your actual Supabase project credentials
    // Find them in: Supabase Dashboard → Project Settings → API
    private let supabaseURL = "https://your-project-id.supabase.co"
    private let supabaseAnonKey = "your-anon-key-here"

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }
}
