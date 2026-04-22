import SwiftUI
import Supabase

final class SupabaseValidationService: ValidationService {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://hrhczylttkcuvdkofcod.supabase.co")!,
            supabaseKey: "sb_publishable_5CYR7rNUwhCB4dQ3gw4FJg_2MSo4bus"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("🌊 [MarineRoute] Validation error: \(error)")
            throw error
        }
    }
}
