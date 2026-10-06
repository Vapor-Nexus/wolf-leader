import Foundation
import Security

/// How this Mac relates to Wolf Leader. Chosen on the first setup screen.
enum SetupPath: String, Codable, CaseIterable {
    /// Wolf Leader already runs on another computer; connect this Mac to it.
    case connectExisting
    /// Wolf Leader is already on this Mac; refresh its files.
    case updateThisMac
    /// New user; host the hub on an always-on computer (NAS, home server, LXC).
    case newOnServer
    /// New user; host the hub on this Mac with Docker (experimental).
    case newOnThisMac

    /// Mode string install.sh understands (see installer/CONFIG.md).
    var installMode: String {
        switch self {
        case .connectExisting, .newOnServer: return "connect"
        case .updateThisMac: return "update"
        case .newOnThisMac: return "new"
        }
    }
}

struct ShareConfig: Codable, Identifiable, Hashable {
    var id = UUID()
    /// e.g. smb://wolf.local/wolf
    var url: String
    /// Username, or empty for guest. The password lives in the Keychain, never here.
    var user: String
    /// "wolf" for the drive holding projects, vault and git remotes; otherwise "extra".
    var role: String = "extra"

    var host: String { URL(string: url)?.host ?? "" }
    var shareName: String { URL(string: url)?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "" }
    /// Where macOS mounts it, e.g. /Volumes/wolf
    var mountPoint: String { "/Volumes/" + (shareName.split(separator: "/").first.map(String.init) ?? shareName) }
}

struct WolfConfig: Codable {
    var setupComplete = false
    var setupPath: SetupPath?
    var hubURL = "http://wolf.local:6971"
    var mcpURL = "http://wolf.local:6972/mcp"
    var deviceName = Host.current().localizedName ?? "Mac"
    var shares: [ShareConfig] = []
    /// Folder of the backup made by the last install (contains restore.sh).
    var lastBackupPath: String?
    /// Where update checks look. Defaults come from the build (Info.plist).
    var repoURL: String = BuildInfo.repoURL
    var branch: String = BuildInfo.branch

    var wolfShare: ShareConfig? { shares.first { $0.role == "wolf" } ?? shares.first }
    /// Obsidian vault on the wolf share, if that share is mounted.
    var vaultPath: String? {
        guard let s = wolfShare else { return nil }
        let p = s.mountPoint + "/wolf-leader/vault"
        return FileManager.default.fileExists(atPath: p) ? p : nil
    }
    var wikiURL: URL? { URL(string: hubURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/wiki/") }
}

final class ConfigStore: ObservableObject {
    @Published var config: WolfConfig
    /// Settings > "Run setup again" sets this to show onboarding without losing the config.
    @Published var showOnboarding = false

    static var supportDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("WolfLeader", isDirectory: true)
    }
    private static var file: URL { supportDir.appendingPathComponent("config.json") }

    init() {
        if let data = try? Data(contentsOf: Self.file),
           let saved = try? JSONDecoder().decode(WolfConfig.self, from: data) {
            config = saved
        } else {
            config = WolfConfig()
        }
    }

    func save() {
        try? FileManager.default.createDirectory(at: Self.supportDir, withIntermediateDirectories: true)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(config) { try? data.write(to: Self.file, options: .atomic) }
    }

    var hub: HubClient { HubClient(baseURL: config.hubURL) }
}

enum BuildInfo {
    private static func plist(_ key: String) -> String? {
        let v = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return (v?.isEmpty == false) ? v : nil
    }
    static var version: String { plist("CFBundleShortVersionString") ?? "dev" }
    /// Commit the app was built from (set by build-app.sh).
    static var gitSHA: String? { plist("WLGitSHA") }
    static var branch: String { plist("WLGitBranch") ?? "main" }
    /// https://github.com/<owner>/<repo> of the build checkout's remote.
    static var repoURL: String { plist("WLRepoURL") ?? "" }
}

/// Files bundled with the app: installer/mac/install.sh, ini.sh, examples/, hub sources.
enum Payload {
    static var root: URL? {
        if let res = Bundle.main.resourceURL?.appendingPathComponent("payload"),
           FileManager.default.fileExists(atPath: res.appendingPathComponent("installer/mac/install.sh").path) {
            return res
        }
        // Running from Xcode / `swift run`: use the repo this package lives in.
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<7 { url.deleteLastPathComponent() }
        return FileManager.default.fileExists(atPath: url.appendingPathComponent("installer/mac/install.sh").path) ? url : nil
    }
}

/// SMB passwords in the login Keychain (same entry Finder uses, so mounting works without prompts).
enum SMBKeychain {
    static func save(host: String, user: String, password: String) -> Bool {
        let base: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: host,
            kSecAttrAccount as String: user,
            kSecAttrProtocol as String: kSecAttrProtocolSMB,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(password.utf8)
        add[kSecAttrLabel as String] = host
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func has(host: String, user: String) -> Bool {
        let q: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: host,
            kSecAttrAccount as String: user,
            kSecAttrProtocol as String: kSecAttrProtocolSMB,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        return SecItemCopyMatching(q as CFDictionary, nil) == errSecSuccess
    }

    static func delete(host: String, user: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: host,
            kSecAttrAccount as String: user,
            kSecAttrProtocol as String: kSecAttrProtocolSMB,
        ]
        SecItemDelete(q as CFDictionary)
    }
}
