import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    // ⚠️ Fill in your credentials from: Supabase Dashboard → Project Settings → API
    // This file is in .gitignore — never commit with real values.
    private let supabaseURL = "https://your-project-id.supabase.co"
    private let supabaseAnonKey = "your-anon-key-here"

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }
}
