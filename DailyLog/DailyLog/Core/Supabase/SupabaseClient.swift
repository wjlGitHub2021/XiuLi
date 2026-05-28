import Supabase
import Foundation

// ⚠️ 个人项目本地使用，请勿将此仓库推送到公共代码平台。
enum AppSupabase {
    static let client: SupabaseClient = {
        guard let url = URL(string: "https://yvpnuagkykpbhlljexnt.supabase.co") else {
            fatalError("Supabase URL 无效，请检查配置")
        }
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2cG51YWdreWtwYmhsbGpleG50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2ODU4ODYsImV4cCI6MjA5NTI2MTg4Nn0.RjJjUP3jsShhlUtCU-su-nTvypmn0x0ZugM69TYy1vE"
        )
    }()
}
