import Supabase
import Foundation

enum AppSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://yvpnuagkykpbhlljexnt.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIUzI1NiIsInJlZiI6Inl2cG51YWdreWtwYmhsbGpleG50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2ODU4ODYsImV4cCI6MjA5NTI2MTg4Nn0.RjJjUP3jsShhlUtCU-su-nTvypmn0x0ZugM69TYy1vE"
    )
}
