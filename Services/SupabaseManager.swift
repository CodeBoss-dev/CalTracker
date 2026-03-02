import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Credentials are loaded from Info.plist (injected via Config.xcconfig).
        // Never hardcode these values in source — add Config.xcconfig to .gitignore.
        let bundle = Bundle.main
        guard
            let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            !urlString.isEmpty,
            let url = URL(string: urlString),
            let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !anonKey.isEmpty
        else {
            fatalError(
                "Supabase credentials missing. " +
                "Add SUPABASE_URL and SUPABASE_ANON_KEY to Config.xcconfig " +
                "and ensure they are referenced in Info.plist."
            )
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
